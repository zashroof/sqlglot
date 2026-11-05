-- Collection functions on arrays and sets.

# name: apply_aggregates
SELECT id, APPLY_SUM(v_int_arr), APPLY_AVG(v_int_arr), APPLY_MIN(v_int_arr), APPLY_MAX(v_int_arr) FROM scalars ORDER BY id;

# name: apply_aggregate_literals
SELECT APPLY_AVG(ARRAY[1, 2.4, 5, 6]), APPLY_SUM(ARRAY[12.5, 3, 4, 1]), APPLY_MAX(ARRAY[1, 3.4, 15]), APPLY_MIN(SET[1, 3.4, 15]), APPLY_SUM(ARRAY[INTERVAL '1' DAY, INTERVAL '2' HOUR]);

# name: apply_counts
SELECT id, APPLY_COUNT(v_int_arr), ARRAY_COUNT(v_text_arr), APPLY_COUNT_ELEMENTS(v_int_arr), ARRAY_LENGTH(v_text_arr) FROM scalars ORDER BY id;

# name: apply_count_literals
SELECT APPLY_COUNT(ARRAY[1, NULL, 3, 7, 8, 5]), APPLY_COUNT_ELEMENTS(ARRAY[1, NULL, 3, 7, 8, 5]), APPLY_COUNT_ELEMENTS(ARRAY[NULL]), APPLY_COUNT_ELEMENTS(SET[1, 1, 3]), ARRAY_LENGTH(ARRAY[]::ARRAY[INT]);

# name: array_cat
SELECT id, ARRAY_CAT(v_int_arr, ARRAY[3, 4, 5.0]), ARRAY_CAT(v_text_arr, v_text_arr) FROM scalars ORDER BY id;

# name: array_dims
SELECT ARRAY_DIMS(ARRAY[[1, 2], [2, 3]]), ARRAY_DIMS(ARRAY[1]), ARRAY_DIMS(ARRAY[ARRAY[ARRAY['a']]]);

# name: array_contains
SELECT id, ARRAY_CONTAINS(v_int_arr, 2), ARRAY_CONTAINS(v_text_arr, 'a') FROM scalars WHERE v_int_arr IS NOT NULL ORDER BY id;

# name: contains_values
SELECT id, CONTAINS(v_int_arr, NULL), CONTAINS(v_text_arr, ''), CONTAINS(SET[1, 2, 3, 4], 2) FROM scalars WHERE v_int_arr IS NOT NULL ORDER BY id;

# name: contains_complex
SELECT CONTAINS(ARRAY[ARRAY[1, 2, 3], ARRAY[1, NULL, 4]], ARRAY[1, NULL, 4]), CONTAINS(ARRAY[ROW(1, 'a'::VARCHAR), ROW(2, 'b'::VARCHAR)], ROW(2, 'b'::VARCHAR));

# name: contains_lambda
SELECT id, CONTAINS(v_int_arr, e -> e > 2), CONTAINS(v_int_arr, (e, idx) -> idx > 0 AND e IS NULL) FROM scalars ORDER BY id;

# name: array_find
SELECT id, ARRAY_FIND(v_int_arr, 3), ARRAY_FIND(v_text_arr, NULL), ARRAY_FIND(v_int_arr, e -> e < 0), ARRAY_FIND(v_text_arr, (e, i) -> i > 0 AND e LIKE '%') FROM scalars ORDER BY id;

# name: array_find_literals
SELECT ARRAY_FIND(ARRAY[1, 2, 7, 5, 7], 7), ARRAY_FIND(ARRAY[1, 3, 5, 7], 4), ARRAY_FIND(ARRAY[ARRAY[1, 2, 3], ARRAY[1, NULL, 4]], ARRAY[1, NULL, 4]);

# name: filter
SELECT id, FILTER(v_int_arr, e -> e > 1), FILTER(v_text_arr, (e, i) -> i <> 1) FROM scalars ORDER BY id;

# name: set_union
SELECT SET_UNION(SET[1, 2, 4], SET[2, 3, 4, 5.9]), SET_UNION(SET['a'], NULL), SET_UNION(NULL::SET[INT], NULL::SET[INT]);

# name: string_to_array
SELECT STRING_TO_ARRAY('[1,3,5]'), STRING_TO_ARRAY('[1,2,3]')::ARRAY[INT], STRING_TO_ARRAY('t|t|f|t' USING PARAMETERS collection_delimiter = '|');

