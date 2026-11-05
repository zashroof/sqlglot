-- Reading each column back checks that values and type mappings agree across engines.

# name: boolean
SELECT id, v_bool FROM scalars ORDER BY id;

# name: integers
SELECT id, v_int2, v_int4, v_int8 FROM scalars ORDER BY id;

# name: floats
SELECT id, v_float4, v_float8 FROM scalars ORDER BY id;

# name: decimals
SELECT id, v_dec, v_dec38 FROM scalars ORDER BY id;

# name: strings
SELECT id, v_text, v_varchar, v_char FROM scalars ORDER BY id;

# name: binary
SELECT id, v_bytes FROM scalars ORDER BY id;

# name: temporal
SELECT id, v_date, v_ts, v_tstz FROM scalars ORDER BY id;

# name: arrays
SELECT id, v_int_arr, v_text_arr FROM scalars ORDER BY id;

# name: json_strings
SELECT id, v_json FROM scalars ORDER BY id;

# name: literals
SELECT TRUE, 1, 9223372036854775807, 1.5, 'text', DATE '2024-01-15', TIMESTAMP '2024-01-15 10:30:00', NULL;

# name: typed_literals
SELECT TIMESTAMPTZ '2024-01-15 10:30:00+02', INTERVAL '1' DAY, INTERVAL '90' MINUTE, '12:30'::TIME, X'0a0b'::VARBINARY;

# name: type_synonyms
SELECT 1::INT8, 1::TINYINT, 1.5::FLOAT8, 1.5::FLOAT(20), 1.5::DOUBLE PRECISION, 'x'::CHARACTER(3), 'x'::CHARACTER VARYING(3), '2024-01-15 10:30:00'::DATETIME, '2024-01-15 10:30:00'::SMALLDATETIME;

# name: binary_types
SELECT TO_HEX('ab'::BINARY(4)), TO_HEX('ab'::VARBINARY(4)), TO_HEX('a'::BINARY), TO_HEX('ab'::BYTEA(4)), TO_HEX('ab'::RAW(4)), TO_HEX('ab'::BINARY VARYING(4)), TO_HEX('ab'::LONG VARBINARY(4)), TO_HEX('abcd'::BINARY(2));

# name: binary_columns
SELECT id, TO_HEX(v_bytes::BINARY(4)), LENGTH(v_bytes::BINARY(4)), TO_HEX(HEX_TO_BINARY('0x' || TO_HEX(v_bytes))), BITSTRING_TO_BINARY('0110') FROM scalars ORDER BY id;

# name: binary_aggregates
SELECT TO_HEX(BIT_AND(v_bytes)), TO_HEX(BIT_OR(v_bytes)), TO_HEX(BIT_XOR(v_bytes)), TO_HEX(MAX(v_bytes)), TO_HEX(MIN(v_bytes)) FROM scalars;

# name: boolean_inputs
SELECT TRUE, FALSE, 't'::BOOLEAN, 'true'::BOOLEAN, 'y'::BOOLEAN, 'yes'::BOOLEAN, '1'::BOOLEAN, 1::BOOLEAN, 'f'::BOOLEAN, 'false'::BOOLEAN, 'n'::BOOLEAN, 'no'::BOOLEAN, '0'::BOOLEAN, 0::BOOLEAN;

# name: character_types
SELECT 'abcd'::CHAR(3), 'ab'::CHAR(4) = 'ab', LENGTH('ab '::CHAR(4)), LENGTH('ab '::VARCHAR(4)), 'x'::CHAR, OCTET_LENGTH('ü'::VARCHAR(2)), LENGTH('vert\0ica'::CHARACTER VARYING);

# name: character_columns
SELECT id, v_char::VARCHAR(5), v_text::CHAR(3), v_varchar::CHARACTER VARYING(4) FROM scalars ORDER BY id;

# name: long_types
SELECT (2 + 2)::LONG VARCHAR, LENGTH(REPEAT('x', 70000)::LONG VARCHAR(100000)), TO_HEX('ab'::LONG VARBINARY), LENGTH('a' || REPEAT('b', 65001)::LONG VARCHAR);

# name: float_types
SELECT 1.1 + 2.2 = 3.3, 1.1::FLOAT + 2.2::FLOAT = 3.3::FLOAT, 'NaN'::FLOAT > 1.0, 'Nan'::FLOAT = 'NaN'::FLOAT, CBRT('NaN'), 'Infinity'::FLOAT > 1e308, -0::FLOAT = 0::FLOAT, FLOAT '-INF';

