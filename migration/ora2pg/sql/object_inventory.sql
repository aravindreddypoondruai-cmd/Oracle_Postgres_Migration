-- Phase 5 | Object inventory - identical query run on both databases
SELECT 'tables' AS object_kind, count(*) AS n FROM pg_tables WHERE schemaname = 'miglab'
UNION ALL
SELECT 'views', count(*) FROM pg_views WHERE schemaname = 'miglab'
UNION ALL
SELECT 'standalone sequences', count(*)
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'S' AND n.nspname = 'miglab'
  AND NOT EXISTS (SELECT 1 FROM pg_depend d WHERE d.objid = c.oid AND d.deptype IN ('a','i'))
UNION ALL
SELECT 'identity columns', count(*) FROM information_schema.columns
WHERE table_schema = 'miglab' AND is_identity = 'YES'
UNION ALL
SELECT 'indexes', count(*) FROM pg_indexes WHERE schemaname = 'miglab'
UNION ALL
SELECT 'constraints ' || contype::text, count(*) FROM pg_constraint
WHERE connamespace = 'miglab'::regnamespace GROUP BY contype
UNION ALL
SELECT 'user triggers', count(*) FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'miglab' AND NOT t.tgisinternal
UNION ALL
SELECT 'routines ' || n.nspname || ' (' || p.prokind::text || ')', count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname IN ('miglab', 'pkg_claim_admin')
GROUP BY n.nspname, p.prokind
ORDER BY 1;
