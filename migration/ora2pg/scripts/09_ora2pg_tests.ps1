# Phase 5 | Step 10 | Ora2Pg built-in validation (Oracle vs PostgreSQL)
. "$PSScriptRoot\_common.ps1"
$t = Join-Path $OutputDir "tests"
 
Write-Host "TEST: object counts on both sides..." -ForegroundColor Cyan
Invoke-Ora2Pg --type TEST       | Out-File -Encoding utf8 (Join-Path $t "test_objects.txt")
 
Write-Host "TEST_COUNT: row counts on both sides..." -ForegroundColor Cyan
Invoke-Ora2Pg --type TEST_COUNT | Out-File -Encoding utf8 (Join-Path $t "test_count.txt")
 
try {
    Write-Host "TEST_DATA: row-by-row data comparison (may take a few minutes)..." -ForegroundColor Cyan
    Invoke-Ora2Pg --type TEST_DATA | Out-File -Encoding utf8 (Join-Path $t "test_data.txt")
} catch {
    Write-Warning "TEST_DATA failed or is not supported by this build - see output\ora2pg_help.txt."
}
 
Write-Host "`nError sections found:" -ForegroundColor Cyan
Select-String -Path (Join-Path $t "*.txt") -Pattern "\[ERRORS" -Context 0, 2
