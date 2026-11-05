-- Date/time functions of the Vertica SQL reference, one or more cases per page.
-- Arithmetic filters out the year-1 and year-9999 rows, which overflow.

# name: add_months_types
SELECT id, ADD_MONTHS(v_date, -2), ADD_MONTHS(v_ts, 1), ADD_MONTHS(v_tstz, 24), ADD_MONTHS(v_date, 12) FROM scalars WHERE v_date BETWEEN DATE '1900-01-01' AND DATE '2100-12-31' ORDER BY id;

# name: add_months_month_ends
SELECT ADD_MONTHS(DATE '2015-09-15', -2), ADD_MONTHS(TIMESTAMP '2016-01-31', 1), ADD_MONTHS(DATE '2015-09-30', -1), ADD_MONTHS(TIMESTAMPTZ '2008-02-29 23:30:00+00', 24);

# name: age_in_months_years
SELECT id, AGE_IN_MONTHS(v_ts, TIMESTAMP '1972-03-02'), AGE_IN_YEARS(v_ts, TIMESTAMP '1972-03-02'), AGE_IN_MONTHS(v_date, DATE '1990-06-21'), AGE_IN_YEARS(DATE '1990-06-21', v_date), AGE_IN_MONTHS(v_tstz, TIMESTAMPTZ '2000-01-01 00:00:00+00'), AGE_IN_YEARS(v_tstz, TIMESTAMPTZ '2000-01-01 00:00:00+00') FROM scalars WHERE v_date BETWEEN DATE '1900-01-01' AND DATE '2100-12-31' ORDER BY id;

# name: age_one_argument
SELECT AGE_IN_MONTHS(DATE '1939-11-21') > 1000, AGE_IN_YEARS(DATE '1939-11-21') > 80, AGE_IN_YEARS(TIMESTAMP '1990-06-21 00:00:00') > 30;

# name: current_date_time
SELECT CURRENT_DATE > DATE '2020-01-01', CURRENT_DATE() = CURRENT_DATE, CURRENT_TIME IS NOT NULL, CURRENT_TIMESTAMP > TIMESTAMPTZ '2020-01-01 00:00:00+00', LOCALTIME IS NOT NULL, LOCALTIMESTAMP > TIMESTAMP '2020-01-01 00:00:00';

# name: current_precision
SELECT MICROSECOND(CURRENT_TIMESTAMP(0)), MICROSECOND(CURRENT_TIMESTAMP(3)) % 1000, EXTRACT(MICROSECONDS FROM CURRENT_TIME(0)) % 1000000, MICROSECOND(LOCALTIMESTAMP(0)), MICROSECOND(LOCALTIMESTAMP(2)) % 10000, EXTRACT(MICROSECONDS FROM LOCALTIME(0)) % 1000000;

# name: statement_and_clock_timestamps
SELECT NOW() = CURRENT_TIMESTAMP, TRANSACTION_TIMESTAMP() = CURRENT_TIMESTAMP, STATEMENT_TIMESTAMP() >= TRANSACTION_TIMESTAMP(), CLOCK_TIMESTAMP() >= STATEMENT_TIMESTAMP(), GETDATE() = SYSDATE(), SYSDATE = GETDATE(), GETUTCDATE() > TIMESTAMP '2020-01-01 00:00:00', LENGTH(TIMEOFDAY()) > 20;

# name: datediff_year_quarter_month_units
SELECT id, DATEDIFF(year, v_date, DATE '2024-03-01'), DATEDIFF(yy, v_date, DATE '2024-03-01'), DATEDIFF(yyyy, v_date, DATE '2024-03-01'), DATEDIFF(quarter, v_date, DATE '2024-03-01'), DATEDIFF(qq, v_date, DATE '2024-03-01'), DATEDIFF(q, v_date, DATE '2024-03-01'), DATEDIFF(month, v_date, DATE '2024-03-01'), DATEDIFF(mm, v_date, DATE '2024-03-01'), DATEDIFF(m, v_date, DATE '2024-03-01') FROM scalars WHERE v_date BETWEEN DATE '1900-01-01' AND DATE '2100-12-31' ORDER BY id;

