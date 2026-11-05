# name: to_char_time_fields
SELECT id, TO_CHAR(v_ts, 'HH HH12 HH24 MI SS MS US SSSS'), TO_CHAR(v_ts, 'hh24:mi:ss.us') FROM scalars ORDER BY id;

# name: to_char_meridian_and_era
SELECT id, TO_CHAR(v_ts, 'HH12 AM A.M. PM P.M.'), TO_CHAR(v_ts, 'HH12 am a.m. pm p.m.'), TO_CHAR(v_ts, 'YYYY BC B.C. AD A.D.'), TO_CHAR(v_ts, 'YYYY bc b.c. ad a.d.') FROM scalars ORDER BY id;

# name: to_char_years
SELECT id, TO_CHAR(v_ts, 'Y,YYY YYYY YYY YY Y'), TO_CHAR(v_ts, 'IYYY IYY IY I'), TO_CHAR(v_ts, 'CC J Q') FROM scalars ORDER BY id;

# name: to_char_month_and_day_names
SELECT id, TO_CHAR(v_ts, 'MONTH Month month MON Mon mon MM'), TO_CHAR(v_ts, 'DAY Day day DY Dy dy'), TO_CHAR(v_ts, 'RM rm') FROM scalars ORDER BY id;

# name: to_char_day_and_week_numbers
SELECT id, TO_CHAR(v_date, 'DDD DD D'), TO_CHAR(v_date, 'W WW IW'), TO_CHAR(v_date, 'IDDD ID id iw') FROM scalars ORDER BY id;

# name: to_char_modifiers
SELECT id, TO_CHAR(v_ts, 'FMMonth FMDD FMHH12:FMMI'), TO_CHAR(v_ts, 'DDTH DDth'), TO_CHAR(v_ts, 'FX Month DD Day'), TO_CHAR(v_ts, 'TMMonth TMDay') FROM scalars ORDER BY id;

# name: to_char_quoted_text
SELECT id, TO_CHAR(v_ts, '"Hello Year " YYYY'), TO_CHAR(v_ts, '"Today is day" DD "of" Month'), TO_CHAR(v_ts, 'YYYY-MM-DD"T"HH24:MI:SS') FROM scalars ORDER BY id;

# name: to_char_time_zone
SELECT id, TO_CHAR(v_tstz, 'YYYY-MM-DD HH24:MI:SS TZ'), TO_CHAR(v_tstz, 'HH24 tz') FROM scalars ORDER BY id;

# name: to_char_time_types
SELECT TO_CHAR(TIME '14:34:06.4', 'HH12:MI am'), TO_CHAR(TIMETZ '14:34:06.4+6', 'HH12:MI am'), TO_CHAR(CAST(TIME '14:34:06.4' AS TIMESTAMP), 'HH24:MI:SS.MS');

# name: to_char_time_column
SELECT id, TO_CHAR(v_time, 'HH24:MI:SS.US'), TO_CHAR(v_time, 'HH12 am') FROM vertica_extras ORDER BY id;

# name: to_char_interval
SELECT id, TO_CHAR(v_interval, 'HH24:MI:SS'), TO_CHAR(v_interval, 'DD HH:MI:SS.MS'), TO_CHAR(v_interval) FROM vertica_extras ORDER BY id;

# name: to_char_interval_literal
SELECT TO_CHAR(INTERVAL '3 days 1000.333 secs'), TO_CHAR(INTERVAL '30 hours', 'HH24 HH'), TO_CHAR(INTERVAL '40 days 3 hours', 'DD HH24');

# name: to_char_default_format
SELECT id, TO_CHAR(v_int8), TO_CHAR(v_dec), TO_CHAR(v_date), TO_CHAR(v_ts), TO_CHAR(v_tstz) FROM scalars ORDER BY id;

# name: to_char_default_format_literals
SELECT TO_CHAR(-1234.567), TO_CHAR('1999-12-25'::DATE), TO_CHAR('1999-12-25 11:31'::TIMESTAMP), TO_CHAR('1999-12-25 11:31 EST'::TIMESTAMPTZ), TO_CHAR('3 days 1000.333 secs'::INTERVAL);

# name: to_char_numeric_patterns
SELECT TO_CHAR(-0.1, '99.99'), TO_CHAR(-0.1, 'FM9.99'), TO_CHAR(0.1, '0.9'), TO_CHAR(12, '9990999.9'), TO_CHAR(12, 'FM9990999.9'), TO_CHAR(485, '999'), TO_CHAR(-485, '999'), TO_CHAR(485, '9 9 9'), TO_CHAR(1485, '9,999'), TO_CHAR(1485, '9G999'), TO_CHAR(148.5, '999.999'), TO_CHAR(148.5, 'FM999.999'), TO_CHAR(148.5, 'FM999.990'), TO_CHAR(148.5, '999D999'), TO_CHAR(3148.5, '9G999D999');

