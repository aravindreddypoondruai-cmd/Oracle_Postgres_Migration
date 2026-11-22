# Phase 4 close-out | Run in PowerShell from the repository root
# Cleans temporary files, checks Git for data/secrets and shows Docker disk use.
# Safe: does NOT touch Docker volumes or database contents.
 
Write-Host "`n[1] Removing temporary export files inside the containers" -ForegroundColor Cyan
docker exec -u root oracle-source bash -c "rm -rf /tmp/export /tmp/export_miglab.sql"
docker exec postgres-target bash -c "rm -rf /tmp/export /tmp/load_miglab.sql /tmp/04_smoke_test.sql"
Write-Host "Done."
 
Write-Host "`n[2] Local CSV export folder" -ForegroundColor Cyan
if (Test-Path "migration\manual\export") {
    Write-Host "migration\manual\export still exists. Phase 4 is reconciled, so the CSVs are no longer needed."
    Remove-Item "migration\manual\export" -Recurse -Confirm
} else {
    Write-Host "Not present - nothing to delete."
}
 
Write-Host "`n[3] Files tracked by Git that should never be committed (expect NO output)" -ForegroundColor Cyan
git ls-files | Select-String -Pattern '\.csv$|\.env$|\.dump$|ora2pg\.conf$'
 
Write-Host "`n[4] Possible secrets in tracked files (review each hit; placeholders like <...> are fine)" -ForegroundColor Cyan
git grep -n -I -i -E "identified by|password *=|_pwd *=|pgpassword" -- . ":(exclude)*.md"
 
Write-Host "`n[5] Phase 4 tag" -ForegroundColor Cyan
$tag = git tag -l "v0.4*"
if ($tag) { Write-Host "Found tag: $tag" } else {
    Write-Warning "No v0.4 tag. Create it:  git tag -a v0.4-manual-migration -m 'Phase 4 reconciled'; git push origin v0.4-manual-migration"
}
 
Write-Host "`n[6] Docker disk usage (volumes are your databases - never prune them)" -ForegroundColor Cyan
docker system df
Write-Host "Optional safe cleanup of dangling images only:  docker image prune"
