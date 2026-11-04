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
        self.validate_identity("SELECT INSTR(v_text, 'l', 1, 2), STRPOS(v_text, 'o') FROM scalars")
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
            "SELECT COALESCE(v_text, '?'), COALESCE(v_int4, 0), NULLIF(v_int4, 0) FROM scalars",
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
