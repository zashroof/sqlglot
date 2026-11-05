# name: match_clause_functions
SELECT grp, id, cat, EVENT_NAME(), PATTERN_ID(), MATCH_ID() FROM facts WHERE id <= 3000 MATCH (PARTITION BY grp ORDER BY id DEFINE Entry AS cat = 'alpha', Onsite AS cat = 'beta' AND qty > 0, Purchase AS cat ILIKE 'delta' PATTERN P AS (Entry Onsite* Purchase) ROWS MATCH FIRST EVENT) ORDER BY grp, id;

# name: match_first_event_overlapping
SELECT id, cat, event_name(), match_id() FROM facts WHERE id <= 300 MATCH (ORDER BY id DEFINE b AS cat = 'beta', a AS cat IS NOT NULL PATTERN p AS (a b+) ROWS MATCH FIRST EVENT) ORDER BY id;

# name: match_all_events_alternation
SELECT id, event_name(), pattern_id(), match_id() FROM join_left MATCH (ORDER BY id DEFINE lo AS id < 3, hi AS id >= 3 PATTERN p AS (lo+ hi? | hi) ROWS MATCH ALL EVENTS) ORDER BY id;

# name: match_reluctant_quantifiers
SELECT id, event_name(), match_id() FROM facts WHERE id <= 200 MATCH (ORDER BY id DEFINE x AS qty < 500, y AS qty >= 500, z AS qty IS NULL PATTERN p AS (x+? y*? z?? y) ) ORDER BY id;

# name: match_possessive_quantifiers
SELECT id, event_name(), match_id() FROM facts WHERE id <= 200 MATCH (ORDER BY id DEFINE x AS qty < 500, y AS qty >= 500, z AS qty IS NULL PATTERN p AS (x++ y*+ z?+)) ORDER BY id;

# name: match_partition_multiple_columns
SELECT flag, grp, id, event_name(), match_id() FROM facts WHERE id <= 1000 AND grp < 3 MATCH (PARTITION BY flag, grp ORDER BY ts DESC DEFINE up AS score > 50, down AS score <= 50 PATTERN p AS (up down+ up)) ORDER BY flag, grp, id;

# name: match_in_subquery
SELECT ev, COUNT(*), MAX(mid) FROM (SELECT id, event_name() AS ev, match_id() AS mid FROM facts WHERE id <= 2000 MATCH (PARTITION BY grp ORDER BY id DEFINE a AS cat = 'alpha', b AS cat <> 'alpha' PATTERN p AS (a b)) ) AS m GROUP BY ev ORDER BY ev;
