# name: basic
SELECT COUNT(*), COUNT(qty), COUNT(DISTINCT grp), SUM(qty), AVG(qty), MIN(qty), MAX(qty) FROM facts;

# name: decimal_and_float
SELECT SUM(price), AVG(price), MIN(price), MAX(price), SUM(score), AVG(score) FROM facts;

# name: group_by
SELECT grp, COUNT(*), SUM(price), AVG(qty), MIN(d), MAX(ts) FROM facts GROUP BY grp ORDER BY grp;

# name: statistics
SELECT STDDEV(score), VARIANCE(score), STDDEV_POP(score), VAR_POP(score), STDDEV_SAMP(qty) FROM facts;

# name: correlation
SELECT CORR(qty, score), COVAR_POP(qty, score), COVAR_SAMP(qty, score), REGR_SLOPE(score, qty) FROM facts;

# name: boolean_aggregates
SELECT grp, BOOL_AND(flag), BOOL_OR(flag) FROM facts GROUP BY grp ORDER BY grp;

# name: listagg
SELECT grp, LISTAGG(cat USING PARAMETERS separator='|') WITHIN GROUP (ORDER BY id) FROM facts WHERE id <= 40 GROUP BY grp ORDER BY grp;

# name: listagg_default_separator
SELECT grp, LISTAGG(cat) WITHIN GROUP (ORDER BY id) FROM facts WHERE id <= 40 GROUP BY grp ORDER BY grp;

# name: rollup
SELECT grp, cat, COUNT(*) FROM facts WHERE grp < 3 AND cat IS NOT NULL GROUP BY ROLLUP (grp, cat) ORDER BY grp, cat;

# name: grouping_sets
SELECT grp, flag, COUNT(*), GROUPING_ID(grp, flag) FROM facts WHERE grp < 3 AND flag IS NOT NULL GROUP BY GROUPING SETS ((grp), (flag), ()) ORDER BY grp, flag;

# name: having
SELECT grp, COUNT(*) FROM facts GROUP BY grp HAVING COUNT(*) > 100 ORDER BY grp;

# name: distinct_aggregates
SELECT SUM(DISTINCT grp), AVG(DISTINCT qty), COUNT(DISTINCT cat) FROM facts;

# name: empty_input
SELECT COUNT(*), SUM(qty), AVG(qty), MAX(cat) FROM facts WHERE id < 0;

# name: all_and_distinct
SELECT grp, COUNT(ALL qty), COUNT(DISTINCT qty), SUM(ALL qty), SUM(DISTINCT qty), AVG(ALL price), AVG(DISTINCT price) FROM facts GROUP BY grp ORDER BY grp;

# name: count_forms
SELECT grp, COUNT(*), COUNT(1), COUNT(cat), COUNT(DISTINCT cat), COUNT(DISTINCT qty + grp) FROM facts GROUP BY grp ORDER BY grp;

# name: min_max_types
SELECT grp, MIN(cat), MAX(cat), MIN(d), MAX(d), MIN(ts), MAX(ts), MIN(flag), MAX(flag), MIN(score), MAX(price) FROM facts GROUP BY grp ORDER BY grp;

# name: min_max_scalars
SELECT MIN(v_text), MAX(v_text), MIN(v_float8), MAX(v_float8), MIN(v_dec38), MAX(v_dec38), MIN(v_tstz), MAX(v_tstz), MIN(v_bool), MAX(v_bool) FROM scalars;

# name: sum_float
SELECT grp, SUM_FLOAT(score), SUM_FLOAT(ALL qty), SUM_FLOAT(DISTINCT qty), SUM_FLOAT(price) FROM facts GROUP BY grp ORDER BY grp;

# name: sum_avg_scalars
SELECT SUM(v_int8), AVG(v_int4), SUM(v_dec), AVG(v_dec38), SUM(v_float8), AVG(v_float8) FROM scalars WHERE ABS(v_float8) < 1e300 AND ABS(v_int8) < 1000000000000;

