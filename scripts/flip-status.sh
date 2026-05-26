#!/usr/bin/env bash
# Purpose: Flip the `status:` front-matter field of a doc artifact, then
#          rebuild the containing INDEX so verify.sh stays happy.
# When:    Doc owner approves a status transition (draft→approved, etc.).
# Example: bash scripts/flip-status.sh docs/rfc/RFC-0001-foo.md accepted

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: flip-status.sh <doc-path> <new-status>" >&2
  exit 2
fi

doc="$1"
new_status="$2"

if [ ! -f "$doc" ]; then
  echo "error: not a file: $doc" >&2
  exit 1
fi

# Verify front-matter has a status: line
if ! tr -d '\r' < "$doc" | awk '/^---$/{c++; if(c==2) exit} c==1' | grep -q '^status:'; then
  echo "error: no status: in front-matter of $doc" >&2
  exit 1
fi

# Cross-platform sed-in-place
sedi() {
  if [ "$(uname)" = "Darwin" ]; then sed -i '' "$@"; else sed -i "$@"; fi
}

sedi "s/^status:[[:space:]].*$/status: ${new_status}/" "$doc"
echo "flipped $doc → status: $new_status"

# Rebuild the INDEX of the parent directory
dir=$(dirname "$doc")
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bash "$REPO_ROOT/scripts/rebuild-indexes.sh"
