# name: distinct
SELECT DISTINCT cat FROM facts ORDER BY cat;

# name: union
SELECT grp FROM facts WHERE id <= 50 UNION SELECT grp FROM facts WHERE id > 9990 ORDER BY 1;

# name: intersect
SELECT k FROM join_left INTERSECT SELECT k FROM join_right ORDER BY 1;

# name: except
SELECT k FROM join_left EXCEPT SELECT k FROM join_right ORDER BY 1;

# name: cte
WITH t AS (SELECT grp, COUNT(*) AS c FROM facts GROUP BY grp) SELECT MAX(c), MIN(c), COUNT(*) FROM t;

# name: recursive_cte
WITH RECURSIVE r(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM r WHERE n < 5) SELECT SUM(n), MAX(n) FROM r;

# name: limit_offset
SELECT id FROM facts ORDER BY id LIMIT 5 OFFSET 10;

# name: derived_column_aliases
SELECT a, b FROM (SELECT id, grp FROM facts WHERE id <= 5) AS t(a, b) ORDER BY a;

# name: in_list_and_between
SELECT COUNT(*) FROM facts WHERE grp IN (1, 2, 3) AND qty BETWEEN 10 AND 20;

# name: select_without_from
SELECT 1 + 2 AS three, 'a' AS letter;

# name: case_insensitive_identifiers
SELECT "ID", Grp FROM FACTS WHERE id <= 3 ORDER BY Id;

# name: select_all
SELECT ALL cat FROM facts WHERE id <= 20 ORDER BY id;

# name: at_epoch_latest
AT EPOCH LATEST SELECT id, k, val FROM join_left ORDER BY id;

# name: at_epoch_latest_with
AT EPOCH LATEST WITH t AS (SELECT k FROM join_right) SELECT COUNT(*), COUNT(k) FROM t;

# name: at_epoch_latest_set_operation
AT EPOCH LATEST SELECT k FROM join_left UNION SELECT k FROM join_right ORDER BY 1;

# name: limit_over_partition
SELECT grp, id, qty FROM facts WHERE id <= 200 LIMIT 2 OVER (PARTITION BY grp ORDER BY qty DESC, id);

# name: limit_over_nulls_placement
SELECT k, id FROM join_left LIMIT 1 OVER (PARTITION BY k ORDER BY id DESC NULLS LAST);

# name: limit_over_nulls_first
SELECT cat, qty, id FROM facts WHERE id <= 300 LIMIT 1 OVER (PARTITION BY cat ORDER BY qty NULLS FIRST, id);

# name: limit_over_in_subquery
SELECT t.k, t.id FROM (SELECT k, id FROM join_left LIMIT 1 OVER (PARTITION BY k ORDER BY id)) AS t ORDER BY t.k, t.id;

# name: limit_all
SELECT id FROM join_left ORDER BY id LIMIT ALL;

# name: offset_only
SELECT id FROM facts WHERE id <= 30 ORDER BY id OFFSET 25;

# name: order_by_ordinal_and_desc
SELECT grp, COUNT(*) AS c FROM facts WHERE grp IS NOT NULL GROUP BY grp ORDER BY 2 DESC, 1 ASC;

# name: order_by_unselected_expression
SELECT id FROM facts WHERE id <= 20 ORDER BY qty * -1, id;

# name: order_by_case
SELECT id, val FROM join_left ORDER BY CASE WHEN k IS NULL THEN 0 ELSE k END DESC, id;

# name: order_by_alias
SELECT id, qty + 1 AS q FROM facts WHERE id <= 20 ORDER BY q, id;

# name: where_predicates
SELECT id FROM facts WHERE NOT (grp = 1 AND qty > 10) AND (cat ILIKE 'a%' OR cat IS NULL) AND qty BETWEEN 0 AND 500 AND grp IN (0, 1, 2) ORDER BY id LIMIT 50;

# name: where_subquery
SELECT id FROM join_left WHERE k = (SELECT MIN(k) FROM join_right) ORDER BY id;

# name: tablesample
SELECT COUNT(*) BETWEEN 1 AND 10000, COUNT(*) <= 10000 FROM facts TABLESAMPLE(50);

# name: tablesample_alias
SELECT COUNT(*) <= 6 FROM join_left TABLESAMPLE(99.9) AS l WHERE l.id > 0;

# name: with_column_aliases
WITH revenue (g, total) AS (SELECT grp, SUM(qty) FROM facts GROUP BY grp ORDER BY 1) SELECT r.g, r.total FROM revenue AS r WHERE r.total = (SELECT MAX(total) FROM revenue) ORDER BY 1;

# name: with_multiple_ctes
WITH sales (g, total) AS (SELECT grp, SUM(price) FROM facts GROUP BY grp), top_groups AS (SELECT g, total FROM sales ORDER BY total DESC LIMIT 3) SELECT f.grp, f.cat, COUNT(*) FROM facts AS f WHERE f.grp IN (SELECT g FROM top_groups) GROUP BY f.grp, f.cat ORDER BY 1, 2;

# name: with_nested
WITH t (a, b) AS (WITH u AS (SELECT id, k FROM join_left) SELECT id, k FROM u WHERE k IS NOT NULL) SELECT a, b FROM t ORDER BY a;

# name: with_materialization_hint
WITH /*+ENABLE_WITH_CLAUSE_MATERIALIZATION*/ g AS (SELECT grp, COUNT(*) AS c FROM facts GROUP BY grp) SELECT a.grp, a.c FROM g AS a JOIN g AS b ON a.grp = b.grp ORDER BY 1;

# name: with_inline_expansion
WITH recent AS (SELECT * FROM facts WHERE d BETWEEN '2020-12-01' AND '2020-12-07') SELECT grp, SUM(qty * price) AS total FROM recent GROUP BY grp ORDER BY total DESC, grp;

# name: recursive_cte_union_distinct
WITH RECURSIVE nums (n) AS (SELECT 1 UNION SELECT n + 1 FROM nums WHERE n < 4) SELECT n FROM nums ORDER BY n;

# name: recursive_cte_hierarchy
WITH RECURSIVE chain (id, k, depth) AS (SELECT id, k, 0 FROM join_left WHERE id = 1 UNION ALL SELECT l.id, l.k, c.depth + 1 FROM join_left AS l JOIN chain AS c ON l.k = c.id + 1) SELECT id, k, depth AS 'Reports to' FROM chain ORDER BY depth, id;

# name: match_columns
SELECT id, MATCH_COLUMNS('v_int%') FROM scalars ORDER BY id;

# name: label_hint
SELECT /*+LABEL(select_label)*/ id, val FROM join_left ORDER BY id;

# name: qualified_table_reference
SELECT l.id, j.k FROM conformance.public.join_left AS l JOIN public.join_right j ON l.id = j.id ORDER BY l.id;
