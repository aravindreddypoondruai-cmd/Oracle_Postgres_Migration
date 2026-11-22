# Phase 5 | Step 9 | Indexes, constraints, FKs, sequence values, views, code, triggers
# Each file runs in ONE transaction: a failing file leaves nothing half-created.
# Remediation rule: never edit generated files. Put a fixed copy with the SAME file
# name in sql\remediation\ - this script uses it automatically instead.
# Resume after a fix:   .\08_post_load.ps1 -StartFrom <step number>
param([int]$StartFrom = 1)
. "$PSScriptRoot\_common.ps1"
 
$gen = "migration/ora2pg/output/schema"
$steps = @(
    @{ File = "$gen/tables/INDEXES_table.sql" },
    @{ File = "$gen/tables/CONSTRAINTS_table.sql" },
    @{ File = "$gen/tables/FKEYS_table.sql" },
    @{ File = "$gen/sequences/sequence_values.sql"; Fallback = "migration/ora2pg/sql/fallback_sequence_values.sql" },
    @{ File = "$gen/views/view.sql" },
    @{ File = "$gen/functions/function.sql" },
    @{ File = "$gen/procedures/procedure.sql" },
    @{ File = "$gen/packages/package.sql" },
    @{ File = "$gen/triggers/trigger.sql" },
    @{ File = "migration/ora2pg/sql/post_load_grants_analyze.sql" }
)
 
for ($i = $StartFrom; $i -le $steps.Count; $i++) {
    $s    = $steps[$i - 1]
    $file = $s.File
    $fix  = "migration/ora2pg/sql/remediation/" + (Split-Path $file -Leaf)
 
    if (Test-Path (Join-Path $RepoRoot $fix)) {
        Write-Host "[$i] Using REMEDIATED version: $fix" -ForegroundColor Yellow
        $file = $fix
    } elseif (-not (Test-Path (Join-Path $RepoRoot $file))) {
        if ($s.Fallback) {
            Write-Host "[$i] $($s.File) not found - using fallback $($s.Fallback)" -ForegroundColor Yellow
            $file = $s.Fallback
        } else {
            Write-Warning "[$i] Not found, skipped: $($s.File)  (check output\schema for the real file name)"
            continue
        }
    }
 
    Write-Host "[$i/$($steps.Count)] $file" -ForegroundColor Cyan
    try {
        Invoke-PgFile -Database $TargetDb -User miglab -File $file -SingleTransaction
    } catch {
        Write-Host "`nFAILED at step $i ($file)" -ForegroundColor Red
        Write-Host "  1. Read the psql error above (file, line, message)."
        Write-Host "  2. Copy the generated file to migration\ora2pg\sql\remediation\ with the same name and fix it."
        Write-Host "  3. Log the issue in docs\ora2pg-migration-report.md (section 4)."
        Write-Host "  4. Resume:  .\08_post_load.ps1 -StartFrom $i"
        exit 1
    }
}
Write-Host "`nPost-load complete." -ForegroundColor Green
