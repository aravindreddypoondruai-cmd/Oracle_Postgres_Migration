-- Phase 4 | Step 7.3 | Oracle PR_RECALCULATE_CLAIM -> PL/pgSQL procedure
-- SQL%ROWCOUNT -> FOUND, RAISE_APPLICATION_ERROR -> RAISE EXCEPTION,
-- SYSTIMESTAMP -> clock_timestamp(), SUBSTR -> left
CREATE OR REPLACE PROCEDURE miglab.pr_recalculate_claim(p_claim_id bigint)
LANGUAGE plpgsql
AS $$
DECLARE
    l_billed  numeric(14,2);
    l_allowed numeric(14,2);
BEGIN
    SELECT COALESCE(SUM(billed_amount), 0),
           COALESCE(SUM(allowed_amount), 0)
      INTO l_billed, l_allowed
      FROM miglab.claim_detail
     WHERE claim_id = p_claim_id;
 
    UPDATE miglab.claim
       SET total_billed  = l_billed,
           total_allowed = l_allowed,
           claim_status  = CASE claim_status WHEN 'NEW' THEN 'PROCESSING'
                                             ELSE claim_status END
     WHERE claim_id = p_claim_id;
 
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Claim ID % does not exist', p_claim_id
              USING ERRCODE = 'P0001';
    END IF;
 
    INSERT INTO miglab.migration_audit
           (process_name, source_count, target_count, status, message)
    VALUES ('PR_RECALCULATE_CLAIM', 1, 1, 'SUCCESS',
            'Claim ' || p_claim_id || ' recalculated at ' ||
            to_char(clock_timestamp(), 'YYYY-MM-DD HH24:MI:SS.US'));
 
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO miglab.migration_audit
               (process_name, source_count, target_count, status, message)
        VALUES ('PR_RECALCULATE_CLAIM', 1, 0, 'FAILED', left(SQLERRM, 4000));
        RAISE;
END;
$$;
