# name: subscript
SELECT id, v_int_arr[0], v_text_arr[1] FROM scalars ORDER BY id;

# name: length
SELECT id, ARRAY_LENGTH(v_int_arr), ARRAY_COUNT(v_int_arr) FROM scalars ORDER BY id;

# name: contains_find
SELECT id, CONTAINS(v_int_arr, 2), ARRAY_FIND(v_int_arr, 3) FROM scalars ORDER BY id;

# name: concat
SELECT id, ARRAY_CAT(v_int_arr, ARRAY[9]) FROM scalars ORDER BY id;

# name: constructors
SELECT ARRAY[1, 2, 3], ARRAY['a', NULL];

# name: nested_constructors
SELECT ARRAY[ARRAY[1], ARRAY[2]], ARRAY[[1, 2], [3, 4]], ARRAY[ROW(1, 2), ROW(1, 3)], ARRAY[]::ARRAY[INT];

# name: element_access
SELECT (ARRAY['a', 'b', 'c', 'd', 'e'])[1], (ARRAY['a', 'b', 'c', 'd', 'e', 'f', 'g'])[1:4], (ARRAY[ARRAY[1, 2], ARRAY[3, 4]])[0][0], (ARRAY[1, 2])[5];

# name: column_slices
SELECT id, v_int_arr[0:2], v_text_arr[1:3], v_int_arr[10] FROM scalars ORDER BY id;

# name: bounded_casts
SELECT ARRAY[1, 2, 3]::ARRAY[VARCHAR, 2], ARRAY[1, 2, 3]::ARRAY[INT](100), ARRAY[ARRAY[1, 2, 3], ARRAY[4, 5, 6]]::ARRAY[ARRAY[VARCHAR, 5], 10], ARRAY['1', '2', '3']::ARRAY[INT];

# name: column_casts
SELECT id, v_int_arr::ARRAY[VARCHAR(10)], v_int_arr::ARRAY[FLOAT, 2], v_text_arr::ARRAY[VARCHAR(100)](1000) FROM scalars ORDER BY id;

# name: comparisons
SELECT ARRAY[1, 3] = NULL, ARRAY[1, 3] <=> NULL, ARRAY[]::ARRAY[INT] = ARRAY[]::ARRAY[INT], ARRAY[1, 2, NULL] = ARRAY[1, 4, NULL], ARRAY[1, 2, NULL] = ARRAY[1, 2, 3], ARRAY[1, 2] < ARRAY[1, 2, 0];

# name: column_comparisons
SELECT id, v_int_arr = ARRAY[1, 2, 3], v_int_arr <=> NULL, v_int_arr < ARRAY[1, 3], v_text_arr > ARRAY['a'] FROM scalars ORDER BY id;

# name: grouping_and_ordering
SELECT v_int_arr, COUNT(*) FROM scalars GROUP BY v_int_arr ORDER BY v_int_arr, 2;

# name: case_and_join
SELECT a.id, b.id, CASE WHEN a.v_int_arr = ARRAY[1, 2, 3] THEN 'yes' ELSE 'no' END FROM scalars AS a JOIN scalars AS b ON a.v_int_arr = b.v_int_arr ORDER BY 1, 2;

# name: set_constructors
SELECT SET[1, 2, 3], SET[3, 1, 1, 2], SET['b', 'a'], ARRAY[1, 5, 2, 6, 3, 0, 6, 4]::SET[INT];

# name: set_casts
SELECT SET['1', '2', '3']::SET[INT], ARRAY[1.2, 1.4, 2]::SET[INT], ARRAY[3, 1]::SET[INT, 10], ARRAY[3, 1]::SET[VARCHAR](100), SET[2, 1]::ARRAY[INT];

# name: set_columns
SELECT id, v_int_arr::SET[INT], v_text_arr::SET[VARCHAR(100)], CONTAINS(v_int_arr::SET[INT], 3) FROM scalars ORDER BY id;

# name: set_comparisons
SELECT SET[1, 2] = SET[2, 1], SET[1, 2] < SET[1, 3], SET[1] <=> NULL, SET[1, 2] = NULL;
