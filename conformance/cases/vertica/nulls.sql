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
