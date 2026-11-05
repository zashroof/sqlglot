# name: int_to_varchar
SELECT id, CAST(v_int4 AS VARCHAR), v_int8::VARCHAR(30) FROM scalars ORDER BY id;

# name: float_to_varchar
SELECT id, CAST(v_float8 AS VARCHAR) FROM scalars ORDER BY id;

# name: decimal_to_int
SELECT id, CAST(v_dec AS INT) FROM scalars WHERE v_dec IS NOT NULL ORDER BY id;

# name: float_to_int
SELECT id, CAST(v_float8 AS INT) FROM scalars WHERE ABS(v_float8) < 1000000 ORDER BY id;

# name: text_to_number
SELECT CAST('123' AS INT), CAST('123.456' AS NUMERIC(10, 2)), CAST('1e3' AS FLOAT), '-0.005'::NUMERIC(10, 2);

# name: text_to_temporal
SELECT CAST('2024-01-15' AS DATE), CAST('2024-01-15 10:30:00' AS TIMESTAMP), CAST('2024-01-15 10:30:00+02' AS TIMESTAMPTZ);

# name: temporal_casts
SELECT id, CAST(v_ts AS DATE), CAST(v_date AS TIMESTAMP), CAST(v_tstz AS DATE), CAST(v_tstz AS TIMESTAMP) FROM scalars ORDER BY id;

# name: boolean_casts
SELECT id, CAST(v_bool AS INT), CAST(v_bool AS VARCHAR) FROM scalars ORDER BY id;

# name: default_varchar_length
SELECT CAST(REPEAT('x', 100) AS VARCHAR), LENGTH(CAST(REPEAT('x', 100) AS VARCHAR));

# name: binary_functions
SELECT id, TO_HEX(v_bytes), LENGTH(v_bytes) FROM scalars ORDER BY id;

# name: integer_types_are_64_bit
SELECT CAST(3000000000 AS INT), CAST(3000000000 AS SMALLINT) + 1, CAST(1.5 AS REAL);

# name: cast_forms
SELECT CAST((2 + 2) AS VARCHAR), (2 + 2)::VARCHAR, INTEGER '123', FLOAT '2.2' + 2, (2 + 2)::LONG VARCHAR, DATE '2024-01-15'::VARCHAR, FLOAT '123.5'::INT;

# name: cast_column_forms
SELECT id, CAST(v_int4 AS NUMERIC(20, 2)), v_text::VARCHAR(3), v_int8::FLOAT::VARCHAR FROM scalars ORDER BY id;

# name: cast_truncation
SELECT 'abcd'::BINARY(2), 'abcd'::CHAR(3), 'abcd'::VARCHAR(2), TO_HEX('ab'::BINARY(4)), TO_HEX('ab'::VARBINARY(4)), TO_HEX('ab'::LONG VARBINARY(4));

# name: binary_resizing
SELECT id, TO_HEX(v_bytes::BINARY(2)), TO_HEX(v_bytes::BINARY(6)::VARBINARY), TO_HEX(v_bytes::LONG VARBINARY::VARBINARY(1)) FROM scalars ORDER BY id;

# name: cast_failures_to_null
SELECT id, v_text::!INT, v_text::!FLOAT, v_text::!DATE, v_char ::! NUMERIC(10, 2), v_text_arr::!ARRAY[INT] FROM scalars ORDER BY id;

# name: cast_failures_in_subqueries
SELECT x::!INT, x ::! FLOAT, x::!TIME FROM (SELECT 'one' AS x UNION ALL SELECT '1') AS t ORDER BY 1;

# name: cast_failures_time_default
SELECT a, a::TIME, a::DATE FROM (SELECT 'one' AS a UNION ALL SELECT '1' UNION ALL SELECT '12:30' UNION ALL SELECT '2024-01-15') AS t ORDER BY 1;

# name: cast_failures_expressions
SELECT id, (v_text || '0')::!INT, (v_int4 + 1)::!VARCHAR FROM scalars ORDER BY id;

# name: complex_default_lengths
SELECT LENGTH(TO_JSON(ROW(REPEAT('x', 100))::ROW(a VARCHAR))), LENGTH(TO_JSON(ARRAY[REPEAT('x', 100)]::ARRAY[VARCHAR])), LENGTH(TO_JSON(ROW(REPEAT('x', 100))::ROW(VARCHAR(90))));

# name: typed_literal_lengths
SELECT CHAR 'abc', LENGTH(CHAR 'abc'), CHARACTER 'xyz', CHAR(2) 'abc', CHAR 'ü', TO_HEX(BINARY 'ab'), TO_HEX(BINARY(4) 'ab'), VARCHAR 'abcdef', TO_HEX(VARBINARY 'ab'), CAST('abc' AS CHAR), TO_HEX(CAST('ab' AS BINARY)), TO_HEX('ab'::BINARY);
