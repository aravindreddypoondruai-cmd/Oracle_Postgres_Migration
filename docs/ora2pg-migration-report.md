# Phase 5 - Ora2Pg Migration Report (Method B)
 
## 1. Scope and Setup
- Tool: Ora2Pg 25.0 (container georgmoser/ora2pg:25.0) on miglab-net
- Source: Oracle FREEPDB1.MIGLAB (frozen baseline, 236,500 rows)
- Target: PostgreSQL 18, database `miglab_ora2pg`
- Key settings: PG_INTEGER_TYPE 1, PG_NUMERIC_TYPE 0, PACKAGE_AS_SCHEMA 1, NULL_EQUAL_EMPTY 0
 
## 2. Assessment Summary (from output/assessment/report.txt)
| Item | Value |
|---|---|
| Migration level | |
| Technical difficulty | |
| Estimated cost (units / person-days) | |
| Objects flagged as complex | |
| My view: is the estimate realistic? | |
 
## 3. Tool Choices vs Manual Choices
| Area | Manual (Phase 4) | Ora2Pg | Better / why |
|---|---|---|---|
| ID columns | bigint identity | | |
| NUMBER(5) | integer | | |
| Money columns | numeric(p,2) | | |
| Business DATE | date | | |
| Audit DATE | timestamp(0) | | |
| SYSDATE defaults | localtimestamp(0) | | |
| CLOB | text | | |
| Sequence + trigger | identity | | |
| Views (NVL/DECODE) | COALESCE / CASE | | |
| FN_CLAIM_BALANCE | IF NOT FOUND | | |
| PR_RECALCULATE_CLAIM | procedure, RAISE EXCEPTION | | |
| Package | schema pkg_claim_admin | | |
| MERGE | alias removed | | |
 
## 4. Issues Found and Remediation
| # | Object / file | Error or behaviour | Fix (remediation file) | Could config avoid it? |
|---|---|---|---|---|
| 1 | | | | |
 
## 5. Validation Results
| Check | Result |
|---|---|
| Ora2Pg TEST (objects) | |
| Ora2Pg TEST_COUNT (rows) | |
| Ora2Pg TEST_DATA | |
| pg_reconciliation.sql vs Phase 4 | IDENTICAL / n differing lines (explained below) |
| Smoke test | |
 
Explanation of every differing line:
-
 
## 6. Performance (same query, both targets)
| Metric | miglabdb (manual) | miglab_ora2pg |
|---|---|---|
| Plan shape | | |
| Execution time | | |
| Buffers | | |
 
## 7. Lessons Learned
-
 
## Result: PASS / FAIL
