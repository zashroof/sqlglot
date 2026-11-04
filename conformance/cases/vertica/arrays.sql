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
