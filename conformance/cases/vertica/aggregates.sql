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
