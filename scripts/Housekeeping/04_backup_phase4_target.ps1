# Phase 4 close-out | Logical backup of the reconciled Phase 4 target
# Run in PowerShell from the repository root. Output goes to backups\ (git-ignored).
# Uses the local socket inside the container, so no password is needed.
 
New-Item -ItemType Directory -Force -Path "backups" | Out-Null
$dump = "miglabdb_phase4_$(Get-Date -Format yyyyMMdd).dump"
 
docker exec postgres-target pg_dump -U miglab -d miglabdb -Fc `
    -n miglab -n pkg_claim_admin -f "/tmp/$dump"
 
# Verify the archive is readable and list what it contains
docker exec postgres-target bash -c "pg_restore -l /tmp/$dump | grep -c 'TABLE DATA'"
docker exec postgres-target bash -c "pg_restore -l /tmp/$dump | head -30"
 
docker cp "postgres-target:/tmp/$dump" "backups\$dump"
docker exec postgres-target rm "/tmp/$dump"
 
Get-Item "backups\$dump" | Select-Object Name, Length, LastWriteTime
Write-Host "Backup saved. It will be reused in Phase 6 to load AWS RDS." -ForegroundColor Green