# name: to_char_numeric_signs
SELECT TO_CHAR(-12, 'S9999'), TO_CHAR(-12, 'MI9999'), TO_CHAR(-485, '999S'), TO_CHAR(-485, '999MI'), TO_CHAR(485, '999MI'), TO_CHAR(485, 'FM999MI'), TO_CHAR(485, 'PL999'), TO_CHAR(485, 'SG999'), TO_CHAR(-485, 'SG999'), TO_CHAR(-485, '9SG99'), TO_CHAR(-485, '999PR');

# name: to_char_numeric_special
SELECT TO_CHAR(485, 'L999'), TO_CHAR(485, 'RN'), TO_CHAR(485, 'FMRN'), TO_CHAR(5.2, 'FMRN'), TO_CHAR(482, '999th'), TO_CHAR(482, '999TH'), TO_CHAR(485, '"Good number:"999'), TO_CHAR(485.8, '"Pre:"999" Post:" .999'), TO_CHAR(12, '99V999'), TO_CHAR(12.4, '99V999'), TO_CHAR(12.45, '99V9');

# name: to_char_numeric_columns
SELECT id, TO_CHAR(v_int8, 'S9999999999999999999'), TO_CHAR(v_dec, 'FM99,999,990.00'), TO_CHAR(v_dec, '00000000D00PR'), TO_CHAR(v_float8, '999.999') FROM scalars WHERE ABS(v_float8) < 1000 OR v_float8 IS NULL ORDER BY id;

# name: to_date_patterns
SELECT TO_DATE('13 Feb 2000', 'DD Mon YYYY'), TO_DATE('2017-1231', 'YYYY-MMDD'), TO_DATE('200001131', 'YYYYMMDD'), CAST(TO_DATE('20000-1131', 'YYYY-MMDD') AS VARCHAR), TO_DATE('2000 JUN', 'YYYY MON'), TO_DATE('21 05 03', 'CC YY MM'), TO_DATE('2024.060', 'YYYY.DDD'), TO_DATE('x 2024-03-15', '"x" YYYY-MM-DD');

# name: to_date_column
SELECT id, TO_DATE(TO_CHAR(v_date, 'YYYY-MM-DD'), 'YYYY-MM-DD'), TO_DATE(TO_CHAR(v_date, 'DD Month YYYY'), 'DD Month YYYY'), TO_DATE(TO_CHAR(v_date, 'J'), 'J') FROM scalars WHERE v_date > DATE '1900-01-01' ORDER BY id;

# name: to_timestamp_patterns
SELECT TO_TIMESTAMP('2017 JUN', 'YYYY MON'), TO_TIMESTAMP('13 Feb 2009', 'DD Mon YYYY'), CAST(TO_TIMESTAMP('12:3', 'SS:MS') AS TIME), CAST(TO_TIMESTAMP('12:003', 'SS:MS') AS TIME), CAST(TO_TIMESTAMP('15:12:02.020.001230', 'HH:MI:SS.MS.US') AS TIME), TO_TIMESTAMP('2000  JUN', 'YYYY MON'), TO_TIMESTAMP('2024-03-15 10:20:30 PM', 'YYYY-MM-DD HH12:MI:SS AM');

# name: to_timestamp_epoch
SELECT TO_TIMESTAMP(200120400), TO_TIMESTAMP(1.5), TO_TIMESTAMP(-86400);

# name: to_timestamp_column
SELECT id, TO_TIMESTAMP(v_int8 // 1000), TO_TIMESTAMP(TO_CHAR(v_ts, 'YYYY-MM-DD HH24:MI:SS.US'), 'YYYY-MM-DD HH24:MI:SS.US') FROM scalars WHERE ABS(v_int8) < 10000000000000 OR v_int8 IS NULL ORDER BY id;

# name: to_timestamp_tz
SELECT TO_TIMESTAMP_TZ('13 Feb 2009', 'DD Mon YYY'), TO_TIMESTAMP_TZ('2017 JUN', 'YYYY MON'), TO_TIMESTAMP_TZ(200120400), TO_TIMESTAMP_TZ(1.5), TO_TIMESTAMP_TZ('2024-03-15 10:20:30.5', 'YYYY-MM-DD HH24:MI:SS.MS');

# name: to_number
SELECT TO_NUMBER('MCML', 'rn'), TO_NUMBER('-123.456e-01'), TO_NUMBER('1,485', '9,999'), TO_NUMBER('<485>', '999PR'), TO_NUMBER('12.5'), TO_NUMBER('  42  ');

# name: to_number_column
SELECT id, TO_NUMBER(TO_CHAR(v_int8)), TO_NUMBER(TO_CHAR(v_dec, '99999999D99'), '99999999D99') FROM scalars ORDER BY id;

# name: to_hex
SELECT id, TO_HEX(v_int8), TO_HEX(v_bytes) FROM scalars ORDER BY id;

# name: to_hex_literals
SELECT TO_HEX(123456789), TO_HEX('ab'::BINARY(2)), TO_HEX(0), TO_HEX(-1);

# name: to_bitstring
SELECT id, TO_BITSTRING(v_bytes) FROM scalars ORDER BY id;

# name: to_bitstring_literals
SELECT TO_BITSTRING('ab'::BINARY(2)), TO_BITSTRING(HEX_TO_BINARY('0x10')), TO_BITSTRING(HEX_TO_BINARY('0xF0'));
