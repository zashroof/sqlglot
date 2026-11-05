from __future__ import annotations

import re
import typing as t

from sqlglot import exp
from sqlglot.dialects.dialect import build_formatted_time
from sqlglot.helper import seq_get
from sqlglot.parser import IsPredicatePrecedence
from sqlglot.parsers.postgres import PostgresParser
from sqlglot.time import format_time
from sqlglot.tokens import TokenType

# Marks ORDER BY items without NULLS FIRST/LAST. Vertica's default NULL placement depends on the
# sort key's type, so the generator must leave these items alone to preserve their semantics.
IMPLICIT_NULL_ORDERING = "vertica_implicit_null_ordering"

# Partitionings of transform functions' input, as in OVER (PARTITION BEST)
TRANSFORM_PARTITIONS = ("BEST", "NODES", "ROW", "LEFT JOIN")
# Marks casts written as typed literals, e.g. TIMESTAMP '...', which unlike CAST become a
# TIMESTAMPTZ or TIMETZ when the string includes a time zone
TYPED_LITERAL = "vertica_typed_literal"

# The length that VARCHAR and VARBINARY columns get when it's omitted
DEFAULT_STRING_LENGTH = 80

# The units of interval qualifiers. Other words after an interval literal, such as MINUTES or
# WEEK, are column aliases: INTERVAL '30' MINUTES is 30 days.
_INTERVAL_QUALIFIER_UNITS = {"YEAR", "MONTH", "DAY", "HOUR", "MINUTE", "SECOND"}

# Double-quoted text in TO_CHAR-style templates is copied verbatim
_QUOTED_TEMPLATE_TEXT_RE = re.compile(r'("[^"]*")')


def format_time_outside_quotes(string: str, mapping: dict[str, str], trie: dict) -> str:
    """Converts a TO_CHAR-style template, leaving its double-quoted literal text untouched."""
    return "".join(
        part if part.startswith('"') else format_time(part, mapping, trie) or ""
        for part in _QUOTED_TEMPLATE_TEXT_RE.split(string)
    )


# Marks LIKE and ILIKE predicates written as LIKEB, ILIKEB, ~# or ~#*, which compare bytes
BYTEWISE_LIKE = "vertica_bytewise_like"

_BYTEWISE_LIKE_OPERATORS = {"LIKEB", "ILIKEB", "~#", "~#*", "!~#", "!~#*"}

# Marks the COALESCE and NULLIF that ZEROIFNULL and NULLIFZERO parse into with the function's name.
# Unlike COALESCE(x, 0) and NULLIF(x, 0), these also accept intervals.
ZERO_NULL_FUNCTION = "vertica_zero_null_function"
# Implicit parameters of types whose defaults differ from what they're generated as: NUMBER is
# NUMERIC(38, 0) rather than NUMERIC's (37, 15), and BINARY is one byte, unlike other dialects'
_DEFAULT_TYPE_PARAMS = {"BINARY": (1,), "NUMBER": (38, 0)}


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


# DATEDIFF, TIMESTAMPDIFF and TIMESTAMPADD units. Some abbreviations differ from other dialects,
# e.g. M is MONTH and Y is DAY.
_DATE_PART_UNITS = {
    "YY": "YEAR",
    "YYYY": "YEAR",
    "QQ": "QUARTER",
    "Q": "QUARTER",
    "MM": "MONTH",
    "M": "MONTH",
    "DAYOFYEAR": "DAY",
    "DD": "DAY",
    "D": "DAY",
    "DY": "DAY",
    "Y": "DAY",
    "WK": "WEEK",
    "WW": "WEEK",
    "HH": "HOUR",
    "MI": "MINUTE",
    "N": "MINUTE",
    "SS": "SECOND",
    "S": "SECOND",
    "MS": "MILLISECOND",
    "MCS": "MICROSECOND",
    "US": "MICROSECOND",
}


