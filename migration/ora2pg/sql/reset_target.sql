-- Phase 5 | Start the Ora2Pg import again from scratch (structure + data)
-- GUARDED: refuses to run anywhere except miglab_ora2pg.
DO $$
BEGIN
    IF current_database() <> 'miglab_ora2pg' THEN
        RAISE EXCEPTION 'Refusing to run in database %. This script is for miglab_ora2pg only.',
                        current_database();
    END IF;
END $$;
 
DROP SCHEMA IF EXISTS pkg_claim_admin CASCADE;
DROP SCHEMA IF EXISTS miglab CASCADE;
