# Phase 5 | Step 4 | Inventory the Oracle schema and produce the migration assessment
. "$PSScriptRoot\_common.ps1"
$a = Join-Path $OutputDir "assessment"
 
Write-Host "Tables and row estimates..." -ForegroundColor Cyan
Invoke-Ora2Pg --type SHOW_TABLE  | Out-File -Encoding utf8 (Join-Path $a "show_table.txt")
 
Write-Host "Columns with proposed PostgreSQL types..." -ForegroundColor Cyan
Invoke-Ora2Pg --type SHOW_COLUMN | Out-File -Encoding utf8 (Join-Path $a "show_column.txt")
 
Write-Host "Assessment report (text and HTML) with cost estimate..." -ForegroundColor Cyan
Invoke-Ora2Pg --type SHOW_REPORT --estimate_cost                | Out-File -Encoding utf8 (Join-Path $a "report.txt")
Invoke-Ora2Pg --type SHOW_REPORT --estimate_cost --dump_as_html | Out-File -Encoding utf8 (Join-Path $a "report.html")
 
Get-ChildItem $a | Select-Object Name, Length
Write-Host "`nFirst lines of the report:" -ForegroundColor Cyan
Get-Content (Join-Path $a "report.txt") -TotalCount 40
Start-Process (Join-Path $a "report.html")
