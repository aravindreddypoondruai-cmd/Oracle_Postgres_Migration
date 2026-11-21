-- Phase 4 | Step 6 | Run in POSTGRESQL as miglab, AFTER the data load
 
-- 6.1 Foreign keys (creation validates every relationship = 0 orphans)
ALTER TABLE miglab.fee_schedule_detail
    ADD CONSTRAINT fk_fsd_schedule
    FOREIGN KEY (schedule_id) REFERENCES miglab.fee_schedule (schedule_id);
 
ALTER TABLE miglab.claim
    ADD CONSTRAINT fk_claim_member
    FOREIGN KEY (member_id) REFERENCES miglab.member (member_id);
 
ALTER TABLE miglab.claim
    ADD CONSTRAINT fk_claim_provider
    FOREIGN KEY (provider_id) REFERENCES miglab.provider (provider_id);
 
ALTER TABLE miglab.claim_detail
    ADD CONSTRAINT fk_claim_detail_claim
    FOREIGN KEY (claim_id) REFERENCES miglab.claim (claim_id);
 
-- 6.2 Secondary indexes (same names as Oracle)
CREATE INDEX idx_claim_member       ON miglab.claim (member_id);
CREATE INDEX idx_claim_provider     ON miglab.claim (provider_id);
CREATE INDEX idx_claim_service_date ON miglab.claim (service_date);
CREATE INDEX idx_claim_status       ON miglab.claim (claim_status);
CREATE INDEX idx_fsd_schedule       ON miglab.fee_schedule_detail (schedule_id);
CREATE INDEX idx_fsd_proc_code      ON miglab.fee_schedule_detail (procedure_code);
CREATE INDEX idx_claim_detail_claim ON miglab.claim_detail (claim_id);
CREATE INDEX idx_provider_specialty ON miglab.provider (specialty);
 
-- 6.3 Move identity sequences past the migrated IDs (handles empty tables)
SELECT setval(pg_get_serial_sequence('miglab.provider','provider_id'),
              COALESCE(MAX(provider_id),1), MAX(provider_id) IS NOT NULL) FROM miglab.provider;
SELECT setval(pg_get_serial_sequence('miglab.member','member_id'),
              COALESCE(MAX(member_id),1), MAX(member_id) IS NOT NULL) FROM miglab.member;
SELECT setval(pg_get_serial_sequence('miglab.fee_schedule','schedule_id'),
              COALESCE(MAX(schedule_id),1), MAX(schedule_id) IS NOT NULL) FROM miglab.fee_schedule;
SELECT setval(pg_get_serial_sequence('miglab.fee_schedule_detail','schedule_detail_id'),
              COALESCE(MAX(schedule_detail_id),1), MAX(schedule_detail_id) IS NOT NULL) FROM miglab.fee_schedule_detail;
SELECT setval(pg_get_serial_sequence('miglab.claim','claim_id'),
              COALESCE(MAX(claim_id),1), MAX(claim_id) IS NOT NULL) FROM miglab.claim;
SELECT setval(pg_get_serial_sequence('miglab.claim_detail','claim_detail_id'),
              COALESCE(MAX(claim_detail_id),1), MAX(claim_detail_id) IS NOT NULL) FROM miglab.claim_detail;
SELECT setval(pg_get_serial_sequence('miglab.migration_audit','audit_id'),
              COALESCE(MAX(audit_id),1), MAX(audit_id) IS NOT NULL) FROM miglab.migration_audit;
 
-- 6.4 Optimizer statistics (PostgreSQL equivalent of DBMS_STATS)
ANALYZE miglab.provider;
ANALYZE miglab.member;
ANALYZE miglab.fee_schedule;
ANALYZE miglab.fee_schedule_detail;
ANALYZE miglab.claim;
ANALYZE miglab.claim_detail;
ANALYZE miglab.migration_audit;
 
-- 6.5 Validation
SELECT conname, contype, conrelid::regclass AS table_name
FROM pg_constraint
WHERE connamespace = 'miglab'::regnamespace
ORDER BY 3, 2;
 
SELECT indexrelid::regclass AS index_name, indrelid::regclass AS table_name
FROM pg_index
WHERE indrelid::regclass::text LIKE 'miglab.%'
ORDER BY 2, 1;
 
SELECT relname, n_live_tup, last_analyze
FROM pg_stat_user_tables
WHERE schemaname = 'miglab'
ORDER BY relname;
