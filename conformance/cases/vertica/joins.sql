# name: inner
SELECT l.id, r.id FROM join_left AS l JOIN join_right AS r ON l.k = r.k ORDER BY 1, 2;

# name: left
SELECT l.id, r.id FROM join_left AS l LEFT JOIN join_right AS r ON l.k = r.k ORDER BY 1, 2;

# name: full
SELECT l.id, r.id FROM join_left AS l FULL OUTER JOIN join_right AS r ON l.k = r.k ORDER BY 1, 2;

# name: null_safe
SELECT l.id, r.id FROM join_left AS l JOIN join_right AS r ON l.k <=> r.k ORDER BY 1, 2;

# name: comma_join
SELECT COUNT(*) FROM join_left AS l, join_right AS r WHERE l.k = r.k;

# name: exists
SELECT id FROM join_left AS l WHERE EXISTS (SELECT 1 FROM join_right AS r WHERE r.k = l.k) ORDER BY id;

# name: in_subquery
SELECT id FROM join_left WHERE k IN (SELECT k FROM join_right) ORDER BY id;

# name: right_outer
SELECT l.id, r.id FROM join_left AS l RIGHT OUTER JOIN join_right AS r ON l.k = r.k ORDER BY 2, 1;

# name: left_outer_keyword
SELECT l.id, r.id FROM join_left AS l LEFT OUTER JOIN join_right AS r ON l.k = r.k ORDER BY 1, 2;

# name: inner_keyword
SELECT l.id, r.val FROM join_left AS l INNER JOIN join_right AS r ON l.k = r.k AND l.id < r.id ORDER BY 1, 2;

# name: cross
SELECT l.id, r.id FROM join_left AS l CROSS JOIN join_right AS r ORDER BY 1, 2;

# name: natural
SELECT l.k, l.lid, r.id FROM (SELECT id AS lid, k FROM join_left) AS l NATURAL JOIN (SELECT id, k FROM join_right) AS r ORDER BY 2, 3;

# name: using
SELECT l.id, r.id FROM join_left AS l JOIN join_right AS r USING (k) ORDER BY 1, 2;

# name: using_full_outer
SELECT l.id, r.id FROM join_left AS l FULL OUTER JOIN join_right AS r USING (k) ORDER BY 1, 2;

# name: where_join
SELECT l.id, r.id FROM join_left AS l, join_right AS r WHERE l.k = r.k AND r.val <> 'r5' ORDER BY 1, 2;

# name: semi
SELECT l.id FROM join_left AS l SEMI JOIN join_right AS r ON l.k = r.k ORDER BY 1;

# name: anti
SELECT l.id FROM join_left AS l ANTI JOIN join_right AS r ON l.k = r.k ORDER BY 1;

# name: tablesample_join
SELECT COUNT(*) <= 4 FROM join_left TABLESAMPLE(99.9) JOIN join_right TABLESAMPLE(99.9) ON join_left.k = join_right.k;

# name: interpolate_previous_full
SELECT l.id, r.id FROM join_left AS l FULL OUTER JOIN join_right AS r ON l.id INTERPOLATE PREVIOUS VALUE r.id ORDER BY 1, 2;

# name: interpolate_next_left
SELECT l.id, l.k, r.id FROM join_left AS l LEFT OUTER JOIN join_right AS r ON l.k = r.k AND l.id INTERPOLATE NEXT VALUE r.id ORDER BY 1, 3;

# name: interpolate_previous_left_timestamps
SELECT a.id, a.ts, b.id, b.ts FROM (SELECT id, ts FROM facts WHERE id <= 20) AS a LEFT OUTER JOIN (SELECT id, ts FROM facts WHERE id BETWEEN 21 AND 40) AS b ON a.ts INTERPOLATE PREVIOUS VALUE b.ts ORDER BY 1, 3;

# name: interpolate_next_right
SELECT l.id, r.id FROM join_left AS l RIGHT OUTER JOIN join_right AS r ON l.id INTERPOLATE NEXT VALUE r.id ORDER BY 2, 1;

# name: interpolate_inner
SELECT l.id, r.id FROM join_left AS l INNER JOIN join_right AS r ON l.id INTERPOLATE PREVIOUS VALUE r.id ORDER BY 1, 2;

# name: join_predicate_or_not
SELECT l.id, r.id FROM join_left AS l JOIN join_right AS r ON l.k = r.k OR NOT l.id <> r.id ORDER BY 1, 2;
