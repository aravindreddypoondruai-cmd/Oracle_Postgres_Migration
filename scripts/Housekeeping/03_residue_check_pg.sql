-- Phase 4 close-out | Run in POSTGRESQL (DBeaver, miglab, database miglabdb)
-- Confirms the Phase 4 target was left clean after smoke and identity tests.
 
SELECT count(*) FILTER (WHERE provider_code LIKE 'TEST-%') AS test_providers
FROM miglab.provider;
 
SELECT count(*) AS audit_rows FROM miglab.migration_audit;   -- expect 0
 
SELECT (SELECT count(*) FROM miglab.provider) + (SELECT count(*) FROM miglab.member)
     + (SELECT count(*) FROM miglab.fee_schedule) + (SELECT count(*) FROM miglab.fee_schedule_detail)
     + (SELECT count(*) FROM miglab.claim) + (SELECT count(*) FROM miglab.claim_detail) AS business_rows;
 
-- Identity sequences vs data. last_value may be MAX+1 because the rolled-back
-- identity test still consumed a value. Gaps are normal; last_value < max_id is NOT.
SELECT s.schemaname, s.sequencename, s.last_value,
       CASE s.sequencename
         WHEN 'provider_provider_id_seq' THEN (SELECT max(provider_id) FROM miglab.provider)
         WHEN 'member_member_id_seq'     THEN (SELECT max(member_id)   FROM miglab.member)
         WHEN 'claim_claim_id_seq'       THEN (SELECT max(claim_id)    FROM miglab.claim)
       END AS max_id
FROM pg_sequences s
WHERE s.schemaname = 'miglab'
ORDER BY s.sequencename;
