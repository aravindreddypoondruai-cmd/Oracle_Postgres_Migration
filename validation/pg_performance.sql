-- Phase 4 | Step 9 | Run in POSTGRESQL as miglab
-- Same business query as the Phase 2D Oracle EXPLAIN PLAN.
-- Oracle: ADD_MONTHS(TRUNC(SYSDATE), -12)  ->  (current_date - interval '12 months')::date
EXPLAIN (ANALYZE, BUFFERS)
SELECT p.provider_id,
       p.provider_name,
       count(*)             AS claim_count,
       SUM(c.total_billed)  AS total_billed,
       SUM(c.total_allowed) AS total_allowed
FROM miglab.provider p
JOIN miglab.claim c
  ON c.provider_id = p.provider_id
WHERE c.service_date >= (current_date - interval '12 months')::date
  AND c.claim_status = 'PAID'
GROUP BY p.provider_id, p.provider_name
ORDER BY total_billed DESC;
 
-- Workload statistics (PostgreSQL's closest equivalent to AWR SQL statistics)
SELECT left(query, 60)                    AS query,
       calls,
       round(mean_exec_time::numeric, 2)  AS mean_ms,
       rows,
       shared_blks_hit,
       shared_blks_read
FROM pg_stat_statements
ORDER BY total_exec_time DESC
