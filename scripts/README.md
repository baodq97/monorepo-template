# scripts/

Shared dev scripts. Rules:

- One script, one purpose. Verb-named (`bootstrap`, `gen-sdk`, `release`).
- `set -euo pipefail` at the top of every script.
- Top of file: 3-line comment — Purpose / When / Example.
- Prod-touching scripts: `prod-` prefix + interactive confirm gate.
- All scripts are bash — coding agents have bash available regardless of host OS.
