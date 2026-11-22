-- Phase 5 | Fallback if Ora2Pg SEQUENCE_VALUES was not generated.
-- Ora2Pg keeps the Oracle sequences as standalone sequences, so we position
-- each one after the highest migrated ID (is_called = true -> next value = max+1).
SELECT setval('miglab.seq_provider',            COALESCE((SELECT max(provider_id)        FROM miglab.provider), 1));
SELECT setval('miglab.seq_member',              COALESCE((SELECT max(member_id)          FROM miglab.member), 1));
SELECT setval('miglab.seq_fee_schedule',        COALESCE((SELECT max(schedule_id)        FROM miglab.fee_schedule), 1));
SELECT setval('miglab.seq_fee_schedule_detail', COALESCE((SELECT max(schedule_detail_id) FROM miglab.fee_schedule_detail), 1));
SELECT setval('miglab.seq_claim',               COALESCE((SELECT max(claim_id)           FROM miglab.claim), 1));
SELECT setval('miglab.seq_claim_detail',        COALESCE((SELECT max(claim_detail_id)    FROM miglab.claim_detail), 1));
SELECT setval('miglab.seq_migration_audit',     COALESCE((SELECT max(audit_id)           FROM miglab.migration_audit), 1));
