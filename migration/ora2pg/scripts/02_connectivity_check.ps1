# Phase 5 | Step 3 | Pull Ora2Pg and prove it can reach both databases
. "$PSScriptRoot\_common.ps1"
 
docker pull $Ora2PgImage
Write-Host "`nOra2Pg version:" -ForegroundColor Cyan
docker run --rm $Ora2PgImage ora2pg --version
 
# Save the full list of actions and options supported by this version
docker run --rm $Ora2PgImage ora2pg --help | Out-File -Encoding utf8 (Join-Path $OutputDir "ora2pg_help.txt")
Write-Host "Saved option list to output\ora2pg_help.txt"
 
Write-Host "`nOracle connection (Ora2Pg -> oracle-source:1521/FREEPDB1):" -ForegroundColor Cyan
Invoke-Ora2Pg --type SHOW_VERSION
 
Write-Host "`nPostgreSQL connection (container -> postgres-target:5432/miglab_ora2pg):" -ForegroundColor Cyan
Invoke-PgCommand -Database $TargetDb -User miglab -Sql "SELECT current_database(), version();"
