<#
.SYNOPSIS
  PowerShell mirror of scripts/eval-agent-operability.sh.

.DESCRIPTION
  Statically verifies the agent-operability layer is present AND has
  meaningful content. Does not run an LLM.

.EXAMPLE
  pwsh scripts/eval-agent-operability.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $RepoRoot

$script:fail = 0
function Note-Ok($m)  { Write-Host "[OK]   $m" }
function Note-Err($m) { Write-Host "[FAIL] $m"; $script:fail = 1 }

function Require-File($path) {
  if (Test-Path -LiteralPath $path -PathType Leaf) { Note-Ok "exists: $path" }
  else { Note-Err "missing: $path" }
}
function Require-Dir($path) {
  if (Test-Path -LiteralPath $path -PathType Container) { Note-Ok "exists/  $path" }
  else { Note-Err "missing dir: $path" }
}
function Read-NormalisedText($path) {
  $raw = (Get-Content -LiteralPath $path -Raw)
  if ($null -eq $raw) { return '' }
  return $raw -replace "`r",""
}
function Require-Grep($file, $needle) {
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { Note-Err "cannot grep (missing file): $file"; return }
  $text = Read-NormalisedText $file
  if ($text.Contains($needle)) { Note-Ok "$file contains '$needle'" }
  else { Note-Err "$file missing '$needle'" }
}
function Require-Regex($file, $pattern, $label) {
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { Note-Err "cannot grep (missing file): $file"; return }
  $text = Read-NormalisedText $file
  if ([regex]::IsMatch($text, $pattern)) { Note-Ok "$file matches: $label" }
  else { Note-Err "$file does not match: $label  (pattern: $pattern)" }
}

# 1. Eval layer files exist.
Require-File ".agent/evals/scoring.md"
Require-File ".agent/evals/README.md"
Require-File ".agent/evals/reports/baseline-current-template.md"
Require-File ".agent/evals/reports/candidate-after-change.md"

# 2. >= 5 task files, each with required sections.
Require-Dir ".agent/evals/tasks"
$taskFiles = @(Get-ChildItem -LiteralPath ".agent/evals/tasks" -Filter 'EVAL-*.md' -File -ErrorAction SilentlyContinue)
if ($taskFiles.Count -ge 5) { Note-Ok "eval tasks present: $($taskFiles.Count) (>= 5)" }
else { Note-Err "eval tasks insufficient: $($taskFiles.Count) (< 5)" }
foreach ($tf in $taskFiles | Sort-Object Name) {
  foreach ($section in @('## Prompt','## Expected baseline','## Expected candidate')) {
    Require-Grep $tf.FullName $section
  }
}

# 3. scoring.md names all 7 dimensions.
foreach ($dim in @(
  'Context discovery',
  'Domain rule awareness',
  'Halt / ask correctness',
  'Validation evidence',
  'Minimal / safe scope',
  'PR handoff quality',
  'No rule bypassing'
)) {
  Require-Grep ".agent/evals/scoring.md" $dim
}

# 4. Reports — meaningful content.
Require-Regex ".agent/evals/reports/candidate-after-change.md" '(8[0-9]|9[0-9]|100)\s*/\s*100' "candidate score >= 80/100"
foreach ($r in @('baseline-current-template.md','candidate-after-change.md')) {
  Require-Regex ".agent/evals/reports/$r" '(estimated|static|manual)' "report acknowledges estimated/static/manual scoring"
}
Require-Regex ".agent/evals/reports/candidate-after-change.md" '\+[0-9]+' "candidate report cites a numeric improvement (e.g. +35)"

# 5. Domain knowledge layer.
Require-Dir "docs/domain"
Require-File "docs/domain/_TEMPLATE.md"
Require-File "docs/domain/AGENTS.md"
Require-File "docs/domain/INDEX.md"
Require-File "docs/domain/tenant-customization.md"
Require-File "docs/domain/pricing-rules.md"
Require-File "docs/domain/permission-model.md"

# 6. Known traps + ownership.
Require-File "docs/known-traps.md"
Require-Grep "docs/known-traps.md" "KT-0001"
Require-Grep "docs/known-traps.md" "KT-0002"
Require-File "docs/ownership-map.md"
foreach ($level in @('implement','guarded','plan-only','forbidden')) {
  Require-Grep "docs/ownership-map.md" "``${level}``"
}

# 7. .agent/ layer — routes + permission flags.
Require-File ".agent/context-map.yml"
$ctxText = Read-NormalisedText ".agent/context-map.yml"
foreach ($route in @('"services/**":','"packages/**":','"apps/**":','"docs/domain/**":','"infra/envs/prod/**":')) {
  $pattern = "(?m)^\s*" + [regex]::Escape($route)
  if ([regex]::IsMatch($ctxText, $pattern)) { Note-Ok ".agent/context-map.yml has route $route" }
  else { Note-Err ".agent/context-map.yml missing route $route" }
}
Require-File ".agent/permissions.yml"
Require-Grep ".agent/permissions.yml" "merge: false"
Require-Grep ".agent/permissions.yml" "approve_pr: false"
Require-Grep ".agent/permissions.yml" "self_flip_status: false"
Require-Grep ".agent/permissions.yml" "self_assign_owner: false"

# 8. PR template additions.
Require-Grep ".github/PULL_REQUEST_TEMPLATE.md" "Knowledge checked"
Require-Grep ".github/PULL_REQUEST_TEMPLATE.md" "Validation evidence"
Require-Grep ".github/PULL_REQUEST_TEMPLATE.md" "Agent assumptions"
Require-Grep ".github/PULL_REQUEST_TEMPLATE.md" "Risk classification"

# 9. Root AGENTS.md wiring.
Require-Grep "AGENTS.md" "Product knowledge for agents"
Require-Grep "AGENTS.md" "docs/domain"
Require-Grep "AGENTS.md" "docs/known-traps.md"
Require-Grep "AGENTS.md" "docs/ownership-map.md"
Require-Grep "AGENTS.md" ".agent/context-map.yml"

# 10. Patterns + issue template + PR-body validator scripts.
Require-File "docs/patterns/agent-task-contract.md"
Require-File ".github/ISSUE_TEMPLATE/agent-task.yml"
Require-File "scripts/validate-pr-body.sh"   # exec bit check not applicable on Windows
Require-File "scripts/validate-pr-body.ps1"

Write-Host ""
if ($script:fail -ne 0) {
  Write-Host "eval-agent-operability: FAIL"
  exit 1
}
Write-Host "eval-agent-operability: OK"
