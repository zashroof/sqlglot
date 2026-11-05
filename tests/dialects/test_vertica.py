from tests.dialects.test_dialect import Validator


class TestVertica(Validator):
    """
    Queries reference the conformance dataset (conformance/dataset/tables.py), so that every
    statement below can be run on the engines with `python -m conformance`.
    """

    dialect = "vertica"

    def test_vertica(self):
        self.validate_identity("SELECT 7 // 2, 7 / 2")
        self.validate_identity("SELECT v_int4 <=> v_int2 FROM scalars")
        self.validate_identity("SELECT v_int_arr[0] FROM scalars")
        self.validate_identity(
            "SELECT CONTAINS(v_int_arr, 2), ADD_MONTHS(v_date, 1) FROM scalars WHERE id = 3"
        )
        self.validate_identity(
            "SELECT INSTR(v_text, 'l', 1, 2), STRPOS(v_text, 'o') FROM scalars",
            "SELECT INSTR(v_text, 'l', 1, 2), INSTR(v_text, 'o') FROM scalars",
        )
        self.validate_identity("SELECT REGEXP_REPLACE(v_text, 'l', 'L') FROM scalars")
        self.validate_identity("SELECT REGEXP_REPLACE(v_text, 'l', 'L', 1, 1) FROM scalars")
        self.validate_identity("SELECT EDIT_DISTANCE(v_text, 'hello') FROM scalars")
        self.validate_identity("SELECT DAYOFWEEK(v_date), DAYOFYEAR(v_date) FROM scalars")
        self.validate_identity(
            "SELECT GROUPING_ID(grp, flag) FROM facts GROUP BY ROLLUP (grp, flag)"
        )
        self.validate_identity("SELECT LISTAGG(cat) FROM facts WHERE id <= 40")
        self.validate_identity(
            "SELECT LISTAGG(cat USING PARAMETERS separator='|') WITHIN GROUP (ORDER BY id) FROM facts WHERE id <= 40"
        )
        self.validate_identity(
            "SELECT DATEDIFF('day', v_date, DATE '2024-03-01') FROM scalars",
            "SELECT DATEDIFF(DAY, v_date, CAST('2024-03-01' AS DATE)) FROM scalars",
        )
        self.validate_identity(
            "SELECT ISNULL(v_text, '?'), ZEROIFNULL(v_int4), NULLIFZERO(v_int4) FROM scalars",
            "SELECT COALESCE(v_text, '?'), ZEROIFNULL(v_int4), NULLIFZERO(v_int4) FROM scalars",
        )
        self.validate_identity(
            "SELECT TRUNC(v_date, 'MM'), TRUNC(v_dec, 1) FROM scalars",
            "SELECT DATE_TRUNC('MONTH', v_date), TRUNC(v_dec, 1) FROM scalars",
        )

    def test_types(self):
        # Integer and floating point types are all 64-bit
        self.validate_identity(
            "SELECT CAST(v_int4 AS INT), CAST(v_int2 AS SMALLINT), CAST(v_float4 AS REAL) FROM scalars",
            "SELECT CAST(v_int4 AS BIGINT), CAST(v_int2 AS BIGINT), CAST(v_float4 AS DOUBLE PRECISION) FROM scalars",
        )
        self.validate_identity(
            "SELECT CAST(v_int_arr AS ARRAY[INT]) FROM scalars",
            "SELECT CAST(v_int_arr AS ARRAY[BIGINT]) FROM scalars",
        )
        self.validate_identity(
            "SELECT CAST(v_text AS VARCHAR), CAST(v_text AS VARCHAR(10)) FROM scalars"
        )

        # Columns without a length are 80 bytes long, but other dialects' are unbounded
        self.validate_identity(
            "CREATE TABLE conformance_t (a VARCHAR, b VARBINARY, c ARRAY[INT])",
            "CREATE TABLE conformance_t (a VARCHAR(80), b VARBINARY(80), c ARRAY[BIGINT])",
        )
        self.validate_all(
            "CREATE TABLE conformance_t (a VARCHAR(65000), b VARCHAR(65000), c VARBINARY(65000), d ARRAY[INT])",
            read={"postgres": "CREATE TABLE conformance_t (a TEXT, b VARCHAR, c BYTEA, d INT[])"},
        )
        self.validate_all(
            "SELECT CAST(v_int4 AS VARCHAR), CAST(v_bytes AS VARBINARY) FROM scalars",
            read={"postgres": "SELECT CAST(v_int4 AS TEXT), CAST(v_bytes AS BYTEA) FROM scalars"},
        )

    def test_types_and_collections(self):
        # NUMBER defaults to NUMERIC(38, 0), and BINARY to BINARY(1)
        self.validate_identity(
            "SELECT v_dec::NUMBER, v_bytes::BINARY, v_bytes::BINARY(4), v_bytes::BINARY VARYING(4) FROM scalars",
            "SELECT CAST(v_dec AS DECIMAL(38, 0)), CAST(v_bytes AS BINARY(1)), CAST(v_bytes AS BINARY(4)), CAST(v_bytes AS VARBINARY(4)) FROM scalars",
        )

        # Typed literals are as long as their string, and bind tighter than ::
        self.validate_identity(
            "SELECT CHAR 'abc', BINARY 'ab', CHAR(2) 'abc', FLOAT '123.5'::INT",
            "SELECT CAST('abc' AS CHAR(3)), CAST('ab' AS BINARY(2)), CAST('abc' AS CHAR(2)), CAST(CAST('123.5' AS DOUBLE PRECISION) AS BIGINT)",
        )

        # Bounded and sized collection types
        self.validate_identity(
            "SELECT v_int_arr::ARRAY[VARCHAR, 2], v_int_arr::ARRAY[INT](100), v_int_arr::SET[INT], v_int_arr::SET[INT, 10] FROM scalars",
            "SELECT CAST(v_int_arr AS ARRAY[VARCHAR, 2]), CAST(v_int_arr AS ARRAY[BIGINT](100)), CAST(v_int_arr AS SET[BIGINT]), CAST(v_int_arr AS SET[BIGINT, 10]) FROM scalars",
        )

        # ::! returns NULL where the cast fails
        self.validate_identity("SELECT v_text::!BIGINT, (v_text || '0')::!BIGINT FROM scalars")
        self.validate_identity(
            "SELECT v_text ::! FLOAT FROM scalars", "SELECT v_text::!DOUBLE PRECISION FROM scalars"
        )

        # ROW constructors and types; field types of ROW casts default to 80 bytes
        self.validate_identity("SELECT ROW('Amy', 2), ROW('Amy' AS name, 2 AS id) AS student")
        self.validate_identity(
            "SELECT ROW('Amy', 2) AS student(name, id)",
            "SELECT ROW('Amy' AS name, 2 AS id) AS student",
        )
        self.validate_identity(
            "SELECT v_row::ROW(a INT, b VARCHAR) FROM vertica_extras",
            "SELECT CAST(v_row AS ROW(a BIGINT, b VARCHAR(80))) FROM vertica_extras",
        )

        # E'...' continued by adjacent strings
        self.validate_identity("SELECT E'a\\n' 'b'", "SELECT CONCAT(e'a\\n', 'b')")

        # Collection functions
        self.validate_identity("SELECT FILTER(v_int_arr, e -> e > 1) FROM scalars")
        self.validate_identity("SELECT EXPLODE(id, v_int_arr) OVER (PARTITION BY id) FROM scalars")
        self.validate_identity("SELECT UNNEST(v_int_arr, v_text_arr) FROM scalars")
        self.validate_identity(
            "SELECT EXPLODE(v_int_arr, id USING PARAMETERS skip_partitioning = TRUE) AS (pos, val, id) FROM scalars"
        )
        self.validate_identity(
            "SELECT STRING_TO_ARRAY(v_varchar USING PARAMETERS collection_delimiter = ' ') FROM scalars"
        )
        self.validate_identity(
            "SELECT id, x FROM scalars CROSS JOIN EXPLODE(v_int_arr USING PARAMETERS skip_partitioning = TRUE) AS t(pos, x)"
        )

    def test_division(self):
        self.validate_all(
            "SELECT 7 // 2, 7 / 2",
            write={
                "postgres": "SELECT DIV(7, 2), CAST(7 AS DOUBLE PRECISION) / 2",
                "spark": "SELECT 7 DIV 2, 7 / 2",
            },
        )
        self.validate_all("SELECT 7 // 2", read={"postgres": "SELECT 7 / 2"})

    def test_null_ordering(self):
        # Outside of windows, NULLs sort first for numbers and last for strings, so the generator
        # places them with an extra sort key unless the query came from Vertica
        self.validate_identity("SELECT id FROM scalars ORDER BY v_text, id")
        self.validate_all(
            "SELECT id FROM scalars ORDER BY CASE WHEN v_text IS NULL THEN 1 ELSE 0 END DESC, v_text DESC",
            read={"postgres": "SELECT id FROM scalars ORDER BY v_text DESC"},
        )
        self.validate_all(
            "SELECT id FROM scalars ORDER BY v_int4",
            write={"postgres": "SELECT id FROM scalars ORDER BY v_int4 NULLS FIRST"},
        )
        self.validate_all(
            "SELECT * FROM (SELECT DISTINCT cat FROM facts) AS _q ORDER BY CASE WHEN _q.cat IS NULL THEN 1 ELSE 0 END, _q.cat",
            read={"postgres": "SELECT DISTINCT cat FROM facts ORDER BY cat"},
        )
        self.validate_all(
            "SELECT * FROM (SELECT k FROM join_left UNION SELECT k FROM join_right) AS _q ORDER BY CASE WHEN _q.k IS NULL THEN 1 ELSE 0 END, _q.k",
            read={"postgres": "SELECT k FROM join_left UNION SELECT k FROM join_right ORDER BY 1"},
        )
        self.validate_all(
            "SELECT id FROM facts ORDER BY CASE WHEN id IS NULL THEN 1 ELSE 0 END, id LIMIT 3",
            read={"postgres": "SELECT id FROM facts ORDER BY id FETCH FIRST 3 ROWS ONLY"},
        )

        # Inside windows, NULLs always sort as the largest values
        self.validate_all(
            "SELECT ROW_NUMBER() OVER (ORDER BY v_int4) FROM scalars",
            write={
                "postgres": "SELECT ROW_NUMBER() OVER (ORDER BY v_int4) FROM scalars",
                "spark": "SELECT ROW_NUMBER() OVER (ORDER BY v_int4 NULLS LAST) FROM scalars",
            },
        )
        self.validate_all(
            "SELECT ROW_NUMBER() OVER (ORDER BY v_int4 NULLS FIRST) FROM scalars",
            read={"spark": "SELECT ROW_NUMBER() OVER (ORDER BY v_int4) FROM scalars"},
        )

    def test_null_propagation(self):
        self.validate_all(
            "SELECT GREATEST(COALESCE(v_int4, v_int2), COALESCE(v_int2, v_int4)) FROM scalars",
            read={"postgres": "SELECT GREATEST(v_int4, v_int2) FROM scalars"},
        )
        self.validate_all(
            "SELECT CONCAT(v_text, v_varchar) FROM scalars",
            write={"postgres": "SELECT v_text || v_varchar FROM scalars"},
        )
        self.validate_all(
            "SELECT CONCAT(COALESCE(v_text, ''), COALESCE(v_varchar, '')) FROM scalars",
            read={"postgres": "SELECT CONCAT(v_text, v_varchar) FROM scalars"},
        )
        self.validate_all(
            "SELECT l.id FROM join_left AS l JOIN join_right AS r ON l.k <=> r.k",
            read={
                "postgres": "SELECT l.id FROM join_left AS l JOIN join_right AS r ON l.k IS NOT DISTINCT FROM r.k"
            },
            write={
                "postgres": "SELECT l.id FROM join_left AS l JOIN join_right AS r ON l.k IS NOT DISTINCT FROM r.k"
            },
        )

    def test_transpile(self):
        self.validate_all(
            "SELECT v_date + INTERVAL '1' MONTH, v_ts - INTERVAL '30' MINUTE FROM scalars WHERE id = 3",
            read={
                "postgres": "SELECT v_date + INTERVAL '1 month', v_ts - INTERVAL '30 minutes' FROM scalars WHERE id = 3"
            },
        )
        self.validate_all(
            "SELECT grp, LISTAGG(cat USING PARAMETERS separator='|') WITHIN GROUP (ORDER BY id) FROM facts WHERE id <= 40 GROUP BY grp",
            write={
                "postgres": "SELECT grp, STRING_AGG(cat, '|' ORDER BY id NULLS FIRST) FROM facts WHERE id <= 40 GROUP BY grp"
            },
        )
        self.validate_all(
            "SELECT COUNT(*) FROM join_left AS l, join_right AS r WHERE l.k = r.k",
            read={
                "spark": "SELECT COUNT(*) FROM join_left AS l CROSS JOIN join_right AS r WHERE l.k = r.k"
            },
        )
        self.validate_all(
            "SELECT SUM(CASE WHEN flag THEN 1 ELSE 0 END) FROM facts",
            read={"postgres": "SELECT COUNT(*) FILTER (WHERE flag) FROM facts"},
        )
        self.validate_all(
            "SELECT * FROM (SELECT 1 AS x, 'a' AS y UNION ALL SELECT 2, 'b') AS v",
            read={"postgres": "SELECT * FROM (VALUES (1, 'a'), (2, 'b')) AS v(x, y)"},
        )
        self.validate_all(
            "SELECT REGEXP_REPLACE(v_text, 'l', 'L', 1, 1), REGEXP_REPLACE(v_text, 'l', 'L') FROM scalars",
            read={
                "postgres": "SELECT REGEXP_REPLACE(v_text, 'l', 'L'), REGEXP_REPLACE(v_text, 'l', 'L', 'g') FROM scalars"
            },
            write={
                "postgres": "SELECT REGEXP_REPLACE(v_text, 'l', 'L', 1, 1), REGEXP_REPLACE(v_text, 'l', 'L', 'g') FROM scalars"
            },
        )
        # Vertica's WEEK counts from January 1st; its ISOWEEK is other dialects' WEEK
        self.validate_identity(
            "SELECT EXTRACT(WEEK FROM v_date) FROM scalars", "SELECT WEEK(v_date) FROM scalars"
        )
        self.validate_all(
            "SELECT EXTRACT(ISOWEEK FROM v_date) FROM scalars",
            read={"vertica": "SELECT WEEK_ISO(v_date) FROM scalars"},
            write={"postgres": "SELECT EXTRACT(WEEK FROM v_date) FROM scalars"},
        )
        self.validate_all(
            "SELECT DATEDIFF(DAY, v_date, CAST('2024-03-01' AS DATE)) FROM scalars",
            write={
                "postgres": "SELECT (CAST('2024-03-01' AS DATE) - CAST(v_date AS DATE)) FROM scalars",
                "spark": "SELECT DATEDIFF(DAY, v_date, CAST('2024-03-01' AS DATE)) FROM scalars",
            },
        )
        self.validate_all(
            "SELECT LEFT(v_text, LENGTH('he')) = 'he' FROM scalars",
            read={"postgres": "SELECT STARTS_WITH(v_text, 'he') FROM scalars"},
        )
        self.validate_all(
            "SELECT GROUPING_ID(grp, flag) FROM facts GROUP BY ROLLUP (grp, flag)",
            write={"postgres": "SELECT GROUPING(grp, flag) FROM facts GROUP BY ROLLUP (grp, flag)"},
        )
        self.validate_all(
            "SELECT v_int_arr[0] FROM scalars",
            read={"postgres": "SELECT v_int_arr[1] FROM scalars"},
            write={"postgres": "SELECT v_int_arr[1] FROM scalars"},
        )
        self.validate_all(
            "SELECT ADD_MONTHS(v_date, 1), CONTAINS(v_int_arr, 2) FROM scalars WHERE id = 3",
            read={
                "spark": "SELECT ADD_MONTHS(v_date, 1), ARRAY_CONTAINS(v_int_arr, 2) FROM scalars WHERE id = 3"
            },
        )
        self.validate_all(
            "SELECT EDIT_DISTANCE(v_text, 'hello') FROM scalars",
            read={"postgres": "SELECT LEVENSHTEIN(v_text, 'hello') FROM scalars"},
        )

    def test_analytic_functions(self):
        self.validate_identity(
            "SELECT FIRST_VALUE(qty IGNORE NULLS) OVER (PARTITION BY grp ORDER BY id), NTH_VALUE(cat, 3 IGNORE NULLS) OVER (ORDER BY id) FROM facts"
        )
        self.validate_identity("SELECT id, EXPLODE(v_int_arr) OVER (PARTITION ROW) FROM scalars")
        self.validate_identity(
            "SELECT id, EXPLODE(v_int_arr) OVER (PARTITION LEFT JOIN) FROM scalars"
        )
        self.validate_identity("SELECT EXPLODE(v_int_arr) OVER (PARTITION BEST) FROM scalars")
        self.validate_identity("SELECT EXPLODE(v_int_arr) OVER (PARTITION NODES) FROM scalars")
        self.validate_identity(
            "SELECT RANK() OVER (ORDER BY qty NULLS AUTO), RANK() OVER (ORDER BY qty DESC NULLS AUTO) FROM facts",
            "SELECT RANK() OVER (ORDER BY qty), RANK() OVER (ORDER BY qty DESC) FROM facts",
        )

        # ARGMAX(target, arg) returns arg from the row with the largest target
        self.validate_all(
            "SELECT ARGMAX(id, cat) OVER (PARTITION BY grp), ARGMIN(id, price) OVER () FROM facts",
            write={
                "spark": "SELECT MAX_BY(cat, id) OVER (PARTITION BY grp), MIN_BY(price, id) OVER () FROM facts",
            },
        )
        self.validate_all(
            "SELECT FIRST_VALUE(qty IGNORE NULLS) OVER (ORDER BY id NULLS FIRST) FROM facts",
            read={"spark": "SELECT FIRST_VALUE(qty) IGNORE NULLS OVER (ORDER BY id) FROM facts"},
        )

    def test_aggregate_functions(self):
        self.validate_identity(
            "SELECT APPROXIMATE_PERCENTILE(qty USING PARAMETERS percentiles='0.5,1.0') FROM facts",
            "SELECT APPROXIMATE_PERCENTILE(qty USING PARAMETERS percentiles = '0.5,1.0') FROM facts",
        )
        self.validate_identity(
            "SELECT APPROXIMATE_QUANTILES(qty USING PARAMETERS nquantiles=6, epsilon=0.01) OVER () FROM facts",
            "SELECT APPROXIMATE_QUANTILES(qty USING PARAMETERS nquantiles = 6, epsilon = 0.01) OVER () FROM facts",
        )
        self.validate_identity(
            "SELECT LISTAGG(cat USING PARAMETERS max_length=40, on_overflow='TRUNCATE') WITHIN GROUP (ORDER BY id) FROM facts",
            "SELECT LISTAGG(cat USING PARAMETERS max_length = 40, on_overflow = 'TRUNCATE') WITHIN GROUP (ORDER BY id) FROM facts",
        )
        self.validate_identity(
            "SELECT grp, GROUPING_ID(), GROUP_ID() FROM facts GROUP BY ROLLUP (grp) ORDER BY GROUPING_ID()"
        )

        # WITHIN GROUP orders NULLs as the largest values, like windows
        self.validate_identity(
            "SELECT ARGMAX_AGG(qty, id) WITHIN GROUP (ORDER BY ts NULLS FIRST, d DESC NULLS LAST, id) FROM facts"
        )
        self.validate_identity(
            "SELECT ARGMAX_AGG(qty, id) WITHIN GROUP (ORDER BY ts NULLS LAST, d DESC NULLS FIRST) FROM facts",
            "SELECT ARGMAX_AGG(qty, id) WITHIN GROUP (ORDER BY ts, d DESC) FROM facts",
        )
        self.validate_identity(
            "SELECT LISTAGG(cat) WITHIN GROUP (ORDER BY cat DESC NULLS LAST, id) FROM facts"
        )
        self.validate_identity(
            "SELECT ARGMIN_AGG(qty, id) WITHIN GROUP (ORDER BY id DESC NULLS AUTO) FROM facts",
            "SELECT ARGMIN_AGG(qty, id) WITHIN GROUP (ORDER BY id DESC) FROM facts",
        )

    def test_datetime_functions(self):
        # DATEDIFF, TIMESTAMPDIFF and TIMESTAMPADD units, where M is MONTH and Y is DAY
        self.validate_identity(
            "SELECT DATEDIFF(m, v_date, DATE '2024-03-01'), DATEDIFF(y, v_date, DATE '2024-03-01'), DATEDIFF(qq, v_date, DATE '2024-03-01'), DATEDIFF(dayofyear, v_date, DATE '2024-03-01') FROM scalars",
            "SELECT DATEDIFF(MONTH, v_date, CAST('2024-03-01' AS DATE)), DATEDIFF(DAY, v_date, CAST('2024-03-01' AS DATE)), DATEDIFF(QUARTER, v_date, CAST('2024-03-01' AS DATE)), DATEDIFF(DAY, v_date, CAST('2024-03-01' AS DATE)) FROM scalars",
        )
        self.validate_identity(
            "SELECT DATEDIFF(('mon' || 'th'), v_date, DATE '2024-03-01') FROM scalars",
            "SELECT DATEDIFF(('mon' || 'th'), v_date, CAST('2024-03-01' AS DATE)) FROM scalars",
        )
        self.validate_identity(
            "SELECT TIMESTAMPDIFF(ww, v_ts, TIMESTAMP '2024-03-01 12:00:00'), TIMESTAMPDIFF(YEAR, '1-1-2006 12:34:00', '1-1-2008 12:34:00') FROM scalars",
            "SELECT DATEDIFF(WEEK, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(YEAR, CAST('1-1-2006 12:34:00' AS TIMESTAMP), CAST('1-1-2008 12:34:00' AS TIMESTAMP)) FROM scalars",
        )
        self.validate_identity(
            "SELECT TIMESTAMPADD(m, -1, v_ts), TIMESTAMPADD(y, 1, v_ts), TIMESTAMPADD(n, 30, v_ts), TIMESTAMPADD(mcs, 1, v_ts) FROM scalars",
            "SELECT TIMESTAMPADD(MONTH, -1, v_ts), TIMESTAMPADD(DAY, 1, v_ts), TIMESTAMPADD(MINUTE, 30, v_ts), TIMESTAMPADD(MICROSECOND, 1, v_ts) FROM scalars",
        )
        self.validate_identity(
            "SELECT TIMESTAMPADD(WEEK, 1, v_ts), TIMESTAMPADD((CASE WHEN id > 10 THEN 'month' ELSE 'day' END), 1, v_ts) FROM scalars"
        )

        # DATE_PART's WEEK is Vertica's non-ISO week
        self.validate_identity(
            "SELECT DATE_PART('week', v_ts), DATE_PART('isoweek', v_ts), DATE_PART('time zone', v_tstz) FROM scalars",
            "SELECT WEEK(v_ts), EXTRACT(ISOWEEK FROM v_ts), EXTRACT(TIME ZONE FROM v_tstz) FROM scalars",
        )
        self.validate_identity("SELECT EXTRACT(TIME ZONE FROM v_tstz) FROM scalars")
        self.validate_identity("SELECT WEEK_ISO('1-3-2016')")

        # These also take VARCHAR, INTEGER and INTERVAL arguments, which EXTRACT doesn't
        self.validate_identity(
            "SELECT DAY(6), DAY('sep 22, 2011 12:34'), MONTH('6-9'), YEAR(INTERVAL '2-35' YEAR TO MONTH), DAYOFMONTH('2024-01-15'), LAST_DAY('2017/02/03')"
        )

        self.validate_identity(
            "SELECT TIMESTAMP_TRUNC(v_ts), TIMESTAMP_TRUNC(v_ts, 'IYY'), TIMESTAMP_TRUNC(v_ts, 'MM') FROM scalars",
            "SELECT TIMESTAMP_TRUNC(v_ts), TIMESTAMP_TRUNC(v_ts, 'IYY'), DATE_TRUNC('MONTH', v_ts) FROM scalars",
        )
        self.validate_identity(
            "SELECT TIME_SLICE(v_ts, 3), TIME_SLICE(v_ts, 1, 'HOUR', 'END'), TIME_SLICE(v_ts, 3, 'ms') FROM scalars",
            "SELECT TIME_SLICE(v_ts, 3, 'SECOND'), TIME_SLICE(v_ts, 1, 'HOUR', 'END'), TIME_SLICE(v_ts, 3, 'MS') FROM scalars",
        )
        self.validate_identity(
            "SELECT CURRENT_TIME, CURRENT_TIME(1), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP(1), LOCALTIMESTAMP(2)"
        )

    def test_string_functions(self):
        self.validate_identity(
            "SELECT COLLATION(v_varchar, 'LEN_AS'), COLLATION(v_varchar) FROM scalars"
        )
        self.validate_identity(
            "SELECT INSERT(v_text, 1, 3, 'Stor'), SHA1(v_text), SHA1(v_bytes) FROM scalars"
        )
        self.validate_identity(
            "SELECT POSITION(HEX_TO_BINARY('02') IN v_bytes), INSTR(v_bytes, HEX_TO_BINARY('02')) FROM scalars",
            "SELECT INSTR(v_bytes, HEX_TO_BINARY('02')), INSTR(v_bytes, HEX_TO_BINARY('02')) FROM scalars",
        )
        self.validate_identity(
            "SELECT INSTR(v_text, 'l', -1), INSTR(v_text, 'l', 1, 2) FROM scalars",
        )
        self.validate_identity("SELECT OCTET_LENGTH(CAST('abc' AS BINARY(6)))")
        self.validate_identity(
            "SELECT REGEXP_LIKE(v_text, '^line2$', 'm'), REGEXP_LIKE(v_text, 'o') FROM scalars",
            "SELECT REGEXP_LIKE(v_text, '^line2$', 'm'), v_text ~ 'o' FROM scalars",
        )

        # USING OCTETS is the same as the byte-counting variant of the function
        self.validate_identity(
            "SELECT CHAR_LENGTH(v_text USING OCTETS), CHARACTER_LENGTH(v_text USING CHARACTERS) FROM scalars",
            "SELECT OCTET_LENGTH(v_text), LENGTH(v_text) FROM scalars",
        )
        self.validate_identity(
            "SELECT POSITION('w' IN v_text USING OCTETS), POSITION('w' IN v_text USING CHARACTERS) FROM scalars",
            "SELECT POSITIONB(v_text, 'w'), INSTR(v_text, 'w') FROM scalars",
        )
        self.validate_identity(
            "SELECT SUBSTRING(v_text, 5, 2 USING OCTETS), SUBSTRING(v_text FROM 2 FOR 3 USING OCTETS), SUBSTRING(v_text, 5, 2 USING CHARACTERS) FROM scalars WHERE id < 16",
            "SELECT SUBSTRB(v_text, 5, 2), SUBSTRB(v_text, 2, 3), SUBSTRING(v_text FROM 5 FOR 2) FROM scalars WHERE id < 16",
        )
        self.validate_identity(
            "SELECT OVERLAY(v_text PLACING 'xxx' FROM 2 FOR 1 USING OCTETS), OVERLAY(v_text PLACING 'xxx' FROM 2 USING CHARACTERS) FROM scalars WHERE id < 16",
            "SELECT OVERLAYB(v_text, 'xxx', 2, 1), OVERLAY(v_text PLACING 'xxx' FROM 2) FROM scalars WHERE id < 16",
        )

    def test_formatting_and_intervals(self):
        # Interval strings keep their units: INTERVAL '1 month' is 30 days, unlike INTERVAL '1' MONTH
        self.validate_identity("SELECT INTERVAL '1 month', INTERVAL '1 month ', INTERVAL '1 week'")
        self.validate_identity("SELECT INTERVAL '@ 5 minutes ago', INTERVAL -'1 month 1 second'")
        self.validate_identity(
            "SELECT v_ts + INTERVAL '1.5 day', v_ts - INTERVAL '30' MINUTE FROM scalars WHERE id = 3"
        )
        # Plural units and WEEK aren't qualifiers, so they're aliases
        self.validate_identity(
            "SELECT INTERVAL '30' MINUTES, INTERVAL '3' WEEK",
            "SELECT INTERVAL '30' AS MINUTES, INTERVAL '3' AS WEEK",
        )
        self.validate_identity("SELECT INTERVAL '1y 10m' YEAR, INTERVAL '3 days 2 hours' HOUR")
        self.validate_identity("SELECT INTERVAL '1h 3m 6s 5msecs 57us' DAY TO SECOND(4)")
        self.validate_identity(
            "SELECT INTERVAL '28 days 3 hours' HOUR % INTERVAL '27 days 3 hours' HOUR"
        )
        self.validate_identity(
            "SELECT INTERVALYM '1 2', INTERVAL '28 days 3 hours' HOUR(4)",
            "SELECT INTERVAL '1 2' YEAR TO MONTH, INTERVAL '28 days 3 hours' HOUR",
        )
        self.validate_identity(
            "SELECT INTERVAL(3) '28 days 3 hours', INTERVAL(1) '1.2467' SECOND(2), INTERVAL(3) '1.5 days' HOUR TO SECOND",
            "SELECT INTERVAL '28 days 3 hours' DAY TO SECOND(3), INTERVAL '1.2467' SECOND(1), INTERVAL '1.5 days' HOUR TO SECOND(3)",
        )
        self.validate_identity(
            "SELECT CAST(v_interval AS INTERVAL(3)), CAST(v_interval AS INTERVAL MINUTE TO SECOND(1)), CAST(v_interval AS INTERVAL HOUR) FROM vertica_extras"
        )
        self.validate_identity(
            "SELECT CAST('1 2' AS INTERVALYM)", "SELECT CAST('1 2' AS INTERVAL YEAR TO MONTH)"
        )
        self.validate_identity(
            "SELECT (v_ts - TIMESTAMP '2000-01-01') YEAR TO MONTH, (v_ts - TIMESTAMP '2000-01-01') MINUTE TO SECOND(3) FROM scalars WHERE id = 3"
        )
        self.validate_identity(
            "SELECT (v_ts - TIMESTAMP '2000-01-01')(0) FROM scalars WHERE id = 3",
            "SELECT (v_ts - TIMESTAMP '2000-01-01') DAY TO SECOND(0) FROM scalars WHERE id = 3",
        )

        # Unlike CASTs, TIMESTAMP and TIME literals become TIMESTAMPTZ and TIMETZ with a zone
        self.validate_identity(
            "SELECT TIMESTAMP '2020-01-01 10:00+05', TIME(2) '04:05:06-08:00', CAST('2020-01-01 10:00+05' AS TIMESTAMP)"
        )
        self.validate_identity(
            "SELECT v_ts AT TIMEZONE 'PDT' FROM scalars",
            "SELECT v_ts AT TIME ZONE 'PDT' FROM scalars",
        )

        self.validate_identity("SELECT TO_CHAR(v_int8), TO_CHAR(v_ts) FROM scalars")
        self.validate_identity("SELECT TO_NUMBER('-123.456e-01'), TO_NUMBER('1,485', '9,999')")
        self.validate_identity(
            "SELECT TO_CHAR(v_ts, 'YYYY ad a.d.'), TO_CHAR(v_date, 'IDDD ID id') FROM scalars"
        )
        self.validate_identity(
            """SELECT TO_CHAR(v_ts, '"Today is day" DD "of" Month'), TO_DATE('x 2024-03-15', '"x" YYYY-MM-DD') FROM scalars"""
        )

    def test_select_clauses(self):
        self.validate_identity("AT EPOCH LATEST SELECT id FROM join_left ORDER BY id")
        self.validate_identity("AT EPOCH 38 SELECT COUNT(*) FROM join_left")
        self.validate_identity(
            "AT TIME '2026-11-04 16:03:59.237089+00' SELECT COUNT(*) FROM join_left"
        )
        self.validate_identity(
            "AT EPOCH LATEST WITH t AS (SELECT k FROM join_right) SELECT COUNT(k) FROM t"
        )
        self.validate_identity(
            "AT EPOCH LATEST SELECT k FROM join_left UNION SELECT k FROM join_right ORDER BY 1"
        )
        self.validate_identity(
            "SELECT k, id FROM join_left LIMIT 1 OVER (PARTITION BY k ORDER BY id DESC NULLS LAST)"
        )
        self.validate_identity(
            "SELECT k FROM join_left MINUS SELECT k FROM join_right ORDER BY 1",
            "SELECT k FROM join_left EXCEPT SELECT k FROM join_right ORDER BY 1",
        )
        self.validate_identity(
            "SELECT /*+LABEL(my_label)*/ id FROM join_left ORDER BY 1",
            "SELECT /*+ LABEL(my_label) */ id FROM join_left ORDER BY 1",
        )
        self.validate_identity(
            "WITH /*+ENABLE_WITH_CLAUSE_MATERIALIZATION*/ RECURSIVE r(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM r WHERE n < 3) SELECT n FROM r",
            "WITH /*+ ENABLE_WITH_CLAUSE_MATERIALIZATION */ RECURSIVE r(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM r WHERE n < 3) SELECT n FROM r",
        )
        self.validate_identity(
            "SELECT COUNT(*) FROM join_left TABLESAMPLE(99.9) AS l JOIN join_right TABLESAMPLE(99.9) AS r ON l.k = r.k",
            "SELECT COUNT(*) FROM join_left TABLESAMPLE (99.9) AS l JOIN join_right TABLESAMPLE (99.9) AS r ON l.k = r.k",
        )
        self.validate_identity(
            "SELECT l.id, r.id FROM join_left AS l FULL OUTER JOIN join_right AS r ON l.id INTERPOLATE PREVIOUS VALUE r.id"
        )
        self.validate_identity(
            "SELECT l.id, r.id FROM join_left AS l LEFT OUTER JOIN join_right AS r ON l.k = r.k AND l.id INTERPOLATE NEXT VALUE r.id"
        )
        self.validate_identity(
            "SELECT id, EVENT_NAME(), PATTERN_ID(), MATCH_ID() FROM facts WHERE id <= 300 MATCH (PARTITION BY grp ORDER BY id DEFINE a AS cat = 'alpha', b AS cat = 'beta' PATTERN p AS (a b*+ | b+?) ROWS MATCH FIRST EVENT)"
        )
        self.validate_identity(
            "SELECT id, EVENT_NAME() FROM join_left MATCH (ORDER BY id DEFINE lo AS id < 3, hi AS id >= 3 PATTERN p AS (lo+ hi?) ROWS MATCH ALL EVENTS)"
        )
        self.validate_identity(
            "SELECT flag, slice_time, TS_FIRST_VALUE(qty IGNORE NULLS, 'LINEAR'), TS_LAST_VALUE(score) FROM facts WHERE ts >= '2020-03-01' AND ts < '2020-03-08' TIMESERIES slice_time AS '12 hours' OVER (PARTITION BY flag ORDER BY ts) ORDER BY slice_time, flag"
        )
        self.validate_identity(
            "SELECT TIME_SLICE(ts, 3), TIME_SLICE(ts, 3, 'MS', 'END') FROM facts",
            "SELECT TIME_SLICE(ts, 3, 'SECOND'), TIME_SLICE(ts, 3, 'MILLISECOND', 'END') FROM facts",
        )

    def test_math_and_operators(self):
        # Factorial: postfix ! binds as tightly as ::, prefix !! takes the whole arithmetic operand
        self.validate_identity(
            "SELECT grp !, !! grp + 1, -grp!, 2 ^ grp!, grp!::VARCHAR FROM facts",
            "SELECT FACTORIAL(grp), FACTORIAL(grp + 1), -FACTORIAL(grp), POWER(2, FACTORIAL(grp)), CAST(FACTORIAL(grp) AS VARCHAR) FROM facts",
        )
        # Prefix operators bind looser than arithmetic
        self.validate_identity(
            "SELECT |/ qty * 2, ||/ qty + 1, @ qty - 500, @ qty & 3, |/ qty > 3 FROM facts",
            "SELECT SQRT(qty * 2), CBRT(qty + 1), ABS(qty - 500), ABS(qty) & 3, SQRT(qty) > 3 FROM facts",
        )
        self.validate_identity(
            "SELECT DEGREES(grp, qty, score), RADIANS(grp, qty, score), DEGREES(score) FROM facts"
        )
        self.validate_identity("SELECT ROUND(CAST(v_float8 AS DOUBLE PRECISION), 2) FROM scalars")
        self.validate_identity("SELECT ZEROIFNULL(v_dec), NULLIFZERO(v_float8) FROM scalars")
        self.validate_all(
            "SELECT ZEROIFNULL(v_dec), NULLIFZERO(v_float8) FROM scalars",
            write={"postgres": "SELECT COALESCE(v_dec, 0), NULLIF(v_float8, 0) FROM scalars"},
        )

        # IS binds tighter than comparisons
        self.validate_identity(
            "SELECT v_bool = FALSE IS FALSE, v_int4 IS NULL = FALSE FROM scalars",
            "SELECT v_bool = (FALSE IS FALSE), (v_int4 IS NULL) = FALSE FROM scalars",
        )
        self.validate_identity(
            "SELECT k FROM join_left WHERE k <=> ANY (SELECT k FROM join_right GROUP BY k)"
        )

        # LIKE operators, including the bytewise LIKEB and ILIKEB
        self.validate_identity(
            "SELECT v_text LIKEB 'h%', v_text NOT ILIKEB 'H%', v_text LIKEB ANY ('a', 'b'), v_text LIKEB '%$_%' ESCAPE '$' FROM scalars"
        )
        self.validate_identity(
            "SELECT v_text ~~ 'h%', v_text !~~ 'h%', v_text ~~* 'H%', v_text !~~* 'H%' FROM scalars",
            "SELECT v_text LIKE 'h%', v_text NOT LIKE 'h%', v_text ILIKE 'H%', v_text NOT ILIKE 'H%' FROM scalars",
        )
        self.validate_identity(
            "SELECT v_text ~# '_', v_text !~# '_', v_text ~#* 'H%', v_text !~#* 'H%' FROM scalars",
            "SELECT v_text LIKEB '_', v_text NOT LIKEB '_', v_text ILIKEB 'H%', v_text NOT ILIKEB 'H%' FROM scalars",
        )
        self.validate_identity(
            "SELECT v_text !~ 'o', v_text !~* 'O' FROM scalars",
            "SELECT NOT v_text ~ 'o', NOT v_text ~* 'O' FROM scalars",
        )
        self.validate_identity(
            "SELECT v_bytes LIKE CAST('%!%%' AS VARBINARY) ESCAPE CAST('!' AS VARBINARY) FROM scalars"
        )
