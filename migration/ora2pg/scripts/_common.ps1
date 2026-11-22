# Phase 5 | Shared settings and helper functions
# Every other script dot-sources this file:  . "$PSScriptRoot\_common.ps1"
# Required environment variables (set in the same PowerShell window):
#   $env:ORACLE_MIGLAB_PASSWORD  $env:MIGLAB_PG_PASSWORD  $env:MIGLAB_RO_PASSWORD
 
$ErrorActionPreference = "Stop"
 
$Ora2PgImage = "georgmoser/ora2pg:25.0"
$PgImage     = "postgres:18"
$Network     = "miglab-net"
$TargetDb    = "miglab_ora2pg"   # Phase 5 target (Ora2Pg)
$ManualDb    = "miglabdb"        # Phase 4 reference (manual) - read only from now on
 
$Ora2PgRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$RepoRoot   = (Resolve-Path (Join-Path $Ora2PgRoot "..\..")).Path
$ConfigDir  = Join-Path $Ora2PgRoot "config"
$OutputDir  = Join-Path $Ora2PgRoot "output"
 
function Assert-Env {
    param([string[]]$Names)
    foreach ($n in $Names) {
        if (-not [Environment]::GetEnvironmentVariable($n)) {
            throw "Environment variable $n is not set in this PowerShell window."
        }
    }
}
 
function Invoke-Ora2Pg {
    # Runs ora2pg in a throw-away container attached to miglab-net.
    # Deliberately a simple function using $args: an advanced function would try to
    # bind short switches such as -o to PowerShell common parameters (-OutVariable).
    $OraArgs = $args
    if (-not (Test-Path (Join-Path $ConfigDir "ora2pg.conf"))) {
        throw "config\ora2pg.conf not found. Run 00_make_config.ps1 first."
    }
    & docker run --rm --network $Network `
        -v "${ConfigDir}:/config:ro" `
        -v "${OutputDir}:/data" `
        $Ora2PgImage ora2pg -c /config/ora2pg.conf @OraArgs
    if ($LASTEXITCODE -ne 0) { throw "ora2pg failed: $($OraArgs -join ' ')" }
}
 
function Get-PgPassword {
    param([string]$User)
    switch ($User) {
        "miglab"    { return $env:MIGLAB_PG_PASSWORD }
        "miglab_ro" { return $env:MIGLAB_RO_PASSWORD }
        default     { throw "Unknown user $User" }
    }
}
 
function Invoke-PgFile {
    # Runs a repository SQL file with psql against postgres-target (container to container).
    param(
        [Parameter(Mandatory)][string]$Database,
        [Parameter(Mandatory)][string]$User,
        [Parameter(Mandatory)][string]$File,          # path relative to the repo root
        [switch]$SingleTransaction,
        [switch]$ContinueOnError
    )
    if (-not (Test-Path (Join-Path $RepoRoot $File))) { throw "File not found: $File" }
    $rel  = $File -replace '\\', '/'
    $stop = if ($ContinueOnError) { "0" } else { "1" }
    $psqlArgs = @("-h", "postgres-target", "-U", $User, "-d", $Database,
                  "-v", "ON_ERROR_STOP=$stop", "-f", "/repo/$rel")
    if ($SingleTransaction) { $psqlArgs += "--single-transaction" }
    & docker run --rm --network $Network `
        -e "PGPASSWORD=$(Get-PgPassword $User)" `
        -v "${RepoRoot}:/repo:ro" `
        $PgImage psql @psqlArgs
    if ($LASTEXITCODE -ne 0 -and -not $ContinueOnError) { throw "psql failed on $File" }
}
 
function Invoke-PgCommand {
    param([string]$Database, [string]$User, [string]$Sql)
    & docker run --rm --network $Network -e "PGPASSWORD=$(Get-PgPassword $User)" $PgImage `
        psql -h postgres-target -U $User -d $Database -v ON_ERROR_STOP=1 -c $Sql
    if ($LASTEXITCODE -ne 0) { throw "psql command failed: $Sql" }
}
 
function Invoke-PgDump {
    param([string]$Database, [string]$User, [string[]]$DumpArgs)
    & docker run --rm --network $Network -e "PGPASSWORD=$(Get-PgPassword $User)" $PgImage `
        pg_dump -h postgres-target -U $User -d $Database @DumpArgs
    if ($LASTEXITCODE -ne 0) { throw "pg_dump failed on $Database" }
}
