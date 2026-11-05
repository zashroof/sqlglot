# name: union_distinct
SELECT k FROM join_left UNION DISTINCT SELECT k FROM join_right ORDER BY 1;

# name: union_all_order_by_name_limit
SELECT id, val FROM join_left UNION ALL SELECT id, val FROM join_right ORDER BY val LIMIT 4;

# name: union_all_order_offset_limit
SELECT id FROM join_left UNION ALL SELECT id FROM join_right ORDER BY id DESC OFFSET 2 LIMIT 5;

# name: union_parenthesized_branches
(SELECT id, val FROM join_left ORDER BY val DESC LIMIT 2) UNION ALL (SELECT id, val FROM join_right ORDER BY val LIMIT 2) ORDER BY 2;

# name: union_grouped_branches
(SELECT 'left' AS side, k, COUNT(*) FROM join_left GROUP BY k) UNION (SELECT 'right' AS side, k, COUNT(*) FROM join_right GROUP BY k) ORDER BY 1, 2;

# name: union_in_subquery
SELECT id FROM join_left WHERE k IN (SELECT k FROM join_right WHERE id < 3 UNION ALL SELECT k FROM join_right WHERE val = 'r5') ORDER BY id;

# name: union_in_from
SELECT t.k, COUNT(*) FROM (SELECT k FROM join_left UNION ALL SELECT k FROM join_right) AS t GROUP BY t.k ORDER BY 1;

# name: intersect_multiple
SELECT k FROM join_left INTERSECT SELECT k FROM join_right INTERSECT SELECT grp FROM facts WHERE id <= 100 ORDER BY 1;

# name: intersect_order_by_name_desc
SELECT k, val FROM (SELECT k, 'x' AS val FROM join_left) AS a INTERSECT SELECT k, 'x' FROM join_right ORDER BY k DESC;

# name: intersect_parenthesized_where
SELECT k FROM join_left INTERSECT (SELECT k FROM join_right WHERE id > 1) ORDER BY k;

# name: intersect_in_subquery
SELECT id FROM join_left WHERE k IN (SELECT k FROM join_right INTERSECT SELECT k FROM join_left WHERE id > 2) ORDER BY id;

# name: except_multiple
SELECT grp FROM facts WHERE id <= 300 EXCEPT SELECT k FROM join_left EXCEPT SELECT k FROM join_right ORDER BY 1;

# name: except_order_limit
SELECT grp FROM facts EXCEPT SELECT k FROM join_left ORDER BY grp DESC LIMIT 5;

# name: except_in_subquery
SELECT id FROM join_left WHERE k IN (SELECT k FROM join_left EXCEPT SELECT k FROM join_right WHERE id > 2) ORDER BY id;

# name: minus
SELECT k FROM join_left MINUS SELECT k FROM join_right ORDER BY 1;

# name: minus_multiple
SELECT grp FROM facts WHERE id <= 300 MINUS SELECT k FROM join_left MINUS SELECT k FROM join_right ORDER BY 1;
