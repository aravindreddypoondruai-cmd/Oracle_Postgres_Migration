-- Phase 4 | Step 8 | Run in ORACLE as MIGLAB
-- Two metrics not captured in Phase 2D, needed for reconciliation.
SELECT SUM(DBMS_LOB.GETLENGTH(description)) AS total_chars,
       MAX(DBMS_LOB.GETLENGTH(description)) AS max_chars
FROM fee_schedule;
 
SELECT COUNT(CASE WHEN modifier_code IS NULL THEN 1 END) AS null_modifiers
FROM claim_detail;
