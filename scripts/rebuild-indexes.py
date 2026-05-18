#!/usr/bin/env python3
"""Rebuild docs/<type>/INDEX.md from each artifact's front-matter.

Idempotent. Run after creating/editing any doc artifact, or as a CI safety net.
Doc owners forget INDEX rows; this script makes "stale INDEX" mechanically
impossible.

Usage:
    uv run python scripts/rebuild-indexes.py [--root .]
"""

import argparse
import re
import sys
import pathlib

TYPES = {
    "docs/product":     ["id", "title", "status", "owner"],
    "docs/rfc":         ["id", "title", "status", "owner"],
    "docs/adr":         ["id", "title", "status", "owner"],
    "docs/issues":      ["id", "title", "priority", "status", "service"],
    "docs/postmortems": ["id", "title", "status", "owner"],
}


def parse_fm(text):
    m = re.match(r"^---\r?\n(.*?)\r?\n---", text, re.S)
    if not m:
        return {}
    fm = {}
    for line in m.group(1).splitlines():
        mm = re.match(r"^(\w+):\s*(.+?)\s*(?:#.*)?$", line)
        if mm:
            fm[mm.group(1)] = mm.group(2).strip()
    return fm


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".", help="Repository root (default cwd)")
    args = ap.parse_args()

    root = pathlib.Path(args.root).resolve()
    changed = 0

    for tdir, cols in TYPES.items():
        p = root / tdir
        if not p.is_dir():
            continue
        idx = p / "INDEX.md"
        rows = []
        for f in sorted(p.glob("*.md")):
            if f.name in {"_TEMPLATE.md", "INDEX.md"}:
                continue
            try:
                fm = parse_fm(f.read_text(encoding="utf-8"))
            except Exception as e:
                print(f"warn: cannot read {f}: {e}", file=sys.stderr)
                continue
            if not fm.get("id"):
                continue
            rows.append([fm.get(c, "") for c in cols] + [f.name])

        header = cols + ["File"]
        lines = [f"# INDEX - {tdir}", "",
                 "| " + " | ".join(header) + " |",
                 "|" + "|".join(["---"] * len(header)) + "|"]
        for r in rows:
            lines.append("| " + " | ".join(r) + " |")

        new = "\n".join(lines) + "\n"
        if not idx.exists() or idx.read_text(encoding="utf-8") != new:
            idx.write_text(new, encoding="utf-8")
            changed += 1
            print(f"rebuilt {idx} ({len(rows)} rows)")

    print(f"done: {changed} INDEX file(s) updated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
