from __future__ import annotations

import typing as t

from sqlglot import exp, transforms
from sqlglot.dialects.dialect import date_delta_sql, no_filter_sql, rename_func
from sqlglot.generator import unsupported_args
from sqlglot.generators.postgres import PostgresGenerator
from sqlglot.parsers.vertica import IMPLICIT_NULL_ORDERING

# The longest VARCHAR / VARBINARY, used for types that are unbounded in other dialects
MAX_STRING_LENGTH = 65000

# Outside of windows, NULLs of these types sort as the smallest values; others as the largest
_NULLS_ARE_SMALL_TYPES = {
    *(exp.DataType.NUMERIC_TYPES - exp.DataType.FLOAT_TYPES),
    *exp.DataType.TEMPORAL_TYPES,
    exp.DType.INTERVAL,
}


def _cross_joins_to_commas(expression: exp.Expr) -> exp.Expr:
    """
    Vertica executes an explicit CROSS JOIN as a cross product even when the WHERE clause joins the
    tables, which makes such queries orders of magnitude slower than with comma joins. Commas bind
    looser than JOIN, so they are only used when every join of the query is an unconditional one.
    """
    joins = expression.args.get("joins") or []
    if joins and all(
        join.args.get("kind") in (None, "CROSS")
        and not join.args.get("side")
        and not join.args.get("on")
        and not join.args.get("using")
        and not isinstance(join.this, (exp.Lateral, exp.Unnest))
        for join in joins
    ):
        for join in joins:
            join.set("kind", None)
    return expression


def _order_outside_for_null_placement(expression: exp.Expr) -> exp.Expr:
    """
    Vertica places NULLs with extra sort keys (see ordered_sql), which the ORDER BY of a SELECT
    DISTINCT or of a set operation can't contain. Such queries are wrapped in an ordered subquery.
    """
    order = expression.args.get("order")
    distinct = isinstance(expression, exp.Select) and expression.args.get("distinct")
    if not order or not (distinct or isinstance(expression, exp.SetOperation)):
        return expression
    if all(ordered.meta.get(IMPLICIT_NULL_ORDERING) for ordered in order.expressions):
        return expression

    query = t.cast(exp.Query, expression)
    names = query.named_selects
    keys = []
    for ordered in order.expressions:
        key = ordered.this
        if key.is_int and 0 < int(key.name) <= len(names):
            name = names[int(key.name) - 1]
        elif isinstance(key, exp.Column) and not key.table:
            name = key.name
        else:
            return expression
        if not name or name == "*" or name not in names:
            return expression
        key = ordered.copy()
        key.set("this", exp.column(name, table="_q"))
        keys.append(key)

    inner = query.copy()
    for arg in ("order", "limit", "offset"):
        inner.set(arg, None)

    outer = exp.select("*").from_(inner.subquery("_q"))
    outer.set("order", exp.Order(expressions=keys))
    outer.set("limit", query.args.get("limit"))
    outer.set("offset", query.args.get("offset"))
    return outer


