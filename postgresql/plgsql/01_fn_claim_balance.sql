-- Phase 4 | Step 7.2 | Oracle FN_CLAIM_BALANCE -> PL/pgSQL
-- NO_DATA_FOUND exception -> IF NOT FOUND
CREATE OR REPLACE FUNCTION miglab.fn_claim_balance(p_claim_id bigint)
RETURNS numeric
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    l_balance numeric(14,2);
BEGIN
    SELECT COALESCE(total_billed, 0) - COALESCE(total_allowed, 0)
      INTO l_balance
      FROM miglab.claim
     WHERE claim_id = p_claim_id;
 
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
 
    RETURN l_balance;
END;
$$;
