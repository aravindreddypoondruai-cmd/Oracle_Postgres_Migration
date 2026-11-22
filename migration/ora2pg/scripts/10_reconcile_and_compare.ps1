# Phase 5 | Step 11 | Same reconciliation as Phase 4 + manual vs Ora2Pg comparison
# Runs identical scripts against miglabdb (manual) and miglab_ora2pg (Ora2Pg).
. "$PSScriptRoot\_common.ps1"
$c = Join-Path $OutputDir "compare"
 
foreach ($db in @($ManualDb, $TargetDb)) {
    Write-Host ">> Collecting evidence from $db" -ForegroundColor Cyan
    # Read-only role: the final DELETE in the script is expected to fail
    Invoke-PgFile -Database $db -User miglab_ro -File "validation/pg_reconciliation.sql" -ContinueOnError |
        Out-File -Encoding utf8 (Join-Path $c "recon_$db.txt")
    Invoke-PgFile -Database $db -User miglab_ro -File "migration/ora2pg/sql/column_type_inventory.sql" |
        Out-File -Encoding utf8 (Join-Path $c "types_$db.txt")
    Invoke-PgFile -Database $db -User miglab_ro -File "migration/ora2pg/sql/object_inventory.sql" |
        Out-File -Encoding utf8 (Join-Path $c "objects_$db.txt")
    Invoke-PgDump -Database $db -User miglab -DumpArgs @("--schema-only", "--no-owner", "--no-privileges",
                                                         "-n", "miglab", "-n", "pkg_claim_admin") |
        Out-File -Encoding utf8 (Join-Path $c "schema_$db.sql")
}
 
Write-Host "`n== Data reconciliation: manual vs Ora2Pg ==" -ForegroundColor Cyan
$diff = Compare-Object (Get-Content (Join-Path $c "recon_$ManualDb.txt")) `
                       (Get-Content (Join-Path $c "recon_$TargetDb.txt"))
if (-not $diff) {
    Write-Host "IDENTICAL - every reconciliation result matches." -ForegroundColor Green
} else {
    $diff | Format-Table -AutoSize | Out-String -Width 250 |
        Out-File -Encoding utf8 (Join-Path $c "recon_diff.txt")
    Write-Warning "$(@($diff).Count) differing lines - see output\compare\recon_diff.txt (explain each one)."
}
 
Write-Host "`n== Structure differences (expected - this is the learning) ==" -ForegroundColor Cyan
git diff --no-index --stat (Join-Path $c "types_$ManualDb.txt")   (Join-Path $c "types_$TargetDb.txt")
git diff --no-index (Join-Path $c "types_$ManualDb.txt")   (Join-Path $c "types_$TargetDb.txt")   | Out-File -Encoding utf8 (Join-Path $c "types_diff.txt")
git diff --no-index (Join-Path $c "objects_$ManualDb.txt") (Join-Path $c "objects_$TargetDb.txt") | Out-File -Encoding utf8 (Join-Path $c "objects_diff.txt")
git diff --no-index (Join-Path $c "schema_$ManualDb.sql")  (Join-Path $c "schema_$TargetDb.sql")  | Out-File -Encoding utf8 (Join-Path $c "schema_diff.txt")
Write-Host "Saved types_diff.txt, objects_diff.txt and schema_diff.txt in output\compare" -ForegroundColor Green
