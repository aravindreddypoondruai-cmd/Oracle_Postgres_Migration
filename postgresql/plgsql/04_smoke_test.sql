-- Phase 4 | Step 7.5 | Functional smoke test - run with psql; fully rolled back
-- docker exec -it postgres-target psql -U miglab -d miglabdb -f /tmp/04_smoke_test.sql
BEGIN;
 
DO $$
DECLARE
    v_id     bigint;
    v_status varchar;
BEGIN
    SELECT MIN(claim_id) INTO v_id
    FROM miglab.claim
    WHERE claim_status = 'NEW';
 
    CALL miglab.pr_recalculate_claim(v_id);
 
    SELECT claim_status INTO v_status
    FROM miglab.claim
    WHERE claim_id = v_id;
 
    RAISE NOTICE 'claim %, status %, balance %, label %',
        v_id, v_status, miglab.fn_claim_balance(v_id),
        pkg_claim_admin.get_status_label(v_status);
END $$;
 
SELECT process_name, status, message
FROM miglab.migration_audit;
 
-- Expected: ERROR  Claim ID -1 does not exist
CALL miglab.pr_recalculate_claim(-1);
 
ROLLBACK;
 
-- After rollback: audit table back to its original count
SELECT count(*) AS audit_rows_after_rollback FROM miglab.migration_audit;
