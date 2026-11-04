# name: length_and_case
SELECT id, LENGTH(v_text), CHARACTER_LENGTH(v_text), OCTET_LENGTH(v_text), UPPER(v_text), LOWER(v_varchar) FROM scalars ORDER BY id;

# name: substring
SELECT id, SUBSTR(v_text, 2, 3), SUBSTRING(v_text, 2), LEFT(v_text, 2), RIGHT(v_text, 2) FROM scalars ORDER BY id;

# name: position
SELECT id, POSITION('l' IN v_text), STRPOS(v_text, 'o'), INSTR(v_text, 'l', 1, 2) FROM scalars ORDER BY id;

# name: trim
SELECT id, TRIM(v_text), LTRIM(v_text), RTRIM(v_text), BTRIM(v_text, 'a') FROM scalars ORDER BY id;

# name: concatenation
SELECT id, v_text || '-' || v_varchar, CONCAT(v_text, v_varchar) FROM scalars ORDER BY id;

# name: padding
SELECT id, LPAD(v_varchar, 8, '*'), RPAD(v_varchar, 8, '*') FROM scalars ORDER BY id;

# name: like
SELECT id, v_text LIKE '%o%', v_text ILIKE 'H%', v_text NOT LIKE '_e%' FROM scalars ORDER BY id;

# name: regex
SELECT id, REGEXP_LIKE(v_text, '^[a-z]+'), REGEXP_REPLACE(v_text, '[aeiou]', '#'), REGEXP_SUBSTR(v_text, '[a-z]+', 1, 2), REGEXP_COUNT(v_text, 'l') FROM scalars ORDER BY id;

# name: regex_operators
SELECT id, v_text ~ '^h', v_text ~* '^H', v_text !~ 'o' FROM scalars ORDER BY id;

# name: split_part
SELECT id, SPLIT_PART(v_text, ' ', 2), SPLIT_PART(v_text, ' ', 1) FROM scalars ORDER BY id;

# name: hashes
SELECT id, MD5(v_text), SHA256(v_text) FROM scalars ORDER BY id;

# name: edit_distance
SELECT id, EDIT_DISTANCE(v_text, 'hello') FROM scalars ORDER BY id;

# name: translate_repeat
SELECT id, TRANSLATE(v_text, 'lo', '01'), REPEAT(v_varchar, 2), REPLACE(v_text, 'l', 'L') FROM scalars ORDER BY id;

# name: char_semantics
SELECT id, LENGTH(v_char), v_char = 'ab', v_char || '|' FROM scalars ORDER BY id;

# name: collation_order
SELECT id, v_varchar FROM scalars WHERE id BETWEEN 21 AND 26 ORDER BY v_varchar;

# name: initcap
SELECT id, INITCAP(v_text) FROM scalars ORDER BY id;