# name: string_to_array_parameters
SELECT STRING_TO_ARRAY('{NASA-1683,NASA-7867,SPX-76}' USING PARAMETERS collection_open = '{', collection_close = '}'), STRING_TO_ARRAY('{"us-1672",null,"darpa-1963"}' USING PARAMETERS collection_open = '{', collection_close = '}'), STRING_TO_ARRAY('<a;-;"b;c">' USING PARAMETERS collection_delimiter = ';', collection_open = '<', collection_close = '>', collection_null_element = '-', collection_enclose = '"');

# name: string_to_array_columns
SELECT id, STRING_TO_ARRAY(v_varchar USING PARAMETERS collection_delimiter = ' ') FROM scalars WHERE id IN (3, 5, 7) ORDER BY id;

# name: to_json
SELECT id, TO_JSON(v_int_arr), TO_JSON(v_text_arr) FROM scalars ORDER BY id;

# name: to_json_literals
SELECT TO_JSON(SET[1683, 7867, 76, 76]), TO_JSON(ROW(1 AS a, ARRAY['x'] AS b)), TO_JSON(ARRAY[ROW(1, 2)]);

# name: explode
SELECT EXPLODE(id, v_int_arr) OVER (PARTITION BY id) FROM scalars ORDER BY 1, 2;

# name: explode_literals
SELECT EXPLODE(ARRAY[1, 2, NULL, 4]) OVER () ORDER BY 1;

# name: explode_partition_best
SELECT EXPLODE(id, v_int_arr) OVER (PARTITION BEST) FROM scalars ORDER BY 1, 2;

# name: explode_parameters
SELECT EXPLODE(v_int_arr, id USING PARAMETERS skip_partitioning = TRUE) AS (pos, val, id) FROM scalars ORDER BY id, pos;

# name: explode_count
SELECT EXPLODE(id, v_int_arr, v_text_arr USING PARAMETERS explode_count = 2) OVER () FROM scalars ORDER BY 1, 2, 4;

# name: explode_all
SELECT EXPLODE(v_int_arr, v_text_arr USING PARAMETERS explode_all = TRUE, with_offset = FALSE) OVER () AS (i, t) FROM scalars WHERE id = 3 ORDER BY 1, 2;

# name: explode_cross_join
SELECT id, pos, x FROM scalars CROSS JOIN EXPLODE(v_int_arr USING PARAMETERS skip_partitioning = TRUE) AS t (pos, x) ORDER BY id, pos;

# name: explode_left_join_lateral
SELECT id, MIN(x), COUNT(x) FROM scalars LEFT JOIN LATERAL EXPLODE(v_int_arr USING PARAMETERS skip_partitioning = TRUE) AS t (pos, x) GROUP BY id ORDER BY id;

# name: unnest
SELECT UNNEST(v_int_arr) AS v, id FROM scalars ORDER BY id, v;

# name: unnest_literals
SELECT UNNEST(ARRAY[1, 2, NULL, 4]) OVER () ORDER BY 1;

# name: unnest_multiple
SELECT id, UNNEST(v_int_arr, v_text_arr) FROM scalars WHERE id IN (3, 5) ORDER BY 1, 2, 3;

# name: unnest_parameters
SELECT id, UNNEST(v_int_arr USING PARAMETERS with_offset = TRUE) OVER (PARTITION BY id) FROM scalars ORDER BY 1, 2;

# name: unnest_joins
SELECT id, x FROM scalars CROSS JOIN UNNEST(v_int_arr) AS t (x) WHERE x > 0 ORDER BY id, x;

# name: unnest_left_join_lateral
SELECT id, MIN(x), AVG(x) FROM scalars LEFT JOIN LATERAL UNNEST(v_int_arr) AS t (x) GROUP BY id ORDER BY id;

# name: implode
SELECT grp, IMPLODE(id) WITHIN GROUP (ORDER BY id DESC) FROM facts WHERE id <= 20 GROUP BY grp ORDER BY grp;

# name: implode_parameters
SELECT grp, ARRAY_LENGTH(IMPLODE(cat USING PARAMETERS allow_truncate = TRUE, max_binary_size = 30)) FROM facts WHERE id <= 100 GROUP BY grp ORDER BY grp;

# name: implode_explode_roundtrip
SELECT id, IMPLODE(x) WITHIN GROUP (ORDER BY pos) FROM (SELECT EXPLODE(id, v_int_arr) OVER (PARTITION BY id) AS (id, pos, x) FROM scalars) AS e GROUP BY id ORDER BY id;

# name: string_to_array_deprecated
SELECT STRING_TO_ARRAY('[a,b]', ','), STRING_TO_ARRAY('[a|b|null]', '|');
