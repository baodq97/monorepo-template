#!/usr/bin/env bash
# Purpose: Statically verify the agent-operability layer is present AND has
#          meaningful content. Does NOT run an LLM. This guarantees the
#          inputs a behavioral eval needs are all in place and well-formed.
#
# Usage:   bash scripts/eval-agent-operability.sh
#
# Exits non-zero on first failure.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

fail=0
ok()  { printf '✓ %s\n' "$1"; }
err() { printf '✗ %s\n' "$1"; fail=1; }

require_file() {
  local path="$1"
  if [ -f "$path" ]; then ok "exists: $path"; else err "missing: $path"; fi
}

require_dir() {
  local path="$1"
  if [ -d "$path" ]; then ok "exists/  $path"; else err "missing dir: $path"; fi
}

require_exec() {
  local path="$1"
  if [ ! -f "$path" ]; then
    err "missing (cannot check exec bit): $path"
    return
  fi
  # On Windows checkouts the executable bit may not survive; treat readable
  # as sufficient there, but warn loudly if neither is true.
  if [ -x "$path" ]; then
    ok "exists+exec: $path"
  elif [ -r "$path" ]; then
    ok "exists (not +x; Windows checkout?): $path"
  else
    err "unreadable: $path"
  fi
}

require_grep() {
  local file="$1" needle="$2"
  if [ ! -f "$file" ]; then err "cannot grep (missing file): $file"; return; fi
  if tr -d '\r' < "$file" | grep -qF "$needle"; then
    ok "$file contains '$needle'"
  else
    err "$file missing '$needle'"
  fi
}

require_regex() {
  local file="$1" pattern="$2" label="$3"
  if [ ! -f "$file" ]; then err "cannot grep (missing file): $file"; return; fi
  if tr -d '\r' < "$file" | grep -qE "$pattern"; then
    ok "$file matches: $label"
  else
    err "$file does not match: $label  (pattern: $pattern)"
  fi
}

# ---------------------------------------------------------------------------
# 1. Eval layer files exist.
# ---------------------------------------------------------------------------
require_file ".agent/evals/scoring.md"
require_file ".agent/evals/README.md"
require_file ".agent/evals/reports/baseline-current-template.md"
require_file ".agent/evals/reports/candidate-after-change.md"

# ---------------------------------------------------------------------------
# 2. At least 5 eval task files, each with required sections.
# ---------------------------------------------------------------------------
require_dir ".agent/evals/tasks"
task_count=$(find .agent/evals/tasks -maxdepth 1 -type f -name 'EVAL-*.md' 2>/dev/null | wc -l | tr -d ' ' || echo 0)
if [ "$task_count" -ge 5 ]; then
  ok "eval tasks present: $task_count (>= 5)"
else
  err "eval tasks insufficient: $task_count (< 5)"
fi
while IFS= read -r tf; do
  for section in "## Prompt" "## Expected baseline" "## Expected candidate"; do
    require_grep "$tf" "$section"
  done
done < <(find .agent/evals/tasks -maxdepth 1 -type f -name 'EVAL-*.md' 2>/dev/null | sort)

# ---------------------------------------------------------------------------
# 3. scoring.md names all 7 dimensions.
# ---------------------------------------------------------------------------
for dim in \
  "Context discovery" \
  "Domain rule awareness" \
  "Halt / ask correctness" \
  "Validation evidence" \
  "Minimal / safe scope" \
  "PR handoff quality" \
  "No rule bypassing"
do
  require_grep ".agent/evals/scoring.md" "$dim"
done

# ---------------------------------------------------------------------------
# 4. Reports — meaningful content, not just file presence.
# ---------------------------------------------------------------------------
# Candidate must claim a score >= 80 (we look for ~85/100, 85/100, or
# explicit ">= 80").
require_regex ".agent/evals/reports/candidate-after-change.md" \
  '(8[0-9]|9[0-9]|100)[[:space:]]*/[[:space:]]*100' \
  "candidate score >= 80/100"

