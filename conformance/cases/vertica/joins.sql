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
