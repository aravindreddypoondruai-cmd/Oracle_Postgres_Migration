# Migration Decision Log
 
Each entry: context, decision, alternatives, consequence. Add new decisions at the bottom.
 
| ID | Phase | Decision | Reason | Alternatives considered |
|---|---|---|---|---|
| DEC-001 | 3 | Target PostgreSQL 18, not 19 | Tooling and RDS support mature; 19 released days earlier | 19 (too new), 17 |
| DEC-002 | 3 | Separate role and schema `miglab`; read-only role `miglab_ro` | Least privilege; mirrors Oracle user=schema | Single superuser (rejected) |
| DEC-003 | 4 | Business DATE -> `date`; audit DATE -> `timestamp(0)` | Data showed no time on business dates | All `timestamp(0)`; all `date` |
| DEC-004 | 4 | Sequence + trigger -> identity BY DEFAULT | Fewer objects; keeps source IDs | Keep sequences + triggers |
| DEC-005 | 4 | Package -> schema `pkg_claim_admin` | Keeps `package.routine` call style | Prefixed function names |
| DEC-006 | 4 | Offline load: CSV + `\copy` | Small volume; full control | Ora2Pg, oracle_fdw, DMS |
| DEC-007 | 5 | Ora2Pg loads a separate database `miglab_ora2pg` | Avoid schema name clash; keep Phase 4 reference intact | Separate schema (clashes with package schema) |
| DEC-008 | 5 | Ora2Pg run with defaults for DATE first | Observe tool behaviour before overriding | MODIFY_TYPE from the start |
| DEC-009 | 5 | `NULL_EQUAL_EMPTY 0` | Same semantics as manual conversion; comparable results | 1 = emulate Oracle '' = NULL |
| DEC-010 | 5 | Fixes stored in `sql/remediation`, never in generated output | Re-runnable, reviewable migration | Hand-editing output |
git add .gitignore scripts docs/decision-log.md
git commit -m "Phase 4 close-out: housekeeping, decision log"
git tag -a v0.4-manual-migration -m "Phase 4: manual migration reconciled"
git push origin main --tags
