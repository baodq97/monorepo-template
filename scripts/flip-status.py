#!/usr/bin/env python3
"""Flip the `status:` front-matter field of a doc artifact.

Usage:
    uv run python scripts/flip-status.py docs/rfc/RFC-0001-foo.md accepted
"""

import re
import sys
import pathlib


def main():
    if len(sys.argv) != 3:
        print("usage: flip-status.py <doc-path> <new-status>", file=sys.stderr)
        return 2
    doc, newstatus = sys.argv[1], sys.argv[2]
    p = pathlib.Path(doc)
    if not p.is_file():
        print(f"not a file: {doc}", file=sys.stderr)
        return 1
    text = p.read_text(encoding="utf-8")
    m = re.match(r"^(---\r?\n.*?\r?\n---\r?\n)", text, re.DOTALL)
    if not m:
        print(f"no front-matter in {doc}", file=sys.stderr)
        return 1
    fm = m.group(1)
    if not re.search(r"^status:", fm, re.M):
        print(f"no status: in front-matter of {doc}", file=sys.stderr)
        return 1
    fm_new = re.sub(r"^status:\s*\S+", f"status: {newstatus}",
                    fm, count=1, flags=re.M)
    p.write_text(fm_new + text[m.end():], encoding="utf-8")
    print(f"flipped {doc} status to {newstatus}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
