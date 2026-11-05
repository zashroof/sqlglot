# name: current_database
SELECT CURRENT_DATABASE, CURRENT_DATABASE(), DBNAME(), CURRENT_DATABASE() = DBNAME();

# name: current_schema
SELECT CURRENT_SCHEMA, CURRENT_SCHEMA();

# name: current_user
SELECT CURRENT_USER, CURRENT_USER(), SESSION_USER, SESSION_USER(), USER, USER(), USERNAME(), CURRENT_USER = SESSION_USER;

# name: current_user_in_query
SELECT id, val, CURRENT_USER = 'dbadmin', USERNAME() || ':' || val FROM join_left WHERE USER() = 'dbadmin' ORDER BY id;

# name: version
SELECT VERSION() LIKE 'Vertica Analytic Database v%', LENGTH(VERSION()) > 30;

# name: current_session
SELECT LENGTH(CURRENT_SESSION()) > 0, CURRENT_SESSION() LIKE '%:0x%';

# name: current_trans_id
SELECT CURRENT_TRANS_ID() > 0, CURRENT_TRANS_ID() IS NOT NULL;

# name: current_load_source
SELECT CURRENT_LOAD_SOURCE() IS NULL, COALESCE(CURRENT_LOAD_SOURCE(), 'none');

# name: has_table_privilege
SELECT HAS_TABLE_PRIVILEGE('public.scalars', 'SELECT'), HAS_TABLE_PRIVILEGE('dbadmin', 'conformance.public.scalars', 'INSERT'), HAS_TABLE_PRIVILEGE('scalars', 'DELETE');

# name: throw_error_not_evaluated
SELECT CASE WHEN FALSE THEN THROW_ERROR('Failure!!!') ELSE 'ok' END;

# name: throw_error_in_branch
SELECT id, CASE WHEN id > 100 THEN THROW_ERROR('Failure at "' || val || '"') ELSE val END FROM join_left ORDER BY id;
