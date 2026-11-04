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
