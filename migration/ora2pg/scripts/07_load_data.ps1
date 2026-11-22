# Phase 5 | Step 8 | Load data directly Oracle -> PostgreSQL with Ora2Pg COPY
. "$PSScriptRoot\_common.ps1"
 
Write-Host "Target must be empty before loading:" -ForegroundColor Cyan
Invoke-PgFile -Database $TargetDb -User miglab -File "migration/ora2pg/sql/row_counts.sql"
 
$sw = [Diagnostics.Stopwatch]::StartNew()
Invoke-Ora2Pg --type COPY
$sw.Stop()
Write-Host ("`nOra2Pg COPY finished in {0:N1} seconds" -f $sw.Elapsed.TotalSeconds) -ForegroundColor Green
 
Write-Host "Row counts after load (expect 236,500 business rows):" -ForegroundColor Cyan
Invoke-PgFile -Database $TargetDb -User miglab -File "migration/ora2pg/sql/row_counts.sql"
