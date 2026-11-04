# name: extract_date_parts
SELECT id, EXTRACT(YEAR FROM v_date), EXTRACT(MONTH FROM v_date), EXTRACT(DAY FROM v_date), EXTRACT(QUARTER FROM v_date) FROM scalars ORDER BY id;

# name: extract_weekday
SELECT id, EXTRACT(DOW FROM v_date), EXTRACT(ISODOW FROM v_date), EXTRACT(DOY FROM v_date) FROM scalars ORDER BY id;

# name: extract_week
SELECT id, EXTRACT(WEEK FROM v_date), EXTRACT(ISOWEEK FROM v_date), WEEK_ISO(v_date) FROM scalars ORDER BY id;

# name: extract_time_parts
SELECT id, EXTRACT(HOUR FROM v_ts), EXTRACT(MINUTE FROM v_ts), EXTRACT(SECOND FROM v_ts) FROM scalars ORDER BY id;

# name: epoch
SELECT id, EXTRACT(EPOCH FROM v_tstz) FROM scalars WHERE v_tstz > TIMESTAMPTZ '1900-01-01 00:00:00+00' ORDER BY id;

# name: date_trunc
SELECT id, DATE_TRUNC('year', v_ts), DATE_TRUNC('month', v_ts), DATE_TRUNC('hour', v_ts) FROM scalars ORDER BY id;

# name: datediff
SELECT id, DATEDIFF('day', v_date, DATE '2024-03-01'), DATEDIFF('month', v_date, DATE '2024-03-01'), DATEDIFF('year', v_date, DATE '2024-03-01') FROM scalars WHERE v_date BETWEEN DATE '1900-01-01' AND DATE '2100-12-31' ORDER BY id;

# name: timestampadd
SELECT id, TIMESTAMPADD('hour', 3, v_ts), TIMESTAMPADD('day', -1, v_ts) FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-12-31' ORDER BY id;

# name: month_functions
SELECT id, ADD_MONTHS(v_date, 1), LAST_DAY(v_date), MONTHS_BETWEEN(v_date, DATE '2020-01-15') FROM scalars WHERE v_date BETWEEN DATE '1900-01-01' AND DATE '2100-12-31' ORDER BY id;

# name: interval_arithmetic
SELECT id, v_ts + INTERVAL '1' DAY, v_ts - INTERVAL '30' MINUTE, v_date + INTERVAL '1' MONTH FROM scalars WHERE v_date BETWEEN DATE '1900-01-01' AND DATE '2100-12-31' ORDER BY id;

# name: date_integer_arithmetic
SELECT id, v_date + 1, v_date - 30 FROM scalars WHERE v_date BETWEEN DATE '1900-01-01' AND DATE '2100-12-31' ORDER BY id;

# name: to_char
SELECT id, TO_CHAR(v_ts, 'YYYY-MM-DD HH24:MI:SS'), TO_CHAR(v_date, 'DD/MM/YYYY') FROM scalars WHERE v_ts > TIMESTAMP '1900-01-01' ORDER BY id;

# name: to_date_timestamp
SELECT TO_DATE('2024-03-15', 'YYYY-MM-DD'), TO_TIMESTAMP('2024-03-15 10:20:30', 'YYYY-MM-DD HH24:MI:SS'), TO_DATE('15/03/2024', 'DD/MM/YYYY');

# name: at_time_zone
SELECT id, v_tstz AT TIME ZONE 'America/New_York', v_ts AT TIME ZONE 'Asia/Kolkata' FROM scalars WHERE v_ts BETWEEN TIMESTAMP '1900-01-01' AND TIMESTAMP '2100-01-01' ORDER BY id;

# name: day_functions
SELECT id, DAYOFWEEK(v_date), DAYOFWEEK_ISO(v_date), DAYOFYEAR(v_date), WEEK(v_date) FROM scalars ORDER BY id;

# name: trunc_date
SELECT id, TRUNC(v_date, 'MM'), TRUNC(v_date, 'YYYY') FROM scalars ORDER BY id;
