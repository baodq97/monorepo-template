# Purpose: One-shot rename of template placeholders. PowerShell mirror of bootstrap.sh.
# When:    Immediately after `git clone` / "Use this template".
# Example: pwsh scripts/bootstrap.ps1 -Project my-project -Owner '@acme-eng'

param(
  [Parameter(Mandatory)][string]$Project,
  [Parameter(Mandatory)][string]$Owner
)

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

if ($Owner -notlike '@*') {
  Write-Error "owner must start with '@' (e.g. @alice or @acme/eng)"
  exit 2
}

Write-Host "-> project name: $Project"
Write-Host "-> owner:        $Owner"
Write-Host ""

function Patch-File($Path, $Pattern, $Replacement) {
  if (-not (Test-Path $Path)) { return }
  $text = Get-Content $Path -Raw
  if ($text -match [regex]::Escape($Pattern)) {
    ($text -replace [regex]::Escape($Pattern), $Replacement) |
      Set-Content -Path $Path -NoNewline
    Write-Host "OK  patched $Path"
  } else {
    Write-Host "--  $Path already patched"
  }
}

Patch-File 'README.md'  '<project>' $Project
Patch-File 'AGENTS.md'  '<project>' $Project
Patch-File '.github/CODEOWNERS' '@OWNER' $Owner

# Fill ADR-0001 owner.
$adr1 = 'docs/adr/ADR-0001-record-architecture-decisions.md'
if (Test-Path $adr1) {
  $text = Get-Content $adr1 -Raw
  if ($text -match '(?m)^owner:\s*TBD.*$') {
    ($text -replace '(?m)^owner:\s*TBD.*$', "owner: $Owner") |
      Set-Content -Path $adr1 -NoNewline
    Write-Host "OK  patched $adr1 (owner: $Owner)"
  } else {
    Write-Host "--  $adr1 owner already set"
  }
}

$adrIndex = 'docs/adr/INDEX.md'
if (Test-Path $adrIndex) {
  $idx = Get-Content $adrIndex -Raw
  if ($idx -match '\| TBD \| 2026-05-16 \|') {
    ($idx -replace '\| TBD \| 2026-05-16 \|', "| $Owner | 2026-05-16 |") |
      Set-Content -Path $adrIndex -NoNewline
    Write-Host "OK  patched $adrIndex (ADR-0001 owner row)"
  }
}

if (Test-Path '.template-unbootstrapped') {
  Remove-Item '.template-unbootstrapped'
  Write-Host "OK  removed .template-unbootstrapped sentinel"
}

Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Pick toolchain; fill the Commands table in AGENTS.md."
Write-Host "  2. Run: pwsh scripts/verify.ps1"
Write-Host "  3. Write ADR-0002 recording the toolchain choice."