def _map_date_part(unit: exp.Expr | None) -> exp.Expr | None:
    if isinstance(unit, (exp.Column, exp.Literal, exp.Var)):
        name = unit.name.upper()
        return exp.var(_DATE_PART_UNITS.get(name, name))
    return unit


def _build_trunc(args: list) -> exp.Expr:
    unit = seq_get(args, 1)
    if len(args) == 2 and unit and unit.is_string and unit.name.upper() in _TRUNC_UNITS:
        return exp.TimestampTrunc(this=args[0], unit=exp.var(_TRUNC_UNITS[unit.name.upper()]))
    return exp.Trunc(this=seq_get(args, 0), decimals=unit)


def _build_timestamp_trunc(args: list) -> exp.Expr:
    trunc = _build_trunc(args)
    if isinstance(trunc, exp.TimestampTrunc):
        return trunc
    return exp.Anonymous(this="TIMESTAMP_TRUNC", expressions=args)


def _build_to_char(args: list, dialect: t.Any) -> exp.ToChar | exp.TimeToStr:
    if len(args) == 1:
        return exp.ToChar(this=seq_get(args, 0))
    return build_formatted_time(exp.TimeToStr)(args, dialect)


def _parse_typed_literal(self: VerticaParser, this: exp.Expr, data_type: exp.DataType) -> exp.Cast:
    cast = self.expression(exp.Cast(this=this, to=data_type))
    if this.is_string:
        cast.meta[TYPED_LITERAL] = True
    return cast


def _build_zero_null(name: str, expression: exp.Coalesce | exp.Nullif) -> exp.Expr:
    expression.meta[ZERO_NULL_FUNCTION] = name
    return expression


def _build_angle(expr_type: type[exp.Func]) -> t.Callable[[list], exp.Expr]:
    # DEGREES and RADIANS also take an angle as degrees, minutes and seconds
    def _builder(args: list) -> exp.Expr:
        if len(args) == 1:
            return expr_type(this=args[0])
        return exp.Anonymous(this=expr_type.key.upper(), expressions=args)

    return _builder


def _negatable_range_parser(
    parser: t.Callable[[VerticaParser, exp.Expr | None], exp.Expr | None],
) -> t.Callable[[VerticaParser, exp.Expr | None], exp.Expr | None]:
    # Operators such as !~ and !~~ are negated by their leading `!`
    def _parse(self: VerticaParser, this: exp.Expr | None) -> exp.Expr | None:
        operator = self._prev.text.upper()
        expression = parser(self, this)
        predicate = expression.this if isinstance(expression, exp.Escape) else expression
        if predicate and operator in _BYTEWISE_LIKE_OPERATORS:
            predicate.meta[BYTEWISE_LIKE] = True
        return self._negate_range(expression) if operator.startswith("!") else expression

    return _parse


def _build_date_diff(args: list) -> exp.DateDiff:
    return exp.DateDiff(
        this=seq_get(args, 2),
        expression=seq_get(args, 1),
        unit=_map_date_part(seq_get(args, 0)),
        date_part_boundary=True,
    )


def _vertica_week(extract: exp.Extract | exp.Anonymous) -> exp.Extract | exp.Anonymous:
    # Vertica's WEEK counts weeks from January 1st, unlike other dialects' ISO 8601 WEEK,
    # which is Vertica's ISOWEEK
    if isinstance(extract, exp.Extract):
        unit = extract.name.upper()
        if unit == "WEEK":
            return exp.Anonymous(this="WEEK", expressions=[extract.expression])
        if unit == "ISOWEEK":
            extract.set("this", exp.var("WEEK"))
    return extract