# name: variance_family
# rel_tol: 1e-6
SELECT grp, VARIANCE(qty), VAR_SAMP(qty), VAR_POP(qty), STDDEV(price), STDDEV_SAMP(price), STDDEV_POP(price) FROM facts GROUP BY grp ORDER BY grp;

# name: variance_single_row
SELECT VARIANCE(qty), VAR_SAMP(qty), VAR_POP(qty), STDDEV(qty), STDDEV_SAMP(qty), STDDEV_POP(qty) FROM facts WHERE id = 1;

# name: covariance
# rel_tol: 1e-6
SELECT grp, CORR(score, qty), COVAR_POP(score, qty), COVAR_SAMP(score, qty) FROM facts GROUP BY grp ORDER BY grp;

# name: regression
# rel_tol: 1e-6
SELECT REGR_AVGX(score, qty), REGR_AVGY(score, qty), REGR_COUNT(score, qty), REGR_INTERCEPT(score, qty), REGR_R2(score, qty), REGR_SLOPE(score, qty), REGR_SXX(score, qty), REGR_SXY(score, qty), REGR_SYY(score, qty) FROM facts;

# name: regression_grouped
# rel_tol: 1e-6
SELECT grp, REGR_COUNT(price, score), REGR_AVGX(price, score), REGR_AVGY(price, score), REGR_SLOPE(price, score), REGR_INTERCEPT(price, score), REGR_R2(price, score) FROM facts GROUP BY grp ORDER BY grp;

# name: bool_xor
SELECT grp, BOOL_AND(flag), BOOL_OR(flag), BOOL_XOR(flag), BOOL_AND(cat = 'alpha'), BOOL_OR(cat = 'alpha'), BOOL_XOR(qty > 500) FROM facts GROUP BY grp ORDER BY grp;

# name: bool_xor_pairs
SELECT g, BOOL_AND(b), BOOL_OR(b), BOOL_XOR(b) FROM (SELECT 1 AS g, TRUE AS b UNION ALL SELECT 1, TRUE UNION ALL SELECT 2, TRUE UNION ALL SELECT 2, FALSE UNION ALL SELECT 3, FALSE UNION ALL SELECT 3, NULL) AS t GROUP BY g ORDER BY g;

# name: bit_aggregates
SELECT TO_HEX(BIT_AND(v_bytes)), TO_HEX(BIT_OR(v_bytes)), TO_HEX(BIT_XOR(v_bytes)) FROM scalars;

# name: bit_aggregates_lengths
SELECT g, TO_HEX(BIT_AND(c)), TO_HEX(BIT_OR(c)), TO_HEX(BIT_XOR(c)) FROM (SELECT 1 AS g, HEX_TO_BINARY('0xFF00') AS c UNION ALL SELECT 1, HEX_TO_BINARY('0xFFFF') UNION ALL SELECT 1, HEX_TO_BINARY('0xF00F') UNION ALL SELECT 2, HEX_TO_BINARY('0xFF') UNION ALL SELECT 2, NULL UNION ALL SELECT 2, HEX_TO_BINARY('0x0F0F')) AS t GROUP BY g ORDER BY g;

# name: argmax_argmin
SELECT grp, ARGMAX_AGG(id, qty), ARGMIN_AGG(id, qty), ARGMAX_AGG(ts, cat), ARGMIN_AGG(price, d) FROM facts GROUP BY grp ORDER BY grp;

# name: argmax_argmin_within_group
SELECT grp, ARGMAX_AGG(qty, id) WITHIN GROUP (ORDER BY id), ARGMAX_AGG(qty, id) WITHIN GROUP (ORDER BY id DESC), ARGMIN_AGG(qty, id) WITHIN GROUP (ORDER BY ts ASC, id DESC) FROM facts WHERE id <= 300 GROUP BY grp ORDER BY grp;

