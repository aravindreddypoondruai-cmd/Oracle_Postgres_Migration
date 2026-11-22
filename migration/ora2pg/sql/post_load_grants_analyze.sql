-- Phase 5 | Final post-load step - run as miglab in miglab_ora2pg
-- Schema USAGE cannot be covered by default privileges, so grant it explicitly.
GRANT USAGE ON SCHEMA miglab TO miglab_ro;
 
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'pkg_claim_admin') THEN
        EXECUTE 'GRANT USAGE ON SCHEMA pkg_claim_admin TO miglab_ro';
    END IF;
END $$;
 
-- Safety net for any object created before default privileges applied
GRANT SELECT ON ALL TABLES    IN SCHEMA miglab TO miglab_ro;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA miglab TO miglab_ro;
 
-- Optimizer statistics for every table miglab owns in this database
ANALYZE;
 
SELECT relname, n_live_tup, last_analyze
FROM pg_stat_user_tables
WHERE schemaname = 'miglab'
ORDER BY relname;
