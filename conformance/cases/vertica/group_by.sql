# name: group_by_expressions
SELECT grp % 3, qty // 100, COUNT(*) FROM facts GROUP BY grp % 3, qty // 100 ORDER BY 1, 2;

# name: group_by_parenthesized
SELECT (grp + 1), COUNT(*) FROM facts GROUP BY (grp + 1) ORDER BY 1;

# name: group_by_position
SELECT cat, flag, COUNT(*) FROM facts GROUP BY 1, 2 ORDER BY 1, 2;

# name: group_by_hint_hash
SELECT grp, COUNT(*) FROM facts GROUP BY /*+GBYTYPE(HASH)*/ grp ORDER BY grp;

# name: group_by_hint_pipe
SELECT grp, cat, SUM(qty) FROM facts GROUP BY /*+GBYTYPE(PIPE)*/ grp, cat ORDER BY grp, cat;

# name: group_by_without_aggregates
SELECT cat FROM facts GROUP BY cat ORDER BY cat;

# name: group_by_with_where
SELECT cat, SUM(qty) FROM facts WHERE cat ILIKE 'a%' GROUP BY cat ORDER BY cat;

# name: group_by_array
SELECT v_int_arr, COUNT(*) FROM scalars GROUP BY v_int_arr ORDER BY COUNT(*), ARRAY_LENGTH(v_int_arr);

# name: group_by_quoted_alias
SELECT grp, MAX(qty) AS "Biggest Qty" FROM facts GROUP BY grp ORDER BY grp;

# name: having_aggregate
SELECT grp, MAX(price) AS highest FROM facts GROUP BY grp HAVING MAX(price) > 99000 ORDER BY highest DESC, grp;

# name: having_compound
SELECT grp, COUNT(*), AVG(qty) FROM facts GROUP BY grp HAVING COUNT(*) > 50 AND AVG(qty) > 400 OR grp IS NULL ORDER BY grp;

# name: having_grouping_column
SELECT grp, COUNT(*) FROM facts GROUP BY grp HAVING grp < 5 ORDER BY grp;

# name: having_without_group_by
SELECT COUNT(*), SUM(qty) FROM facts HAVING COUNT(*) > 0;

# name: cube
SELECT grp, flag, COUNT(*), SUM(qty) FROM facts WHERE grp < 3 GROUP BY CUBE (grp, flag) ORDER BY 1, 2, GROUPING_ID();

# name: cube_having_grouping
SELECT grp, flag, SUM(qty) FROM facts WHERE grp < 3 GROUP BY CUBE (grp, flag) HAVING GROUPING(flag) = 1 ORDER BY grp;

# name: cube_having_grouping_id
SELECT grp, flag, SUM(qty) FROM facts WHERE grp < 3 GROUP BY CUBE (grp, flag) HAVING GROUPING_ID(grp, flag) < 2 ORDER BY 1, 2, GROUPING_ID();

# name: cube_composite
SELECT grp, cat, flag, COUNT(*) FROM facts WHERE grp < 2 AND cat IN ('alpha', 'beta') GROUP BY CUBE ((grp, cat), flag) ORDER BY 1, 2, 3, GROUPING_ID();

# name: cube_three_columns
SELECT grp, cat, flag, COUNT(*), GROUPING_ID(grp, cat, flag) FROM facts WHERE grp < 2 AND cat IN ('alpha', 'beta') GROUP BY CUBE (grp, cat, flag) ORDER BY 1, 2, 3, GROUPING_ID();

# name: rollup_expenses_style
SELECT cat, grp, SUM(price), GROUPING(cat), GROUPING(grp) FROM facts WHERE grp < 3 AND cat IN ('alpha', 'beta') GROUP BY ROLLUP (cat, grp) ORDER BY 1, 2, GROUPING_ID();

# name: rollup_having_grouping
SELECT cat, grp, SUM(price) FROM facts WHERE grp < 3 GROUP BY ROLLUP (cat, grp) HAVING GROUPING(grp) = 1 ORDER BY 1, 2, GROUPING_ID();

# name: rollup_having_grouping_id
SELECT cat, grp, SUM(price) FROM facts WHERE grp < 3 GROUP BY ROLLUP (cat, grp) HAVING GROUPING_ID(cat, grp) < 3 ORDER BY 1, 2, GROUPING_ID();

# name: rollup_composite
SELECT grp, cat, flag, COUNT(*), GROUPING_ID(grp, cat, flag) FROM facts WHERE grp < 2 AND cat IN ('alpha', 'beta') GROUP BY ROLLUP ((grp, cat), flag) ORDER BY 1, 2, 3, GROUPING_ID();

# name: rollup_expression
SELECT grp % 2, flag, COUNT(*) FROM facts WHERE grp < 4 GROUP BY ROLLUP (grp % 2, flag) ORDER BY 1, 2, GROUPING_ID();

# name: rollup_decode_grouping_id
SELECT grp, flag, COUNT(*), DECODE(GROUPING_ID(grp, flag), 3, 'Total', 1, 'grp', 0, 'grp,flag') AS level FROM facts WHERE grp < 3 GROUP BY ROLLUP (grp, flag) ORDER BY 1, 2, GROUPING_ID();

# name: grouping_sets
SELECT grp, flag, COUNT(*) FROM facts WHERE grp < 3 GROUP BY GROUPING SETS ((grp, flag), (flag)) ORDER BY 1, 2, GROUPING_ID();

# name: grouping_sets_with_total
SELECT grp, flag, COUNT(*) FROM facts WHERE grp < 3 GROUP BY GROUPING SETS ((grp, flag), (flag), ()) ORDER BY 1, 2, GROUPING_ID();

# name: grouping_sets_nested
SELECT grp, cat, flag, COUNT(*), GROUPING_ID(grp, cat, flag) FROM facts WHERE grp < 2 AND cat IN ('alpha', 'beta') GROUP BY GROUPING SETS ((grp, flag), (cat), CUBE (grp, cat), ROLLUP (flag)) ORDER BY 1, 2, 3, GROUPING_ID(), GROUP_ID();

# name: grouping_sets_group_id_filter
SELECT grp, cat, COUNT(*) FROM facts WHERE grp < 3 AND cat IN ('alpha', 'beta') GROUP BY GROUPING SETS ((grp, cat), (grp, cat), (grp)) HAVING GROUP_ID() = 0 ORDER BY 1, 2, GROUPING_ID();

# name: concatenated_groupings
SELECT grp, cat, flag, COUNT(*) FROM facts WHERE grp < 2 AND cat IN ('alpha', 'beta') GROUP BY grp, cat, CUBE (grp, cat), ROLLUP (flag) ORDER BY 1, 2, 3, GROUPING_ID(), GROUP_ID();

# name: concatenated_multilevel
SELECT grp, cat, flag, COUNT(*) FROM facts WHERE grp < 2 AND cat IN ('alpha', 'beta') GROUP BY ROLLUP (grp), CUBE (cat), GROUPING SETS (flag) ORDER BY 1, 2, 3, GROUPING_ID();

# name: concatenated_grouping_sets
SELECT grp, cat, flag, COUNT(*) FROM facts WHERE grp < 2 AND cat IN ('alpha', 'beta') GROUP BY grp, cat, flag, GROUPING SETS ((grp, flag), (cat), (grp, cat), (grp), (cat), ()) ORDER BY 1, 2, 3, GROUPING_ID(), GROUP_ID();
