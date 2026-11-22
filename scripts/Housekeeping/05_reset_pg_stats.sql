-- Phase 4 close-out | Run as the postgres superuser:
-- docker exec -it postgres-target psql -U postgres -d miglabdb -f /tmp/05_reset_pg_stats.sql
-- Clears pg_stat_statements so Phase 5 workload statistics start clean.
SELECT pg_stat_statements_reset();
SELECT count(*) AS statements_after_reset FROM pg_stat_statements;
