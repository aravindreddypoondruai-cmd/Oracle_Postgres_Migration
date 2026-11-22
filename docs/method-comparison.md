# Migration Method Comparison
 
| Criterion | A - Manual (Phase 4) | B - Ora2Pg (Phase 5) | C - AWS (Phase 6) |
|---|---|---|---|
| Hands-on effort (hours) | | | |
| Schema conversion quality | | | |
| PL/SQL conversion quality | | | |
| Data type control | Full | Config-driven | |
| Data movement speed | | | |
| Built-in validation | None (own scripts) | TEST / TEST_COUNT / TEST_DATA | |
| Repeatability | Scripts | Config + remediation | |
| Online (CDC) capable | No | No | |
| Best suited for | Small schemas, learning, critical code | Medium/large schemas, assessment | |
| Main risk | Human error, slow at scale | Trusting output without review | |
 
## When I would use each
- Manual:
- Ora2Pg:
- AWS:
