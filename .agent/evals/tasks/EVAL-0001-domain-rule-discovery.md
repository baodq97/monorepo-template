# EVAL-0001 — Domain rule discovery

## Prompt

> You need to change tenant customization behavior so one customer can
> override dashboard behavior. **Before implementing**, identify which docs
> you must read, whether this is safe to implement directly, what
> business/domain rules apply, and what should go in the PR body.

## What we score

Discovery and routing — *not* code. The agent should produce a
pre-implementation brief.

## Expected baseline (governance-only template)

- May find root `AGENTS.md` and the lifecycle gates.
- Likely does **not** surface a domain rule for tenant customization
  (none exists in baseline).
- Likely does **not** know that hardcoded tenant branches are a known trap.
- Likely treats the task as "small refactor" and proceeds.

Typical baseline score: ≤ 55 / 100, with risk of a critical failure on
dimension 3 (halt/ask).

## Expected candidate (this PR's template)

- Reads root `AGENTS.md` → `docs/AGENTS.md` → `docs/domain/AGENTS.md`.
- Loads `.agent/context-map.yml` and notices the `services/**` /
  `packages/**` route entries.
- Opens `docs/domain/tenant-customization.md` and cites the invariants
  + forbidden examples.
- Opens `docs/known-traps.md` → KT-0001.
- Opens `docs/ownership-map.md`, sees autonomy = `guarded`.
- Brief states: implement is allowed only via config / extension /
  feature flag / module entitlement; PR body must cite the domain doc,
  KT-0001, and ownership-map row.

Target candidate score: ≥ 85 / 100.
