from __future__ import annotations

from sqlglot.dialects.dialect import NormalizationStrategy
from sqlglot.dialects.postgres import Postgres
from sqlglot.generators.vertica import VerticaGenerator
from sqlglot.parsers.vertica import VerticaParser
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
    TABLES_REFERENCEABLE_AS_COLUMNS = False

    class Tokenizer(Postgres.Tokenizer):
        KEYWORDS = {
            **Postgres.Tokenizer.KEYWORDS,
            "//": TokenType.DIV,
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
            "DATETIME": TokenType.TIMESTAMP,
            "SMALLDATETIME": TokenType.TIMESTAMP,
            "NUMBER": TokenType.DECIMAL,
        }

    Parser = VerticaParser

    Generator = VerticaGenerator
