-- Exports all MIGLAB tables to CSV in /tmp/export
SET MARKUP CSV ON QUOTE ON
SET HEADING OFF
SET FEEDBACK OFF
SET TERMOUT OFF
SET TRIMSPOOL ON
SET PAGESIZE 0
SET NUMWIDTH 20
SET LONG 1000000
SET LONGCHUNKSIZE 1000000
 
ALTER SESSION SET NLS_DATE_FORMAT        = 'YYYY-MM-DD HH24:MI:SS';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT   = 'YYYY-MM-DD HH24:MI:SS.FF6';
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';
 
SPOOL /tmp/export/provider.csv
SELECT provider_id, provider_code, provider_name, specialty, state_code,
       active_flag, created_date, updated_timestamp
FROM provider ORDER BY provider_id;
SPOOL OFF
 
SPOOL /tmp/export/member.csv
SELECT member_id, member_number, first_name, last_name, date_of_birth,
       state_code, active_flag, created_date
FROM member ORDER BY member_id;
SPOOL OFF
 
SPOOL /tmp/export/fee_schedule.csv
SELECT schedule_id, schedule_code, schedule_name, effective_date,
       termination_date, status, description, created_date, updated_timestamp
FROM fee_schedule ORDER BY schedule_id;
SPOOL OFF
 
SPOOL /tmp/export/fee_schedule_detail.csv
SELECT schedule_detail_id, schedule_id, procedure_code, modifier_code,
       allowed_amount, effective_date, termination_date
FROM fee_schedule_detail ORDER BY schedule_detail_id;
SPOOL OFF
 
SPOOL /tmp/export/claim.csv
SELECT claim_id, claim_number, member_id, provider_id, service_date,
       received_date, claim_status, total_billed, total_allowed, created_timestamp
FROM claim ORDER BY claim_id;
SPOOL OFF
 
SPOOL /tmp/export/claim_detail.csv
SELECT claim_detail_id, claim_id, line_number, procedure_code, modifier_code,
       billed_amount, allowed_amount
FROM claim_detail ORDER BY claim_detail_id;
SPOOL OFF
 
SPOOL /tmp/export/migration_audit.csv
SELECT audit_id, process_name, source_count, target_count, status,
       message, created_timestamp
FROM migration_audit ORDER BY audit_id;
SPOOL OFF
 
EXIT
