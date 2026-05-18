#!/usr/bin/env bash
# Purpose: Quarterly governance audit. Surfaces decay vectors that verify.sh
#          (per-PR) is too cheap to check on every run.
# When:    Run quarterly, or when onboarding a new maintainer.
# Example: bash scripts/audit.sh
#
# Read-only. Never modifies files. Exits 0 always — output is a report,
# not a gate.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

today_epoch=$(date +%s)
section() { printf '\n== %s ==\n' "$1"; }

# ---------------------------------------------------------------------------
# Stale `proposed` ADRs / RFCs (≥90 days without acceptance).
# ---------------------------------------------------------------------------
section "Stale 'proposed' artifacts (>90 days)"
hit=0
for dir in docs/adr docs/rfc; do
  [ -d "$dir" ] || continue
  for f in "$dir"/*.md; do
    base=$(basename "$f")
    [ "$base" = "_TEMPLATE.md" ] && continue
    [ "$base" = "INDEX.md" ] && continue
    status=$(awk -F': *' '/^status:/{print $2; exit}' "$f" | awk '{print $1}')
    date_iso=$(awk -F': *' '/^date:/{print $2; exit}' "$f" | awk '{print $1}')
    [ "$status" = "proposed" ] || continue
    [ -z "$date_iso" ] && continue
    # POSIX-ish date parsing (works on GNU + BSD via fallback).
    if date_epoch=$(date -d "$date_iso" +%s 2>/dev/null); then :;
    elif date_epoch=$(date -j -f %Y-%m-%d "$date_iso" +%s 2>/dev/null); then :;
    else continue
    fi
    age_days=$(( (today_epoch - date_epoch) / 86400 ))
    if [ "$age_days" -gt 90 ]; then
      printf '  %s — %s days proposed\n' "$f" "$age_days"
      hit=$((hit + 1))
    fi
  done
done
[ "$hit" -eq 0 ] && echo "  (none)"

# ---------------------------------------------------------------------------
# Postmortem action items not closed (lines marked TODO / not closed).
# ---------------------------------------------------------------------------
section "Postmortem action items needing follow-up"
if [ -d docs/postmortems ]; then
  hit=0
  for f in docs/postmortems/*.md; do
    base=$(basename "$f")
    [ "$base" = "_TEMPLATE.md" ] && continue
    [ "$base" = "INDEX.md" ] && continue
    # Lines starting with "| 1 |" through "| 9 |" inside Action items table
    # that mention TODO / open. Heuristic — adapt as your team's convention sets.
    if grep -nE '^\| *[0-9]+ \|.*(TODO|todo|open|OPEN)' "$f" >/dev/null 2>&1; then
      echo "  $f:"
      grep -nE '^\| *[0-9]+ \|.*(TODO|todo|open|OPEN)' "$f" | sed 's/^/    /'
      hit=$((hit + 1))
    fi
  done
  [ "$hit" -eq 0 ] && echo "  (none — or table uses different markers)"
else
  echo "  (no docs/postmortems/ yet)"
fi

# ---------------------------------------------------------------------------
# CODEOWNERS handle freshness — list distinct handles for manual review.
# (We don't call GitHub here to keep the script offline; a maintainer can
# eyeball the list against the org / leavers list.)
# ---------------------------------------------------------------------------
section "CODEOWNERS distinct handles (verify each is still active)"
if [ -f .github/CODEOWNERS ]; then
  grep -oE '@[A-Za-z0-9_/-]+' .github/CODEOWNERS \
    | grep -v '^@TBD$' \
    | sort -u \
    | sed 's/^/  /'
else
  echo "  (no CODEOWNERS file)"
fi

# ---------------------------------------------------------------------------
# Stale `<install>` / `<dev>` / `<run>` placeholders in Commands table
# (warning, not failure — agent may be working pre-toolchain-pick).
# ---------------------------------------------------------------------------
section "Toolchain Commands placeholders still present"
if [ -f AGENTS.md ]; then
  if grep -nE '\| `<(install|dev|build|run|lint|typecheck|test-one|test-all|codegen)>` \|' AGENTS.md >/dev/null 2>&1; then
    grep -nE '\| `<(install|dev|build|run|lint|typecheck|test-one|test-all|codegen)>` \|' AGENTS.md | sed 's/^/  /'
    echo "  -> pick a toolchain and fill the Commands table; see ADR-0002 if it exists."
  else
    echo "  (clean)"
  fi
fi

# ---------------------------------------------------------------------------
# Template-version drift — if .template-version is missing or older than the
# upstream marker, recommend re-syncing.
# ---------------------------------------------------------------------------
section "Template version"
if [ -f .template-version ]; then
  cat .template-version | sed 's/^/  /'
else
  echo "  (no .template-version file — consider adding one to track upstream merges)"
fi

echo
echo "audit: report complete (read-only)."
