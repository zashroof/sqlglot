# name: abs_sign
SELECT id, ABS(v_int8), ABS(v_float8), ABS(v_dec), SIGN(v_float8), SIGN(v_int4), SIGN(v_dec) FROM scalars WHERE id <= 12 ORDER BY id;

# name: abs_sign_literals
SELECT ABS(-28.7), ABS(-5), ABS(0.0), SIGN(-8.4), SIGN(0), SIGN(3);

# name: trig
SELECT ACOS(1), ACOS(0.5), ASIN(1), ASIN(-0.5), ATAN(1), ATAN(-2), ATAN2(2, 1), ATAN2(-1, -1), COS(-1), SIN(30 * 2 * 3.14159 / 360), TAN(30), COT(1), PI();

# name: trig_columns
SELECT id, SIN(score), COS(score), TAN(score), COT(score), ATAN(score), ATAN2(score, qty), ASIN(score / 200), ACOS(score / 200) FROM facts WHERE id <= 50 ORDER BY id;

# name: trig_float_edge_cases
SELECT id, SIN(v_float8), COS(v_float8), ATAN(v_float8), ATAN2(v_float8, 1) FROM scalars WHERE id IN (1, 2, 3, 5, 8, 9, 12) ORDER BY id;

# name: hyperbolic
SELECT ACOSH(4), ACOSH(1), ASINH(2.85), ASINH(-1), ATANH(-0.875), ATANH(0), COSH(-1), SINH(30 * 2 * 3.14159 / 360), TANH(-1), SINH(0);

# name: hyperbolic_columns
SELECT id, SINH(score / 10), COSH(score / 10), TANH(score / 10), ASINH(score), ACOSH(ABS(score) + 1), ATANH(score / 200) FROM facts WHERE id <= 50 ORDER BY id;

# name: degrees_radians
SELECT DEGREES(0.5), DEGREES(PI()), DEGREES(1, 2, 3), DEGREES(-10, 30, 0), RADIANS(45), RADIANS(180), RADIANS(1, 2, 3), RADIANS(-10, 30, 0);

# name: degrees_radians_columns
SELECT id, DEGREES(score), RADIANS(score), DEGREES(grp, qty, score), RADIANS(grp, qty, score) FROM facts WHERE id <= 50 ORDER BY id;

# name: distance
SELECT DISTANCE(45, 0, 45, 1), DISTANCE(45, 0, 45, 1, 6371.009), DISTANCE(0, 0, 0, 180), DISTANCE(0, 0, 0, 0), DISTANCEV(45, 0, 45, 1), DISTANCEV(52.5, 13.4, 48.85, 2.35);

# name: distance_columns
SELECT id, DISTANCE(score - 50, qty / 10, 0, 0), DISTANCE(score - 50, qty / 10, 10, 10, 6378.137), DISTANCEV(score - 50, qty / 10, 10, 10) FROM facts WHERE id <= 50 AND qty IS NOT NULL ORDER BY id;

# name: exp_log
SELECT EXP(1.0), EXP(0), EXP(-1), LN(2), LN(EXP(3)), LOG(100), LOG(2.0, 64), LOG(10, 1000), LOG10(30), LOG10(1000), CBRT(27.0), CBRT(-8), SQRT(2), SQRT(16.0);

# name: exp_log_columns
SELECT id, EXP(score / 100), LN(qty), LOG(qty), LOG(2, qty), LOG(qty, 1000), LOG10(qty), SQRT(qty), CBRT(score) FROM facts WHERE qty > 1 AND id <= 50 ORDER BY id;

# name: exp_log_decimals
SELECT id, EXP(v_dec / 10000), LN(v_dec), LOG(v_dec), LOG10(v_dec), SQRT(v_dec), CBRT(v_dec) FROM scalars WHERE v_dec > 0 ORDER BY id;

# name: ceil_floor
SELECT CEIL(-42.8), CEILING(48.01), CEIL(5.01), FLOOR(-42.8), FLOOR(42.8), FLOOR(5.99), FLOOR(1 << 49), CEIL(-0.5::FLOAT), FLOOR(7);

# name: ceil_floor_columns
SELECT id, CEIL(v_dec), CEILING(v_float8), FLOOR(v_dec), FLOOR(v_float8), CEIL(v_int8), FLOOR(v_dec38) FROM scalars WHERE id <= 12 ORDER BY id;

# name: power
SELECT POWER(9.0, 3.0), POW(2, 10), POWER(2, -1), POWER(4, 0.5), POW(0, 0), POWER(-2, 3), POW(1.5, 2.5);