# name: argmax_within_group_nulls
SELECT g, ARGMAX_AGG(v, k) WITHIN GROUP (ORDER BY o NULLS FIRST), ARGMAX_AGG(v, k) WITHIN GROUP (ORDER BY o NULLS LAST), ARGMIN_AGG(v, k) WITHIN GROUP (ORDER BY o DESC NULLS LAST), ARGMIN_AGG(v, k) WITHIN GROUP (ORDER BY o DESC NULLS FIRST), ARGMIN_AGG(v, k) WITHIN GROUP (ORDER BY o DESC) FROM (SELECT 1 AS g, 5 AS v, 'a' AS k, 1 AS o UNION ALL SELECT 1, 5, 'b', NULL UNION ALL SELECT 1, 5, 'c', 2 UNION ALL SELECT 1, 1, 'd', 3) AS t GROUP BY g ORDER BY g;

# name: argmax_within_group_nulls_auto
SELECT grp, ARGMAX_AGG(qty, id) WITHIN GROUP (ORDER BY id NULLS AUTO), ARGMIN_AGG(qty, id) WITHIN GROUP (ORDER BY id DESC NULLS AUTO) FROM facts WHERE id <= 300 GROUP BY grp ORDER BY grp;

# name: listagg_parameters
SELECT grp, LISTAGG(cat USING PARAMETERS max_length=40, on_overflow='TRUNCATE') WITHIN GROUP (ORDER BY id) FROM facts WHERE grp < 5 GROUP BY grp ORDER BY grp;

# name: listagg_all_parameters
SELECT grp, LISTAGG(cat || ':' || id USING PARAMETERS separator=' | ', max_length=2000, on_overflow='ERROR') WITHIN GROUP (ORDER BY cat DESC, id) FROM facts WHERE id <= 60 GROUP BY grp ORDER BY grp;

# name: listagg_empty_separator
SELECT grp, LISTAGG(cat USING PARAMETERS separator='') WITHIN GROUP (ORDER BY id DESC) FROM facts WHERE id <= 40 GROUP BY grp ORDER BY grp;

# name: listagg_within_group_nulls
SELECT grp, LISTAGG(id USING PARAMETERS separator=',') WITHIN GROUP (ORDER BY cat NULLS FIRST, id), LISTAGG(id) WITHIN GROUP (ORDER BY cat DESC NULLS LAST, id) FROM facts WHERE id <= 60 GROUP BY grp ORDER BY grp;

# name: grouping_functions
SELECT grp, cat, COUNT(*), GROUPING(grp), GROUPING(cat), GROUPING_ID(grp, cat), GROUPING_ID(), GROUP_ID() FROM facts WHERE grp < 3 AND cat IS NOT NULL GROUP BY ROLLUP (grp, cat) ORDER BY grp, cat, GROUPING_ID();

# name: group_id_duplicates
SELECT grp, cat, COUNT(*), GROUPING_ID(grp, cat), GROUP_ID() FROM facts WHERE grp < 3 AND cat IS NOT NULL GROUP BY grp, ROLLUP (grp, cat) ORDER BY grp, cat, GROUPING_ID(), GROUP_ID();

# name: aggregates_in_order_by
SELECT grp, SUM(qty) FROM facts WHERE grp IS NOT NULL GROUP BY grp ORDER BY SUM(qty) DESC, COUNT(*), grp;

# name: aggregate_of_expression
SELECT grp, SUM(qty * 2 + 1), AVG(price / 100), MAX(LENGTH(cat)), COUNT(DISTINCT grp + qty) FROM facts GROUP BY grp ORDER BY grp;

# name: empty_input_all
SELECT COUNT(qty), MIN(d), MAX(ts), SUM_FLOAT(score), VARIANCE(qty), STDDEV_POP(qty), CORR(score, qty), REGR_COUNT(score, qty), REGR_SLOPE(score, qty), BOOL_AND(flag), BOOL_XOR(flag), ARGMAX_AGG(qty, id), LISTAGG(cat) FROM facts WHERE id < 0;
