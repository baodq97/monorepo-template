#!/usr/bin/env bash
# Purpose: One-shot rename of template placeholders. Run once after cloning.
# When:    Immediately after `git clone` / "Use this template".
# Example: bash scripts/bootstrap.sh my-project @acme-eng
#
# Replaces:
#   - `<project>` → $1 in README.md + AGENTS.md (titles only)
#   - `@OWNER`    → $2 in .github/CODEOWNERS (all entries)
#   - `owner: TBD` → $2 in docs/adr/ADR-0001-record-architecture-decisions.md
#
# Idempotent: re-running with the same args is a no-op.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  cat >&2 <<USAGE
usage: $0 <project-name> <@github-handle-or-team>
example: $0 acme-platform @acme/eng
USAGE
  exit 2
fi

PROJECT="$1"
OWNER="$2"

case "$OWNER" in
  @*) ;;
  *) echo "error: owner must start with '@' (e.g. @alice or @acme/eng)" >&2; exit 2 ;;
esac

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Cross-platform sed-in-place wrapper.
sedi() {
  if [ "$(uname)" = "Darwin" ]; then sed -i '' "$@"; else sed -i "$@"; fi
}

echo "→ project name: $PROJECT"
echo "→ owner:        $OWNER"
echo

# Rename `<project>` only in the documented files (README + root AGENTS title).
for f in README.md AGENTS.md; do
  if grep -q '<project>' "$f"; then
    sedi "s/<project>/${PROJECT}/g" "$f"
    echo "✓ patched $f"
  else
    echo "· $f already patched"
  fi
done

# Rename @OWNER in CODEOWNERS.
if [ -f .github/CODEOWNERS ]; then
  if grep -qE '(^|[[:space:]])@OWNER(\b|$)' .github/CODEOWNERS; then
    # Escape forward slashes in owner (teams use @org/team).
    esc=$(printf '%s' "$OWNER" | sed 's/[\/&]/\\&/g')
    sedi "s/@OWNER/${esc}/g" .github/CODEOWNERS
    echo "✓ patched .github/CODEOWNERS"
  else
    echo "· .github/CODEOWNERS already patched"
  fi
fi

# Fill ADR-0001 owner.
ADR1="docs/adr/ADR-0001-record-architecture-decisions.md"
if [ -f "$ADR1" ]; then
  if grep -qE '^owner:\s*TBD' "$ADR1"; then
    esc=$(printf '%s' "$OWNER" | sed 's/[\/&]/\\&/g')
    sedi "s/^owner:[[:space:]]*TBD.*/owner: ${esc}/" "$ADR1"
    echo "✓ patched $ADR1 (owner: $OWNER)"
  else
    echo "· $ADR1 owner already set"
  fi
fi

# Mirror the ADR-0001 owner into the ADR INDEX row (keeps verify happy).
ADR_INDEX="docs/adr/INDEX.md"
if [ -f "$ADR_INDEX" ] && grep -q 'ADR-0001' "$ADR_INDEX" && grep -q '| TBD | 2026-05-16 |' "$ADR_INDEX"; then
  esc=$(printf '%s' "$OWNER" | sed 's/[\/&]/\\&/g')
  sedi "s/| TBD | 2026-05-16 |/| ${esc} | 2026-05-16 |/" "$ADR_INDEX"
  echo "✓ patched $ADR_INDEX (ADR-0001 owner row)"
fi

if [ -f .template-unbootstrapped ]; then
  rm .template-unbootstrapped
  echo "✓ removed .template-unbootstrapped sentinel"
fi

echo
echo "Next steps:"
echo "  1. Pick toolchain; fill the Commands table in AGENTS.md."
echo "  2. Run: bash scripts/verify.sh"
echo "  3. Write ADR-0002 recording the toolchain choice."
