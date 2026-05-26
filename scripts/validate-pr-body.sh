#!/usr/bin/env bash
# Purpose: Validate that a PR body contains the agent-operability sections
#          required by .github/PULL_REQUEST_TEMPLATE.md, **and** that those
#          sections are actually filled in — not left as empty labels from
#          an unmodified template.
#
# Usage:   bash scripts/validate-pr-body.sh <pr-body-file> <changed-files-file>
#
# Inputs:  pr-body-file        — file containing the PR description text.
#          changed-files-file  — file containing one changed path per line
#                                (e.g. `git diff --name-only origin/main`).
#
# Exits non-zero on the first failure. Toolchain-agnostic. No network / no gh.

set -euo pipefail

fail=0
ok()  { printf '✓ %s\n' "$1"; }
err() { printf '✗ %s\n' "$1"; fail=1; }

usage() {
  echo "usage: $0 <pr-body-file> <changed-files-file>" >&2
  exit 2
}

[ "$#" -eq 2 ] || usage
body="$1"
changed="$2"

if [ ! -f "$body" ]; then
  err "PR body file not found: $body"
  exit 1
fi
if [ ! -f "$changed" ]; then
  err "Changed-files file not found: $changed"
  exit 1
fi

body_text=$(tr -d '\r' < "$body")
changed_text=$(tr -d '\r' < "$changed")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Section presence — header must appear in body.
section_present() {
  local header="$1"
  local esc
  esc=$(printf '%s' "$header" | sed 's/[][\\.*^$(){}?+|/]/\\\\&/g')
  printf '%s\n' "$body_text" | grep -qE "^[[:space:]]*#{1,6}[[:space:]]+${esc}[[:space:]]*$"
}

# Field has a non-empty, non-placeholder value.
# Matches "- <Label>: <value>" or "* <Label>: <value>" or "<Label>: <value>".
# Value must contain at least one non-whitespace char that is not '<' (to
# reject literal "<fill in>" / "<placeholder>" style stubs).
field_has_value() {
  local label="$1"
  # Escape regex metachars in label.
  local esc
  esc=$(printf '%s' "$label" | sed 's/[][\\.*^$(){}?+|/]/\\\\&/g')
  printf '%s\n' "$body_text" \
    | grep -qE "^[[:space:]]*([-*][[:space:]]+)?${esc}:[[:space:]]+[^[:space:]<].*"
}

paths_match() {
  printf '%s\n' "$changed_text" | grep -qE "$1"
}

# ---------------------------------------------------------------------------
# 1. Required sections must be present.
# ---------------------------------------------------------------------------
for section in "Knowledge checked" "Agent assumptions" "Validation evidence" "Risk classification"; do
  if section_present "$section"; then
    ok "PR body has section '$section'."
  else
    err "PR body missing section '$section'."
  fi
done

# ---------------------------------------------------------------------------
# 2. Knowledge checked — at least the nearest-AGENTS.md field must be filled.
# ---------------------------------------------------------------------------
if section_present "Knowledge checked"; then
  if field_has_value "Nearest AGENTS.md"; then
    ok "Knowledge checked: 'Nearest AGENTS.md' is filled."
  else
    err "Knowledge checked: 'Nearest AGENTS.md' is blank (unmodified template?)."
  fi
fi

# ---------------------------------------------------------------------------
# 3. Agent assumptions — Assumption + Why it is safe must be filled.
# ---------------------------------------------------------------------------
if section_present "Agent assumptions"; then
  if field_has_value "Assumption"; then
    ok "Agent assumptions: 'Assumption' is filled."
  else
    err "Agent assumptions: 'Assumption' is blank."
  fi
  if field_has_value "Why it is safe"; then
    ok "Agent assumptions: 'Why it is safe' is filled."
  else
    err "Agent assumptions: 'Why it is safe' is blank."
  fi
fi

# ---------------------------------------------------------------------------
# 4. Validation evidence — Command and Result must both be filled.
# ---------------------------------------------------------------------------
if section_present "Validation evidence"; then
  if field_has_value "Command"; then
    ok "Validation evidence: 'Command' is filled."
  else
    err "Validation evidence: 'Command' is blank."
  fi
  if field_has_value "Result"; then
    ok "Validation evidence: 'Result' is filled."
  else
    err "Validation evidence: 'Result' is blank."
  fi
fi

# ---------------------------------------------------------------------------
# 5. Risk classification — at least one checkbox ticked.
# ---------------------------------------------------------------------------
if section_present "Risk classification"; then
  if printf '%s\n' "$body_text" | grep -qE '^[[:space:]]*-[[:space:]]+\[[xX]\][[:space:]]+(low|medium|high|critical)\b'; then
    ok "Risk classification: a level is checked."
  else
    err "Risk classification: no level is checked."
  fi
fi

# ---------------------------------------------------------------------------
# 6. Path-specific citations — touching certain subtrees demands a real
#    AGENTS.md reference (label must carry a value, not just appear as a
#    bullet stub in the template).
# ---------------------------------------------------------------------------

# Helper: confirm a path name appears anywhere after a colon (i.e. as a
# value, not as a template stub).
mention_has_value() {
  local needle="$1"
  printf '%s\n' "$body_text" \
    | grep -qE ":[[:space:]].*${needle}"
}

if paths_match '(^|/)services/'; then
  if mention_has_value "services/AGENTS\.md"; then
    ok "services/** touched → PR body cites services/AGENTS.md as a value."
  else
    err "services/** touched but PR body does not cite services/AGENTS.md as a filled value."
  fi
fi

if paths_match '(^|/)packages/'; then
  if mention_has_value "packages/AGENTS\.md"; then
    ok "packages/** touched → PR body cites packages/AGENTS.md as a value."
  else
    err "packages/** touched but PR body does not cite packages/AGENTS.md as a filled value."
  fi
fi

if paths_match '(^|/)docs/domain/'; then
  if mention_has_value "docs/domain/AGENTS\.md"; then
    ok "docs/domain/** touched → PR body cites docs/domain/AGENTS.md as a value."
  else
    err "docs/domain/** touched but PR body does not cite docs/domain/AGENTS.md as a filled value."
  fi
fi

if paths_match '(^|/)infra/envs/prod/'; then
  if printf '%s\n' "$body_text" | grep -qE 'ADR-[0-9A-Za-z_-]+'; then
    ok "infra/envs/prod/** touched → PR body cites an ADR-… id."
  else
    err "infra/envs/prod/** touched but PR body does not reference an 'ADR-' id."
  fi
fi

echo
if [ "$fail" -ne 0 ]; then
  echo "validate-pr-body: FAIL"
  exit 1
fi
echo "validate-pr-body: OK"
