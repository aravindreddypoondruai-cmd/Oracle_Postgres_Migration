-- Phase 4 | Step 5 | Run with psql INSIDE postgres-target (not DBeaver)
-- docker exec -it postgres-target psql -U miglab -d miglabdb -f /tmp/load_miglab.sql
-- Every \copy command must stay on ONE line.
\set ON_ERROR_STOP on
\timing on
 
BEGIN;
 
\copy miglab.provider (provider_id, provider_code, provider_name, specialty, state_code, active_flag, created_date, updated_timestamp) FROM '/tmp/export/provider.csv' WITH (FORMAT csv)
 
\copy miglab.member (member_id, member_number, first_name, last_name, date_of_birth, state_code, active_flag, created_date) FROM '/tmp/export/member.csv' WITH (FORMAT csv)
 
\copy miglab.fee_schedule (schedule_id, schedule_code, schedule_name, effective_date, termination_date, status, description, created_date, updated_timestamp) FROM '/tmp/export/fee_schedule.csv' WITH (FORMAT csv)
 
\copy miglab.fee_schedule_detail (schedule_detail_id, schedule_id, procedure_code, modifier_code, allowed_amount, effective_date, termination_date) FROM '/tmp/export/fee_schedule_detail.csv' WITH (FORMAT csv)
 
\copy miglab.claim (claim_id, claim_number, member_id, provider_id, service_date, received_date, claim_status, total_billed, total_allowed, created_timestamp) FROM '/tmp/export/claim.csv' WITH (FORMAT csv)
 
\copy miglab.claim_detail (claim_detail_id, claim_id, line_number, procedure_code, modifier_code, billed_amount, allowed_amount) FROM '/tmp/export/claim_detail.csv' WITH (FORMAT csv)
 
\copy miglab.migration_audit (audit_id, process_name, source_count, target_count, status, message, created_timestamp) FROM '/tmp/export/migration_audit.csv' WITH (FORMAT csv)
 
COMMIT;
