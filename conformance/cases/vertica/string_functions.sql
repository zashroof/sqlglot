# name: ascii_chr
SELECT id, ASCII(v_text), ASCII(SUBSTR(v_varchar, 1, 1)), CHR(id + 64), CHR(233), ASCII(CHR(id + 64)) FROM scalars ORDER BY id;

# name: bit_functions
SELECT id, BITCOUNT(v_bytes), BIT_LENGTH(v_bytes), BIT_LENGTH(v_text), BIT_LENGTH(v_char), BIT_LENGTH(CAST(v_text AS VARBINARY(1000))) FROM scalars ORDER BY id;

# name: bitstring_to_binary
SELECT id, TO_HEX(BITSTRING_TO_BINARY('0110000101100010')), TO_BITSTRING(v_bytes), BITSTRING_TO_BINARY(TO_BITSTRING(v_bytes)) = v_bytes FROM scalars ORDER BY id;

# name: btrim_ltrim_rtrim
SELECT id, BTRIM(v_text), BTRIM(v_text, 'hd'), LTRIM(v_text, 'h '), RTRIM(v_text, 'd '), LTRIM('zzzyyyyyyxxxxxxxxtrim', 'xyz'), RTRIM('trimzzzyyyyyyxxxxxxxx', 'xyz') FROM scalars ORDER BY id;

# name: character_length
SELECT id, CHAR_LENGTH(v_text), CHARACTER_LENGTH(v_text USING OCTETS), CHAR_LENGTH(v_char USING CHARACTERS), CHARACTER_LENGTH(v_char USING OCTETS), CHAR_LENGTH(CAST('1234  ' AS CHAR(10)) USING OCTETS) FROM scalars ORDER BY id;

# name: lengths_in_bytes
SELECT id, LENGTH(v_char), LENGTH(v_bytes), OCTET_LENGTH(v_text), OCTET_LENGTH(v_char), OCTET_LENGTH(v_bytes), LENGTH(CAST('1234 ' AS CHAR(10))), OCTET_LENGTH(CAST('abc' AS BINARY(6))) FROM scalars ORDER BY id;

# name: collation_order
SELECT id, v_varchar FROM scalars WHERE id BETWEEN 21 AND 26 ORDER BY COLLATION(v_varchar, 'LEN_AS'), id;

# name: collation_default_locale
SELECT id, v_text FROM scalars WHERE id BETWEEN 21 AND 26 ORDER BY COLLATION(v_text), id;

# name: collation_equality
SELECT COLLATION('U.S.A', 'LEN_AS') = COLLATION('USA', 'LEN_AS'), COLLATION('a', 'LEN_S1') = COLLATION('A', 'LEN_S1');

# name: concat_any_type
SELECT id, CONCAT(v_text, ' is text'), CONCAT(CONCAT(v_varchar, ' and '), CONCAT(v_char, '!')), CONCAT(v_int4, v_date) FROM scalars ORDER BY id;

# name: greatestb_leastb
SELECT id, GREATESTB(v_text, v_varchar), LEASTB(v_text, v_varchar), GREATESTB(v_int4, v_int2, 0), LEASTB(v_int4, v_int2, 0), GREATESTB('straße', 'strasse'), LEASTB('7', '5', '10'), GREATESTB(1, 1.5) FROM scalars ORDER BY id;

# name: greatest_least_star
SELECT id, GREATEST(*), LEAST(*), GREATESTB(*), LEASTB(*) FROM (SELECT id, v_int2, v_int4, v_int8 FROM scalars) AS t ORDER BY id;

# name: hex_to_binary
SELECT id, HEX_TO_BINARY('0x6162'), HEX_TO_BINARY('6162'), HEX_TO_BINARY(TO_HEX(v_bytes)) = v_bytes, TO_HEX(HEX_TO_BINARY('abc')) FROM scalars ORDER BY id;

# name: hex_to_integer
SELECT id, HEX_TO_INTEGER('0aedc'), HEX_TO_INTEGER('0xaedc'), HEX_TO_INTEGER(TO_HEX(v_int4)) FROM scalars WHERE v_int4 >= 0 ORDER BY id;

# name: initcapb
SELECT id, INITCAPB(v_text), INITCAPB(v_varchar), INITCAPB('étudiant') FROM scalars ORDER BY id;