class VerticaGenerator(PostgresGenerator):
    # INTERVAL '1 MONTH' means 30 days in Vertica; INTERVAL '1' MONTH is a calendar month
    SINGLE_STRING_INTERVAL = False
    # INTERVAL '30' MINUTES parses as INTERVAL '30' aliased as MINUTES
    INTERVAL_ALLOWS_PLURAL_FORM = False
    LIMIT_FETCH = "LIMIT"
    VALUES_AS_TABLE = False

    TYPE_MAPPING = {
        **PostgresGenerator.TYPE_MAPPING,
        exp.DType.BINARY: "VARBINARY",
        exp.DType.BLOB: "VARBINARY",
        exp.DType.JSON: "VARCHAR",
        exp.DType.JSONB: "VARCHAR",
        exp.DType.LONGBLOB: "LONG VARBINARY",
        exp.DType.LONGTEXT: "LONG VARCHAR",
        exp.DType.ROWVERSION: "VARBINARY",
        exp.DType.TEXT: "VARCHAR",
        exp.DType.VARBINARY: "VARBINARY",
    }

    TRANSFORMS = {
        **{
            k: v
            for k, v in PostgresGenerator.TRANSFORMS.items()
            if k not in (exp.GroupConcat, exp.Levenshtein, exp.RegexpReplace, exp.StrPosition)
        },
        exp.DayOfWeek: rename_func("DAYOFWEEK"),
        exp.DayOfWeekIso: rename_func("DAYOFWEEK_ISO"),
        exp.DayOfYear: rename_func("DAYOFYEAR"),
        exp.ArrayContains: rename_func("CONTAINS"),
        exp.DateDiff: date_delta_sql("DATEDIFF"),
        exp.Filter: no_filter_sql,
        exp.Hex: rename_func("TO_HEX"),
        exp.IntDiv: lambda self, e: self.binary(e, "//"),
        exp.NullSafeEQ: lambda self, e: self.binary(e, "<=>"),
        exp.NullSafeNEQ: lambda self, e: f"NOT {self.binary(e, '<=>')}",
        exp.Select: transforms.preprocess(
            [
                transforms.eliminate_distinct_on,
                transforms.eliminate_semi_and_anti_joins,
                transforms.eliminate_qualify,
                _cross_joins_to_commas,
                _order_outside_for_null_placement,
            ]
        ),
        exp.Except: lambda self, e: self._set_operation_sql(e),
        exp.Intersect: lambda self, e: self._set_operation_sql(e),
        exp.StartsWith: lambda self, e: self.sql(
            exp.Left(this=e.this, expression=exp.Length(this=e.expression)).eq(e.expression)
        ),
        exp.Union: lambda self, e: self._set_operation_sql(e),
        exp.Unhex: rename_func("HEX_TO_BINARY"),
        exp.Uuid: lambda *_: "UUID_GENERATE()",
    }

    def _set_operation_sql(self, expression: exp.SetOperation) -> str:
        wrapped = _order_outside_for_null_placement(expression)
        if wrapped is not expression:
            return self.sql(wrapped)
        return self.set_operations(expression)

    def datatype_sql(self, expression: exp.DataType) -> str:
        if expression.is_type(exp.DType.ARRAY):
            if expression.expressions:
                return f"ARRAY[{self.expressions(expression, flat=True)}]"
            return "ARRAY"

        # Columns of these types are unbounded in other dialects, but default to 80 bytes in
        # Vertica. Casts to VARCHAR without a length don't truncate, though.
        if (
            isinstance(expression.parent, exp.ColumnDef)
            and expression.is_type(
                exp.DType.BINARY,
                exp.DType.BLOB,
                exp.DType.JSON,
                exp.DType.JSONB,
                exp.DType.TEXT,
                exp.DType.VARBINARY,
                exp.DType.VARCHAR,
            )
            and not expression.expressions
        ):
            expression = expression.copy()
            expression.set(
                "expressions", [exp.DataTypeParam(this=exp.Literal.number(MAX_STRING_LENGTH))]
            )

        return super().datatype_sql(expression)

    def ordered_sql(self, expression: exp.Ordered) -> str:
        desc = expression.args.get("desc")
        sort_order = " DESC" if desc else (" ASC" if desc is False else "")
        this = self.sql(expression, "this")

        if expression.meta.get(IMPLICIT_NULL_ORDERING):
            return f"{this}{sort_order}"

        nulls_first = bool(expression.args.get("nulls_first"))

        # Ordered-set aggregates (e.g. PERCENTILE_CONT, LISTAGG) ignore NULLs and take a single key
        if isinstance(expression.find_ancestor(exp.WithinGroup, exp.Select), exp.WithinGroup):
            return f"{this}{sort_order}"

        # Inside windows, NULLS FIRST/LAST is supported and NULLs sort as the largest values
        if isinstance(expression.find_ancestor(exp.Window, exp.Select), exp.Window):
            if nulls_first == bool(desc):
                return f"{this}{sort_order}"
            return f"{this}{sort_order} NULLS {'FIRST' if nulls_first else 'LAST'}"

        key = expression.this
        if isinstance(key, exp.Null) or (isinstance(key, exp.Literal) and not key.is_int):
            return f"{this}{sort_order}"

        target = self._null_ordering_target(expression)
        if target is None:
            self.unsupported("Vertica can't specify where NULLs sort for this ORDER BY key")
            return f"{this}{sort_order}"

        # Elsewhere, NULLS FIRST/LAST isn't supported and the default depends on the type, so an
        # extra sort key places NULLs, unless the type is known and the default already matches
        if target.type and not target.is_type(exp.DType.UNKNOWN):
            nulls_are_small = target.is_type(*_NULLS_ARE_SMALL_TYPES)
            if nulls_first == (nulls_are_small != bool(desc)):
                return f"{this}{sort_order}"

        nulls_key = f"CASE WHEN {self.sql(target)} IS NULL THEN 1 ELSE 0 END"
        return f"{nulls_key}{' DESC' if nulls_first else ''}, {this}{sort_order}"

    def _null_ordering_target(self, expression: exp.Ordered) -> exp.Expr | None:
        """The expression that an ORDER BY key sorts by, or None if it can't be referenced."""
        key = expression.this
        order = expression.parent
        query = order.parent if isinstance(order, exp.Order) else None

        if key.is_int:
            position = int(key.name)
            if isinstance(query, exp.Select) and 0 < position <= len(query.selects):
                return query.selects[position - 1].unalias()
            return None

        # Set operations can only be ordered by their output columns, not by expressions
        if isinstance(query, exp.SetOperation):
            return None

        return self._resolve_ordered_for_null_ordering_simulation(expression) or key

    def arraysize_sql(self, expression: exp.ArraySize) -> str:
        dimension = expression.expression
        if dimension and not (dimension.is_int and dimension.to_py() == 1):
            self.unsupported("Vertica's ARRAY_LENGTH only measures the first dimension")
        return self.func("ARRAY_LENGTH", expression.this)

    def strposition_sql(self, expression: exp.StrPosition) -> str:
        position = expression.args.get("position")
        occurrence = expression.args.get("occurrence")
        if position or occurrence:
            return self.func(
                "INSTR",
                expression.this,
                expression.args.get("substr"),
                position or exp.Literal.number(1),
                occurrence,
            )
        return self.func("STRPOS", expression.this, expression.args.get("substr"))

    def div_sql(self, expression: exp.Div) -> str:
        # Integer literals don't need type annotations to know that they divide as integers
        if expression.args.get("typed") and expression.left.is_int and expression.right.is_int:
            return self.sql(exp.IntDiv(this=expression.left, expression=expression.right))
        return super().div_sql(expression)

    def extract_sql(self, expression: exp.Extract) -> str:
        # Vertica's WEEK isn't the ISO 8601 week other dialects mean
        if expression.name.upper() == "WEEK":
            expression = expression.copy()
            expression.set("this", exp.var("ISOWEEK"))
        return super().extract_sql(expression)

    def grouping_sql(self, expression: exp.Grouping) -> str:
        # Vertica's GROUPING takes a single argument; GROUPING_ID computes the same bitmask
        name = "GROUPING_ID" if len(expression.expressions) > 1 else "GROUPING"
        return self.func(name, *expression.expressions)

    def regexpreplace_sql(self, expression: exp.RegexpReplace) -> str:
        modifiers = expression.args.get("modifiers")
        flags = modifiers.name if modifiers and modifiers.is_string else ""
        replace_all = "g" in flags or not expression.args.get("single_replace")
        flags = flags.replace("g", "")

        # Vertica replaces every occurrence by default, or only the given one (0 means all)
        occurrence = expression.args.get("occurrence")
        if occurrence is None and not replace_all:
            occurrence = exp.Literal.number(1)
        if occurrence is None and flags:
            occurrence = exp.Literal.number(0)

        position = expression.args.get("position")
        if position is None and occurrence is not None:
            position = exp.Literal.number(1)

        return self.func(
            "REGEXP_REPLACE",
            expression.this,
            expression.expression,
            expression.args.get("replacement") or exp.Literal.string(""),
            position,
            occurrence,
            exp.Literal.string(flags) if flags else None,
        )

    def groupconcat_sql(self, expression: exp.GroupConcat) -> str:
        this = expression.this
        order = this.find(exp.Order)
        if order and order.this:
            this = order.this.pop()

        separator = expression.args.get("separator")
        parameters = ""
        if separator and not (separator.is_string and separator.name == ","):
            if not separator.is_string:
                self.unsupported("Vertica's LISTAGG separator must be a string literal")
            parameters = f" USING PARAMETERS separator={self.sql(separator)}"

        listagg = f"LISTAGG({self.sql(this)}{parameters})"
        if order:
            listagg = f"{listagg} WITHIN GROUP ({self.sql(order).strip()})"
        return listagg

    def greatest_sql(self, expression: exp.Greatest) -> str:
        return self.func("GREATEST", *self._null_ignoring_args(expression))

    def least_sql(self, expression: exp.Least) -> str:
        return self.func("LEAST", *self._null_ignoring_args(expression))

    def _null_ignoring_args(self, expression: exp.Greatest | exp.Least) -> list[exp.Expr]:
        args = [expression.this, *expression.expressions]
        if not expression.args.get("ignore_nulls") or len(args) < 2:
            return args

        # Vertica returns NULL if any argument is NULL. Replacing each argument with the first
        # non-NULL one, starting from itself, ignores NULLs unless every argument is NULL.
        return [
            exp.Coalesce(
                this=arg.copy(), expressions=[other.copy() for other in args if other is not arg]
            )
            for arg in args
        ]

    @unsupported_args("ins_cost", "del_cost", "sub_cost", "max_dist")
    def levenshtein_sql(self, expression: exp.Levenshtein) -> str:
        return self.func("EDIT_DISTANCE", expression.this, expression.expression)
