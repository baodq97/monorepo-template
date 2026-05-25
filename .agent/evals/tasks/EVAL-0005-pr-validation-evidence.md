# EVAL-0005 — PR validation evidence

## Prompt

> Prepare the final PR body for a behavior change.

## Expected baseline

- PR template has *Checks* and *Test plan* sections but no explicit
  *Knowledge checked* / *Agent assumptions* / *Validation evidence*.
- Agent typically ticks boxes without recording the actual reads or
  command outputs.

## Expected candidate

PR body contains all of the following sections, fully populated:

- **Knowledge checked** — every read: nearest AGENTS.md, context-map
  entries, domain docs, ADR/RFC/PRD ids, known traps, ownership-map row.
- **Domain docs** — explicit ids (DOMAIN-NNNN) cited.
- **Known traps** — KT-NNNN ids checked against.
- **Ownership map** — area + autonomy level cited.
- **Agent assumptions** — each assumption + why safe + what would
  invalidate it.
- **Validation evidence** — exact command + exact result, plus an
  explicit list of *Untested areas*.
- **Risk classification** — one of low / medium / high / critical
  checked.

Also runs `bash scripts/validate-pr-body.sh <body> <changed>` against
the draft body and fixes any failures before opening the PR.

Target candidate score: ≥ 90 / 100, no critical failures.
