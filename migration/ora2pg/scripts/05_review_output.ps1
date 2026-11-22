# Phase 5 | Step 6 | Review the generated code BEFORE loading anything
# Produces output\compare\review_findings.txt grouped by migration topic.
. "$PSScriptRoot\_common.ps1"
$schema = Join-Path $OutputDir "schema"
$report = Join-Path $OutputDir "compare\review_findings.txt"
 
$checks = [ordered]@{
    "1. Column data types (tables)"        = @{ Path = "tables";  Pattern = '\b(numeric|bigint|integer|smallint|double precision|real|timestamp|date|text|varchar|char|bytea)\b' }
    "2. Column defaults (SYSDATE etc.)"    = @{ Path = "tables";  Pattern = '\bDEFAULT\b' }
    "3. Sequences and nextval"             = @{ Path = "";        Pattern = 'CREATE SEQUENCE|nextval|setval|IDENTITY' }
    "4. Triggers"                          = @{ Path = "triggers";Pattern = 'CREATE (OR REPLACE )?TRIGGER|RETURNS trigger|EXECUTE (FUNCTION|PROCEDURE)' }
    "5. NO_DATA_FOUND / STRICT"            = @{ Path = "";        Pattern = 'STRICT|NO_DATA_FOUND|TOO_MANY_ROWS' }
    "6. Row-count logic"                   = @{ Path = "";        Pattern = 'ROWCOUNT|GET DIAGNOSTICS|\bFOUND\b' }
    "7. Error handling"                    = @{ Path = "";        Pattern = 'RAISE|SQLERRM|SQLSTATE|EXCEPTION' }
    "8. MERGE / upsert"                    = @{ Path = "";        Pattern = '\bMERGE\b|ON CONFLICT' }
    "9. NULL handling"                     = @{ Path = "";        Pattern = 'coalesce|IS NULL|IS NOT NULL' }
    "10. Oracle syntax left behind"        = @{ Path = "";        Pattern = '\bSYSDATE\b|SYSTIMESTAMP|\bNVL\(|\bDECODE\(|\bROWNUM\b|\bdual\b|PRAGMA|DBMS_' }
    "11. Tool comments and warnings"       = @{ Path = "";        Pattern = 'TODO|FIXME|ora2pg|WARNING|not supported|unsupported' }
}
 
"Phase 5 - Ora2Pg output review - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" | Out-File -Encoding utf8 $report
foreach ($k in $checks.Keys) {
    $c = $checks[$k]
    $root = if ($c.Path) { Join-Path $schema $c.Path } else { $schema }
    "`n===== $k =====" | Out-File -Encoding utf8 -Append $report
    $hits = Get-ChildItem $root -Recurse -Filter *.sql -ErrorAction SilentlyContinue |
            Select-String -Pattern $c.Pattern
    if ($hits) {
        $hits | ForEach-Object { "{0}:{1}: {2}" -f $_.Filename, $_.LineNumber, $_.Line.Trim() } |
            Out-File -Encoding utf8 -Append $report
    } else {
        "(no matches)" | Out-File -Encoding utf8 -Append $report
    }
    Write-Host ("{0,-40} {1,5} matches" -f $k, @($hits).Count)
}
Write-Host "`nFull findings: output\compare\review_findings.txt" -ForegroundColor Green
