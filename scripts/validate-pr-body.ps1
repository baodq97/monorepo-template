<#
.SYNOPSIS
  PowerShell mirror of scripts/validate-pr-body.sh.

.DESCRIPTION
  Validates that a PR body contains the agent-operability sections required by
  .github/PULL_REQUEST_TEMPLATE.md AND that those sections are actually filled
  in — not left as empty labels from an unmodified template.

.EXAMPLE
  pwsh scripts/validate-pr-body.ps1 pr-body.txt changed-files.txt
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)] [string] $BodyFile,
  [Parameter(Mandatory = $true, Position = 1)] [string] $ChangedFile
)

$ErrorActionPreference = 'Stop'
$script:fail = 0

function Note-Ok($m)  { Write-Host "[OK]   $m" }
function Note-Err($m) { Write-Host "[FAIL] $m"; $script:fail = 1 }

if (-not (Test-Path -LiteralPath $BodyFile))   { Note-Err "PR body file not found: $BodyFile";        exit 1 }
if (-not (Test-Path -LiteralPath $ChangedFile)){ Note-Err "Changed-files file not found: $ChangedFile"; exit 1 }

$bodyText    = (Get-Content -LiteralPath $BodyFile    -Raw) -replace "`r",""
$changedText = (Get-Content -LiteralPath $ChangedFile -Raw) -replace "`r",""

function Section-Present([string]$Header) {
  $esc = [regex]::Escape($Header)
  return [regex]::IsMatch($bodyText, "(?m)^\s*#{1,6}\s+$esc\s*$")
}

function Field-HasValue([string]$Label) {
  $esc = [regex]::Escape($Label)
  # "- <Label>: <non-whitespace, not '<'> ..."  on a SINGLE line.
  # Use horizontal-whitespace classes so a trailing newline after the colon
  # (the unmodified-template case) is NOT counted as a filled value.
  return [regex]::IsMatch($bodyText, "(?m)^[ \t]*([-*][ \t]+)?${esc}:[ \t]+[^ \t<\r\n][^\r\n]*")
}

function Paths-Match([string]$Pattern) {
  return [regex]::IsMatch($changedText, $Pattern, 'Multiline')
}

function Mention-HasValue([string]$Needle) {
  # Needle appears AFTER a colon on the SAME line as the label — i.e. as
  # a filled value, not on the next line where another field happens to
  # contain the substring.
  return [regex]::IsMatch($bodyText, "(?m):[ \t]*[^ \t<\r\n][^\r\n]*$Needle")
}

# 1. Required sections.
foreach ($section in @('Knowledge checked','Agent assumptions','Validation evidence','Risk classification')) {
  if (Section-Present $section) { Note-Ok "PR body has section '$section'." }
  else                           { Note-Err "PR body missing section '$section'." }
}

# 2. Knowledge checked.
if (Section-Present 'Knowledge checked') {
  if (Field-HasValue 'Nearest AGENTS.md') { Note-Ok  "Knowledge checked: 'Nearest AGENTS.md' is filled." }
  else                                    { Note-Err "Knowledge checked: 'Nearest AGENTS.md' is blank (unmodified template?)." }
}

# 3. Agent assumptions.
if (Section-Present 'Agent assumptions') {
  if (Field-HasValue 'Assumption')       { Note-Ok  "Agent assumptions: 'Assumption' is filled." }
  else                                    { Note-Err "Agent assumptions: 'Assumption' is blank." }
  if (Field-HasValue 'Why it is safe')   { Note-Ok  "Agent assumptions: 'Why it is safe' is filled." }
  else                                    { Note-Err "Agent assumptions: 'Why it is safe' is blank." }
}

# 4. Validation evidence.
if (Section-Present 'Validation evidence') {
  if (Field-HasValue 'Command') { Note-Ok  "Validation evidence: 'Command' is filled." }
  else                          { Note-Err "Validation evidence: 'Command' is blank." }
  if (Field-HasValue 'Result')  { Note-Ok  "Validation evidence: 'Result' is filled." }
  else                          { Note-Err "Validation evidence: 'Result' is blank." }
}

# 5. Risk classification.
if (Section-Present 'Risk classification') {
  if ([regex]::IsMatch($bodyText, '(?m)^\s*-\s+\[[xX]\]\s+(low|medium|high|critical)\b')) {
    Note-Ok "Risk classification: a level is checked."
  } else {
    Note-Err "Risk classification: no level is checked."
  }
}

# 6. Path-specific citations.
if (Paths-Match '(^|/)services/') {
  if (Mention-HasValue 'services/AGENTS\.md') { Note-Ok  "services/** touched → PR body cites services/AGENTS.md as a value." }
  else                                          { Note-Err "services/** touched but PR body does not cite services/AGENTS.md as a filled value." }
}
if (Paths-Match '(^|/)packages/') {
  if (Mention-HasValue 'packages/AGENTS\.md') { Note-Ok  "packages/** touched → PR body cites packages/AGENTS.md as a value." }
  else                                          { Note-Err "packages/** touched but PR body does not cite packages/AGENTS.md as a filled value." }
}
if (Paths-Match '(^|/)docs/domain/') {
  if (Mention-HasValue 'docs/domain/AGENTS\.md') { Note-Ok  "docs/domain/** touched → PR body cites docs/domain/AGENTS.md as a value." }
  else                                            { Note-Err "docs/domain/** touched but PR body does not cite docs/domain/AGENTS.md as a filled value." }
}
if (Paths-Match '(^|/)infra/envs/prod/') {
  if ([regex]::IsMatch($bodyText, 'ADR-[0-9A-Za-z_-]+')) { Note-Ok  "infra/envs/prod/** touched → PR body cites an ADR-… id." }
  else                                                    { Note-Err "infra/envs/prod/** touched but PR body does not reference an 'ADR-' id." }
}

Write-Host ""
if ($script:fail -ne 0) {
  Write-Host "validate-pr-body: FAIL"
  exit 1
}
Write-Host "validate-pr-body: OK"
