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
