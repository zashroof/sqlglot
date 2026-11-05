# name: ts_first_value_interpolation
SELECT slice_time, TS_FIRST_VALUE(qty), TS_FIRST_VALUE(qty, 'CONST'), TS_FIRST_VALUE(score, 'LINEAR') FROM facts WHERE ts >= '2020-03-01' AND ts < '2020-03-08' TIMESERIES slice_time AS '6 hours' OVER (ORDER BY ts) ORDER BY slice_time;

# name: ts_last_value_partitioned
SELECT flag, slice_time, TS_LAST_VALUE(qty), TS_LAST_VALUE(score, 'linear') FROM facts WHERE ts >= '2020-03-01' AND ts < '2020-03-08' TIMESERIES slice_time AS '12 hours' OVER (PARTITION BY flag ORDER BY ts) ORDER BY slice_time, flag;

# name: ts_ignore_nulls
SELECT slice_time, TS_FIRST_VALUE(q IGNORE NULLS), TS_FIRST_VALUE(q IGNORE NULLS, 'LINEAR'), TS_LAST_VALUE(s IGNORE NULLS, 'CONST') FROM (SELECT ts, CASE WHEN id % 2 = 0 THEN NULL ELSE qty END AS q, CASE WHEN id % 3 = 0 THEN NULL ELSE score END AS s FROM facts WHERE ts >= '2020-03-01' AND ts < '2020-03-08') AS t TIMESERIES slice_time AS '4 hours' OVER (ORDER BY ts) ORDER BY slice_time;

# name: timeseries_partition_expressions_time_slice
SELECT grp % 2 AS parity, slice_time, TIME_SLICE(slice_time, 12, 'HOUR'), TS_LAST_VALUE(qty) FROM facts WHERE ts >= '2020-03-01' AND ts < '2020-03-05' AND grp IS NOT NULL TIMESERIES slice_time AS '1 day' OVER (PARTITION BY grp % 2 ORDER BY ts) ORDER BY slice_time, parity;

# name: timeseries_seconds_slices
SELECT k, slice_time, TS_FIRST_VALUE(id, 'LINEAR'), TS_LAST_VALUE(id) FROM join_left TIMESERIES slice_time AS '3 seconds' OVER (PARTITION BY k ORDER BY TIMESTAMP '2020-01-01 00:00:00' + id * INTERVAL '2 seconds') ORDER BY slice_time, k;

# name: timeseries_grouped_in_outer_query
SELECT flag, AVG(first_qty) AS avg_qty, COUNT(*) FROM (SELECT flag, slice_time, TS_FIRST_VALUE(qty) AS first_qty FROM facts WHERE ts >= '2020-03-01' AND ts < '2020-03-15' TIMESERIES slice_time AS '1 day' OVER (PARTITION BY flag ORDER BY ts)) AS gfi GROUP BY flag ORDER BY flag;
