from __future__ import annotations

import os
import typing as t
from datetime import date, datetime, time, timedelta
from decimal import Decimal
from uuid import UUID

from conformance.engines.base import (
    STATEMENT_TIMEOUT_SECONDS,
    Engine,
    EngineError,
    EngineUnavailable,
)
from conformance.result import Result

if t.TYPE_CHECKING:
    from conformance.dataset.model import Table

_FAMILIES = {
    "Boolean": "boolean",
    "Integer": "integer",
    "Numeric": "decimal",
    "Float": "float",
    "Char": "string",
    "Varchar": "string",
    "Long Varchar": "string",
    "Binary": "binary",
    "Varbinary": "binary",
    "Long Varbinary": "binary",
    "Date": "date",
    "Time": "time",
    "TimeTz": "time",
    "Timestamp": "timestamp",
    "TimestampTz": "timestamptz",
    "Interval Day to Second": "interval",
    "Interval Year to Month": "interval",
    "Uuid": "uuid",
    "Row": "struct",
}

# Rows per INSERT ... SELECT ... UNION ALL statement when loading tables
_INSERT_BATCH_SIZE = 500


class Vertica(Engine):
    name = "vertica"
    dialect = "vertica"
    service = "vertica"

    # CHAR(n) and VARCHAR(n) lengths count bytes, not characters
    CHAR_LENGTH_IN_BYTES = True

    def __init__(self, timezone: str = "UTC") -> None:
        super().__init__(timezone)
        self.options: dict[str, t.Any] = {
            "host": "127.0.0.1",
            "port": int(os.environ.get("CONFORMANCE_VERTICA_PORT", "55433")),
            "user": "dbadmin",
            "password": "sqlglot",
            "database": "conformance",
        }
        # e.g. "host=db.example.com port=5433 user=dbadmin password=secret database=analytics"
        for option in os.environ.get("CONFORMANCE_VERTICA_DSN", "").split():
            key, _, value = option.partition("=")
            self.options[key] = int(value) if key == "port" else value
        self._connection: t.Any = None

    @property
    def external(self) -> bool:
        return "CONFORMANCE_VERTICA_DSN" in os.environ

    def connect(self) -> None:
        if self._connection is not None and not self._connection.closed():
            return

        import warnings

        import vertica_python

        # The driver reports server notices, such as "no transaction in progress", as warnings
        warnings.filterwarnings("ignore", module="vertica_python")
        try:
            connection = vertica_python.connect(
                **self.options,
                autocommit=False,
                tlsmode="disable",
                # This bounds every socket read, so it must outlast the statement timeout
                connection_timeout=STATEMENT_TIMEOUT_SECONDS + 10,
                # The text protocol rounds floats to 15 significant digits
                binary_transfer=True,
            )
        except Exception as e:
            raise EngineUnavailable(
                f"can't connect to Vertica at {self.options['host']}: {e}"
            ) from e

        cursor = connection.cursor()
        zone = self.timezone.replace("'", "''")
        cursor.execute(f"SET TIME ZONE TO '{zone}'")
        cursor.execute("SET DATESTYLE TO ISO")
        cursor.execute(f"SET SESSION RUNTIMECAP '{STATEMENT_TIMEOUT_SECONDS} seconds'")
        self._connection = connection

    def close(self) -> None:
        if self._connection is not None:
            self._connection.close()
            self._connection = None

    def version(self) -> str:
        return str(self.query("SELECT VERSION()").rows[0][0])

    def query(self, sql: str) -> Result:
        import vertica_python

        self.connect()
        connection = self._connection
        cursor = connection.cursor()
        try:
            cursor.execute(sql)
            description = cursor.description or []
            rows = cursor.fetchall() if cursor.description else []
        except vertica_python.errors.QueryError as e:
            raise EngineError(f"{e.message} (SQLSTATE {e.sqlstate})") from e
        except (vertica_python.errors.ConnectionError, OSError) as e:
            self._connection = None
            raise EngineUnavailable(f"lost the connection to Vertica: {e}") from e
        except vertica_python.errors.Error as e:
            raise EngineError(str(e)) from e
        finally:
            # Rolling back keeps cases from leaving side effects behind
            if self._connection is not None:
                connection.rollback()

        types = [d.type_name for d in description]
        return Result(
            columns=[d.name for d in description],
            types=types,
            families=[_family(name) for name in types],
            rows=[tuple(_convert(value) for value in row) for row in rows],
        )

    def load_table(self, table: Table) -> None:
        import vertica_python

        self.connect()
        connection = self._connection
        cursor = connection.cursor()

        types = [column.types[self.name] for column in table.columns]
        rows = [
            "SELECT " + ", ".join(f"CAST({_literal(v)} AS {ddl})" for v, ddl in zip(row, types))
            for row in table.rows
        ]
        statements = [
            f"DROP TABLE IF EXISTS {table.name}",
            f"CREATE TABLE {table.name} ({self.column_definitions(table)})",
            *(
                f"INSERT INTO {table.name} "
                + " UNION ALL ".join(rows[start : start + _INSERT_BATCH_SIZE])
                for start in range(0, len(rows), _INSERT_BATCH_SIZE)
            ),
            # Without statistics, Vertica plans joins of even small tables badly enough to time out
            f"SELECT ANALYZE_STATISTICS('{table.name}')",
        ]
        try:
            for statement in statements:
                cursor.execute(statement)
            connection.commit()
        except vertica_python.errors.QueryError as e:
            connection.rollback()
            raise EngineError(f"{e.message} (SQLSTATE {e.sqlstate})") from e


def _family(type_name: str) -> str:
    if type_name.startswith(("Array[", "Set[")):
        return "array"
    return _FAMILIES.get(type_name, type_name.lower())


def _convert(value: t.Any) -> t.Any:
    """Converts driver values that the comparator doesn't understand."""
    # Day-to-second intervals arrive as dateutil relativedeltas
    if type(value).__name__ == "relativedelta" and not (value.years or value.months):
        return timedelta(
            days=value.days,
            hours=value.hours,
            minutes=value.minutes,
            seconds=value.seconds,
            microseconds=value.microseconds,
        )
    if isinstance(value, list):
        return [_convert(v) for v in value]
    return value


def _literal(value: t.Any) -> str:
    """Renders a Python value as a Vertica literal, without relying on sqlglot."""
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if value != value:
            return "'NaN'"
        if value in (float("inf"), float("-inf")):
            return "'Infinity'" if value > 0 else "'-Infinity'"
        return f"'{value!r}'"
    if isinstance(value, (Decimal, UUID)):
        return f"'{value}'"
    if isinstance(value, str):
        return "'" + value.replace("'", "''") + "'"
    if isinstance(value, (bytes, bytearray)):
        return f"HEX_TO_BINARY('{bytes(value).hex()}')"
    if isinstance(value, datetime):
        return f"'{value.isoformat(sep=' ')}'"
    if isinstance(value, (date, time)):
        return f"'{value.isoformat()}'"
    if isinstance(value, timedelta):
        return f"'{value // timedelta(microseconds=1)} microseconds'"
    if isinstance(value, list):
        return f"ARRAY[{', '.join(_literal(v) for v in value)}]"
    if isinstance(value, dict):
        return f"ROW({', '.join(_literal(v) for v in value.values())})"
    raise TypeError(f"can't render {value!r} as a Vertica literal")