# name: datediff_day_week_units
SELECT id, DATEDIFF(day, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(dayofyear, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(dd, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(d, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(dy, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(y, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(week, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(wk, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(ww, v_ts, TIMESTAMP '2024-03-01 12:00:00') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: datediff_time_units
SELECT id, DATEDIFF(hour, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(hh, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(minute, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(mi, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(n, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(second, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(ss, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(s, v_ts, TIMESTAMP '2024-03-01 12:00:00') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: datediff_subsecond_units
SELECT id, DATEDIFF(millisecond, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(ms, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(microsecond, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(mcs, v_ts, TIMESTAMP '2024-03-01 12:00:00'), DATEDIFF(us, v_ts, TIMESTAMP '2024-03-01 12:00:00') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: datediff_quoted_and_expression_units
SELECT id, DATEDIFF('month', v_date, DATE '2024-03-01'), DATEDIFF('y', v_date, DATE '2024-03-01'), DATEDIFF('M', v_date, DATE '2024-03-01'), DATEDIFF(('mon' || 'th'), v_date, DATE '2024-03-01'), DATEDIFF((CASE WHEN id > 10 THEN 'year' ELSE 'day' END), v_date, DATE '2024-03-01') FROM scalars WHERE v_date BETWEEN DATE '1900-01-01' AND DATE '2100-12-31' ORDER BY id;

# name: datediff_input_types
SELECT id, DATEDIFF(day, v_date, v_ts), DATEDIFF(hour, v_ts, v_tstz), DATEDIFF(month, v_tstz, v_date), DATEDIFF(year, v_date, v_tstz), DATEDIFF(week, v_tstz, TIMESTAMPTZ '2024-03-01 00:00:00+00') FROM scalars WHERE v_date BETWEEN DATE '1900-01-01' AND DATE '2100-12-31' ORDER BY id;

# name: datediff_time_and_interval
SELECT id, DATEDIFF(minute, v_time, TIME '23:00:00'), DATEDIFF(second, TIME '01:00:00', v_time), DATEDIFF(hour, v_interval, INTERVAL '5 days'), DATEDIFF(day, INTERVAL '26 days', v_interval) FROM vertica_extras ORDER BY id;

# name: datediff_interval_doc_example
SELECT DATEDIFF(day, INTERVAL '26 days', INTERVAL '1 month ');

# name: timestampdiff_units
SELECT id, TIMESTAMPDIFF(year, v_ts, TIMESTAMP '2024-03-01 12:00:00'), TIMESTAMPDIFF(qq, v_ts, TIMESTAMP '2024-03-01 12:00:00'), TIMESTAMPDIFF(m, v_ts, TIMESTAMP '2024-03-01 12:00:00'), TIMESTAMPDIFF(y, v_ts, TIMESTAMP '2024-03-01 12:00:00'), TIMESTAMPDIFF(ww, v_ts, TIMESTAMP '2024-03-01 12:00:00'), TIMESTAMPDIFF(hh, v_ts, TIMESTAMP '2024-03-01 12:00:00'), TIMESTAMPDIFF(n, v_ts, TIMESTAMP '2024-03-01 12:00:00'), TIMESTAMPDIFF(ss, v_ts, TIMESTAMP '2024-03-01 12:00:00'), TIMESTAMPDIFF(ms, v_ts, TIMESTAMP '2024-03-01 12:00:00'), TIMESTAMPDIFF(mcs, v_ts, TIMESTAMP '2024-03-01 12:00:00') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: timestampdiff_tstz_and_strings
SELECT id, TIMESTAMPDIFF(day, v_tstz, TIMESTAMPTZ '2024-03-01 00:00:00+00'), TIMESTAMPDIFF((CASE WHEN id > 10 THEN 'month' ELSE 'day' END), v_tstz, TIMESTAMPTZ '2024-03-01 00:00:00+00'), TIMESTAMPDIFF(YEAR, '1-1-2006 12:34:00', '1-1-2008 12:34:00') FROM scalars WHERE v_tstz BETWEEN TIMESTAMPTZ '1900-01-01 00:00:00+00' AND TIMESTAMPTZ '2100-12-31 00:00:00+00' ORDER BY id;

# name: timestampadd_year_quarter_month_units
SELECT id, TIMESTAMPADD(year, 1, v_ts), TIMESTAMPADD(yy, 1, v_ts), TIMESTAMPADD(yyyy, -1, v_ts), TIMESTAMPADD(quarter, 1, v_ts), TIMESTAMPADD(qq, 1, v_ts), TIMESTAMPADD(q, -1, v_ts), TIMESTAMPADD(month, 1, v_ts), TIMESTAMPADD(mm, 1, v_ts), TIMESTAMPADD(m, -1, v_ts) FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: timestampadd_day_week_units
SELECT id, TIMESTAMPADD(day, 1, v_ts), TIMESTAMPADD(dayofyear, 1, v_ts), TIMESTAMPADD(dd, 1, v_ts), TIMESTAMPADD(d, -1, v_ts), TIMESTAMPADD(dy, 1, v_ts), TIMESTAMPADD(y, 1, v_ts), TIMESTAMPADD(week, 1, v_ts), TIMESTAMPADD(wk, 1, v_ts), TIMESTAMPADD(ww, -1, v_ts) FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: timestampadd_time_units
SELECT id, TIMESTAMPADD(hour, 3, v_ts), TIMESTAMPADD(hh, 3, v_ts), TIMESTAMPADD(minute, 30, v_ts), TIMESTAMPADD(mi, 30, v_ts), TIMESTAMPADD(n, -30, v_ts), TIMESTAMPADD(second, 90, v_ts), TIMESTAMPADD(ss, 90, v_ts), TIMESTAMPADD(s, -90, v_ts) FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: timestampadd_subsecond_units
SELECT id, TIMESTAMPADD(millisecond, 1500, v_ts), TIMESTAMPADD(ms, -1, v_ts), TIMESTAMPADD(microsecond, 1, v_ts), TIMESTAMPADD(mcs, 1000001, v_ts), TIMESTAMPADD(us, -1, v_ts) FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: timestampadd_tstz_and_expressions
SELECT id, TIMESTAMPADD(month, 2, v_tstz), TIMESTAMPADD('day', 14, v_tstz), TIMESTAMPADD('M', 1, v_tstz), TIMESTAMPADD((CASE WHEN id > 10 THEN 'month' ELSE 'day' END), 1, v_tstz), TIMESTAMPADD(DD, 14, (SELECT TRUNC(TIMESTAMP '2016-05-02 06:56:57', 'MM'))) FROM scalars WHERE v_tstz BETWEEN TIMESTAMPTZ '1900-01-01 00:00:00+00' AND TIMESTAMPTZ '2100-12-31 00:00:00+00' ORDER BY id;

# name: date_part_date_fields
SELECT id, DATE_PART('century', v_ts), DATE_PART('day', v_ts), DATE_PART('decade', v_ts), DATE_PART('doq', v_ts), DATE_PART('dow', v_ts), DATE_PART('doy', v_ts), DATE_PART('isodow', v_ts), DATE_PART('isoweek', v_ts), DATE_PART('isoyear', v_ts), DATE_PART('millennium', v_ts), DATE_PART('month', v_ts), DATE_PART('quarter', v_ts), DATE_PART('week', v_ts), DATE_PART('year', v_ts) FROM scalars ORDER BY id;

# name: date_part_time_fields
SELECT id, DATE_PART('epoch', v_ts), DATE_PART('hour', v_ts), DATE_PART('microseconds', v_ts), DATE_PART('milliseconds', v_ts), DATE_PART('minute', v_ts), DATE_PART('MINUTES', v_ts), DATE_PART('second', v_ts) FROM scalars WHERE v_ts > TIMESTAMP '1900-01-01' ORDER BY id;

# name: date_part_tstz_and_date
SELECT id, DATE_PART('time zone', v_tstz), DATE_PART('timezone_hour', v_tstz), DATE_PART('timezone_minute', v_tstz), DATE_PART('day', v_tstz), DATE_PART('week', v_date), DATE_PART('doq', v_date), DATE_PART('isoyear', v_date) FROM scalars ORDER BY id;

# name: date_part_interval
SELECT id, DATE_PART('epoch', v_interval), DATE_PART('day', v_interval), DATE_PART('hour', v_interval), DATE_PART('minute', v_interval), DATE_PART('second', v_interval), DATE_PART('microseconds', v_interval), DATE_PART('month', INTERVAL '2-35' YEAR TO MONTH), DATE_PART('year', INTERVAL '2-35' YEAR TO MONTH) FROM vertica_extras ORDER BY id;

# name: extract_all_date_fields
SELECT id, EXTRACT(CENTURY FROM v_ts), EXTRACT(DECADE FROM v_ts), EXTRACT(DOQ FROM v_ts), EXTRACT(ISOYEAR FROM v_ts), EXTRACT(MILLENNIUM FROM v_ts), EXTRACT(WEEK FROM v_ts), EXTRACT(ISOWEEK FROM v_ts), EXTRACT(DOQ FROM v_date), EXTRACT(CENTURY FROM v_date) FROM scalars ORDER BY id;

# name: extract_subsecond_and_zone_fields
SELECT id, EXTRACT(MICROSECONDS FROM v_ts), EXTRACT(MILLISECONDS FROM v_ts), EXTRACT(TIME ZONE FROM v_tstz), EXTRACT(TIMEZONE_HOUR FROM v_tstz), EXTRACT(TIMEZONE_MINUTE FROM v_tstz), EXTRACT(EPOCH FROM v_ts) FROM scalars WHERE v_ts > TIMESTAMP '1900-01-01' ORDER BY id;

# name: extract_interval
SELECT id, EXTRACT(EPOCH FROM v_interval), EXTRACT(DAY FROM v_interval), EXTRACT(HOUR FROM v_interval), EXTRACT(MINUTE FROM v_interval), EXTRACT(SECOND FROM v_interval), EXTRACT(EPOCH FROM -INTERVAL '5 days 3 hours'), EXTRACT(MONTH FROM INTERVAL '2-35' YEAR TO MONTH) FROM vertica_extras ORDER BY id;

# name: date_trunc_date_precisions
SELECT id, DATE_TRUNC('millennium', v_ts), DATE_TRUNC('century', v_ts), DATE_TRUNC('decade', v_ts), DATE_TRUNC('year', v_ts), DATE_TRUNC('quarter', v_ts), DATE_TRUNC('month', v_ts), DATE_TRUNC('week', v_ts), DATE_TRUNC('day', v_ts) FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: date_trunc_time_precisions
SELECT id, DATE_TRUNC('hour', v_ts), DATE_TRUNC('minute', v_ts), DATE_TRUNC('second', v_ts), DATE_TRUNC('milliseconds', v_ts), DATE_TRUNC('microseconds', v_ts) FROM scalars ORDER BY id;

# name: date_trunc_input_types
SELECT id, DATE_TRUNC('YEAR', v_tstz), DATE_TRUNC('week', v_tstz), DATE_TRUNC('MONTH', v_date), DATE_TRUNC('quarter', v_date) FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: date_trunc_time_and_interval
SELECT id, DATE_TRUNC('hour', v_interval), DATE_TRUNC('day', v_interval), DATE_TRUNC('minute', v_time), DATE_TRUNC('hour', v_time) FROM vertica_extras ORDER BY id;

# name: date_function
SELECT id, DATE(v_ts), DATE(v_tstz), DATE(v_date), DATE(id), DATE(734260) FROM scalars ORDER BY id;

# name: date_function_strings
SELECT DATE('2024-02-29'), DATE('2024-02-29 12:34:56'), DATE(v_text), DATE(v_varchar) FROM scalars WHERE id = 20;

# name: day_month_year_quarter
SELECT id, DAY(v_date), DAY(v_ts), DAY(v_tstz), MONTH(v_date), MONTH(v_ts), MONTH(v_tstz), YEAR(v_date), YEAR(v_ts), YEAR(v_tstz), QUARTER(v_date), QUARTER(v_ts), QUARTER(v_tstz), DAYOFMONTH(v_date), DAYOFMONTH(v_ts), DAYOFMONTH(v_tstz) FROM scalars ORDER BY id;

# name: day_month_year_other_inputs
SELECT DAY(6), DAY('sep 22, 2011 12:34'), DAY(INTERVAL '35 12:34'), MONTH('6-9'), MONTH(INTERVAL '2-35' YEAR TO MONTH), YEAR(INTERVAL '2-35' YEAR TO MONTH), YEAR('2-3'), QUARTER('2024-08-01'), DAYOFMONTH('2024-01-15');

# name: day_of_interval_column
SELECT id, DAY(v_interval), HOUR(v_interval), MINUTE(v_interval), SECOND(v_interval), MICROSECOND(v_interval) FROM vertica_extras ORDER BY id;

# name: day_month_year_varchar_columns
SELECT id, DAY(v_text), YEAR(v_text), MONTH(v_text), HOUR(v_varchar), MINUTE(v_varchar), SECOND(v_varchar), MICROSECOND(v_varchar) FROM scalars WHERE id = 20 ORDER BY id;

# name: hour_minute_second_microsecond
SELECT id, HOUR(v_ts), HOUR(v_tstz), HOUR(v_date), MINUTE(v_ts), MINUTE(v_tstz), MINUTE(v_date), SECOND(v_ts), SECOND(v_tstz), MICROSECOND(v_ts), MICROSECOND(v_tstz) FROM scalars ORDER BY id;

# name: hour_minute_second_strings
SELECT HOUR('12:34'), HOUR(TIMESTAMP '2011-09-22 12:34:00'), HOUR(INTERVAL '35 12:34'), MINUTE('12:34:03.456789'), MINUTE(INTERVAL '35 12:34:03.456789'), SECOND('23:34:03.456789'), SECOND(INTERVAL '35 12:34:03.456789'), MICROSECOND('12:34:01.123456'), MICROSECOND(TIMESTAMP '2011-09-22 12:34:01.123456');

# name: day_of_week_and_year
SELECT id, DAYOFWEEK(v_date), DAYOFWEEK(v_ts), DAYOFWEEK(v_tstz), DAYOFWEEK_ISO(v_date), DAYOFWEEK_ISO(v_ts), DAYOFWEEK_ISO(v_tstz), DAYOFYEAR(v_date), DAYOFYEAR(v_ts), DAYOFYEAR(v_tstz) FROM scalars ORDER BY id;

# name: week_and_iso_functions
SELECT id, WEEK(v_date), WEEK(v_ts), WEEK(v_tstz), WEEK_ISO(v_date), WEEK_ISO(v_ts), WEEK_ISO(v_tstz), YEAR_ISO(v_date), YEAR_ISO(v_ts), YEAR_ISO(v_tstz) FROM scalars ORDER BY id;

# name: day_and_week_functions_strings
SELECT DAYOFWEEK('2024-01-15'), DAYOFWEEK_ISO('Jan 1, 2000'), DAYOFYEAR('2024-03-01'), WEEK('1-2-2016'), WEEK('1-3-2016'), WEEK_ISO('1-3-2016'), WEEK_ISO('12-29-2014'), YEAR_ISO('Jan1,2000'), YEAR_ISO(DATE '2016-01-01');

# name: days_julian_midnight_seconds
SELECT id, DAYS(v_date), DAYS(v_ts), DAYS(v_tstz), JULIAN_DAY(v_date), JULIAN_DAY(v_ts), JULIAN_DAY(v_tstz), MIDNIGHT_SECONDS(v_date), MIDNIGHT_SECONDS(v_ts), MIDNIGHT_SECONDS(v_tstz) FROM scalars ORDER BY id;

# name: days_julian_midnight_seconds_strings
SELECT DAYS('2011-01-22'), DAYS(DATE '2011-01-22'), JULIAN_DAY('2001-01-01'), JULIAN_DAY(DATE '2001-01-01'), MIDNIGHT_SECONDS('2016-03-03 12:00'), MIDNIGHT_SECONDS(TIMESTAMP '2016-03-03 12:00:00');

# name: isfinite
SELECT id, ISFINITE(v_ts), ISFINITE(TIMESTAMP '2009-02-16 21:28:30'), ISFINITE(TIMESTAMP 'INFINITY'), ISFINITE(TIMESTAMP '-INFINITY') FROM scalars ORDER BY id;

# name: last_day_types
SELECT id, LAST_DAY(v_date), LAST_DAY(v_ts), LAST_DAY(v_tstz) FROM scalars WHERE v_date BETWEEN DATE '1900-01-01' AND DATE '2100-12-31' ORDER BY id;

# name: last_day_strings
SELECT LAST_DAY('2016-02-28 23:30 PST'), LAST_DAY('2017/02/03'), LAST_DAY(DATE '2003-03-15'), DATE('2022/07/04') - DAYOFMONTH('2022/07/04') + 1, LAST_DAY('1929/06/06') - (SELECT DAY(LAST_DAY('1929/06/06')) - 1);

# name: months_between_types
SELECT id, MONTHS_BETWEEN(v_date, DATE '2020-01-15'), MONTHS_BETWEEN(v_ts, TIMESTAMP '2016-02-29 10:00:00'), MONTHS_BETWEEN(TIMESTAMPTZ '2016-03-31 00:00:00+00', v_tstz), MONTHS_BETWEEN(v_date, v_ts) FROM scalars WHERE v_date BETWEEN DATE '1900-01-01' AND DATE '2100-12-31' ORDER BY id;

# name: months_between_month_ends
SELECT MONTHS_BETWEEN(TIMESTAMP '2016-04-07', TIMESTAMP '2015-01-07'), MONTHS_BETWEEN(TIMESTAMP '2016-03-31', TIMESTAMP '2016-02-28'), MONTHS_BETWEEN(TIMESTAMP '2016-03-31', TIMESTAMP '2016-02-29'), MONTHS_BETWEEN(DATE '2016-04-30', DATE '2016-03-31');

# name: new_time
SELECT id, NEW_TIME(v_ts, 'EST', 'PST'), NEW_TIME(v_tstz, 'GMT', 'CST'), NEW_TIME(v_date, 'PDT', 'EDT') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: new_time_strings
SELECT NEW_TIME('05-24-12 13:48:00', 'EST', 'PST'), NEW_TIME('01-01-12 01:00:00', 'EST', 'PST'), NEW_TIME('May 24, 2012 10:00', 'AST', 'MDT'), NEW_TIME('April 1, 45 BC', 'GMT', 'NST')::DATE::VARCHAR;

# name: next_day
SELECT id, NEXT_DAY(v_date, 'Monday'), NEXT_DAY(v_ts, 'tues'), NEXT_DAY(v_tstz, 'FRI'), NEXT_DAY(v_date, 'sunday') FROM scalars WHERE v_date BETWEEN DATE '1900-01-01' AND DATE '2100-12-31' ORDER BY id;

# name: next_day_strings
SELECT NEXT_DAY('4-29-2016', 'Monday'), NEXT_DAY(TIMESTAMP '2016-04-29 00:00:00', 'Sat'), NEXT_DAY(CURRENT_TIMESTAMP, 'tues') > CURRENT_DATE;

# name: overlaps
SELECT (DATE '2016-02-16', DATE '2016-12-21') OVERLAPS (DATE '2008-10-30', DATE '2016-10-30'), (DATE '2016-02-16', DATE '2016-12-21') OVERLAPS (DATE '2008-01-30', DATE '2008-10-30'), (TIME '01:00:00', TIME '03:00:00') OVERLAPS (TIME '02:00:00', TIME '04:00:00'), (TIMESTAMP '2016-02-16 00:00:00', INTERVAL '7 days') OVERLAPS (TIMESTAMP '2016-02-20 00:00:00', INTERVAL '1' DAY);

# name: overlaps_columns
SELECT id, (v_date, v_ts) OVERLAPS (DATE '2024-01-01', DATE '2024-12-31'), (v_tstz, INTERVAL '2' DAY) OVERLAPS (TIMESTAMPTZ '2024-03-01 00:00:00+00', TIMESTAMPTZ '2024-03-02 00:00:00+00') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: round_formats
SELECT id, ROUND(v_ts), ROUND(v_ts, 'CC'), ROUND(v_ts, 'SCC'), ROUND(v_ts, 'YYYY'), ROUND(v_ts, 'YEAR'), ROUND(v_ts, 'YYY'), ROUND(v_ts, 'YY'), ROUND(v_ts, 'Y'), ROUND(v_ts, 'IYYY'), ROUND(v_ts, 'IYY'), ROUND(v_ts, 'IY'), ROUND(v_ts, 'I'), ROUND(v_ts, 'Q'), ROUND(v_ts, 'MONTH'), ROUND(v_ts, 'MON'), ROUND(v_ts, 'MM'), ROUND(v_ts, 'RM') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: round_formats_week_day_time
SELECT id, ROUND(v_ts, 'WW'), ROUND(v_ts, 'IW'), ROUND(v_ts, 'W'), ROUND(v_ts, 'DDD'), ROUND(v_ts, 'DD'), ROUND(v_ts, 'J'), ROUND(v_ts, 'DAY'), ROUND(v_ts, 'DY'), ROUND(v_ts, 'D'), ROUND(v_ts, 'HH'), ROUND(v_ts, 'HH12'), ROUND(v_ts, 'HH24'), ROUND(v_ts, 'MI'), ROUND(v_ts, 'SS') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: round_dates_and_tstz
SELECT id, ROUND(v_date), ROUND(v_date, 'MM'), ROUND(v_date, 'Q'), ROUND(v_date, 'IW'), ROUND(v_tstz, 'HH'), ROUND(v_tstz, 'YEAR'), ROUND(TIMESTAMP '2011-09-22 12:34:00', 'MM') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: trunc_formats
SELECT id, TRUNC(v_ts), TRUNC(v_ts, 'CC'), TRUNC(v_ts, 'SCC'), TRUNC(v_ts, 'YYYY'), TRUNC(v_ts, 'YEAR'), TRUNC(v_ts, 'YYY'), TRUNC(v_ts, 'YY'), TRUNC(v_ts, 'Y'), TRUNC(v_ts, 'IYYY'), TRUNC(v_ts, 'IYY'), TRUNC(v_ts, 'IY'), TRUNC(v_ts, 'I'), TRUNC(v_ts, 'Q'), TRUNC(v_ts, 'MONTH'), TRUNC(v_ts, 'MON'), TRUNC(v_ts, 'MM'), TRUNC(v_ts, 'RM') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: trunc_formats_week_day_time
SELECT id, TRUNC(v_ts, 'WW'), TRUNC(v_ts, 'IW'), TRUNC(v_ts, 'W'), TRUNC(v_ts, 'DDD'), TRUNC(v_ts, 'DD'), TRUNC(v_ts, 'J'), TRUNC(v_ts, 'DAY'), TRUNC(v_ts, 'DY'), TRUNC(v_ts, 'D'), TRUNC(v_ts, 'HH'), TRUNC(v_ts, 'HH12'), TRUNC(v_ts, 'HH24'), TRUNC(v_ts, 'MI'), TRUNC(v_ts, 'SS') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: trunc_dates_and_tstz
SELECT id, TRUNC(v_date), TRUNC(v_date, 'MM'), TRUNC(v_date, 'Q'), TRUNC(v_date, 'IW'), TRUNC(v_date, 'D'), TRUNC(v_tstz, 'HH'), TRUNC(v_tstz, 'YEAR'), TRUNC(v_tstz, 'W'), TRUNC(TIMESTAMP '2011-09-22 12:34:00', 'MM') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: timestamp_round_formats
SELECT id, TIMESTAMP_ROUND(v_ts), TIMESTAMP_ROUND(v_ts, 'CC'), TIMESTAMP_ROUND(v_ts, 'Y'), TIMESTAMP_ROUND(v_ts, 'IYYY'), TIMESTAMP_ROUND(v_ts, 'I'), TIMESTAMP_ROUND(v_ts, 'Q'), TIMESTAMP_ROUND(v_ts, 'MON'), TIMESTAMP_ROUND(v_ts, 'RM'), TIMESTAMP_ROUND(v_ts, 'WW'), TIMESTAMP_ROUND(v_ts, 'IW'), TIMESTAMP_ROUND(v_ts, 'W'), TIMESTAMP_ROUND(v_ts, 'J'), TIMESTAMP_ROUND(v_ts, 'DY'), TIMESTAMP_ROUND(v_ts, 'HH24'), TIMESTAMP_ROUND(v_ts, 'MI'), TIMESTAMP_ROUND(v_ts, 'SS'), TIMESTAMP_ROUND(v_tstz, 'HH') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: timestamp_trunc_formats
SELECT id, TIMESTAMP_TRUNC(v_ts), TIMESTAMP_TRUNC(v_ts, 'SCC'), TIMESTAMP_TRUNC(v_ts, 'YEAR'), TIMESTAMP_TRUNC(v_ts, 'YYY'), TIMESTAMP_TRUNC(v_ts, 'IYY'), TIMESTAMP_TRUNC(v_ts, 'IY'), TIMESTAMP_TRUNC(v_ts, 'Q'), TIMESTAMP_TRUNC(v_ts, 'MONTH'), TIMESTAMP_TRUNC(v_ts, 'MM'), TIMESTAMP_TRUNC(v_ts, 'WW'), TIMESTAMP_TRUNC(v_ts, 'IW'), TIMESTAMP_TRUNC(v_ts, 'W'), TIMESTAMP_TRUNC(v_ts, 'DDD'), TIMESTAMP_TRUNC(v_ts, 'DAY'), TIMESTAMP_TRUNC(v_ts, 'D'), TIMESTAMP_TRUNC(v_ts, 'HH12'), TIMESTAMP_TRUNC(v_ts, 'MI'), TIMESTAMP_TRUNC(v_ts, 'SS'), TIMESTAMP_TRUNC(v_tstz, 'MM'), TIMESTAMP_TRUNC(v_date, 'MM') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: time_slice_units
SELECT id, TIME_SLICE(v_ts, 3), TIME_SLICE(v_ts, 9), TIME_SLICE(v_ts, 2, 'HOUR'), TIME_SLICE(v_ts, 15, 'MINUTE'), TIME_SLICE(v_ts, 3, 'SECOND'), TIME_SLICE(v_ts, 250, 'MILLISECOND'), TIME_SLICE(v_ts, 3, 'ms'), TIME_SLICE(v_ts, 7, 'MICROSECOND'), TIME_SLICE(v_ts, 3, 'us') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: time_slice_start_end
SELECT id, TIME_SLICE(v_ts, 3, 'SECOND', 'START'), TIME_SLICE(v_ts, 3, 'SECOND', 'END'), TIME_SLICE(v_ts, 1, 'HOUR', 'END'), TIME_SLICE(v_tstz, 3), TIME_SLICE(v_tstz, 10, 'MINUTE', 'END') FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: time_slice_strings
SELECT TIME_SLICE('2009-09-19 00:00:01', 3), TIME_SLICE('2009-09-19 00:00:01', 3, 'SECOND', 'END'), TIME_SLICE('2009-09-19 00:00:01', 3, 'ms'), TIME_SLICE('2009-09-19 00:00:01', 3, 'us'), TIME_SLICE('2009-02-14 20:13:01', 9) + INTERVAL '6' SECOND, TIME_SLICE('2009-02-14 20:13:01', 5);

# name: time_slice_grouping
SELECT TIME_SLICE(v_ts, 1, 'HOUR') AS slice, COUNT(*) FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' GROUP BY TIME_SLICE(v_ts, 1, 'HOUR') ORDER BY slice;

# name: overlaps_interval_doc_example
SELECT (DATE '2016-02-16', INTERVAL '1 week') OVERLAPS (DATE '2016-10-16', INTERVAL '-8 months');
