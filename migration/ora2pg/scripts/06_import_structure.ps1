# Phase 5 | Step 7 | Create schemas, tables and sequences (no indexes / FKs yet)
. "$PSScriptRoot\_common.ps1"
 
$files = @(
    "migration/ora2pg/output/schema/tables/table.sql",
    "migration/ora2pg/output/schema/sequences/sequence.sql"
)
foreach ($f in $files) {
    Write-Host ">> $f" -ForegroundColor Cyan
    Invoke-PgFile -Database $TargetDb -User miglab -File $f -SingleTransaction
}
 
Invoke-PgCommand -Database $TargetDb -User miglab -Sql @"
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog','information_schema')
ORDER BY 1, 2;
"@
