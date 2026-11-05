# Vertica dialect guide

How to work on sqlglot's Vertica dialect: running it against a real Vertica, how the dialect models
Vertica's semantics, what is supported, and what is known to be broken.

Status figures were last verified on 2026-11-04 against Vertica 25.3.0-8. `conformance/baseline.json`
is the source of truth for what currently fails; refresh the numbers below with the commands in
[Support status](#support-status) whenever you change the dialect.

## Quick start

```bash
pip install -e ".[dev,conformance]"           # psycopg, pyspark-client, vertica-python

python -m conformance up --engines vertica      # first run builds the image and creates the database
python -m conformance up                        # or start all three engines, which cross-dialect checks need

python -m unittest tests.dialects.test_vertica  # unit tests, no engine needed
python -m conformance run --engines vertica     # Vertica cases, checked by roundtrip only
python -m conformance run                       # everything, including transpilation to and from Vertica

# One query, with the generated SQL and rows of every check
python -m conformance run --read vertica --sql "SELECT 7 // 2 AS q"
python -m conformance run --read postgres --write vertica --sql "SELECT 7 / 2 AS q"

# Every known failure that involves Vertica, with SQL and row differences
python -m conformance run --write vertica --all
grep vertica conformance/baseline.json

# A SQL shell inside the container, with the conformance dataset loaded
docker exec -it sqlglot-conformance-vertica-1 /opt/vertica/bin/vsql -U dbadmin -w sqlglot
```

The general harness documentation, including the case file format, statuses and comparison rules, is
in [conformance/README.md](../README.md). Read it first if you haven't used the harness before.

## Where the code is

| Path | Contents |
|---|---|
| `sqlglot/dialects/vertica.py` | Dialect flags and tokenizer: type keywords and the `//` operator |
| `sqlglot/parsers/vertica.py` | Vertica function builders, `ARRAY[T]` types, LISTAGG, NULL ordering metadata |
| `sqlglot/generators/vertica.py` | Type mapping, ORDER BY NULL placement, query rewrites, function renames |
| `tests/dialects/test_vertica.py` | Unit tests, written against the conformance dataset so they can be run on Vertica |
| `conformance/cases/vertica/*.sql` | Conformance cases written in Vertica SQL |
| `conformance/engines/vertica.py` | Driver adapter: connection settings, type families, table loading |
| `conformance/docker/vertica/` | Dockerfile and entrypoint that create a single-node database |
| `conformance/dataset/tables.py` | Vertica physical types of the shared tables, and `vertica_extras` |

The dialect subclasses Postgres, so anything not listed below is parsed and generated the Postgres
way. That is right for most core SQL, but it also means Postgres-only syntax (JSON operators,
`= ANY(array)`, `GENERATE_SERIES`, ...) is emitted for Vertica unless a Vertica override exists.

## How the dialect models Vertica

| Vertica behavior | How sqlglot handles it |
|---|---|
| INT, INTEGER, SMALLINT and TINYINT are all 64-bit; REAL, FLOAT and FLOAT8 are all 64-bit | The tokenizer reads them as BIGINT and DOUBLE, so `CAST(x AS INT)` roundtrips as `CAST(x AS BIGINT)` |
| `/` on integers returns an exact NUMERIC, e.g. `5 / 2 = 2.5`; `//` divides integers | `TYPED_DIVISION = False`; `//` is `exp.IntDiv`. A typed division from Postgres becomes `//` when both operands are integer literals; with columns it needs `annotate_types` |
| Arrays are 0-based; out-of-range subscripts return NULL | `INDEX_OFFSET = 0` |
| Array types are written `ARRAY[INT]` | Parsed and generated as nested `ARRAY` data types |
| Identifiers are case-insensitive, even when quoted | `NORMALIZATION_STRATEGY = CASE_INSENSITIVE` |
| CONCAT, GREATEST, LEAST and array functions such as ARRAY_CAT return NULL if any argument is NULL | `CONCAT_COALESCE`, `LEAST_GREATEST_IGNORES_NULLS` and `ARRAY_FUNCS_PROPAGATES_NULLS`. From dialects that ignore NULLs, CONCAT gets COALESCEs and GREATEST/LEAST get `GREATEST(COALESCE(a, b), COALESCE(b, a))` |
| VARCHAR and VARBINARY columns without a length are 80 bytes; casts without a length don't truncate | The parser makes a column's 80 explicit. Unbounded columns from other dialects, such as Postgres TEXT, become VARCHAR(65000) |
| `INTERVAL '1 month'` means 30 days, `INTERVAL '1' MONTH` is a calendar month, and `INTERVAL '30' MINUTES` is 30 days aliased as MINUTES | The parser keeps Vertica's interval strings as written and only reads YEAR, MONTH, DAY, HOUR, MINUTE and SECOND as qualifiers, so plural and WEEK words are aliases, as in Vertica. It also reads `unit(p) TO unit(p)`, `INTERVAL(p)`, `INTERVALYM` and `(a - b) DAY TO SECOND`. For other dialects' intervals, the generator writes `INTERVAL '1' MONTH` and never plural units (`SINGLE_STRING_INTERVAL = False`, `INTERVAL_ALLOWS_PLURAL_FORM = False`) |
| `TIMESTAMP '...'` and `TIME '...'` become TIMESTAMPTZ or TIMETZ when the string has a time zone, unlike CAST | Typed literals carry the `TYPED_LITERAL` meta key and are generated as typed literals again |
| Postfix `!`, prefix `!!`, `@`, `\|/` and `\|\|/` bind looser than arithmetic, and IS binds tighter than comparisons | `!` and `!!` are `exp.Factorial`, `@` is `exp.Abs`; `IS_PREDICATE_PRECEDENCE = HIGH` |
| An explicit CROSS JOIN runs as a cross product even when WHERE joins the tables | Unconditional CROSS JOINs are generated as comma joins when every join of the query is one |
| No DISTINCT ON, aggregate FILTER, VALUES in FROM, FETCH FIRST or IS [NOT] DISTINCT FROM | Rewritten to a ROW_NUMBER subquery, `CASE` inside the aggregate, UNION ALL, LIMIT and `<=>` |

### NULL ordering

This is the subtlest part of the dialect; keep its invariants intact when changing ORDER BY code.

- **Vertica's defaults.** Outside of windows, NULLs sort first for numeric, temporal and interval
  types, but last for strings, floats and booleans. Inside window specifications, NULLs always sort
  as the largest values (last ascending, first descending).
- **No NULLS FIRST/LAST outside windows.** Vertica rejects the clause in query ORDER BY. The
  generator places NULLs with an extra key instead:
  `ORDER BY CASE WHEN x IS NULL THEN 1 ELSE 0 END, x`. It skips the key when the expression's type
  is annotated and the default already matches, and inside ordered-set aggregates such as
  PERCENTILE_CONT, which ignore NULLs and accept a single key.
- **Queries that can't take extra keys.** SELECT DISTINCT and set operations are wrapped in an ordered
  subquery `_q`. If an ORDER BY key can't be resolved to an output column name, the generator reports
  it as unsupported.
- **Queries parsed from Vertica.** The parser tags ORDER BY items without NULLS FIRST/LAST with the
  `IMPLICIT_NULL_ORDERING` meta key, and the generator leaves those items untouched. This keeps the
  roundtrip exact even though the default depends on types the parser can't see.
- **Transpiling out of Vertica.** Implicit items are assumed to sort NULLs first (`NULL_ORDERING =
  "nulls_are_small"`), which is right for numbers and dates but wrong for strings. Window items are
  corrected to Vertica's window default by `_parse_window`.

### Function and syntax mappings

| Vertica | Parsed as | Notes |
|---|---|---|
| `DATEDIFF(unit, start, end)`, `TIMESTAMPDIFF` | `exp.DateDiff` with `date_part_boundary` | Counts unit boundaries crossed. Units go through Vertica's own abbreviations, where `m` is MONTH and `y` is DAY |
| `TIMESTAMPADD(unit, n, ts)` | `exp.TimestampAdd` | Generated as TIMESTAMPADD, not interval arithmetic |
| `DAY`, `MONTH`, `YEAR`, `DAYOFMONTH`, `LAST_DAY` | `exp.Day`, `exp.Month`, ... | Generated by name, because EXTRACT rejects their VARCHAR and INTEGER arguments |
| `TIME_SLICE(ts, n [, unit [, START \| END]])` | `exp.TimeSlice` | The unit defaults to SECOND |
| `TIMESTAMP_TRUNC(ts, fmt)` | `exp.TimestampTrunc` for TRUNC's units | Other formats stay anonymous |
| `DATE_PART('week', d)` | `WEEK(d)`, as EXTRACT(WEEK) | |
| `ADD_MONTHS(d, n)` | `exp.AddMonths` with `preserve_end_of_month` | Month ends stay month ends, as in Oracle |
| `MONTHS_BETWEEN(a, b)` | `exp.MonthsBetween` | |
| `TRUNC(d, 'MM')` and other Oracle-style units | `exp.TimestampTrunc`, generated as `DATE_TRUNC` | `TRUNC(number, n)` stays `exp.Trunc` |
| `EXTRACT(WEEK FROM d)` | `WEEK(d)`, an anonymous function | Counts weeks from January 1st, unlike other dialects' ISO WEEK |
| `EXTRACT(ISOWEEK FROM d)`, `WEEK_ISO(d)` | `exp.Extract` with unit WEEK | Other dialects' WEEK is generated as ISOWEEK |
| `DAYOFWEEK`, `DAYOFWEEK_ISO`, `DAYOFYEAR` | `exp.DayOfWeek`, `exp.DayOfWeekIso`, `exp.DayOfYear` | DAYOFWEEK is 1 for Sunday |
| `LISTAGG(x USING PARAMETERS separator='s') WITHIN GROUP (ORDER BY ...)` | `exp.GroupConcat` with the order folded in | The default separator is a comma. With other parameters, such as `max_length`, LISTAGG stays anonymous |
| `f(x USING PARAMETERS a=1, ...)` in any function | The last argument wrapped in `exp.UsingParameters` | |
| `ARGMAX(target, arg)`, `ARGMIN` | `exp.ArgMax`, `exp.ArgMin` with the arguments swapped | Vertica's argument order is the reverse of MAX_BY's |
| `f(x IGNORE NULLS)` | `exp.IgnoreNulls` | Generated inside the parentheses (`IGNORE_NULLS_IN_FUNC`) |
| `OVER (PARTITION BEST \| NODES \| ROW \| LEFT JOIN)` | `[exp.var(kind)]` as `partition_by` | For transform functions such as EXPLODE |
| `NULLS AUTO` | An implicit ORDER BY item | Lets Vertica choose, so it's dropped |
| `MATCH (... DEFINE ... PATTERN p AS (...) ROWS MATCH ...)` | `exp.MatchRecognize`, generated after WHERE (`MATCH_AFTER_WHERE`) | The pattern name is an alias around the pattern |
| `TIMESERIES slice AS '1 second' OVER (...)` | An `exp.Window` in the `timeseries` query modifier | |
| `a INTERPOLATE PREVIOUS \| NEXT VALUE b` | `exp.Interpolate` | Event series joins |
| `LIMIT n OVER (PARTITION BY ... ORDER BY ...)` | `exp.Limit` whose expression is an `exp.Window` | |
| `AT EPOCH LATEST \| n`, `AT TIME '...'` before a query | `exp.HistoricalData` in the `when` query modifier | |
| `MINUS` | `exp.Except` | |
| `/*+ hints */` after SELECT, INSERT, UPDATE, DELETE and WITH | Query hints | Hints elsewhere, such as after GROUP BY or JOIN, become plain comments |
| `x::!T` | `exp.TryCast` | Returns NULL where the cast fails |
| `ROW(a, b)`, `ROW(a AS x)`, ROW types | `exp.Struct`, STRUCT types | `ROW(a, b) AS s(x, y)` names the fields |
| `ARRAY[T, n]`, `ARRAY[T](size)`, `SET[T]` | ARRAY and SET data types | Bounds in `expressions`, sizes in `values` |
| `UNNEST(...)`, `EXPLODE(...)`, `FILTER(...)` | `exp.Unnest`, `exp.Explode`, `exp.ArrayFilter` | |
| `CHAR_LENGTH`, `OVERLAY`, `POSITION`, `SUBSTRING` with `USING OCTETS` | The byte variants OCTET_LENGTH, OVERLAYB, POSITIONB and SUBSTRB | `USING CHARACTERS` is the default and dropped |
| `LIKEB`, `ILIKEB`, `~~`, `~~*`, `~#`, `~#*` and their `!` negations | `exp.Like`, `exp.ILike` | Byte-wise forms carry the `BYTEWISE_LIKE` meta key |
| `COLLATION(s, locale)`, 3-argument `DEGREES` / `RADIANS` | Anonymous functions | Their sqlglot namesakes mean something else |
| `TO_CHAR(x)`, `TO_NUMBER(x)` with one argument | `exp.ToChar`, `exp.ToNumber` | Double-quoted text in templates isn't converted |
| Bare `NUMBER`, `BINARY`, and `CHAR 'abc'` | `DECIMAL(38, 0)`, `BINARY(1)`, a CHAR of the string's length | Their Vertica defaults differ from sqlglot's |
| `REGEXP_REPLACE(s, p, r, position, occurrence, flags)` | `exp.RegexpReplace` | Replaces every match by default. Postgres's first-match default becomes `..., 1, 1)` |
| `REGEXP_ILIKE`, `~`, `~*`, `!~` | `exp.RegexpILike`, regex operators | |
| `INSTR(s, sub, position, occurrence)`, `STRPOS` | `exp.StrPosition`, generated as INSTR | STRPOS rejects VARBINARY |
| `REGEXP_LIKE(s, p, flags)` | `exp.RegexpLike` | Generated as REGEXP_LIKE when it has flags |
| `SHA1`, `INSERT(s, pos, n, new)` | `exp.SHA`, `exp.Stuff` | Vertica has no SHA or STUFF |
| `EDIT_DISTANCE(a, b)` | `exp.Levenshtein` | Vertica counts bytes, other engines count characters |
| `TO_HEX`, `HEX_TO_BINARY` | `exp.Hex`, `exp.Unhex` | |
| `ISNULL(a, b)`, `ZEROIFNULL(x)`, `NULLIFZERO(x)` | `exp.Coalesce`, `exp.Nullif` | ZEROIFNULL and NULLIFZERO keep their name for Vertica, because they also accept intervals |
| `CONTAINS(array, value)` | `exp.ArrayContains` | |
| `ARRAY_LENGTH(array)` | `exp.ArraySize` | First dimension only |
| `GROUPING_ID(a, b)`, `GROUPING_ID()` | Multi-argument `exp.Grouping`, `exp.GroupingId` | Vertica's GROUPING takes one argument |
| `UUID_GENERATE()` | `exp.Uuid` | |
| `a <=> b` | `exp.NullSafeEQ` | |
| `STARTS_WITH` from other dialects | Generated as `LEFT(s, LENGTH(p)) = p` | Vertica has no STARTS_WITH |

## Support status

Pass counts below include `weak` passes. Each row is a kind of check across all cases that apply. The
27 cases that query `vertica_extras` only have a roundtrip check, hence 742 transpilation checks out
of Vertica. Transpiling the Vertica-only syntax most cases exercise isn't attempted yet, which is why
those rows are low.

| Check | Passing |
|---|---|
| Vertica roundtrip | 768 of 769 |
| Postgres to Vertica | 144 of 188 |
| Spark to Vertica | 92 of 163 |
| Vertica to Postgres | 347 of 742 |
| Vertica to Spark | 292 of 742 |

To refresh these, run `python -m conformance run` and read the summary table. For the current list
of failures, read `conformance/baseline.json` or run `python -m conformance run --write vertica --all`.
Every failing check is listed there with its generated SQL and either the engine error or the row
differences.

### Coverage of the SQL reference

The Vertica cases were written page by page against the
[Vertica 24.3 SQL reference](https://docs.rocketsoftware.com/bundle/vertica_24.3/page/sql-reference/index.html),
so every query-level page has at least one case exercising its documented forms:

| Reference section | Case files |
|---|---|
| Analytic functions, window clauses | `analytic`, `windows` |
| Aggregate functions, GROUP BY, HAVING | `aggregates`, `approximate`, `group_by` |
| Datetime functions | `datetime`, `datetime_functions` |
| Formatting functions, datetime literals and types, intervals | `formatting`, `datetime_types`, `intervals` |
| String, regular expression, IP, URI and UUID functions | `strings`, `string_functions`, `regex`, `network` |
| Mathematical and NULL-handling functions, operators, predicates, expressions, system information, THROW_ERROR | `numeric`, `math_functions`, `nulls`, `operators`, `predicates`, `system` |
| Data types, literals, casts, collection functions | `types`, `literals`, `casts`, `arrays`, `collections`, `extras` |
| SELECT and its clauses, MATCH, TIMESERIES, INTERPOLATE | `queries`, `joins`, `set_operations`, `match`, `timeseries` |

Not covered, because a read-only SELECT on the shared dataset can't test them:

- Management, ML, geospatial, flex, Hadoop, Database Designer, directed query, stored procedure and
  text search functions; system tables; statements other than SELECT.
- Sequences (CURRVAL, NEXTVAL), SELECT INTO, FOR UPDATE, LIST_ENABLED_CIPHERS (needs TLS), MAP
  (external tables only), and `AT EPOCH n` / `AT TIME` with a fixed value (valid values change with
  every load; unit tests cover the syntax). SET INTERVALSTYLE and DATESTYLE are session statements.

Documented syntax that Vertica 25.3 rejects, so no case uses it: EXCLUDE in window frames, a frame
on BOOL_XOR, PARTITION BEST/NODES with ordinary analytic functions, the `SYYY` date format, the
`EEEE` numeric pattern, CHAR_LENGTH on VARBINARY, and NEXT_DAY with trailing spaces.

### Bugs in the Vertica dialect

These produce wrong results or invalid Vertica SQL. Most are fixed in the Vertica parser or generator;
some need the Postgres parser, which the Vertica one inherits, to recognize a function first. They are
good first tasks; the first one silently returns wrong results.

- **WEEK intervals from other dialects.** Vertica has no WEEK interval qualifier, so
  `INTERVAL '3' WEEK` means 3 days aliased as WEEK. The generator emits exactly that for other
  dialects' weeks, and also for fractional ones like `'1.5 weeks'`. Weeks have a fixed length, so a
  single string is exact in Vertica: `INTERVAL '3 weeks'` is 21 days and `INTERVAL '1.5 weeks'` is
  10.5 days. Note that `'1.5' DAY` truncates to one day. When overriding `interval_sql`, copy the
  node before calling `super()`, because the Postgres version modifies it in place. Case:
  `postgres/datetime:interval_units`.
- **Invalid UTF-8 in escape strings.** `E'\xC2\xC0'` is regenerated as `e'ÂÀ'`, because the shared
  tokenizer decodes escaped bytes that aren't valid UTF-8 as one character per byte. Vertica keeps the
  bytes, so ISUTF8 and MAKEUTF8 return different results. Fixing it needs the tokenizer to keep such
  bytes recoverable, which affects every dialect with `NUMERIC_ESCAPES_ARE_BYTES`. Case:
  `vertica/string_functions:invalid_utf8_escape_literals`, the only failing Vertica roundtrip.
- **Hints outside queries' heads.** `GROUP BY /*+GBYTYPE(HASH)*/` and `JOIN /*+JTYPE(H)*/` become
  plain comments, so Vertica ignores them. Results don't change.
- **Aggregate ARGMAX from other dialects.** `exp.ArgMax` is always generated as ARGMAX, which is
  analytic only in Vertica. An aggregate MAX_BY needs ARGMAX_AGG.
- **Abbreviated DATE_TRUNC units.** Spark's `TRUNC(d, 'MM')` becomes `DATE_TRUNC('MM', d)`, which
  Vertica rejects. Case: `spark/datetime:trunc`.
- **Postgres syntax inherited by the generator.** The generator emits JSON operators and functions,
  `x = ANY(array)`, array slices, ARRAY_APPEND, ARRAY_TO_STRING, CARDINALITY, STRING_TO_ARRAY, UNNEST,
  GENERATE_SERIES, MAKE_DATE, MAKE_TIMESTAMP, `ENCODE(b, 'hex')`, `ENCODE(b, 'base64')`, EVERY,
  CONCAT_WS, REVERSE, LATERAL and ARRAY_AGG, none of which Vertica accepts. Some have Vertica
  equivalents, for example TO_HEX, BOOL_AND, EXPLODE and IMPLODE; others should be reported as
  unsupported. EVERY, MAKE_DATE and CARDINALITY parse as anonymous functions, so the Postgres parser
  must map them to expressions before any generator can translate them. The cases are spread across
  `postgres/json`, `arrays`, `aggregates`, `casts`, `datetime`, `strings`, `queries` and `joins`;
  `python -m conformance run --write vertica --all -k postgres/` lists them all.
- **Spark functions passed through unchanged.** Examples are CONV, PMOD, ENDS_WITH,
  SUBSTRING_INDEX, REGEXP_EXTRACT and DATE_FORMAT. Check each one's Vertica equivalent in the
  [SQL reference](https://docs.vertica.com/latest/en/sql-reference/) before mapping it.
- **Division of integer columns** keeps `/`, which divides exactly in Vertica, unless the operands
  are integer literals or the expression is annotated with types. Case:
  `postgres/numeric:column_division`.

### Gaps in other dialects' generators

These fail when transpiling out of Vertica, and are fixed in the target dialect's generator or in
shared code.

- Postgres has no ADD_MONTHS, DAYOFWEEK or `TO_HEX` for bytes. INSTR's occurrence argument is
  dropped, and NULL-propagating GREATEST and LEAST aren't emulated.
- Neither Postgres nor Spark has ARRAY_FIND, ARRAY_COUNT or Vertica's non-ISO WEEK.
- A one-argument LOG becomes Spark's natural log instead of LOG(10, x).
- Quoted identifiers keep their case, so `"ID"` breaks on case-sensitive engines. Plain
  transpilation doesn't normalize identifiers.
- ORDER BY on a string without NULLS FIRST/LAST assumes Vertica's numeric NULL placement, as
  described in [NULL ordering](#null-ordering).

### Engine differences

These are genuine Vertica behaviors that sqlglot can't or shouldn't paper over. They are expected to
stay in the baseline unless someone finds an exact emulation.

- CHAR(n) pads to n bytes, not characters, and EDIT_DISTANCE counts bytes.
- Floats cast to text keep 15 significant digits, and ROUND on a float rounds half away from zero.
- NaN sorts before every other float, and comparisons such as `NaN > 1` are false.
- `ASCII('')` is NULL, and INITCAP treats apostrophes as word boundaries differently.
- Casting an integer to BOOLEAN only accepts 0 and 1.
- PERCENTILE_CONT and MEDIAN are analytic functions, so they return a row per input row.
- Recursive CTEs stop after 8 iterations, the default of `WithClauseRecursionLimit`.
- `x NOT IN (subquery)` raises an error when the subquery returns NULLs.
- Correlated subqueries with aggregates, LATERAL, EXCEPT ALL and PIVOT aren't supported.
- Columns joined with USING aren't merged, so referencing them unqualified is ambiguous.
- LISTAGG fails when its result exceeds 1024 bytes, unless its `max_length` parameter is raised.

## Vertica behavior worth knowing

These matter when writing cases, unit tests or dataset rows.

- **NULL sentinels.** Vertica stores the BIGINT value -2^63 and the nil UUID as NULL. The dataset
  avoids both.
- **Lengths count bytes.** CHAR, VARCHAR and VARBINARY lengths are in bytes, so `'😀'` needs
  CHAR(4).
- **Results that overflow.** Arithmetic on the dataset's year-9999 rows fails in the driver, so
  date arithmetic in tests filters rows, e.g. `WHERE id = 3`.
- **Return types.** EXTRACT returns NUMERIC, and DATE_TRUNC on a DATE returns a TIMESTAMP.
- **Array literals.** A literal array needs parentheses to be subscripted, as in
  `(ARRAY[1, 2])[0]`. Column subscripts work directly.
- **Statistics.** Without statistics, Vertica plans joins badly enough to time out. The loader runs
  ANALYZE_STATISTICS after loading each table.
- **Float precision.** The driver's text protocol rounds floats to 15 significant digits, so the
  adapter uses binary transfer.

## Writing tests and cases

- **Unit tests.** `tests/dialects/test_vertica.py` follows the usual `validate_identity` and
  `validate_all` style. Every query targets the conformance dataset so that it can be run on the
  engines, as the test-validity rule in AGENTS.md requires. Check a statement with
  `python -m conformance run --read <dialect> --sql "<SQL>"`. Use the dataset's tables and columns,
  listed in [conformance/README.md](../README.md#dataset).
- **Conformance cases.** Add them to `conformance/cases/vertica/<topic>.sql` and give each one a
  `# name:`. Their SQL must run on Vertica itself; otherwise the case is reported as
  `invalid_case`. Cases written in Postgres or Spark SQL also exercise the Vertica generator,
  because every case is transpiled to every other engine.
- **Vertica-only types** go in `vertica_extras` in `conformance/dataset/tables.py`. Cases that query
  it are only checked by roundtrip.

A typical change, using the WEEK interval bug as an example:

1. Reproduce it:
   `python -m conformance run --read postgres --write vertica --sql "SELECT TIMESTAMP '2024-01-01' + INTERVAL '3 weeks'"`
2. Fix the generator, e.g. by overriding `interval_sql` in `sqlglot/generators/vertica.py`.
3. Add a `validate_all` test to `tests/dialects/test_vertica.py` and run
   `python -m unittest tests.dialects.test_vertica`.
4. Run `python -m conformance run`. It should list `postgres/datetime:interval_units
   transpile:postgres->vertica` as fixed and report no new failures. Record the result with
   `python -m conformance run --update-baseline`. A filtered update, such as one with `-k` or
   `--engines vertica`, only rewrites the entries of the checks that ran.

   Most cases test several functions at once, so fixing one function may only change a case's
   failure reason, or move it from `error` to `mismatch`. The run reports that as a changed status.
   Check the function on its own with `--sql`, and consider splitting a case so each function gets
   its own check.
5. Update this guide's tables if the change alters a mapping or the support status.

## The engine

Vertica's Community Edition images on Docker Hub now require a login, so
`conformance/docker/vertica/` builds a single-node database on the public
`opentext/vertica-k8s:25.3.0-8` image. That image normally relies on the VerticaDB Kubernetes
operator. Its entrypoint instead creates TLS certificates for the node management agent, starts the
agent, and runs `vcluster create_db` on the first start or `vcluster start_db` afterwards. Version
25.3 is the newest that accepts the Community Edition license; databases created with 26.1 or later
refuse to start with it.

| Setting | Value |
|---|---|
| Image | `sqlglot-conformance-vertica:25.3.0-8`, built on first `up` (about 2.3 GB) |
| Database, user, password | `conformance`, `dbadmin`, `sqlglot` |
| Host port | `55433`, or `CONFORMANCE_VERTICA_PORT` |
| External server | `CONFORMANCE_VERTICA_DSN="host=... port=... user=... password=... database=..."` |
| Session | UTC time zone, ISO dates, a 60 second statement limit, binary collation |

Troubleshooting:

- **The container doesn't become healthy.** Read `docker logs sqlglot-conformance-vertica-1`, which
  shows each `vcluster` step. Vertica's own log is inside the container, at
  `/data/conformance/v_conformance_node0001_catalog/vertica.log`.
- **Data looks wrong or stale.** Reload it with `python -m conformance load --engines vertica --force`.
  To start over completely, run `python -m conformance down`, which deletes the database.
- **Queries hit the 60 second limit.** Find them with
  `SELECT request_duration_ms, request FROM query_requests ORDER BY request_duration_ms DESC LIMIT 10`
  in vsql. Missing statistics and explicit CROSS JOINs have been the causes so far.
- **Upgrading Vertica.** A newer release needs a license other than Community Edition, so it can't
  be added without one. Keep the image tag, the compose file and this guide in sync.