class VerticaParser(PostgresParser):
    WINDOW_ALIAS_TOKENS = PostgresParser.WINDOW_ALIAS_TOKENS - {TokenType.PARTITION}
    # IS binds tighter than comparisons, e.g. a = b IS NULL means a = (b IS NULL)
    IS_PREDICATE_PRECEDENCE = IsPredicatePrecedence.HIGH

    FUNCTIONS = {
        **PostgresParser.FUNCTIONS,
        "ADD_MONTHS": lambda args: exp.AddMonths(
            this=seq_get(args, 0), expression=seq_get(args, 1), preserve_end_of_month=True
        ),
        # Vertica's COLLATION applies a collation, unlike other dialects' that returns its name
        "COLLATION": lambda args: exp.Anonymous(this="COLLATION", expressions=args),
        "CONTAINS": exp.ArrayContains.from_arg_list,
        "DATEDIFF": _build_date_diff,
        "DEGREES": _build_angle(exp.Degrees),
        "EDIT_DISTANCE": exp.Levenshtein.from_arg_list,
        "GROUPING_ID": lambda args: exp.Grouping(expressions=args) if args else exp.GroupingId(),
        "HEX_TO_BINARY": exp.Unhex.from_arg_list,
        "ISNULL": lambda args: exp.Coalesce(this=seq_get(args, 0), expressions=args[1:]),
        "MONTHS_BETWEEN": exp.MonthsBetween.from_arg_list,
        "NULLIFZERO": lambda args: _build_zero_null(
            "NULLIFZERO", exp.Nullif(this=seq_get(args, 0), expression=exp.Literal.number(0))
        ),
        "RADIANS": _build_angle(exp.Radians),
        "REGEXP_ILIKE": exp.RegexpILike.from_arg_list,
        "ROW": exp.Struct.from_arg_list,
        # Unlike EXPLODE, UNNEST expands every collection and returns no positions
        "UNNEST": lambda args: exp.Unnest(expressions=args),
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
            unit=_map_date_part(seq_get(args, 0)),
        ),
        # TIMESTAMPDIFF only takes timestamps, whereas DATEDIFF can't resolve string literals' type
        "TIMESTAMPDIFF": lambda args: _build_date_diff(
            [
                exp.cast(arg, exp.DType.TIMESTAMP) if i and arg.is_string else arg
                for i, arg in enumerate(args)
            ]
        ),
        "TIMESTAMP_TRUNC": _build_timestamp_trunc,
        # TIME_SLICE(expression, slice_length [, unit [, START | END]]), the unit defaults to SECOND
        "TIME_SLICE": lambda args: exp.TimeSlice(
            this=seq_get(args, 0),
            expression=seq_get(args, 1),
            unit=seq_get(args, 2) or exp.var("SECOND"),
            kind=seq_get(args, 3),
        ),
        "TO_CHAR": _build_to_char,
        "TO_HEX": exp.Hex.from_arg_list,
        "TRUNC": _build_trunc,
        "WEEK_ISO": lambda args: exp.Extract(this=exp.var("WEEK"), expression=seq_get(args, 0)),
        "UUID_GENERATE": lambda args: exp.Uuid(),
        "ZEROIFNULL": lambda args: _build_zero_null(
            "ZEROIFNULL", exp.Coalesce(this=seq_get(args, 0), expressions=[exp.Literal.number(0)])
        ),
    }

    FUNCTION_PARSERS = {
        **PostgresParser.FUNCTION_PARSERS,
        "ARGMAX": lambda self: self._parse_argmax_argmin(exp.ArgMax),
        "ARGMIN": lambda self: self._parse_argmax_argmin(exp.ArgMin),
        "CHAR_LENGTH": lambda self: self._parse_string_unit(
            exp.Length(this=self._parse_assignment()), "OCTET_LENGTH"
        ),
        "CHARACTER_LENGTH": lambda self: self._parse_string_unit(
            exp.Length(this=self._parse_assignment()), "OCTET_LENGTH"
        ),
        "LISTAGG": lambda self: self._parse_listagg(),
        "OVERLAY": lambda self: self._parse_string_unit(self._parse_overlay(), "OVERLAYB"),
        "POSITION": lambda self: self._parse_string_unit(self._parse_position(), "POSITIONB"),
        "SUBSTRING": lambda self: self._parse_string_unit(self._parse_substring(), "SUBSTRB"),
    }

    def _parse_argmax_argmin(self, func: type[exp.ArgMax | exp.ArgMin]) -> exp.Expr:
        # ARGMAX(target, arg) returns arg from the row with the largest target
        args = self._parse_csv(self._parse_assignment)
        return self.expression(func(this=seq_get(args, 1), expression=seq_get(args, 0)))

    # FLOAT '123.5'::INT is (FLOAT '123.5')::INT
    TYPED_LITERAL_BINDS_COLUMN_OPS = False

    # ROW('Amy' AS name, 2 AS id)
    FUNCTIONS_WITH_ALIASED_ARGS = {*PostgresParser.FUNCTIONS_WITH_ALIASED_ARGS, "ROW"}

    COLUMN_OPERATORS = {
        **PostgresParser.COLUMN_OPERATORS,
        TokenType.QDCOLON: lambda self, this, to: self.build_cast(False, this=this, to=to),
    }

    CAST_COLUMN_OPERATORS = {*PostgresParser.CAST_COLUMN_OPERATORS, TokenType.QDCOLON}

    def _parse_atom(self) -> exp.Expr | None:
        if (
            self._curr.token_type == TokenType.BYTE_STRING
            and self._next.token_type == TokenType.STRING
        ):
            return None
        return super()._parse_atom()

    def _parse_primary(self) -> exp.Expr | None:
        primary = super()._parse_primary()

        # E'first part' 'second part' is a single literal, like adjacent plain strings
        if isinstance(primary, exp.ByteString) and self._match(TokenType.STRING, advance=False):
            parts: list[exp.Expr] = [primary]
            while self._match(TokenType.STRING):
                parts.append(exp.Literal.string(self._prev.text))
            return self.expression(exp.Concat(expressions=parts, coalesce=False))

        return primary

    def _parse_function_args(self, alias: bool = False) -> list[exp.Expr]:
        args = super()._parse_function_args(alias)

        # f(x USING PARAMETERS name=value, ...)
        if self._match_text_seq("USING", "PARAMETERS"):
            parameters = self._parse_csv(self._parse_assignment)
            this = args.pop() if args else None
            args.append(self.expression(exp.UsingParameters(this=this, expressions=parameters)))

        return args

    def _parse_string_unit(self, func: exp.Func, octets_function: str) -> exp.Expr:
        # f(... USING OCTETS) is the same as the byte-counting variant, e.g. OVERLAYB for OVERLAY,
        # whose arguments are in the same order. USING CHARACTERS is the default.
        if self._match_text_seq("USING", "OCTETS"):
            args = [func.args[key] for key in func.arg_types if func.args.get(key) is not None]
            return self.expression(exp.Anonymous(this=octets_function, expressions=args))
        self._match_text_seq("USING", "CHARACTERS")
        return func

    TYPE_LITERAL_PARSERS = {
        **PostgresParser.TYPE_LITERAL_PARSERS,
        exp.DType.TIME: _parse_typed_literal,
        exp.DType.TIMESTAMP: _parse_typed_literal,
    }

    def _parse_at_time_zone(self, this: exp.Expr | None) -> exp.Expr | None:
        # TIMEZONE is a synonym of TIME ZONE
        if self._match_text_seq("AT", "TIMEZONE"):
            return self._parse_at_time_zone(
                self.expression(exp.AtTimeZone(this=this, zone=self._parse_unary()))
            )
        return super()._parse_at_time_zone(this)

    def _parse_interval(
        self, require_interval: bool = True, parse_function_unit: bool = True
    ) -> exp.Add | exp.Interval | None:
        # INTERVAL [(p)] [-]'literal' [qualifier], and INTERVALYM 'literal'. The string is kept
        # as is, because INTERVAL '1 month' is 30 days, while INTERVAL '1' MONTH is a calendar month.
        index = self._index
        if not self._match(TokenType.INTERVAL):
            return super()._parse_interval(require_interval, parse_function_unit)

        year_to_month = self._prev.text.upper() == "INTERVALYM"
        precision = self._parse_interval_precision()
        negate = self._match(TokenType.DASH)
        if not self._match(TokenType.STRING):
            self._retreat(index)
            return super()._parse_interval(require_interval, parse_function_unit)

        this: exp.Expr = self.expression(exp.Literal.string(self._prev.text))
        if negate:
            this = self.expression(exp.Neg(this=this))

        unit = (
            exp.IntervalSpan(this=exp.var("YEAR"), expression=exp.var("MONTH"))
            if year_to_month
            else self._parse_interval_qualifier(precision)
        )
        return self.expression(exp.Interval(this=this, unit=unit))

    def _parse_interval_precision(self) -> exp.Expr | None:
        index = self._index
        if self._match(TokenType.L_PAREN):
            precision = self._parse_number()
            if precision and self._match(TokenType.R_PAREN):
                return precision
        self._retreat(index)
        return None

    def _parse_interval_qualifier(self, precision: exp.Expr | None = None) -> exp.Expr | None:
        """
        unit [(p)] [TO unit [(p)]], where precision is that of a preceding INTERVAL(p). Without a
        qualifier, INTERVAL(p) '...' means INTERVAL '...' DAY TO SECOND(p).
        """
        unit = self._parse_interval_unit(precision)
        if unit and self._match_text_seq("TO"):
            unit = exp.IntervalSpan(this=unit, expression=self._parse_interval_unit(precision))
        if not unit and precision:
            unit = exp.IntervalSpan(this=exp.var("DAY"), expression=exp.Second(this=precision))
        return unit

    def _parse_interval_unit(self, precision: exp.Expr | None = None) -> exp.Expr | None:
        if (
            not self._curr
            or self._curr.token_type != TokenType.VAR
            or self._curr.text.upper() not in _INTERVAL_QUALIFIER_UNITS
        ):
            return None

        unit = self._curr.text.upper()
        self._advance()
        unit_precision = self._parse_interval_precision()

        # Only SECOND has a precision, its fractional digits; Vertica ignores the others. When
        # both INTERVAL(p) and SECOND(p) are given, the lesser one applies.
        precisions = [p for p in (precision, unit_precision) if p]
        if unit != "SECOND" or not precisions:
            return exp.var(unit)
        return exp.Second(this=min(precisions, key=lambda p: int(p.name)))

    def _parse_paren(self) -> exp.Expr | None:
        this = super()._parse_paren()

        # (a - b) <qualifier> converts the difference of two datetimes to the qualifier's units,
        # e.g. (ts1 - ts2) YEAR TO MONTH, and (a - b)(p) sets the precision of its seconds
        if isinstance(this, exp.Paren) and isinstance(this.this, exp.Sub):
            unit = self._parse_interval_qualifier(self._parse_interval_precision())
            if unit:
                return self.expression(exp.Interval(this=this, unit=unit))

        return this

    QUERY_MODIFIER_PARSERS = {
        **PostgresParser.QUERY_MODIFIER_PARSERS,
        TokenType.TIMESERIES: lambda self: ("timeseries", self._parse_timeseries()),
    }
    QUERY_MODIFIER_TOKENS = set(QUERY_MODIFIER_PARSERS)

    def _parse_statement(self) -> exp.Expr | None:
        # Historical queries: AT EPOCH { LATEST | n } | AT TIME 'timestamp' <query>
        if not (self._match_text_seq("AT", "EPOCH") or self._match_text_seq("AT", "TIME")):
            return super()._parse_statement()

        kind = self._prev.text.upper()
        epoch = exp.var("LATEST") if self._match_text_seq("LATEST") else self._parse_primary()
        query = super()._parse_statement()
        if not isinstance(query, exp.Query):
            self.raise_error("Expecting a query after AT EPOCH or AT TIME")
            return query

        query.set("when", exp.HistoricalData(this="AT", kind=kind, expression=epoch))
        return query

    def _parse_timeseries(self) -> exp.Expr | None:
        # TIMESERIES slice_time AS '1 second' OVER (PARTITION BY ... ORDER BY ...)
        if not self._match(TokenType.TIMESERIES):
            return None

        alias = self._parse_id_var()
        self._match(TokenType.ALIAS)
        window = self._parse_window(self._parse_string())
        if not isinstance(window, exp.Window):
            self.raise_error("Expecting OVER")
            return window

        window.set("alias", alias)
        return window

    def _parse_match_recognize(self) -> exp.MatchRecognize | None:
        # MATCH ([PARTITION BY ...] ORDER BY ... DEFINE name AS cond, ...
        #   PATTERN name AS (regexp) [ROWS MATCH { ALL EVENTS | FIRST EVENT }])
        if not self._match(TokenType.MATCH_RECOGNIZE):
            return None

        self._match_l_paren()
        partition = self._parse_partition_by()
        order = self._parse_order()
        define = (
            self._parse_csv(self._parse_name_as_expression)
            if self._match_text_seq("DEFINE")
            else None
        )

        pattern = None
        if self._match_text_seq("PATTERN"):
            name = self._parse_id_var()
            self._match(TokenType.ALIAS)
            pattern = self.expression(
                exp.Alias(this=self._parse_match_recognize_pattern(), alias=name)
            )

        rows = None
        if self._match_text_seq("ROWS", "MATCH"):
            if self._match_text_seq("ALL", "EVENTS"):
                rows = exp.var("ROWS MATCH ALL EVENTS")
            elif self._match_text_seq("FIRST", "EVENT"):
                rows = exp.var("ROWS MATCH FIRST EVENT")
            else:
                self.raise_error("Expecting ALL EVENTS or FIRST EVENT")

        self._match_r_paren()
        return self.expression(
            exp.MatchRecognize(
                partition_by=partition, order=order, define=define, pattern=pattern, rows=rows
            )
        )

    def _parse_limit(
        self,
        this: exp.Expr | None = None,
        top: bool = False,
        skip_limit_token: bool = False,
    ) -> exp.Expr | None:
        limit = super()._parse_limit(this=this, top=top, skip_limit_token=skip_limit_token)

        # LIMIT n OVER (PARTITION BY ... ORDER BY ...) limits the rows of each partition
        if isinstance(limit, exp.Limit) and self._match(TokenType.OVER, advance=False):
            limit.set("expression", self._parse_window(limit.expression))
        return limit

    def _parse_range(self, this: exp.Expr | None = None, parse_is: bool = False) -> exp.Expr | None:
        this = super()._parse_range(this, parse_is=parse_is)

        # Event series joins: ON a INTERPOLATE { PREVIOUS | NEXT } VALUE b
        if self._match_text_seq("INTERPOLATE", "PREVIOUS", "VALUE"):
            return self.expression(exp.Interpolate(this=this, expression=self._parse_bitwise()))
        if self._match_text_seq("INTERPOLATE", "NEXT", "VALUE"):
            return self.expression(
                exp.Interpolate(this=this, expression=self._parse_bitwise(), next=True)
            )
        return this

    RANGE_PARSERS = {
        **PostgresParser.RANGE_PARSERS,
        **{
            token_type: _negatable_range_parser(PostgresParser.RANGE_PARSERS[token_type])
            for token_type in (TokenType.LIKE, TokenType.ILIKE, TokenType.RLIKE, TokenType.IRLIKE)
        },
    }

    # Prefix operators bind looser than arithmetic, e.g. |/ 16 * 2 is SQRT(32)
    UNARY_PARSERS = {
        **PostgresParser.UNARY_PARSERS,
        TokenType.PIPE_SLASH: lambda self: self.expression(exp.Sqrt(this=self._parse_term())),
        TokenType.DPIPE_SLASH: lambda self: self.expression(exp.Cbrt(this=self._parse_term())),
        TokenType.PARAMETER: lambda self: self._parse_absolute_value(),
        TokenType.EXCLAMATION: lambda self: self._parse_prefix_factorial(),
    }

    def _parse_absolute_value(self) -> exp.Expr | None:
        # @ x is the absolute value of x, but $ is tokenized as a parameter too
        if self._prev.text != "@":
            self._retreat(self._index - 1)
            return self._parse_type()
        return self.expression(exp.Abs(this=self._parse_term()))

    def _parse_prefix_factorial(self) -> exp.Factorial:
        # !! x is the factorial of x
        if not self._match(TokenType.EXCLAMATION):
            self.raise_error("Expected !! before the operand")
        return self.expression(exp.Factorial(this=self._parse_term()))

    def _parse_escape(self, this: exp.Expr | None) -> exp.Expr | None:
        if not self._match(TokenType.ESCAPE):
            return this

        # Binary patterns need a binary escape character, e.g. ESCAPE '!'::VARBINARY
        return self.expression(exp.Escape(this=this, expression=self._parse_unary()))

    def _parse_unary(self) -> exp.Expr | None:
        this = super()._parse_unary()

        # The postfix x ! is the factorial of x, and binds as tightly as ::
        while self._match(TokenType.EXCLAMATION):
            this = self._parse_column_ops(self.expression(exp.Factorial(this=this)))

        return this

    def _parse_alias(self, this: exp.Expr | None, explicit: bool = False) -> exp.Expr | None:
        alias = super()._parse_alias(this, explicit=explicit)

        # ROW(a, b) AS name(x, y) names the fields, like ROW(a AS x, b AS y) AS name
        if (
            isinstance(alias, exp.Alias)
            and isinstance(alias.this, exp.Struct)
            and self._match(TokenType.L_PAREN)
        ):
            names = self._parse_csv(self._parse_id_var)
            self._match_r_paren()
            for field, name in zip(alias.this.expressions, names):
                field.replace(exp.alias_(field.unalias(), t.cast(exp.Identifier, name)))

        return alias

    def _parse_listagg(self) -> exp.GroupConcat | exp.Anonymous:
        # LISTAGG(expr [USING PARAMETERS separator = ',', ...]) [WITHIN GROUP (ORDER BY ...)]
        this = self._parse_assignment()
        separator: exp.Expr = exp.Literal.string(",")

        if self._match_text_seq("USING", "PARAMETERS"):
            parameters = self._parse_csv(self._parse_assignment)
            for parameter in parameters:
                if isinstance(parameter, exp.EQ) and parameter.this.name.lower() == "separator":
                    separator = parameter.expression
                else:
                    # GroupConcat has no equivalent of parameters such as max_length
                    return self.expression(
                        exp.Anonymous(
                            this="LISTAGG",
                            expressions=[exp.UsingParameters(this=this, expressions=parameters)],
                        )
                    )

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
        if self._match_text_seq("TIME", "ZONE", "FROM"):
            return self.expression(
                exp.Extract(this=exp.var("TIME ZONE"), expression=self._parse_bitwise())
            )
        return _vertica_week(super()._parse_extract())

    def _parse_date_part(self) -> exp.Expr:
        date_part = super()._parse_date_part()
        return _vertica_week(date_part) if isinstance(date_part, exp.Extract) else date_part

    def _parse_types(
        self,
        check_func: bool = False,
        schema: bool = False,
        allow_identifiers: bool = True,
        with_collation: bool = False,
    ) -> exp.Expr | None:
        index = self._index

        # INTERVAL [(p)] [qualifier] and INTERVALYM, i.e. INTERVAL YEAR TO MONTH
        if self._match(TokenType.INTERVAL):
            if self._prev.text.upper() == "INTERVALYM":
                unit: exp.Expr | None = exp.IntervalSpan(
                    this=exp.var("YEAR"), expression=exp.var("MONTH")
                )
            else:
                precision = self._parse_interval_precision()
                unit = self._parse_interval_qualifier()
                if not unit:
                    return exp.DataType(
                        this=exp.DType.INTERVAL,
                        expressions=[exp.DataTypeParam(this=precision)] if precision else None,
                    )
            return exp.DataType(this=exp.Interval(unit=unit))

        # ARRAY[INT] and SET[INT], as opposed to the ARRAY[1, 2] and SET[1, 2] constructors. They
        # take a maximum element count, ARRAY[INT, 10], or binary size, ARRAY[INT](100).
        if self._match_set((TokenType.ARRAY, TokenType.SET)) and self._match(TokenType.L_BRACKET):
            is_set = self._tokens[index].token_type == TokenType.SET
            collection = exp.DType.SET if is_set else exp.DType.ARRAY
            element = self._parse_types(check_func=check_func, schema=schema)
            if isinstance(element, exp.DataType) and not element.is_type(exp.DType.USERDEFINED):
                expressions: list[exp.Expr] = [element]
                if self._match(TokenType.COMMA):
                    expressions.append(exp.DataTypeParam(this=self._parse_number()))
                if self._match(TokenType.R_BRACKET):
                    size = None
                    if self._match(TokenType.L_PAREN):
                        size = exp.DataTypeParam(this=self._parse_number())
                        self._match_r_paren()
                    return exp.DataType(
                        this=collection,
                        expressions=expressions,
                        values=[size] if size else None,
                        nested=True,
                    )
            self._retreat(index)

        defaults = _DEFAULT_TYPE_PARAMS.get(self._curr.text.upper()) if self._curr else None

        data_type = super()._parse_types(
            check_func=check_func,
            schema=schema,
            allow_identifiers=allow_identifiers,
            with_collation=with_collation,
        )

        if isinstance(data_type, exp.DataType) and not data_type.expressions:
            # Typed literals such as CHAR 'abc' and BINARY 'ab' are as long as their string
            if (
                data_type.is_type(exp.DType.CHAR, exp.DType.BINARY)
                and self._curr
                and self._curr.token_type == TokenType.STRING
            ):
                defaults = (max(len(self._curr.text.encode()), 1),)

            if defaults:
                data_type.set(
                    "expressions",
                    [exp.DataTypeParam(this=exp.Literal.number(n)) for n in defaults],
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

        # NULLS AUTO lets Vertica choose either placement, so it's the same as omitting it
        self._match_text_seq("NULLS", "AUTO")

        prev = self._tokens[max(self._index - 2, 0) : self._index]
        explicit = (
            len(prev) == 2
            and prev[0].text.upper() == "NULLS"
            and prev[1].text.upper() in ("FIRST", "LAST")
        )
        if ordered and not explicit:
            ordered.meta[IMPLICIT_NULL_ORDERING] = True
        return ordered

    def _parse_partition_and_order(self) -> tuple[list[exp.Expr], exp.Expr | None]:
        index = self._index
        if self._match(TokenType.PARTITION):
            kind = (self._match_texts(TRANSFORM_PARTITIONS) and self._prev.text.upper()) or (
                self._match_text_seq("LEFT", "JOIN") and "LEFT JOIN"
            )
            if kind:
                return [exp.var(kind)], self._parse_order()
            self._retreat(index)
        return super()._parse_partition_and_order()

    def _parse_window(self, this: exp.Expr | None, alias: bool = False) -> exp.Expr | None:
        window = super()._parse_window(this, alias=alias)

        # Inside windows, NULLs sort as the largest values regardless of the type
        if isinstance(window, exp.Window):
            order = window.args.get("order")
            for ordered in order.expressions if order else []:
                if ordered.meta.get(IMPLICIT_NULL_ORDERING):
                    ordered.set("nulls_first", bool(ordered.args.get("desc")))

        return window
