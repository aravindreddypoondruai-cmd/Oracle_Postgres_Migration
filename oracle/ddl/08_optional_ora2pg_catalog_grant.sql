-- Phase 5 | OPTIONAL | Run in ORACLE as SYSTEM, connected to FREEPDB1
-- Use ONLY if Ora2Pg as MIGLAB fails with ORA-00942 / ORA-01031 on dictionary views
-- even with USER_GRANTS 1. Grant temporarily and revoke at the end of Phase 5.
 
SELECT SYS_CONTEXT('USERENV','CON_NAME') AS container_name FROM dual;   -- must be FREEPDB1
 
GRANT SELECT_CATALOG_ROLE TO MIGLAB;
 
-- ===== At the end of Phase 5 =====
-- REVOKE SELECT_CATALOG_ROLE FROM MIGLAB;
-- SELECT granted_role FROM dba_role_privs WHERE grantee = 'MIGLAB';
