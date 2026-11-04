from __future__ import annotations

import typing as t

from sqlglot import exp
from sqlglot.dialects.dialect import map_date_part
from sqlglot.helper import seq_get
from sqlglot.parsers.postgres import PostgresParser
from sqlglot.tokens import TokenType

# Marks ORDER BY items without NULLS FIRST/LAST. Vertica's default NULL placement depends on the
# sort key's type, so the generator must leave these items alone to preserve their semantics.
IMPLICIT_NULL_ORDERING = "vertica_implicit_null_ordering"

# The length that VARCHAR and VARBINARY columns get when it's omitted
DEFAULT_STRING_LENGTH = 80


# Oracle-style TRUNC(<date>, <format>) units
_TRUNC_UNITS = {
    "DD": "DAY",
    "DDD": "DAY",
    "J": "DAY",
    "HH": "HOUR",
    "HH12": "HOUR",
    "HH24": "HOUR",
    "IW": "WEEK",
    "MI": "MINUTE",
    "MM": "MONTH",
    "MON": "MONTH",
    "MONTH": "MONTH",
    "Q": "QUARTER",
    "Y": "YEAR",
    "YEAR": "YEAR",
    "YY": "YEAR",
    "YYY": "YEAR",
    "YYYY": "YEAR",
}


def _build_trunc(args: list) -> exp.Expr:
    unit = seq_get(args, 1)
    if len(args) == 2 and unit and unit.is_string and unit.name.upper() in _TRUNC_UNITS:
        return exp.TimestampTrunc(this=args[0], unit=exp.var(_TRUNC_UNITS[unit.name.upper()]))
    return exp.Trunc(this=seq_get(args, 0), decimals=unit)


def _build_date_diff(args: list) -> exp.DateDiff:
    return exp.DateDiff(
        this=seq_get(args, 2),
        expression=seq_get(args, 1),
        unit=map_date_part(seq_get(args, 0)),
        date_part_boundary=True,
    )


