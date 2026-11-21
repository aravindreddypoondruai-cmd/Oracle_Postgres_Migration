-- Phase 4 | Step 7.1 | Run in POSTGRESQL as miglab
-- NVL -> COALESCE, DECODE -> CASE
CREATE OR REPLACE VIEW miglab.v_active_fee_schedule AS
SELECT fs.schedule_id,
       fs.schedule_code,
       fs.schedule_name,
       fs.effective_date,
       fs.termination_date,
       COALESCE(fs.termination_date, DATE '2999-12-31') AS effective_end_date,
       fs.status,
       COUNT(fsd.schedule_detail_id)        AS detail_count,
       COALESCE(AVG(fsd.allowed_amount), 0) AS average_allowed_amount
FROM miglab.fee_schedule fs
LEFT JOIN miglab.fee_schedule_detail fsd
       ON fsd.schedule_id = fs.schedule_id
WHERE fs.status = 'ACTIVE'
GROUP BY fs.schedule_id, fs.schedule_code, fs.schedule_name,
         fs.effective_date, fs.termination_date, fs.status;
 
CREATE OR REPLACE VIEW miglab.v_claim_summary AS
SELECT c.claim_id,
       c.claim_number,
       m.member_number,
       p.provider_code,
       p.provider_name,
       c.service_date,
       c.claim_status,
       CASE c.claim_status
            WHEN 'NEW'        THEN 'Pending Intake'
            WHEN 'PROCESSING' THEN 'Under Review'
            WHEN 'PAID'       THEN 'Completed'
            WHEN 'DENIED'     THEN 'Rejected'
            ELSE 'Unknown'
       END                                                         AS status_description,
       COALESCE(c.total_billed, 0)                                 AS total_billed,
       COALESCE(c.total_allowed, 0)                                AS total_allowed,
       COALESCE(c.total_billed, 0) - COALESCE(c.total_allowed, 0)  AS adjustment_amount
FROM miglab.claim c
JOIN miglab.member   m ON m.member_id   = c.member_id
JOIN miglab.provider p ON p.provider_id = c.provider_id;
