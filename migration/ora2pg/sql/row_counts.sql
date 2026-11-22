-- Phase 5 | Row counts in the current database (expect 236,500 business rows)
SELECT 'PROVIDER' AS table_name, count(*) AS row_count FROM miglab.provider
UNION ALL SELECT 'MEMBER', count(*) FROM miglab.member
UNION ALL SELECT 'FEE_SCHEDULE', count(*) FROM miglab.fee_schedule
UNION ALL SELECT 'FEE_SCHEDULE_DETAIL', count(*) FROM miglab.fee_schedule_detail
UNION ALL SELECT 'CLAIM', count(*) FROM miglab.claim
UNION ALL SELECT 'CLAIM_DETAIL', count(*) FROM miglab.claim_detail
UNION ALL SELECT 'MIGRATION_AUDIT', count(*) FROM miglab.migration_audit
ORDER BY 1;
