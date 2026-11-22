-- Leftover test rows from Phase 2C smoke tests (expect 0, 0, 0)
SELECT
  (SELECT COUNT(*) FROM provider WHERE provider_code LIKE 'TEST-%') AS test_providers,
  (SELECT COUNT(*) FROM member   WHERE member_number LIKE 'TEST-%') AS test_members,
  (SELECT COUNT(*) FROM claim    WHERE claim_number  LIKE 'TEST-%') AS test_claims
FROM dual;
 
-- Audit rows (expect 0 unless you deliberately kept some)
SELECT COUNT(*) AS audit_rows FROM migration_audit;
 
-- Business row total (expect 236,500)
SELECT (SELECT COUNT(*) FROM provider) + (SELECT COUNT(*) FROM member)
     + (SELECT COUNT(*) FROM fee_schedule) + (SELECT COUNT(*) FROM fee_schedule_detail)
     + (SELECT COUNT(*) FROM claim) + (SELECT COUNT(*) FROM claim_detail) AS business_rows
FROM dual;
 
-- Invalid objects (expect no rows)
SELECT object_type, object_name FROM user_objects WHERE status <> 'VALID';
