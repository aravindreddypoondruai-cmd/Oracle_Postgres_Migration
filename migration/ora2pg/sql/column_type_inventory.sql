-- Phase 5 | Column-level inventory - identical query run on both databases
SELECT table_name,
       column_name,
       data_type,
       COALESCE(character_maximum_length::text,
                numeric_precision || ',' || numeric_scale,
                datetime_precision::text, '')            AS size,
       is_nullable,
       is_identity,
       COALESCE(column_default, '')                      AS column_default
FROM information_schema.columns
WHERE table_schema = 'miglab'
ORDER BY table_name, ordinal_position;
