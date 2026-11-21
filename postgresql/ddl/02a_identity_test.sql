-- Phase 4 | Step 6 | Identity test - run in psql, rolled back
BEGIN;
SELECT MAX(provider_id) AS current_max FROM miglab.provider;
INSERT INTO miglab.provider (provider_code, provider_name)
VALUES ('TEST-P001', 'Identity test')
RETURNING provider_id;          -- expect current_max + 1
ROLLBACK;