# name: insert
SELECT id, INSERT(v_text, 1, 3, 'Stor'), INSERT(v_varchar, 2, 0, '*') FROM scalars ORDER BY id;

# name: instr_variants
SELECT id, INSTR(v_text, 'o'), INSTR(v_text, 'l', 3), INSTR(v_text, 'l', -1), INSTR(v_text, 'l', -1, 2), INSTR(v_bytes, HEX_TO_BINARY('02')), INSTR(v_bytes, HEX_TO_BINARY('ff'), -1) FROM scalars ORDER BY id;

# name: instrb
SELECT id, INSTRB(v_text, 'l'), INSTRB(v_text, 'o', 1, 2), INSTRB(v_text, 'w', 3), INSTRB(v_text, 'l', -1), INSTRB('straße', 'ß') FROM scalars ORDER BY id;

# name: isutf8_makeutf8
SELECT id, ISUTF8(v_text), ISUTF8(SUBSTRB(v_text, 1, 2)), MAKEUTF8(v_text), MAKEUTF8(SUBSTRB(v_text, 1, 2)), MAKEUTF8(SUBSTRB(v_text, 1, 2) USING PARAMETERS replacement_string='^'), ISUTF8(E'\xC2\xBF') FROM scalars ORDER BY id;

# name: invalid_utf8_escape_literals
SELECT ISUTF8(E'\xC2\xC0'), MAKEUTF8(E'a\xC2\xC0b'), MAKEUTF8(E'a\xC2\xC0b' USING PARAMETERS replacement_string='^');

# name: jaro_distances
SELECT id, JARO_DISTANCE(v_text, 'hello'), JARO_WINKLER_DISTANCE(v_text, 'hello'), JARO_WINKLER_DISTANCE(v_text, 'help' USING PARAMETERS prefix_scale=0.1, prefix_length=0), JARO_WINKLER_DISTANCE(v_text, 'hell' USING PARAMETERS prefix_scale=0.2) FROM scalars WHERE v_text IS NOT NULL ORDER BY id;

# name: left_right
SELECT id, LEFT(v_varchar, 3), RIGHT(v_varchar, 3), LEFT(v_text, 0), RIGHT(CAST(v_date AS VARCHAR), 5) FROM scalars ORDER BY id;

# name: case_conversion_bytes
SELECT id, UPPER(v_text), LOWER(v_varchar), UPPERB(v_text), LOWERB(v_varchar), UPPERB('étudiant'), LOWERB('ÉTUDIANT') FROM scalars ORDER BY id;

# name: padding_defaults
SELECT id, LPAD(v_varchar, 8), RPAD(v_varchar, 8), LPAD(v_text, 15, 'xzy'), RPAD(v_text, 6, 'xzy') FROM scalars ORDER BY id;

# name: hashes
SELECT id, MD5(v_bytes), SHA1(v_text), SHA1(v_bytes), SHA224(v_text), SHA224(v_bytes), SHA256(v_bytes), SHA384(v_text), SHA512(v_text), SHA512(v_bytes) FROM scalars ORDER BY id;

# name: overlay
SELECT id, OVERLAY(v_text PLACING 'xxx' FROM 2), OVERLAY(v_text PLACING 'ABC' FROM 5 FOR 4), OVERLAY(v_text PLACING 'ABC' FROM 5 FOR -2), OVERLAY(v_text PLACING 'é' FROM 2 USING CHARACTERS), OVERLAY(v_text PLACING 'XXX' FROM 2 FOR 1 USING OCTETS) FROM scalars WHERE id NOT IN (16, 17, 25) ORDER BY id;

# name: overlay_multibyte
SELECT id, OVERLAY(v_text PLACING 'xé' FROM 2 FOR 3), OVERLAY(v_text PLACING 'ab' FROM 3 USING CHARACTERS) FROM scalars ORDER BY id;

# name: overlayb
SELECT id, OVERLAYB(v_text, 'ééé', 2), OVERLAYB(v_text, 'xxx', 2, 4), OVERLAYB('123456789', 'ßßß', 2), OVERLAYB('123456789', 'xxx', 2, 6) FROM scalars WHERE id NOT IN (16, 17, 25) ORDER BY id;

