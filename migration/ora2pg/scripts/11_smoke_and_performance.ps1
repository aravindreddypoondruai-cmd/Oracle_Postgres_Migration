# Phase 5 | Step 12 | Functional smoke test (rolled back) + performance on both targets
. "$PSScriptRoot\_common.ps1"
$c = Join-Path $OutputDir "compare"
 
Write-Host ">> Smoke test on $TargetDb (the -1 call is EXPECTED to raise an error)" -ForegroundColor Cyan
Invoke-PgFile -Database $TargetDb -User miglab -File "migration/ora2pg/sql/smoke_test_ora2pg.sql" -ContinueOnError
 
foreach ($db in @($ManualDb, $TargetDb)) {
    Write-Host ">> EXPLAIN (ANALYZE, BUFFERS) on $db" -ForegroundColor Cyan
    Invoke-PgFile -Database $db -User miglab -File "validation/pg_performance.sql" -ContinueOnError |
        Out-File -Encoding utf8 (Join-Path $c "perf_$db.txt")
}
Write-Host "Compare output\compare\perf_miglabdb.txt with perf_miglab_ora2pg.txt" -ForegroundColor Green