# name: power_columns
SELECT id, POWER(score, 2), POW(qty, 0.5), POWER(1.01, grp) FROM facts WHERE id <= 50 AND qty >= 0 ORDER BY id;

# name: mod
SELECT MOD(9, 4), MOD(10, 3), MOD(-10, 3), MOD(-10, -3), MOD(10, -3), MOD(5.5, 2), MOD(-7.25, 2.5);

# name: mod_columns
SELECT id, MOD(v_int8, 7), MOD(v_dec, 3), MOD(v_int4, -5), MOD(v_dec38, 0.7) FROM scalars WHERE v_int4 IS NOT NULL ORDER BY id;

# name: mod_expressions
SELECT id, MOD(qty + 3, grp + 1) * 2, -MOD(qty, 7), MOD(qty, 7) ^ 2 FROM facts WHERE id <= 50 ORDER BY id;

# name: round_places
SELECT ROUND(3.5), ROUND(2.0, 1.0), ROUND(12.345, 2.0), ROUND(3.444444444444444), ROUND(3.14159, 3), ROUND(1234567, -3), ROUND(3.4999, -1);

# name: round_columns
SELECT id, ROUND(v_dec), ROUND(v_dec, 1), ROUND(v_dec, -2), ROUND(v_float8, 2), ROUND(v_dec38, 5), ROUND(v_int8, -3) FROM scalars WHERE id <= 12 ORDER BY id;

# name: round_float_columns
SELECT id, ROUND(score), ROUND(score, 2), ROUND(score, -1), ROUND(price, 1) FROM facts WHERE id <= 50 ORDER BY id;

# name: trunc_places
SELECT TRUNC(3.5), TRUNC(42.8), TRUNC(42.4382, 2), TRUNC(1234567, -3), TRUNC(-3.789, 1), TRUNC(1234567.0, -4), TRUNC(0.1234567, 5);

# name: trunc_columns
SELECT id, TRUNC(v_dec), TRUNC(v_dec, 1), TRUNC(v_dec, -2), TRUNC(v_float8, 3), TRUNC(v_dec38, 4), TRUNC(v_int8, -4) FROM scalars WHERE id <= 12 ORDER BY id;

# name: hash
SELECT id, HASH(k, val), HASH(val), HASH(k), HASH(*) FROM join_left ORDER BY id;

# name: hash_literals
SELECT HASH(1, 'a'), HASH('a', 1), HASH(NULL), HASH(1.5, DATE '2024-01-01') >= 0;

# name: random
SELECT RANDOM() >= 0 AND RANDOM() < 1, RANDOMINT(5) BETWEEN 0 AND 4, RANDOMINT_CRYPTO(5) BETWEEN 0 AND 4, RANDOMINT(1), RANDOMINT_CRYPTO(1);

# name: random_rows
SELECT COUNT(*), COUNT(CASE WHEN RANDOM() < 1 THEN 1 END), MAX(RANDOMINT(10)) < 10, MIN(RANDOMINT_CRYPTO(3)) >= 0 FROM facts;

# name: width_bucket
SELECT id, WIDTH_BUCKET(score, 0, 100, 5), WIDTH_BUCKET(qty, 0, 1000, 4), WIDTH_BUCKET(price, 100, 70000, 3) FROM facts WHERE id <= 50 ORDER BY id;

# name: width_bucket_literals
SELECT WIDTH_BUCKET(5, 0, 10, 3), WIDTH_BUCKET(-1, 0, 10, 3), WIDTH_BUCKET(10, 0, 10, 3), WIDTH_BUCKET(2.5, 0, 10, 4), WIDTH_BUCKET(NULL, 0, 10, 3);

# name: width_bucket_datetime
SELECT id, WIDTH_BUCKET(d, DATE '2020-01-01', DATE '2025-01-01', 5), WIDTH_BUCKET(ts, TIMESTAMP '2020-01-01', TIMESTAMP '2025-01-01', 10), WIDTH_BUCKET(d, TIMESTAMP '2020-01-01', DATE '2025-01-01', 3) FROM facts WHERE id <= 50 ORDER BY id;

# name: width_bucket_interval_time
SELECT id, WIDTH_BUCKET(v_interval, INTERVAL '0' DAY, INTERVAL '2' DAY, 4), WIDTH_BUCKET(v_time, TIME '00:00:00', TIME '23:59:59', 4) FROM vertica_extras ORDER BY id;

# name: round_typed_float
SELECT id, ROUND(v_float8::FLOAT, 2), ROUND(CAST(v_float8 AS DOUBLE PRECISION), -1), ROUND(-2.5::FLOAT, 0) FROM scalars WHERE id <= 12 ORDER BY id;