# Both reports must acknowledge the manual / static / estimated nature.
for r in baseline-current-template.md candidate-after-change.md; do
  require_regex ".agent/evals/reports/$r" \
    '(estimated|static|manual)' \
    "report acknowledges estimated/static/manual scoring"
done

# Candidate must mention the delta threshold satisfaction.
require_regex ".agent/evals/reports/candidate-after-change.md" \
  '\+[0-9]+' \
  "candidate report cites a numeric improvement (e.g. +35)"

# ---------------------------------------------------------------------------
# 5. Domain knowledge layer.
# ---------------------------------------------------------------------------
require_dir "docs/domain"
require_file "docs/domain/_TEMPLATE.md"
require_file "docs/domain/AGENTS.md"
require_file "docs/domain/INDEX.md"
require_file "docs/domain/tenant-customization.md"
require_file "docs/domain/pricing-rules.md"
require_file "docs/domain/permission-model.md"

# ---------------------------------------------------------------------------
# 6. Known traps + ownership.
# ---------------------------------------------------------------------------
require_file "docs/known-traps.md"
require_grep "docs/known-traps.md" "KT-0001"
require_grep "docs/known-traps.md" "KT-0002"
require_file "docs/ownership-map.md"
for level in implement guarded plan-only forbidden; do
  require_grep "docs/ownership-map.md" "\`$level\`"
done

# ---------------------------------------------------------------------------
# 7. .agent/ layer — routes and permission flags.
# ---------------------------------------------------------------------------
require_file ".agent/context-map.yml"
for route in \
  '"services/\*\*":' \
  '"packages/\*\*":' \
  '"apps/\*\*":' \
  '"docs/domain/\*\*":' \
  '"infra/envs/prod/\*\*":'
do
  if tr -d '\r' < .agent/context-map.yml | grep -qE "^[[:space:]]*${route}"; then
    ok ".agent/context-map.yml has route ${route}"
  else
    err ".agent/context-map.yml missing route ${route}"
  fi
done

require_file ".agent/permissions.yml"
require_grep ".agent/permissions.yml" "merge: false"
require_grep ".agent/permissions.yml" "approve_pr: false"
require_grep ".agent/permissions.yml" "self_flip_status: false"
require_grep ".agent/permissions.yml" "self_assign_owner: false"

# ---------------------------------------------------------------------------
# 8. PR template additions.
# ---------------------------------------------------------------------------
require_grep ".github/PULL_REQUEST_TEMPLATE.md" "Knowledge checked"
require_grep ".github/PULL_REQUEST_TEMPLATE.md" "Validation evidence"
require_grep ".github/PULL_REQUEST_TEMPLATE.md" "Agent assumptions"
require_grep ".github/PULL_REQUEST_TEMPLATE.md" "Risk classification"

# ---------------------------------------------------------------------------
# 9. Root AGENTS.md product-knowledge wiring.
# ---------------------------------------------------------------------------
require_grep "AGENTS.md" "Product knowledge for agents"
require_grep "AGENTS.md" "docs/domain"
require_grep "AGENTS.md" "docs/known-traps.md"
require_grep "AGENTS.md" "docs/ownership-map.md"
require_grep "AGENTS.md" ".agent/context-map.yml"

# ---------------------------------------------------------------------------
# 10. Patterns + issue template + PR-body validator scripts.
# ---------------------------------------------------------------------------
require_file "docs/patterns/agent-task-contract.md"
require_file ".github/ISSUE_TEMPLATE/agent-task.yml"
require_exec "scripts/validate-pr-body.sh"
require_file "scripts/validate-pr-body.sh"

echo
if [ "$fail" -ne 0 ]; then
  echo "eval-agent-operability: FAIL"
  exit 1
fi
echo "eval-agent-operability: OK"
