# name: regexp_count_args
SELECT id, REGEXP_COUNT(v_text, 'l'), REGEXP_COUNT(v_text, '[a-z]', 5), REGEXP_COUNT(v_text, '[a-z]l', 1, 'i'), REGEXP_COUNT(v_text, '^l', 1, 'm'), REGEXP_COUNT(v_text, 'L . N', 1, 'ix') FROM scalars ORDER BY id;

# name: regexp_count_bytes
SELECT id, REGEXP_COUNT(v_text, '.'), REGEXP_COUNT(v_text, '.', 1, 'b'), REGEXP_COUNT(v_text, '.', 3, 'nb') FROM scalars ORDER BY id;

# name: regexp_like_modifiers
SELECT id, REGEXP_LIKE(v_text, 'o'), REGEXP_LIKE(v_text, '^H', 'i'), REGEXP_LIKE(v_text, '^H', 'c'), REGEXP_LIKE(v_text, 'l l', 'x'), REGEXP_LIKE(v_text, '^line2$', 'm'), REGEXP_LIKE(v_text, 'line1.line2', 'n'), REGEXP_LIKE(v_text, '^LINE2$', 'mi') FROM scalars ORDER BY id;

# name: regexp_ilike_not_like
SELECT id, REGEXP_ILIKE(v_text, 'H'), REGEXP_ILIKE(v_text, 'Ö'), REGEXP_NOT_LIKE(v_text, 'o'), REGEXP_NOT_ILIKE(v_text, 'A'), REGEXP_NOT_LIKE(v_text, '.*ö.*ß') FROM scalars ORDER BY id;

# name: regexp_like_where
SELECT id FROM scalars WHERE REGEXP_LIKE(v_text, '\d') OR REGEXP_ILIKE(v_varchar, '^apple') OR REGEXP_NOT_ILIKE(v_text, '[a-z]') ORDER BY id;

# name: regexp_instr_args
SELECT id, REGEXP_INSTR(v_text, 'o'), REGEXP_INSTR(v_text, 'o', 6), REGEXP_INSTR(v_text, 'l', 1, 3), REGEXP_INSTR(v_text, '\s', 1, 1, 1), REGEXP_INSTR(v_text, 'L+', 1, 2, 1, 'i'), REGEXP_INSTR(v_text, '(\w+)\s+(\w+)', 1, 1, 0, '', 2), REGEXP_INSTR(v_text, '(\w)(\w)', 1, 2, 1, 'i', 1) FROM scalars ORDER BY id;

# name: regexp_instr_literals
SELECT REGEXP_INSTR('easy come, easy go', 'e\w*y'), REGEXP_INSTR('easy come, easy go', 'e\w*y', 2), REGEXP_INSTR('easy come, easy go', 'e\w*y', 1, 2), REGEXP_INSTR('easy come, easy go', '\s', 1, 1, 1), REGEXP_INSTR('one two three', '(\w+)\s+(\w+)\s+(\w+)', 1, 1, 0, '', 3);

# name: regexp_replace_args
SELECT id, REGEXP_REPLACE(v_text, 'l'), REGEXP_REPLACE(v_text, 'l', 'L'), REGEXP_REPLACE(v_text, 'l', 'L', 4), REGEXP_REPLACE(v_text, 'l', 'L', 1, 2), REGEXP_REPLACE(v_text, 'l', 'L', 1, 0), REGEXP_REPLACE(v_text, 'L', '_', 1, 0, 'i'), REGEXP_REPLACE(v_text, 'O', '0', 2, 1, 'i') FROM scalars ORDER BY id;

# name: regexp_replace_backrefs
SELECT id, REGEXP_REPLACE(v_text, '(\w+) (\w+)', '\2 \1'), REGEXP_REPLACE(v_text, '(\w)thy', '\1ish'), REGEXP_REPLACE(v_text, '^(.)', '[\1]', 1, 1, 'm') FROM scalars ORDER BY id;

# name: regexp_replace_literals
SELECT REGEXP_REPLACE('healthy, wealthy, and wise', '\w+thy'), REGEXP_REPLACE('healthy, wealthy, and wise', '\w+thy', 'something', 3), REGEXP_REPLACE('healthy, wealthy, and wise', '\w+thy', 'something', 1, 2), REGEXP_REPLACE('17815551234', '(\d)(\d{3})(\d{3})(\d{4})', '\1-(\2) \3-\4');

# name: regexp_substr_args
SELECT id, REGEXP_SUBSTR(v_text, '\w+'), REGEXP_SUBSTR(v_text, '\w+', 3), REGEXP_SUBSTR(v_text, '\w+', 1, 2), REGEXP_SUBSTR(v_text, 'W\w+', 1, 1, 'i'), REGEXP_SUBSTR(v_text, '(\w)(\w+)', 1, 1, '', 2), REGEXP_SUBSTR(v_text, '(\w)(\w+)', 2, 2, 'i', 1) FROM scalars ORDER BY id;

# name: regexp_substr_literals
SELECT REGEXP_SUBSTR('healthy, wealthy, and wise', '\w+thy'), REGEXP_SUBSTR('healthy, wealthy, and wise', '\w+thy', 2), REGEXP_SUBSTR('healthy, wealthy, and wise', '\w+thy', 1, 2), REGEXP_SUBSTR('one two three', '(\w+)\s+(\w+)\s+(\w+)', 1, 1, '', 3);

# name: match_columns
SELECT id, MATCH_COLUMNS('v_int%') FROM scalars ORDER BY id;

# name: match_columns_escape
SELECT MATCH_COLUMNS('v\_int_') FROM scalars ORDER BY id;