# name: position_using
SELECT id, POSITION('l' IN v_text USING CHARACTERS), POSITION('w' IN v_text USING OCTETS), POSITION(HEX_TO_BINARY('02') IN v_bytes), POSITIONB(v_text, 'w'), POSITIONB('straße', 'ße') FROM scalars ORDER BY id;

# name: quote_functions
SELECT id, QUOTE_IDENT(v_text), QUOTE_IDENT(v_varchar), QUOTE_IDENT('select'), QUOTE_LITERAL(v_text), QUOTE_NULLABLE(v_text), QUOTE_NULLABLE(v_varchar) FROM scalars ORDER BY id;

# name: repeat_types
SELECT id, REPEAT(v_text, 2), REPEAT(v_bytes, 3), REPEAT(v_char, 2), REPLACE(v_text, 'ß', 'ss') FROM scalars ORDER BY id;

# name: soundex
SELECT id, SOUNDEX(v_text), SOUNDEX(v_varchar), SOUNDEX_MATCHES(v_text, 'hello'), SOUNDEX_MATCHES('Lewis', 'Li'), SOUNDEX_MATCHES('Lee', 'Li') FROM scalars ORDER BY id;

# name: space
SELECT id, 'x' || SPACE(10) || 'y', LENGTH(SPACE(id)), SPACE(0) = '' FROM scalars ORDER BY id;

# name: split_partb
SELECT id, SPLIT_PARTB(v_text, ' ', 2), SPLIT_PARTB(v_text, 'l', 1), SPLIT_PARTB(v_text, ' ', 10), SPLIT_PARTB('straße~@~café~@~soupçon', '~@~', 3) FROM scalars ORDER BY id;

# name: strposb
SELECT id, STRPOS(v_text, 'w'), STRPOSB(v_text, 'w'), STRPOSB('étudiant', 'tud'), STRPOS('étudiant', 'tud') FROM scalars ORDER BY id;

# name: substrb
SELECT id, SUBSTRB(v_text, 5), SUBSTRB(v_text, 2, 3), SUBSTRB('soupçon', 5, 2), SUBSTRB(v_text, 2.7, 2.2) FROM scalars WHERE id NOT IN (16, 17, 25) ORDER BY id;

# name: substring_using
SELECT id, SUBSTRING(v_text, 5, 2 USING CHARACTERS), SUBSTRING(v_text, 5, 2 USING OCTETS), SUBSTRING(v_text, 3 USING OCTETS), SUBSTRING(v_text FROM 2 FOR 3), SUBSTRING(v_text FROM 2 FOR 3 USING OCTETS), SUBSTRING(v_text FROM 4) FROM scalars WHERE id NOT IN (16, 17, 25) ORDER BY id;

# name: byte_slices_of_multibyte
SELECT id, TO_HEX(CAST(SUBSTRB(v_text, 2, 3) AS VARBINARY(1000))), TO_HEX(CAST(SUBSTRING(v_text, 2, 3 USING OCTETS) AS VARBINARY(1000))), TO_HEX(CAST(OVERLAYB(v_text, 'x', 2) AS VARBINARY(1000))), TO_HEX(CAST(OVERLAY(v_text PLACING 'x' FROM 2 USING OCTETS) AS VARBINARY(1000))) FROM scalars WHERE id IN (16, 17, 25) ORDER BY id;

# name: substring_edge_positions
SELECT id, SUBSTRING(v_text, -4, 8), SUBSTRING(v_text, 2.6, 3.9), SUBSTR(v_bytes, 2), SUBSTR(v_bytes, 1, 2), SUBSTRING(v_bytes, 2, 1) FROM scalars ORDER BY id;

# name: translate_multibyte
SELECT id, TRANSLATE(v_text, 'ß', 'ss'), TRANSLATE(v_text, 'éö', 'eo'), TRANSLATE(v_text, 'lo', '') FROM scalars ORDER BY id;

# name: trim_forms
SELECT id, '-' || TRIM(LEADING 'h' FROM v_text) || '-', '-' || TRIM(TRAILING 'd' FROM v_text) || '-', '-' || TRIM(BOTH 'hd' FROM v_text) || '-', '-' || TRIM('h' FROM v_text) || '-', '-' || TRIM(LEADING FROM v_text) || '-', '-' || TRIM(TRAILING FROM v_text) || '-', '-' || TRIM(v_text) || '-' FROM scalars ORDER BY id;
