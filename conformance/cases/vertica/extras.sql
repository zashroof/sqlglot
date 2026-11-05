-- vertica_extras only exists on Vertica, so these cases only check the roundtrip.

# name: types
SELECT id, v_uuid, v_time, v_interval, v_numeric, v_long_varchar, v_binary, v_row FROM vertica_extras ORDER BY id;

# name: uuid
SELECT id, CAST(v_uuid AS VARCHAR), v_uuid = '123e4567-e89b-12d3-a456-426614174000' FROM vertica_extras ORDER BY id;

# name: time_and_interval
SELECT id, v_time + INTERVAL '1' HOUR, v_interval * 2, EXTRACT(HOUR FROM v_time) FROM vertica_extras ORDER BY id;

# name: row_fields
SELECT id, v_row.a, v_row.b FROM vertica_extras ORDER BY id;

# name: long_types
SELECT id, LENGTH(v_long_varchar), TO_HEX(v_binary) FROM vertica_extras ORDER BY id;

# name: uuid_formats
SELECT id, v_uuid = '{123e4567-e89b-12d3-a456-426614174000}'::UUID, v_uuid = '123E4567E89B12D3A456426614174000'::UUID, v_uuid = '123e-4567-e89b-12d3-a456-4266-1417-4000'::UUID, v_uuid::CHAR(36) FROM vertica_extras ORDER BY id;

# name: uuid_aggregates
SELECT MIN(v_uuid), MAX(v_uuid), COUNT(v_uuid), COUNT(DISTINCT v_uuid) FROM vertica_extras;

# name: uuid_generate
SELECT LENGTH(UUID_GENERATE()::VARCHAR), UUID_GENERATE() IS NOT NULL;

# name: row_constructors
SELECT ROW('Amy', 2, FALSE), ROW('Amy', 2, FALSE) AS student(name, id, current), ROW('Amy' AS name, 2 AS id, FALSE AS current) AS student, ROW('Howard''s house', 2.5::INT, FALSE::VARCHAR);

# name: row_in_arrays
SELECT ARRAY[ROW('Amy' AS name, 2 AS id), ROW('Fred' AS first_name, 4 AS id)], ROW(1, ARRAY['a', 'b'], ROW(2 AS x) AS inner_row);

# name: row_comparisons
SELECT ROW(1, 'joe') > ROW(2, 'bob'), ROW(1, NULL, 3) = ROW(1, 2, 3), ROW(1, 2) <=> ROW(1, 2), ROW(1, 2) IS NULL;

# name: row_columns
SELECT id, v_row = ROW(1, 'x'), v_row IS NULL, v_row.a + 1, UPPER(v_row.b), v_row FROM vertica_extras ORDER BY id;

# name: row_casts
SELECT id, v_row::ROW(VARCHAR, VARCHAR), v_row::ROW(x VARCHAR(10), y VARCHAR(5)), CAST(v_row AS ROW(a FLOAT, b VARCHAR(20))) FROM vertica_extras ORDER BY id;

# name: row_grouping
SELECT v_row, COUNT(*) FROM vertica_extras GROUP BY v_row ORDER BY 2, v_row;

# name: numeric_wide
SELECT id, v_numeric + 1, v_numeric * 2, v_numeric::NUMERIC(30, 5), v_numeric::FLOAT, v_numeric::!INT FROM vertica_extras ORDER BY id;

# name: binary_fixed_width
SELECT id, TO_HEX(v_binary::VARBINARY), LENGTH(v_binary), TO_HEX(v_binary::BINARY(2)), v_binary = X'01020304' FROM vertica_extras ORDER BY id;

# name: long_varchar_casts
SELECT id, v_long_varchar::VARCHAR(10), LENGTH(v_long_varchar::LONG VARCHAR(2000)), v_long_varchar || 'x' FROM vertica_extras ORDER BY id;

# name: time_interval_coercion
SELECT id, v_time::INTERVAL, v_interval::TIME, v_time::VARCHAR, v_interval::VARCHAR FROM vertica_extras ORDER BY id;
