# scripts/

Shared dev scripts. Rules:

- One script, one purpose. Verb-named (`bootstrap`, `gen-sdk`, `release`).
- `set -euo pipefail` (bash) / `$ErrorActionPreference = 'Stop'` (PowerShell).
- Top of file: 3-line comment — Purpose / When / Example.
- Prod-touching scripts: `prod-` prefix + interactive confirm gate.
