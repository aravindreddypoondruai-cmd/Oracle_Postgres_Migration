# Phase 5 | Step 1 | Build ora2pg.conf from the template and create output folders
. "$PSScriptRoot\_common.ps1"
Assert-Env @("ORACLE_MIGLAB_PASSWORD", "MIGLAB_PG_PASSWORD", "MIGLAB_RO_PASSWORD")
 
$template = Get-Content -Raw (Join-Path $ConfigDir "ora2pg.conf.template")
$conf = $template.Replace("<ORACLE_MIGLAB_PASSWORD>", $env:ORACLE_MIGLAB_PASSWORD).
                  Replace("<MIGLAB_PG_PASSWORD>",     $env:MIGLAB_PG_PASSWORD)
 
# Ora2Pg is a Linux/Perl tool: write LF line endings and UTF-8 without BOM,
# otherwise a trailing carriage return can end up inside the password.
$conf = $conf -replace "`r`n", "`n"
$target = Join-Path $ConfigDir "ora2pg.conf"
[IO.File]::WriteAllText($target, $conf, (New-Object System.Text.UTF8Encoding $false))
 
$folders = @("assessment", "tests", "compare",
             "schema\tables", "schema\sequences", "schema\views", "schema\triggers",
             "schema\functions", "schema\procedures", "schema\packages")
foreach ($f in $folders) { New-Item -ItemType Directory -Force -Path (Join-Path $OutputDir $f) | Out-Null }
 
git -C $RepoRoot check-ignore -q "migration/ora2pg/config/ora2pg.conf"
if ($LASTEXITCODE -ne 0) {
    Write-Warning "ora2pg.conf is NOT git-ignored. Add the lines from scripts\housekeeping\gitignore_additions.txt now."
} else {
    Write-Host "ora2pg.conf created and git-ignored." -ForegroundColor Green
}
