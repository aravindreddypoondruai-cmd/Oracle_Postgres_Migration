DO $$
BEGIN
    IF current_database() <> 'miglab_ora2pg' THEN
        RAISE EXCEPTION 'Refusing to run in database %.', current_database();
    END IF;
END $$;
 
TRUNCATE miglab.claim_detail, miglab.claim, miglab.fee_schedule_detail,
         miglab.fee_schedule, miglab.member, miglab.provider,
         miglab.migration_audit CASCADE;
