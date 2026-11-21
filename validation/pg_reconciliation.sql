-- Phase 4 | Step 8 | Run in POSTGRESQL as miglab_ro (read-only connection)
-- Compare every result with the Oracle Phase 2D baseline.
 
-- 8.1 Row counts (expect 236,500 total)
SELECT 'PROVIDER' AS table_name, count(*) AS row_count FROM miglab.provider
UNION ALL SELECT 'MEMBER', count(*) FROM miglab.member
UNION ALL SELECT 'FEE_SCHEDULE', count(*) FROM miglab.fee_schedule
UNION ALL SELECT 'FEE_SCHEDULE_DETAIL', count(*) FROM miglab.fee_schedule_detail
UNION ALL SELECT 'CLAIM', count(*) FROM miglab.claim
UNION ALL SELECT 'CLAIM_DETAIL', count(*) FROM miglab.claim_detail
ORDER BY 1;
 
-- 8.2 Financial totals and date range (must equal Oracle exactly)
SELECT ROUND(SUM(total_billed), 2)                 AS total_billed,
       ROUND(SUM(total_allowed), 2)                AS total_allowed,
       ROUND(SUM(total_billed - total_allowed), 2) AS total_adjustment,
       MIN(service_date)                           AS earliest_service_date,
       MAX(service_date)                           AS latest_service_date
FROM miglab.claim;
 
SELECT ROUND(SUM(billed_amount), 2)  AS detail_billed,
       ROUND(SUM(allowed_amount), 2) AS detail_allowed,
       MIN(billed_amount)            AS minimum_billed,
       MAX(billed_amount)            AS maximum_billed
FROM miglab.claim_detail;
 
SELECT claim_status,
       count(*)                     AS claim_count,
       ROUND(SUM(total_billed), 2)  AS billed_amount,
       ROUND(SUM(total_allowed), 2) AS allowed_amount
FROM miglab.claim
GROUP BY claim_status
ORDER BY 1;
 
-- 8.3 ID ranges (keys preserved)
SELECT 'PROVIDER' AS object_name, MIN(provider_id) AS min_id, MAX(provider_id) AS max_id FROM miglab.provider
UNION ALL SELECT 'MEMBER', MIN(member_id), MAX(member_id) FROM miglab.member
UNION ALL SELECT 'FEE_SCHEDULE', MIN(schedule_id), MAX(schedule_id) FROM miglab.fee_schedule
UNION ALL SELECT 'FEE_SCHEDULE_DETAIL', MIN(schedule_detail_id), MAX(schedule_detail_id) FROM miglab.fee_schedule_detail
UNION ALL SELECT 'CLAIM', MIN(claim_id), MAX(claim_id) FROM miglab.claim
UNION ALL SELECT 'CLAIM_DETAIL', MIN(claim_detail_id), MAX(claim_detail_id) FROM miglab.claim_detail;
 
-- 8.4 CLOB integrity (catches truncation)
SELECT SUM(length(description)) AS total_chars,
       MAX(length(description)) AS max_chars
FROM miglab.fee_schedule;
 
-- 8.5 NULL preservation (catches NULL -> empty-string conversion)
SELECT count(*) FILTER (WHERE modifier_code IS NULL) AS null_modifiers,
       count(*) FILTER (WHERE modifier_code = '')    AS empty_modifiers
FROM miglab.claim_detail;
 
-- 8.6 Header vs detail consistency (expect 0)
SELECT count(*) AS mismatched_claims
FROM miglab.claim c
JOIN (SELECT claim_id,
             SUM(billed_amount)  AS b,
             SUM(allowed_amount) AS a
      FROM miglab.claim_detail
      GROUP BY claim_id) d
  ON d.claim_id = c.claim_id
WHERE c.total_billed <> d.b
   OR c.total_allowed <> d.a;
 
-- 8.7 Views and converted code
SELECT count(*) AS active_fee_schedule_view FROM miglab.v_active_fee_schedule;  -- expect 450
SELECT count(*) AS claim_summary_view       FROM miglab.v_claim_summary;        -- expect 50000
 
SELECT claim_status,
       pkg_claim_admin.get_status_label(claim_status) AS status_label,
       count(*) AS claim_count
FROM miglab.claim
GROUP BY 1, 2
ORDER BY 1;
 
SELECT claim_id
FROM miglab.claim
WHERE miglab.fn_claim_balance(claim_id) <> total_billed - total_allowed
LIMIT 5;                                    -- expect no rows
 
-- 8.8 Read-only proof (this statement MUST FAIL: permission denied)
DELETE FROM miglab.provider WHERE provider_id = -1;
