# name: approximate_count_distinct
SELECT APPROXIMATE_COUNT_DISTINCT(qty), APPROXIMATE_COUNT_DISTINCT(cat), APPROXIMATE_COUNT_DISTINCT(d), APPROXIMATE_COUNT_DISTINCT(ts) FROM facts;

# name: approximate_count_distinct_tolerance
SELECT APPROXIMATE_COUNT_DISTINCT(qty), APPROXIMATE_COUNT_DISTINCT(qty, 5), APPROXIMATE_COUNT_DISTINCT(qty, 1), APPROXIMATE_COUNT_DISTINCT(qty, .88), APPROXIMATE_COUNT_DISTINCT(qty, 10) FROM facts;

# name: approximate_count_distinct_grouped
SELECT grp, APPROXIMATE_COUNT_DISTINCT(qty), APPROXIMATE_COUNT_DISTINCT(score, 2.5) FROM facts GROUP BY grp ORDER BY grp;

# name: approximate_count_distinct_bounded
SELECT ABS(APPROXIMATE_COUNT_DISTINCT(id) - 10000) <= 500, ABS(APPROXIMATE_COUNT_DISTINCT(id, 5) - 10000) <= 1000 FROM facts;

# name: approximate_count_distinct_of_synopsis
SELECT APPROXIMATE_COUNT_DISTINCT_OF_SYNOPSIS(syn), APPROXIMATE_COUNT_DISTINCT_OF_SYNOPSIS(syn, 5) FROM (SELECT APPROXIMATE_COUNT_DISTINCT_SYNOPSIS(qty) AS syn FROM facts) AS s;

# name: approximate_count_distinct_synopsis_tolerance
SELECT grp, APPROXIMATE_COUNT_DISTINCT_OF_SYNOPSIS(syn, 5) FROM (SELECT grp, APPROXIMATE_COUNT_DISTINCT_SYNOPSIS(qty, 5) AS syn FROM facts GROUP BY grp) AS s GROUP BY grp ORDER BY grp;

# name: approximate_count_distinct_synopsis_merge
SELECT APPROXIMATE_COUNT_DISTINCT_OF_SYNOPSIS(merged) FROM (SELECT APPROXIMATE_COUNT_DISTINCT_SYNOPSIS_MERGE(syn) AS merged FROM (SELECT grp, APPROXIMATE_COUNT_DISTINCT_SYNOPSIS(qty) AS syn FROM facts GROUP BY grp) AS s) AS m;

# name: approximate_count_distinct_synopsis_merge_tolerance
SELECT APPROXIMATE_COUNT_DISTINCT_OF_SYNOPSIS(merged, 5) FROM (SELECT APPROXIMATE_COUNT_DISTINCT_SYNOPSIS_MERGE(syn, 5) AS merged FROM (SELECT flag, APPROXIMATE_COUNT_DISTINCT_SYNOPSIS(cat, 5) AS syn FROM facts GROUP BY flag) AS s) AS m;

# name: approximate_median
SELECT APPROXIMATE_MEDIAN(qty), APPROXIMATE_MEDIAN(score) FROM facts;

# name: approximate_median_grouped
SELECT grp, APPROXIMATE_MEDIAN(qty) FROM facts GROUP BY grp ORDER BY grp;

# name: approximate_percentile
SELECT grp, APPROXIMATE_PERCENTILE(qty USING PARAMETERS percentiles='0.5') AS median FROM facts GROUP BY grp ORDER BY grp;

# name: approximate_percentile_multiple
SELECT grp, APPROXIMATE_PERCENTILE(score USING PARAMETERS percentiles='0.5,1.0') FROM facts GROUP BY grp ORDER BY grp;

# name: approximate_percentile_subscript
SELECT ps[0] AS q0, ps[1] AS q1, ps[2] AS q2, ps[3] AS q3, ps[4] AS q4 FROM (SELECT grp, APPROXIMATE_PERCENTILE(qty USING PARAMETERS percentiles='0, 0.25, 0.5, 0.75, 1') AS ps FROM facts GROUP BY grp) AS s1 ORDER BY grp;

# name: approximate_percentile_deprecated_parameter
SELECT APPROXIMATE_PERCENTILE(qty USING PARAMETERS percentile=0.9) FROM facts;

# name: approximate_quantiles
SELECT APPROXIMATE_QUANTILES(qty USING PARAMETERS nquantiles=6) OVER () FROM facts;

# name: approximate_quantiles_epsilon
SELECT APPROXIMATE_QUANTILES(score USING PARAMETERS nquantiles=5, epsilon=0.01) OVER () FROM facts;

# name: approximate_quantiles_default
SELECT APPROXIMATE_QUANTILES(qty USING PARAMETERS epsilon=0.001) OVER () FROM facts;
