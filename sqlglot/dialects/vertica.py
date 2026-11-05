from __future__ import annotations

from sqlglot import exp
from sqlglot.dialects.dialect import NormalizationStrategy
from sqlglot.dialects.postgres import Postgres
from sqlglot.generators.vertica import VerticaGenerator
from sqlglot.parsers.vertica import VerticaParser, format_time_outside_quotes
from sqlglot.tokens import TokenType


class Vertica(Postgres):
    """
    Vertica (OpenText Analytics Database). Its SQL derives from Postgres, so this dialect builds on
    the Postgres one. Reference: https://docs.vertica.com/latest/en/sql-reference/

    conformance/dialects/vertica.md documents how this dialect models Vertica, what it supports, its
    known bugs, and how to test changes against a real Vertica.
    """

    # Identifiers are case-insensitive, even when quoted
    NORMALIZATION_STRATEGY = NormalizationStrategy.CASE_INSENSITIVE
    INDEX_OFFSET = 0

    # Dividing integers returns an exact NUMERIC, e.g. 5 / 2 = 2.5, and `//` divides integers
    TYPED_DIVISION = False

    # CONCAT, GREATEST, LEAST and array functions like ARRAY_CAT return NULL if any argument is NULL
    CONCAT_COALESCE = False
    LEAST_GREATEST_IGNORES_NULLS = False
    ARRAY_FUNCS_PROPAGATES_NULLS = True

    # Outside of windows, NULLs sort first for numeric and temporal types but last for strings,
    # floats and booleans; this assumes the former. Inside windows they always sort as the largest
    # values, which the parser accounts for, and the generator spells out NULL placement.
    NULL_ORDERING = "nulls_are_small"

    SUPPORTS_LIMIT_ALL = False
    # TABLESAMPLE comes before the table alias
    ALIAS_POST_TABLESAMPLE = True
    TABLES_REFERENCEABLE_AS_COLUMNS = False

    TIME_MAPPING = {
        **Postgres.TIME_MAPPING,
        # Lowercase patterns that contain a mapped one, e.g. "d", but differ from its uppercase form
        "ad": "ad",
        "a.d.": "a.d.",
        "id": "id",
    }

    @classmethod
    def format_time(cls, expression: str | exp.Expr | None) -> exp.Expr | None:
        if isinstance(expression, exp.Expr) and expression.is_string:
            return exp.Literal.string(
                format_time_outside_quotes(expression.this, cls.TIME_MAPPING, cls.TIME_TRIE)
            )
        return super().format_time(expression)

    class Tokenizer(Postgres.Tokenizer):
        TOKENS_PRECEDING_HINT = {*Postgres.Tokenizer.TOKENS_PRECEDING_HINT, TokenType.WITH}
        # `!` is the factorial operator, except as part of operators like != and !~~
        SINGLE_TOKENS = {**Postgres.Tokenizer.SINGLE_TOKENS, "!": TokenType.EXCLAMATION}

        KEYWORDS = {
            **Postgres.Tokenizer.KEYWORDS,
            "/*+": TokenType.HINT,
            "//": TokenType.DIV,
            "INTERVALYM": TokenType.INTERVAL,
            "!~": TokenType.RLIKE,
            "!~*": TokenType.IRLIKE,
            "!~~": TokenType.LIKE,
            "!~~*": TokenType.ILIKE,
            "~#": TokenType.LIKE,
            "~#*": TokenType.ILIKE,
            "!~#": TokenType.LIKE,
            "!~#*": TokenType.ILIKE,
            "LIKEB": TokenType.LIKE,
            "ILIKEB": TokenType.ILIKE,
            # Casts that return NULL instead of failing
            "::!": TokenType.QDCOLON,
            "BINARY VARYING": TokenType.VARBINARY,
            "ROW": TokenType.STRUCT,
            # All integer types are 64-bit and all floating point types are 64-bit
            "INT": TokenType.BIGINT,
            "INTEGER": TokenType.BIGINT,
            "SMALLINT": TokenType.BIGINT,
            "TINYINT": TokenType.BIGINT,
            "FLOAT8": TokenType.DOUBLE,
            "REAL": TokenType.DOUBLE,
            "BYTEA": TokenType.VARBINARY,
            "RAW": TokenType.VARBINARY,
            "LONG VARBINARY": TokenType.LONGBLOB,
            "LONG VARCHAR": TokenType.LONGTEXT,
            "MATCH": TokenType.MATCH_RECOGNIZE,
            "MINUS": TokenType.EXCEPT,
            "TIMESERIES": TokenType.TIMESERIES,
            "DATETIME": TokenType.TIMESTAMP,
            "SMALLDATETIME": TokenType.TIMESTAMP,
            "NUMBER": TokenType.DECIMAL,
        }

    Parser = VerticaParser

    Generator = VerticaGenerator
