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
