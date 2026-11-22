-- Phase 5 | Step 2 | Run as postgres (superuser) - executed by 01_create_target_db.ps1
-- A separate database keeps the Phase 4 result (miglabdb) untouched and avoids
-- name clashes: both methods create schemas "miglab" and "pkg_claim_admin".
 
CREATE DATABASE miglab_ora2pg
    OWNER miglab
    ENCODING 'UTF8'
    TEMPLATE template0;
 
REVOKE ALL ON DATABASE miglab_ora2pg FROM PUBLIC;
GRANT CONNECT ON DATABASE miglab_ora2pg TO miglab, miglab_ro;
 
ALTER ROLE miglab    IN DATABASE miglab_ora2pg SET search_path = miglab, public;
ALTER ROLE miglab_ro IN DATABASE miglab_ora2pg SET search_path = miglab, public;
 
\c miglab_ora2pg
 
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
 
-- No "IN SCHEMA": applies to every schema miglab creates in this database,
-- including the schemas Ora2Pg will generate (miglab, pkg_claim_admin).
ALTER DEFAULT PRIVILEGES FOR ROLE miglab GRANT SELECT ON TABLES    TO miglab_ro;
ALTER DEFAULT PRIVILEGES FOR ROLE miglab GRANT SELECT ON SEQUENCES TO miglab_ro;
 
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
 
\l miglab_ora2pg
