# name: arithmetic_operators
SELECT 2 + 3, 2 - 3, 2 * 3, 4 / 2, 117.32 // 2.5, 7 // 2, -7 // 2, 5 % 4, -5 % 4, 2.0 ^ 3.0, 2 ^ 10, 2 ^ -1;

# name: arithmetic_operators_columns
SELECT id, qty + grp, qty - grp, qty * grp, qty / 7, qty // 7, qty % 7, price // 3, score ^ 2 FROM facts WHERE id <= 50 ORDER BY id;

# name: factorial_operators
SELECT 5 !, 4.98 !, 0 !, !! 5, !! 0, 3! * 2, -3!, -(3!), (-1.5)!;

# name: factorial_columns
SELECT id, grp !, !! grp, (grp + 1)!, grp! + 1 FROM facts WHERE id <= 50 AND grp <= 15 ORDER BY id;

# name: root_and_absolute_value_operators
SELECT |/ 25.0, |/ 2, ||/ 27.0, ||/ -8, @ -5.0, @ 3, @ -2 ^ 2;

# name: root_and_absolute_value_columns
SELECT id, |/ ABS(score), ||/ score, @ score, @ qty, @ v FROM (SELECT id, score, qty, qty - 500 AS v FROM facts WHERE id <= 50) AS t ORDER BY id;

# name: prefix_operator_precedence
SELECT |/ 16 * 2, |/ 4 ^ 2, ||/ 8 + 1, @ -5 + 1, @ 2 - 5 * 2, !! 3 + 1, !! 2 * 3, 2 * |/ 16 + 9, @ -5 & 3, |/ 16 > 3, |/ 16 || 'x';

# name: postfix_operator_precedence
SELECT 2 ^ 3!, 3! ^ 2, 3!::VARCHAR, '3'::INT!, !! 3!, 2 + 3! * 2, (2 + 3)!;

# name: exponent_precedence
SELECT 2 ^ 3 ^ 2, -2 ^ 2, 2 * 3 ^ 2, 2 + 3 * 4 ^ 2 - -1, 10 - 2 - 3, 100 / 10 / 5, 2 ^ 0.5 * 2;

# name: bitwise_operators
SELECT 12 & 4, 32 | 3, 17 # 5, ~1, 1 << 4, 8 >> 2, ~0, -1 >> 60, 12 & 10 | 1, 1 << 2 + 1, 3 # 1 + 1;

# name: bitwise_operators_columns
SELECT id, v_int8 & 255, v_int8 | 1, v_int8 # v_int4, ~v_int4, v_int4 << 2, v_int8 >> 3 FROM scalars WHERE v_int4 IS NOT NULL AND id NOT IN (6, 7) ORDER BY id;

# name: bitwise_binary
SELECT 'xyz'::VARBINARY & 'zyx'::VARBINARY, 'xyz'::VARBINARY | 'zyx'::VARBINARY, 'xyz'::VARBINARY & 'zy'::VARBINARY, 'xyz'::VARBINARY # 'zyx'::VARBINARY, ~'xyz'::VARBINARY;

# name: bitwise_binary_columns
SELECT id, v_bytes & 'ab'::VARBINARY, v_bytes | '\001'::VARBINARY, ~v_bytes FROM scalars WHERE v_bytes IS NOT NULL ORDER BY id;

# name: comparison_operators
SELECT 1 < 2, 1 > 2, 1 <= 1, 2 >= 3, 1 = 1, 1 <=> 1, 1 != 2, 1 <> 1, NULL <=> NULL, 1 <=> NULL, NULL = NULL, NULL != 1;

# name: comparison_operators_columns
SELECT id, v_int4 < v_int8, v_int4 > 0, v_text <= 'm', v_text >= 'm', v_int4 = v_int8, v_int4 <=> v_int8, v_text != 'zzz', v_date <> DATE '2024-01-15' FROM scalars ORDER BY id;

# name: comparison_collections
SELECT id, v_int_arr = ARRAY[1, 2, 3], v_int_arr < ARRAY[1, 3], v_int_arr <=> NULL FROM scalars WHERE id <= 8 ORDER BY id;

# name: logical_operators
SELECT TRUE AND NULL, TRUE OR NULL, FALSE AND NULL, FALSE OR NULL, NULL AND NULL, NULL OR NULL, NOT NULL, NOT TRUE, TRUE AND NOT FALSE;

# name: logical_operators_columns
SELECT id, v_bool AND v_int4 > 0, v_bool OR v_int4 > 0, NOT v_bool, NOT v_bool AND v_bool, NOT (v_bool OR FALSE), v_bool OR v_int4 IS NULL AND v_text IS NULL FROM scalars ORDER BY id;

# name: logical_precedence
SELECT TRUE OR TRUE AND FALSE, NOT TRUE OR TRUE, NOT 1 = 2 AND TRUE, NOT 1 > 2 = TRUE, FALSE AND FALSE OR TRUE;

# name: null_operators
SELECT id, v_int4 IS NULL, v_int4 IS NOT NULL, v_text ISNULL, v_text NOTNULL, v_int4 + 1 ISNULL FROM scalars ORDER BY id;

# name: string_concatenation
SELECT id, v_text || '!', v_varchar || v_char, v_int4 || v_text, 'n=' || v_int4 || ';' FROM scalars ORDER BY id;

# name: string_concatenation_literals
SELECT 'auto' || 'mobile', 1 || 2, '1' || '2', E'xx' || '\\', 'a' || NULL, 'ab'::VARBINARY || 'c'::VARBINARY;

# name: adjacent_string_literals
SELECT 'auto'
'mobile', '1'
'2', 'a' -- comment between the parts
'b';

# name: precedence
SELECT -2 ^ 2 * 3, 1 + 2 * 3 % 4, 2 + 3 IN (5), 1 + 1 BETWEEN 1 AND 3, 'a' || 'b' LIKE 'ab', 1 < 2 = TRUE, NOT 1 = 2, NOT TRUE AND FALSE, TRUE OR FALSE AND FALSE, (ARRAY[1, 2])[0] + 1, '5'::INT * 2;

# name: precedence_columns
SELECT id, -v_int4 ^ 2, v_int4 + v_int8 * 2 % 7, v_int4 + 1 IN (1, 43), v_int4 * 2 BETWEEN 0 AND 100, NOT v_int4 = 42 OR v_bool AND v_int4 IS NULL, v_int_arr[0] * 10 FROM scalars ORDER BY id;

# name: evaluation_order
SELECT id FROM scalars WHERE CASE WHEN v_int4 <> 0 THEN v_int8 / v_int4 > 1.5 ELSE FALSE END AND v_int4 IS NOT NULL ORDER BY id;

# name: column_references
SELECT scalars.id, public.scalars.v_int4, conformance.public.scalars.v_text, s.id FROM scalars, public.scalars AS s WHERE scalars.id = s.id AND public.scalars.id <= 5 ORDER BY scalars.id;

# name: comments
SELECT id, -- a standard SQL comment
  v_int4 /* a block comment */ + 1, /* multiline comment
   * with nesting: /* nested block comment */
   */ v_text
FROM scalars -- trailing comment
WHERE id <= 5 ORDER BY id;
