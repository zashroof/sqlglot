# name: order_integers
SELECT id, v_int4 FROM scalars ORDER BY v_int4, id;

# name: order_integers_desc
SELECT id, v_int4 FROM scalars ORDER BY v_int4 DESC, id;

# name: order_strings
SELECT id, v_text FROM scalars ORDER BY v_text, id;

# name: order_dates
SELECT id, v_date FROM scalars ORDER BY v_date DESC, id;

# name: null_functions
SELECT id, COALESCE(v_int4, -1), NVL(v_int4, -1), NVL2(v_int4, 'set', 'unset'), ISNULL(v_text, '?'), IFNULL(v_text, '?'), NULLIF(v_int4, 42) FROM scalars ORDER BY id;

# name: decode
SELECT id, DECODE(v_int4, 42, 'answer', 0, 'zero', 'other') FROM scalars ORDER BY id;

# name: case
SELECT id, CASE WHEN v_int4 > 0 THEN 'positive' WHEN v_int4 < 0 THEN 'negative' WHEN v_int4 = 0 THEN 'zero' ELSE 'null' END FROM scalars ORDER BY id;

# name: three_valued_logic
SELECT NULL = NULL, NULL IS NULL, NULL <=> NULL, 1 <=> NULL, NULL AND FALSE, NULL OR TRUE, NOT NULL;

# name: boolean_tests
SELECT id, v_bool IS TRUE, v_bool IS NOT FALSE, v_bool IS UNKNOWN FROM scalars ORDER BY id;

# name: coalesce_forms
SELECT id, COALESCE(v_int4), COALESCE(v_int4, v_int8, -1), COALESCE(v_text, v_varchar, ''), COALESCE(NULL, NULL, v_date), COALESCE(v_float8, v_dec, 0) FROM scalars ORDER BY id;

# name: coalesce_star
SELECT COALESCE(*) FROM (SELECT k, id FROM join_left) AS t ORDER BY 1;

# name: nvl_ifnull_isnull
SELECT id, NVL(v_date, DATE '2000-01-01'), IFNULL(v_dec, 0.0), ISNULL(v_float8, -1), NVL('fast', NULL), IFNULL(NULL, 140), ISNULL(60, 90) FROM scalars ORDER BY id;

# name: nvl2_types
SELECT id, NVL2(v_text, 'Known', 'Withheld'), NVL2(v_int4, v_int4 * 2, 0.5), NVL2(v_date, v_ts, NULL), NVL2(NULL, 'fast', 'database') FROM scalars ORDER BY id;

# name: nullif_types
SELECT id, NULLIF(v_text, ''), NULLIF(v_dec, 0), NULLIF(v_date, DATE '2024-01-15'), NULLIF(1, 1), NULLIF(20.45, 50.80), NULLIF(v_tstz, '2024-01-15 10:30:00+00') FROM scalars ORDER BY id;

# name: zeroifnull_nullifzero_types
SELECT id, ZEROIFNULL(v_float8), NULLIFZERO(v_float8), ZEROIFNULL(v_dec), NULLIFZERO(v_dec), ZEROIFNULL(v_int8) + 1 FROM scalars ORDER BY id;

# name: zeroifnull_nullifzero_interval
SELECT id, ZEROIFNULL(v_interval), NULLIFZERO(v_interval) FROM vertica_extras ORDER BY id;

# name: case_searched
SELECT id, CASE WHEN v_int4 = 1 THEN 'one' WHEN v_int4 = 42 THEN 'answer' END, CASE WHEN v_bool THEN 1 WHEN NOT v_bool THEN 0 ELSE -1 END FROM scalars ORDER BY id;

# name: case_simple
SELECT id, CASE v_int4 WHEN 1 THEN 'one' WHEN 42 THEN 'answer' ELSE 'other' END, CASE v_text WHEN 'zzz' THEN 1 WHEN 'AAA' THEN 2 END, CASE v_int4 WHEN NULL THEN 'null' ELSE 'not matched' END FROM scalars ORDER BY id;

# name: case_short_circuit
SELECT id, CASE WHEN v_int4 <> 0 THEN 100 / v_int4 > 1.5 ELSE FALSE END, CASE WHEN v_int4 = 0 THEN NULL ELSE v_int8 // v_int4 END FROM scalars ORDER BY id;

# name: case_where
SELECT id FROM scalars WHERE CASE WHEN v_int4 <> 0 THEN v_int8 / v_int4 > 1.5 ELSE FALSE END ORDER BY id;

# name: case_mixed_result_types
SELECT id, CASE WHEN v_int4 > 0 THEN v_int4 WHEN v_int4 < 0 THEN v_dec ELSE v_float8 END FROM scalars ORDER BY id;

# name: null_value
SELECT id, v_text = '', v_text IS NULL, v_text = NULL, v_int4 > NULL, v_text || NULL, NULL || '' FROM scalars ORDER BY id;

# name: null_safe_join
SELECT l.id, r.id FROM join_left AS l JOIN join_right AS r ON l.k <=> r.k ORDER BY l.id, r.id;

# name: null_characters
SELECT LENGTH(E'a\000b'), E'a\000b' = E'a\000c', OCTET_LENGTH(E'\000');

# name: order_nulls_by_type
SELECT id, v_float8, v_bool FROM scalars ORDER BY v_float8, v_bool, id;
