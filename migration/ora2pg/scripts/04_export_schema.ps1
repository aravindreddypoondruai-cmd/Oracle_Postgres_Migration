# Phase 5 | Step 5 | Export DDL and code, one object type per folder
. "$PSScriptRoot\_common.ps1"
 
$exports = @(
    @{ Type = "TABLE";     Dir = "schema/tables";     File = "table.sql" },
    @{ Type = "SEQUENCE";  Dir = "schema/sequences";  File = "sequence.sql" },
    @{ Type = "VIEW";      Dir = "schema/views";      File = "view.sql" },
    @{ Type = "TRIGGER";   Dir = "schema/triggers";   File = "trigger.sql" },
    @{ Type = "FUNCTION";  Dir = "schema/functions";  File = "function.sql" },
    @{ Type = "PROCEDURE"; Dir = "schema/procedures"; File = "procedure.sql" },
    @{ Type = "PACKAGE";   Dir = "schema/packages";   File = "package.sql" }
)
 
foreach ($e in $exports) {
    Write-Host ">> Exporting $($e.Type)" -ForegroundColor Cyan
    Invoke-Ora2Pg --type $e.Type --basedir "/data/$($e.Dir)" --out $e.File
}
 
# Sequence positions (setval statements). If this action is not available in
# your build, 08_post_load.ps1 falls back to sql\fallback_sequence_values.sql
try {
    Write-Host ">> Exporting SEQUENCE_VALUES" -ForegroundColor Cyan
    Invoke-Ora2Pg --type SEQUENCE_VALUES --basedir "/data/schema/sequences" --out "sequence_values.sql"
} catch {
    Write-Warning "SEQUENCE_VALUES export not available - the fallback script will be used."
}
 
Write-Host "`nGenerated files:" -ForegroundColor Green
Get-ChildItem (Join-Path $OutputDir "schema") -Recurse -File |
    Select-Object @{n = "File"; e = { $_.FullName.Replace($OutputDir, "output") } }, Length |
    Format-Table -AutoSize
