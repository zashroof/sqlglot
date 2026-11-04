# name: row_number
SELECT id, grp, ROW_NUMBER() OVER (PARTITION BY grp ORDER BY id) FROM facts WHERE id <= 200 ORDER BY id;

# name: rank_nulls
SELECT id, RANK() OVER (ORDER BY grp), DENSE_RANK() OVER (ORDER BY grp DESC) FROM facts WHERE id <= 200 ORDER BY id;

# name: rank_strings
SELECT id, RANK() OVER (ORDER BY cat) FROM facts WHERE id <= 200 ORDER BY id;

# name: running_sum
SELECT id, SUM(qty) OVER (PARTITION BY grp ORDER BY id ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) FROM facts WHERE id <= 200 ORDER BY id;

# name: lag_lead
SELECT id, LAG(qty) OVER (ORDER BY id), LEAD(qty, 2, 0) OVER (ORDER BY id) FROM facts WHERE id <= 200 ORDER BY id;

# name: first_last_value
SELECT id, FIRST_VALUE(qty) OVER (PARTITION BY grp ORDER BY id), LAST_VALUE(qty) OVER (PARTITION BY grp ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) FROM facts WHERE id <= 200 ORDER BY id;

# name: distribution
SELECT id, NTILE(4) OVER (ORDER BY id), PERCENT_RANK() OVER (ORDER BY qty, id), CUME_DIST() OVER (ORDER BY qty, id) FROM facts WHERE id <= 200 ORDER BY id;

# name: partition_aggregate
SELECT id, AVG(price) OVER (PARTITION BY cat), COUNT(*) OVER () FROM facts WHERE id <= 200 ORDER BY id;

# name: explicit_null_placement
SELECT id, ROW_NUMBER() OVER (ORDER BY qty NULLS FIRST, id) FROM facts WHERE id <= 200 ORDER BY id;
