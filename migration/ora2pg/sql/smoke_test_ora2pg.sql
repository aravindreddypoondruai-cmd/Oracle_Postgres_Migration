-- Phase 5 | Functional smoke test of Ora2Pg-converted code - fully rolled back
-- Works whether Ora2Pg produced pr_recalculate_claim as a PROCEDURE or a FUNCTION.
BEGIN;
 
DO $$
DECLARE
    v_id     bigint;
    v_kind   "char";
    v_status text;
BEGIN
    SELECT min(claim_id) INTO v_id FROM miglab.claim WHERE claim_status = 'NEW';
 
    SELECT p.prokind INTO v_kind
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'miglab' AND p.proname = 'pr_recalculate_claim';
 
    RAISE NOTICE 'pr_recalculate_claim is a % (p = procedure, f = function)', v_kind;
 
    IF v_kind = 'p' THEN
        EXECUTE format('CALL miglab.pr_recalculate_claim(%s)', v_id);
    ELSE
        EXECUTE format('SELECT miglab.pr_recalculate_claim(%s)', v_id);
    END IF;
 
    SELECT claim_status INTO v_status FROM miglab.claim WHERE claim_id = v_id;
 
    RAISE NOTICE 'claim %, status %, balance %, label %',
        v_id, v_status,
        miglab.fn_claim_balance(v_id),
        pkg_claim_admin.get_status_label(v_status);
END $$;
 
SELECT process_name, status, message FROM miglab.migration_audit;
 
-- Expected to FAIL with the converted "Claim ID -1 does not exist" error
DO $$
DECLARE v_kind "char";
BEGIN
    SELECT p.prokind INTO v_kind
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'miglab' AND p.proname = 'pr_recalculate_claim';
    IF v_kind = 'p' THEN
        CALL miglab.pr_recalculate_claim(-1);
    ELSE
        PERFORM miglab.pr_recalculate_claim(-1);
    END IF;
END $$;
 
ROLLBACK;
 
SELECT count(*) AS audit_rows_after_rollback FROM miglab.migration_audit;   -- expect 0
