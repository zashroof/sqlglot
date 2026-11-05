# name: any_some_all
SELECT id, k FROM join_left WHERE k > ANY (SELECT k FROM join_right WHERE k IS NOT NULL) ORDER BY id;

# name: any_some_all_operators
SELECT id, k = ANY (SELECT k FROM join_right WHERE k IS NOT NULL), k = SOME (SELECT k FROM join_right WHERE k IS NOT NULL), k >= ALL (SELECT k FROM join_right WHERE k IS NOT NULL), k <> ALL (SELECT k FROM join_right WHERE k IS NOT NULL) FROM join_left WHERE k IS NOT NULL ORDER BY id;

# name: any_all_aggregates
SELECT id, k FROM join_left WHERE k <> ANY (SELECT MAX(k) FROM join_right) AND id <> ALL (SELECT MAX(id) FROM join_right) ORDER BY id;

# name: any_all_group_by
SELECT k FROM join_left WHERE k IS NOT NULL GROUP BY k HAVING k <> ALL (SELECT MAX(k) FROM join_right GROUP BY val HAVING MAX(k) IS NOT NULL) ORDER BY k;

# name: any_null_safe
SELECT id, k FROM join_left WHERE k <=> ANY (SELECT k FROM join_right GROUP BY k) ORDER BY id;

# name: any_correlated
SELECT l.id, l.k FROM join_left AS l WHERE l.k >= ANY (SELECT r.k FROM join_right AS r WHERE r.id = l.id) ORDER BY l.id;

# name: between
SELECT id, v_int4 BETWEEN 0 AND 100, v_int4 NOT BETWEEN 0 AND 100, v_date BETWEEN '2024-01-01' AND '2024-12-31', v_text BETWEEN 'a' AND 'm', v_dec BETWEEN -1 AND 1 FROM scalars ORDER BY id;

# name: between_dates
SELECT id, d FROM facts WHERE d BETWEEN DATE '2023-01-01' AND DATE '2023-01-01' + INTERVAL '2' DAY ORDER BY id;

# name: between_where
SELECT id, qty FROM facts WHERE qty NOT BETWEEN 10 AND 990 AND id <= 500 ORDER BY id;

# name: boolean_predicate
SELECT id, v_bool IS TRUE, v_bool IS NOT TRUE, v_bool IS FALSE, v_bool IS NOT FALSE, v_bool IS UNKNOWN, v_bool IS NOT UNKNOWN FROM scalars ORDER BY id;

# name: boolean_predicate_expressions
SELECT id, (v_int4 > 0) IS TRUE, (v_int4 > 0) IS NOT FALSE, (v_int4 > 0) IS UNKNOWN, (v_int4 > 0) IS NOT UNKNOWN, v_int4 + 1 IS NULL FROM scalars ORDER BY id;

# name: is_precedence
SELECT id, v_bool = FALSE IS FALSE, v_bool = v_bool IS NULL, v_bool <> TRUE IS NOT NULL, v_bool IS NULL = FALSE, NOT v_bool IS NULL FROM scalars ORDER BY id;

# name: exists
SELECT l.id, EXISTS (SELECT 1 FROM join_right AS r WHERE r.k = l.k), NOT EXISTS (SELECT * FROM join_right AS r WHERE r.k = l.k) FROM join_left AS l ORDER BY l.id;

# name: exists_where
SELECT id FROM join_left AS l WHERE EXISTS (SELECT 1 FROM join_right AS r WHERE r.id = l.id AND r.k > 1) OR NOT EXISTS (SELECT 1 FROM join_right AS r WHERE r.id = l.id) ORDER BY id;

# name: in_list
SELECT id, v_int4 IN (0, 42), v_int4 NOT IN (0, 42), v_text IN ('a', 'b', 'hello world'), v_int4 IN (NULL, 1), v_int4 NOT IN (1, NULL) FROM scalars ORDER BY id;

# name: in_multicolumn
SELECT id FROM join_left WHERE (id, k) IN ((1, 1), (3, 2), (4, NULL)) ORDER BY id;

# name: not_in_multicolumn
SELECT id FROM join_left WHERE (id, k) NOT IN ((1, 1), (3, 2)) ORDER BY id;

# name: in_subquery
SELECT id, k FROM join_left WHERE k IN (SELECT k FROM join_right) AND id NOT IN (SELECT id FROM join_right WHERE id > 4) ORDER BY id;

# name: in_multicolumn_subquery
SELECT id FROM join_left WHERE (id, k) IN (SELECT id, k FROM join_right) ORDER BY id;

# name: like
SELECT id, v_text LIKE 'h%', v_text LIKE '%o_', v_text NOT LIKE '%a%', v_text ILIKE 'H%', v_text NOT ILIKE '%E%', v_text LIKE '' FROM scalars ORDER BY id;

# name: like_bytes
SELECT id, v_text LIKEB 'h%', v_text ILIKEB 'H%', v_text NOT LIKEB '%a%', v_text NOT ILIKEB '%E%', v_text LIKEB '_', v_text LIKE '_', v_text ILIKEB '_' FROM scalars ORDER BY id;

# name: like_any_all
SELECT id, v_text LIKE ANY ('h%', '%e'), v_text LIKE SOME ('%o%', 'A%'), v_text LIKE ALL ('h%', '%d'), v_text ILIKE ANY ('H%', 'N%'), v_text NOT LIKE ANY ('h%', '%d'), v_text NOT LIKE ALL ('h%', '%e'), v_text LIKEB ANY ('a', 'b') FROM scalars ORDER BY id;

# name: like_escape
SELECT id, v_text LIKE '50!% off!_sale' ESCAPE '!', v_text LIKE '%!_%' ESCAPE '!', v_text NOT LIKE '%#%%' ESCAPE '#', v_text ILIKE '50\% OFF%', v_text LIKEB '%$_s%' ESCAPE '$', v_text ILIKEB '%$_S%' ESCAPE '$' FROM scalars ORDER BY id;

# name: like_symbols
SELECT id, v_text ~~ 'h%', v_text !~~ 'h%', v_text ~~* 'H%', v_text !~~* 'H%', v_text ~# '_', v_text !~# '_', v_text ~#* 'H%', v_text !~#* 'H%' FROM scalars ORDER BY id;

# name: like_binary
SELECT id, v_bytes LIKE 'a%'::VARBINARY, v_bytes NOT LIKE '%c'::VARBINARY, v_bytes LIKE '%!%%'::VARBINARY ESCAPE '!'::VARBINARY FROM scalars WHERE v_bytes IS NOT NULL ORDER BY id;

# name: null_predicate
SELECT id, v_int4 IS NULL, v_text IS NOT NULL, v_int4 + v_int8 IS NULL, 'a' IS NOT NULL, NULL IS NULL FROM scalars ORDER BY id;

# name: null_predicate_function
SELECT MAX(k) IS NULL, MIN(k) IS NOT NULL, MAX(CASE WHEN k > 100 THEN k END) IS NULL FROM join_left;