class VerticaParser(PostgresParser):
    FUNCTIONS = {
        **PostgresParser.FUNCTIONS,
        "ADD_MONTHS": lambda args: exp.AddMonths(
            this=seq_get(args, 0), expression=seq_get(args, 1), preserve_end_of_month=True
        ),
        "CONTAINS": exp.ArrayContains.from_arg_list,
        "DATEDIFF": _build_date_diff,
        "EDIT_DISTANCE": exp.Levenshtein.from_arg_list,
        "GROUPING_ID": lambda args: exp.Grouping(expressions=args),
        "HEX_TO_BINARY": exp.Unhex.from_arg_list,
        "ISNULL": lambda args: exp.Coalesce(this=seq_get(args, 0), expressions=args[1:]),
        "MONTHS_BETWEEN": exp.MonthsBetween.from_arg_list,
        "NULLIFZERO": lambda args: exp.Nullif(
            this=seq_get(args, 0), expression=exp.Literal.number(0)
        ),
        "REGEXP_ILIKE": exp.RegexpILike.from_arg_list,
        # Unlike in Postgres, every occurrence is replaced unless `occurrence` says otherwise
        "REGEXP_REPLACE": lambda args: exp.RegexpReplace(
            this=seq_get(args, 0),
            expression=seq_get(args, 1),
            replacement=seq_get(args, 2),
            position=seq_get(args, 3),
            occurrence=seq_get(args, 4),
            modifiers=seq_get(args, 5),
        ),
        "TIMESTAMPADD": lambda args: exp.TimestampAdd(
            this=seq_get(args, 2),
            expression=seq_get(args, 1),
            unit=map_date_part(seq_get(args, 0)),
        ),
        "TIMESTAMPDIFF": _build_date_diff,
        "TO_HEX": exp.Hex.from_arg_list,
        "TRUNC": _build_trunc,
        "WEEK_ISO": lambda args: exp.Extract(this=exp.var("WEEK"), expression=seq_get(args, 0)),
        "UUID_GENERATE": lambda args: exp.Uuid(),
        "ZEROIFNULL": lambda args: exp.Coalesce(
            this=seq_get(args, 0), expressions=[exp.Literal.number(0)]
        ),
    }

    FUNCTION_PARSERS = {
        **PostgresParser.FUNCTION_PARSERS,
        "LISTAGG": lambda self: self._parse_listagg(),
    }

    def _parse_listagg(self) -> exp.GroupConcat:
        # LISTAGG(expr [USING PARAMETERS separator = ',', ...]) [WITHIN GROUP (ORDER BY ...)]
        this = self._parse_assignment()
        separator: exp.Expr = exp.Literal.string(",")

        if self._match_text_seq("USING", "PARAMETERS"):
            for parameter in self._parse_csv(self._parse_assignment):
                if isinstance(parameter, exp.EQ) and parameter.this.name.lower() == "separator":
                    separator = parameter.expression
                else:
                    self.raise_error(f"Unsupported LISTAGG parameter: {parameter}")

        # Like STRING_AGG, the WITHIN GROUP order is folded into the GroupConcat. The caller
        # matches the closing parenthesis of WITHIN GROUP.
        index = self._index
        if self._match(TokenType.R_PAREN) and self._match_text_seq("WITHIN", "GROUP"):
            self._match_l_paren()
            this = self._parse_order(this=this)
        else:
            self._retreat(index)

        return self.expression(exp.GroupConcat(this=this, separator=separator))

    def _parse_extract(self) -> exp.Extract | exp.Anonymous:
        extract = super()._parse_extract()

        # Vertica's WEEK counts weeks from January 1st, unlike other dialects' ISO 8601 WEEK,
        # which is Vertica's ISOWEEK
        if isinstance(extract, exp.Extract):
            unit = extract.name.upper()
            if unit == "WEEK":
                return exp.Anonymous(this="WEEK", expressions=[extract.expression])
            if unit == "ISOWEEK":
                extract.set("this", exp.var("WEEK"))
        return extract

    def _parse_types(
        self,
        check_func: bool = False,
        schema: bool = False,
        allow_identifiers: bool = True,
        with_collation: bool = False,
    ) -> exp.Expr | None:
        index = self._index

        # ARRAY[INT], as opposed to the ARRAY[1, 2] constructor
        if self._match(TokenType.ARRAY) and self._match(TokenType.L_BRACKET):
            element = self._parse_types(check_func=check_func, schema=schema)
            if (
                isinstance(element, exp.DataType)
                and not element.is_type(exp.DType.USERDEFINED)
                and self._match(TokenType.R_BRACKET)
            ):
                return exp.DataType(this=exp.DType.ARRAY, expressions=[element], nested=True)
            self._retreat(index)

        data_type = super()._parse_types(
            check_func=check_func,
            schema=schema,
            allow_identifiers=allow_identifiers,
            with_collation=with_collation,
        )

        # Make the implicit length of columns explicit, since other dialects' VARCHAR is
        # unbounded. Casts to VARCHAR without a length don't truncate.
        if (
            schema
            and isinstance(data_type, exp.DataType)
            and data_type.is_type(exp.DType.VARCHAR, exp.DType.VARBINARY)
            and not data_type.expressions
        ):
            data_type.set(
                "expressions",
                [exp.DataTypeParam(this=exp.Literal.number(DEFAULT_STRING_LENGTH))],
            )

        return data_type

    def _parse_ordered(
        self, parse_method: t.Callable[[], exp.Expr | None] | None = None
    ) -> exp.Ordered | None:
        ordered = super()._parse_ordered(parse_method)
        prev = self._tokens[max(self._index - 2, 0) : self._index]
        explicit = (
            len(prev) == 2
            and prev[0].text.upper() == "NULLS"
            and prev[1].text.upper() in ("FIRST", "LAST")
        )
        if ordered and not explicit:
            ordered.meta[IMPLICIT_NULL_ORDERING] = True
        return ordered

    def _parse_window(self, this: exp.Expr | None, alias: bool = False) -> exp.Expr | None:
        window = super()._parse_window(this, alias=alias)

        # Inside windows, NULLs sort as the largest values regardless of the type
        if isinstance(window, exp.Window):
            order = window.args.get("order")
            for ordered in order.expressions if order else []:
                if ordered.meta.get(IMPLICIT_NULL_ORDERING):
                    ordered.set("nulls_first", bool(ordered.args.get("desc")))

        return window