# name: float_nan_predicate
SELECT id, v_float8 != v_float8, v_float8 = 'NaN', v_float8 + 1 FROM scalars WHERE ABS(v_float8) < 1000 OR v_float8 != v_float8 ORDER BY id;

# name: float_division_by_zero
SELECT 0.0::FLOAT / 0, 0.0::FLOAT // 0, 2.0::FLOAT / 0, 200.0::FLOAT // 0, -2.0::FLOAT / 0;

# name: numeric_types
SELECT (1 / 3)::NUMERIC, (1 / 3)::DECIMAL, (1 / 3)::NUMBER, (1 / 3)::MONEY, (1 / 3)::NUMERIC(5, 2), (1 / 3)::DECIMAL(10), 12.5::NUMBER(10, 1), 1.23456::MONEY(10, 2), NUMBER '12.5', MONEY '1.23456';

# name: numeric_operations
SELECT id, v_dec + 1, v_dec * 2, -v_dec, ABS(v_dec), v_dec::FLOAT, v_dec / 7, v_dec % 3, v_dec <=> v_dec38 FROM scalars ORDER BY id;

# name: numeric_precision
SELECT 123456.78::NUMERIC(8, 2), 1.5::NUMERIC(2, 0), (18. + 3. / 16) / 1024 * 1000, 99999999999999999999999999999999999999::NUMERIC(38, 0) + 1, 1::NUMERIC(1000, 990);

# name: numeric_sums
SELECT SUM(v_dec38), SUM_FLOAT(v_dec38), AVG(v_dec38), SUM(v_int8), SUM_FLOAT(v_int8), AVG(v_dec) FROM scalars;

# name: numeric_sum_overflow
SELECT SUM_FLOAT(x) FROM (SELECT (1 << 62) AS x FROM scalars WHERE id <= 5) AS t;

# name: spatial_types
SELECT ST_AsText(ST_GeomFromText('POINT(1 2)')::GEOMETRY), ST_AsText(ST_GeographyFromText('POINT(0 1)')::GEOGRAPHY), ST_Distance(ST_GeographyFromText('POINT(0 0)'), ST_GeographyFromText('POINT(0 1)')) > 0;

# name: coercion_implicit
SELECT 2 + '2', 2 + 2 || 2, '3'::CHAR + 4.33::FLOAT, DATE '2013-07-31' + INTERVAL '1 12:00:00', DATE '2013-07-31' - INTERVAL '6:6:6', '2.5'::FLOAT + 2;

# name: coercion_numeric_strings
SELECT NUMERIC '12.3e3', '12.3p10'::NUMERIC, CAST('0x12.3p-10e3' AS NUMERIC), FLOAT '123.5'::INT, (FLOAT '123.5')::INT;

# name: coercion_chart
SELECT TRUE::INT, TRUE::VARCHAR, 1::BOOLEAN, 5::NUMERIC(5, 1), 5::FLOAT, 2.5::INT, 'abc'::CHAR(5)::VARCHAR, '12:30:00'::TIME::INTERVAL, INTERVAL '1 02:30:00'::TIME, '12:30'::TIME::TIMESTAMP > TIMESTAMP '2000-01-01', 3::INTERVAL DAY, 3::INTERVAL YEAR;

# name: coercion_columns
SELECT id, v_int4::FLOAT, v_int4::NUMERIC(20, 2), v_float8::NUMERIC(30, 5), v_dec::INT, v_date::TIMESTAMPTZ, v_ts::TIME, v_tstz::TIMETZ IS NULL, v_int2 || '' FROM scalars WHERE ABS(v_float8) < 1e20 ORDER BY id;

# name: oracle_mappings
SELECT 12345678901234567890::NUMERIC(20, 0), 1.5::NUMBER(5, 0), 1.5::NUMBER, 1.25::FLOAT, 'ab'::VARBINARY(2000), 'ab'::LONG VARBINARY, 'ab'::CHAR(6), 'ab'::VARCHAR(12), '2024-01-15 10:30:00.123456'::TIMESTAMP, '2024-01-15 10:30:00+02'::TIMESTAMP WITH TIME ZONE, '1-2'::INTERVAL YEAR TO MONTH, '1 02:03:04'::INTERVAL DAY TO SECOND, 'clob'::LONG VARCHAR;
