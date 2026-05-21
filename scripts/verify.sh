#!/usr/bin/env bash
# Purpose: Mechanically verify the items in root AGENTS.md § Agent self-check
#          that CAN be automated. Run before declaring a task done.
# When:    Local pre-PR; CI later (after toolchain pick).
# Example: bash scripts/verify.sh
#
# Exits non-zero on first failure. Each check is independent and idempotent.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

fail=0
note() { printf '  %s\n' "$1"; }
ok()   { printf '✓ %s\n' "$1"; }
err()  { printf '✗ %s\n' "$1"; fail=1; }

UNBOOTSTRAPPED=0
if [ -f .template-unbootstrapped ]; then
  UNBOOTSTRAPPED=1
  note "template-unbootstrapped sentinel present — skipping placeholder checks."
fi

# ---------------------------------------------------------------------------
# 1+2. No `@OWNER` / `<project>` placeholders anywhere in tracked files
# (post-bootstrap). Scans the full git tree, not just root files.
# ---------------------------------------------------------------------------
if [ "$UNBOOTSTRAPPED" -eq 0 ]; then
  # Tooling that processes the placeholders must reference them — exclude.
  # Also exclude .pr/ (local-PR convention discussion files may legitimately
  # cite @OWNER as a topic of review).
  exclude='^(scripts/(bootstrap|verify)\.(sh|ps1)|\.template-unbootstrapped|\.pr/.+)$'
  owner_hits=$(git ls-files -z | xargs -0 grep -lE '(^|[[:space:]])@OWNER(\b|$)' 2>/dev/null \
    | grep -vE "$exclude" || true)
  if [ -n "$owner_hits" ]; then
    err "Files still contain literal '@OWNER':"
    printf '    %s\n' $owner_hits
  else
    ok "No '@OWNER' placeholder in tracked files."
  fi
  proj_hits=$(git ls-files -z | xargs -0 grep -lE '<project>' 2>/dev/null \
    | grep -vE "$exclude" || true)
  if [ -n "$proj_hits" ]; then
    err "Files still contain '<project>' placeholder:"
    printf '    %s\n' $proj_hits
  else
    ok "No '<project>' placeholder in tracked files."
  fi
fi

# ---------------------------------------------------------------------------
# 3. No committed `.env*` (except `.env.example`).
# ---------------------------------------------------------------------------
if git ls-files -- ':(glob)**/.env' ':(glob)**/.env.*' 2>/dev/null \
  | grep -v -E '(^|/)\.env\.example$' \
  | grep . >/dev/null; then
  err "Committed .env files detected:"
  git ls-files -- ':(glob)**/.env' ':(glob)**/.env.*' \
    | grep -v -E '(^|/)\.env\.example$' \
    | sed 's/^/    /'
else
  ok "No leaked .env* files in git."
fi

# ---------------------------------------------------------------------------
# 4. Every doc file has required front-matter keys.
# ---------------------------------------------------------------------------
check_frontmatter() {
  local dir="$1"; shift
  local required=("$@")
  [ -d "$dir" ] || return 0
  while IFS= read -r f; do
    case "$(basename "$f")" in
      _TEMPLATE.md|INDEX.md) continue ;;
    esac
    # CRLF-tolerant: strip \r before pattern-matching the `---` delimiter,
    # otherwise Windows-checked-out docs (line ending `---\r`) silently fail
    # the awk pattern and head_block becomes empty.
    head_block=$(tr -d '\r' < "$f" | awk '/^---$/{c++; if(c==2) exit} c>=1')
    for key in "${required[@]}"; do
      if ! printf '%s' "$head_block" | grep -qE "^${key}:"; then
        err "$f: missing required front-matter key '$key'."
      fi
    done
  done < <(find "$dir" -maxdepth 1 -name '*.md' -type f 2>/dev/null)
}
check_frontmatter docs/adr        id title status owner date
check_frontmatter docs/rfc        id title status owner date
check_frontmatter docs/product    id title status owner date
check_frontmatter docs/issues     id title status priority parent service owner date
check_frontmatter docs/runbooks   id title service severity owner date
check_frontmatter docs/postmortems id title status owner date
ok "Front-matter check completed."

# ---------------------------------------------------------------------------
# 5. INDEX.md status column matches each doc's front-matter `status:`.
# ---------------------------------------------------------------------------
check_index_status() {
  local dir="$1"
  local index="$dir/INDEX.md"
  [ -f "$index" ] || return 0
  while IFS= read -r f; do
    case "$(basename "$f")" in
      _TEMPLATE.md|INDEX.md) continue ;;
    esac
    # CRLF-tolerant — strip \r so `grep -F "$id"` matches INDEX rows on Windows.
    id=$(awk -F': *' '/^id:/{print $2; exit}' "$f" | tr -d '\r')
    fm_status=$(awk -F': *' '/^status:/{print $2; exit}' "$f" | awk '{print $1}' | tr -d '\r')
    fm_owner=$(awk -F': *' '/^owner:/{print $2; exit}' "$f" | awk '{print $1}' | tr -d '\r')
    [ -z "$id" ] && continue
    if [ "$dir" = "docs/runbooks" ]; then
      continue
    fi
    row=$(grep -F "$id" "$index" || true)
    if [ -z "$row" ]; then
      err "$index: no row for $id (doc exists but is unindexed)."
      continue
    fi
    if [ -n "$fm_status" ] && ! printf '%s' "$row" | grep -qE "[| ]$fm_status[ |]"; then
      err "$index: status for $id does not match doc front-matter ($fm_status)."
      note "  row: $row"
    fi
    # Owner column drift check — only if the INDEX has an Owner column.
    if grep -q '| Owner ' "$index" && [ -n "$fm_owner" ]; then
      if ! printf '%s' "$row" | grep -qF "$fm_owner"; then
        err "$index: owner for $id does not match doc front-matter ($fm_owner)."
        note "  row: $row"
      fi
    fi
  done < <(find "$dir" -maxdepth 1 -name '*.md' -type f 2>/dev/null)
}
check_index_status docs/adr
check_index_status docs/rfc
check_index_status docs/product
check_index_status docs/issues
check_index_status docs/postmortems
ok "INDEX status sync check completed."

# ---------------------------------------------------------------------------
# 6. Sub-tree AGENTS.md does not repeat root rules (sanity: file size guard).
# ---------------------------------------------------------------------------
if [ -f AGENTS.md ]; then
  root_size=$(wc -l < AGENTS.md | tr -d ' ')
  warns=0
  while IFS= read -r f; do
    [ "$f" = "./AGENTS.md" ] && continue
    sub_size=$(wc -l < "$f" | tr -d ' ')
    if [ "$sub_size" -gt "$root_size" ]; then
      printf '! WARN  %s is longer than root AGENTS.md (%s > %s). Review for repeated rules.\n' \
        "$f" "$sub_size" "$root_size"
      warns=$((warns + 1))
    fi
  done < <(find . -name AGENTS.md -not -path './.git/*' -not -path './AGENTS.md')
  if [ "$warns" -eq 0 ]; then
    ok "Sub-tree AGENTS.md size sanity passed."
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
if [ "$fail" -ne 0 ]; then
  echo "verify: FAIL"
  exit 1
fi
echo "verify: OK"
