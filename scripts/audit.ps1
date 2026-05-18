# Purpose: Quarterly governance audit. PowerShell mirror of audit.sh.
# When:    Run quarterly, or when onboarding a new maintainer.
# Example: pwsh scripts/audit.ps1
# Read-only; exits 0 always.

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

function Section($t) { Write-Host ""; Write-Host "== $t ==" -ForegroundColor Cyan }

# Stale proposed artifacts (>90 days).
Section "Stale 'proposed' artifacts (>90 days)"
$today = Get-Date
$hit = 0
foreach ($dir in @('docs/adr','docs/rfc')) {
  if (-not (Test-Path $dir)) { continue }
  Get-ChildItem -Path $dir -Filter *.md -File | ForEach-Object {
    if ($_.Name -in @('_TEMPLATE.md','INDEX.md')) { return }
    $c = Get-Content $_.FullName -Raw
    if ($c -notmatch '(?m)^status:\s*proposed') { return }
    if ($c -match '(?m)^date:\s*(\d{4}-\d{2}-\d{2})') {
      $d = [datetime]::Parse($matches[1])
      $age = ($today - $d).Days
      if ($age -gt 90) {
        Write-Host ("  {0} - {1} days proposed" -f $_.FullName, $age)
        $script:hit++
      }
    }
  }
}
if ($hit -eq 0) { Write-Host "  (none)" }

# Postmortem action items.
Section "Postmortem action items needing follow-up"
if (Test-Path 'docs/postmortems') {
  $hit = 0
  Get-ChildItem -Path 'docs/postmortems' -Filter *.md -File | ForEach-Object {
    if ($_.Name -in @('_TEMPLATE.md','INDEX.md')) { return }
    $lines = Get-Content $_.FullName
    $matches = $lines | Where-Object { $_ -match '^\| *\d+ \|.*(TODO|todo|open|OPEN)' }
    if ($matches) {
      Write-Host "  $($_.FullName):"
      $matches | ForEach-Object { Write-Host "    $_" }
      $script:hit++
    }
  }
  if ($hit -eq 0) { Write-Host "  (none - or table uses different markers)" }
} else {
  Write-Host "  (no docs/postmortems/ yet)"
}

# CODEOWNERS handles.
Section "CODEOWNERS distinct handles (verify each is still active)"
if (Test-Path '.github/CODEOWNERS') {
  Select-String -Path '.github/CODEOWNERS' -Pattern '@[A-Za-z0-9_/-]+' -AllMatches |
    ForEach-Object { $_.Matches.Value } |
    Where-Object { $_ -ne '@TBD' } |
    Sort-Object -Unique |
    ForEach-Object { Write-Host "  $_" }
} else {
  Write-Host "  (no CODEOWNERS file)"
}

# Toolchain placeholders.
Section "Toolchain Commands placeholders still present"
if (Test-Path 'AGENTS.md') {
  $hits = Select-String -Path 'AGENTS.md' -Pattern '\| `<(install|dev|build|run|lint|typecheck|test-one|test-all|codegen)>` \|'
  if ($hits) {
    $hits | ForEach-Object { Write-Host ("  L{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) }
    Write-Host "  -> pick a toolchain and fill the Commands table; see ADR-0002 if it exists."
  } else {
    Write-Host "  (clean)"
  }
}

# Template version.
Section "Template version"
if (Test-Path '.template-version') {
  Get-Content '.template-version' | ForEach-Object { Write-Host "  $_" }
} else {
  Write-Host "  (no .template-version file - consider adding one to track upstream merges)"
}

Write-Host ""
Write-Host "audit: report complete (read-only)."
