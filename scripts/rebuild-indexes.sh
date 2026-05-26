#!/usr/bin/env bash
# Purpose: Rebuild docs/<type>/INDEX.md from each artifact's front-matter.
# When:    After creating/editing any doc artifact, or as a CI safety net.
# Example: bash scripts/rebuild-indexes.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

changed=0

# Extract front-matter value for a key (full value, trimmed, comments stripped).
fm() {
  tr -d '\r' < "$1" | awk -v k="$2" '
    /^---$/ { c++; if (c==2) exit; next }
    c==1 && index($0, k ": ")==1 {
      sub(k ": ", "")
      sub(/[[:space:]]+#.*/, "")
      sub(/[[:space:]]+$/, "")
      print
      exit
    }
  '
}

# Capitalize words: "last_drill" → "Last Drill"
label_for() {
  printf '%s' "$1" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1'
}

# rebuild <dir> <col1:col2:...>
rebuild() {
  local dir="$1"
  IFS=':' read -ra cols <<< "$2"

  [ -d "$dir" ] || return 0

  local index="$dir/INDEX.md"
  local tmpfile
  tmpfile=$(mktemp)
  trap "rm -f '$tmpfile'" RETURN

  # Preserve preamble (everything before the first | line).
  if [ -f "$index" ]; then
    tr -d '\r' < "$index" | awk '/^\|/{exit} {print}' > "$tmpfile"
    # Trim trailing blank lines, keep one
    local last_non_blank
    last_non_blank=$(awk 'NF{line=NR} END{print line+0}' "$tmpfile")
    if [ "$last_non_blank" -gt 0 ]; then
      head -n "$last_non_blank" "$tmpfile" > "${tmpfile}.trim"
      mv "${tmpfile}.trim" "$tmpfile"
    fi
  fi

  # Fallback if no preamble
  if [ ! -s "$tmpfile" ]; then
    echo "# INDEX — ${dir}" > "$tmpfile"
  fi

  # Blank line before table
  echo "" >> "$tmpfile"

  # Header + separator
  local hdr="|" sep="|"
  for col in "${cols[@]}"; do
    hdr="$hdr $(label_for "$col") |"
    sep="$sep---|"
  done
  echo "$hdr" >> "$tmpfile"
  echo "$sep" >> "$tmpfile"

  # Collect data rows into a temp, then sort by ID
  local rowfile
  rowfile=$(mktemp)
  local count=0
  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    local base
    base=$(basename "$f")
    case "$base" in _TEMPLATE.md|INDEX.md|README.md|AGENTS.md) continue ;; esac

    local id
    id=$(fm "$f" "id")
    [ -z "$id" ] && continue

    local row="| [$id]($base)"
    for col in "${cols[@]}"; do
      [ "$col" = "id" ] && continue
      row="$row | $(fm "$f" "$col")"
    done
    echo "$row |" >> "$rowfile"
    count=$((count + 1))
  done

  # Sort rows by the link text [ID]
  sort -t'[' -k2,2 "$rowfile" >> "$tmpfile"
  rm -f "$rowfile"

  # Compare and write
  if [ -f "$index" ] && diff -q <(tr -d '\r' < "$index") "$tmpfile" >/dev/null 2>&1; then
    rm -f "$tmpfile"
    return 0
  fi

  mv "$tmpfile" "$index"
  changed=$((changed + 1))
  echo "rebuilt $index ($count rows)"
}

rebuild "docs/product"     "id:title:status:owner:date"
rebuild "docs/rfc"         "id:title:status:owner:date"
rebuild "docs/adr"         "id:title:status:owner:date"
rebuild "docs/issues"      "id:title:priority:status:service:blocks:parent"
rebuild "docs/postmortems" "id:title:status:owner:severity:date"
rebuild "docs/domain"      "id:title:risk:status:owner:date"
rebuild "docs/runbooks"    "id:title:service:severity:last_drill"

echo "done: $changed INDEX file(s) updated"
