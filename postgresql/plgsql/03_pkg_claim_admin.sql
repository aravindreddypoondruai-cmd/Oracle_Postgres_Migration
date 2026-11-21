-- Phase 4 | Step 7.4 | Oracle package PKG_CLAIM_ADMIN -> schema pkg_claim_admin
CREATE SCHEMA IF NOT EXISTS pkg_claim_admin AUTHORIZATION miglab;
GRANT USAGE ON SCHEMA pkg_claim_admin TO miglab_ro;
 
-- DECODE -> CASE; pure function so IMMUTABLE
CREATE OR REPLACE FUNCTION pkg_claim_admin.get_status_label(p_status varchar)
RETURNS varchar
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE p_status
                WHEN 'NEW'        THEN 'Pending Intake'
                WHEN 'PROCESSING' THEN 'Under Review'
                WHEN 'PAID'       THEN 'Completed'
                WHEN 'DENIED'     THEN 'Rejected'
                ELSE 'Unknown'
           END;
$$;
 
-- MERGE: no DUAL; TRUNC(date) -> ::date; no target alias in UPDATE SET
CREATE OR REPLACE PROCEDURE pkg_claim_admin.upsert_audit(
    p_process_name varchar,
    p_source_count bigint,
    p_target_count bigint,
    p_status       varchar,
    p_message      varchar)
LANGUAGE plpgsql
AS $$
BEGIN
    MERGE INTO miglab.migration_audit a
    USING (SELECT p_process_name AS process_name) s
       ON a.process_name = s.process_name
      AND a.created_timestamp::date = current_date
    WHEN MATCHED THEN
        UPDATE SET source_count      = p_source_count,
                   target_count      = p_target_count,
                   status            = p_status,
                   message           = p_message,
                   created_timestamp = localtimestamp
    WHEN NOT MATCHED THEN
        INSERT (process_name, source_count, target_count,
                status, message, created_timestamp)
        VALUES (p_process_name, p_source_count, p_target_count,
                p_status, p_message, localtimestamp);
END;
$$;
 
-- Cursor FOR loop -> FOR r IN SELECT loop; procedure calls use CALL
CREATE OR REPLACE PROCEDURE pkg_claim_admin.recalculate_open_claims()
LANGUAGE plpgsql
AS $$
DECLARE
    r       record;
    l_count bigint := 0;
BEGIN
    FOR r IN SELECT claim_id
               FROM miglab.claim
              WHERE claim_status IN ('NEW', 'PROCESSING')
    LOOP
        CALL miglab.pr_recalculate_claim(r.claim_id);
        l_count := l_count + 1;
    END LOOP;
 
    CALL pkg_claim_admin.upsert_audit('RECALCULATE_OPEN_CLAIMS', l_count, l_count,
                                      'SUCCESS', 'Open claims processed successfully');
EXCEPTION
    WHEN OTHERS THEN
        CALL pkg_claim_admin.upsert_audit('RECALCULATE_OPEN_CLAIMS', l_count, 0,
                                          'FAILED', left(SQLERRM, 4000));
        RAISE;
END;
$$;
 
-- Validation: list converted routines (f = function, p = procedure)
SELECT n.nspname AS schema_name, p.proname, p.prokind
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname IN ('miglab', 'pkg_claim_admin')
ORDER BY 1, 2;
