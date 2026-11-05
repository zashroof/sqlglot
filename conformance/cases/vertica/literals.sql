-- Literals: numbers, strings and their prefixed forms.

# name: number_literals
SELECT 42, 3.5, 4., .001, 5e2, 1.925e-3, 9223372036854775807, 92233720368547758070, -7, +7, 40 / 25, 40 // 25;

# name: numeric_string_literals
SELECT NUMERIC '1e10', NUMERIC '1p10', NUMERIC '0x0abc', FLOAT '1e10', FLOAT 'Infinity', FLOAT '-Infinity';

# name: character_strings
SELECT 'This is a string', 'Chester''s gorilla', 'This \is a string', '', 'a'
    'b';

# name: character_strings_in_columns
SELECT id, v_text = 'it''s a "quote" and a \ backslash', v_text || '!' FROM scalars ORDER BY id;

# name: dollar_quoted
SELECT $$Fred's\n car$$, $$SELECT 'fact';$$, $$$$, LENGTH($$a'b\c$$);

# name: extended_strings
SELECT E'This is a \n new line', E'This \is a string', E'You\'re here!', E'a\\b', E'tab\there', e'lower';

# name: extended_string_escapes
SELECT E'\x41\x7e', E'\101\176', E'\b\f\r' = CHR(8) || CHR(12) || CHR(13), LENGTH(E'vert\0ica'), LENGTH(E'\xF0\x90\x83\x8C');

# name: extended_string_continuation
SELECT E'first part o'
    'f a long line';

# name: unicode_strings
SELECT U&'m\00fcde', U&'\0441\043F\0430\0441\0438\0431\043E', U&'d!0061t!+000061' UESCAPE '!', u&'plain';

# name: varbinary_strings
SELECT TO_HEX(X'abcd'), TO_HEX(x'0A'), TO_HEX(B'101100'), TO_HEX(b'11111111'), X'abcd' = HEX_TO_BINARY('abcd');

# name: varbinary_strings_compared
SELECT id, v_bytes = X'010203', v_bytes > B'00000001' FROM scalars ORDER BY id;
