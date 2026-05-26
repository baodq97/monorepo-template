# Report — baseline (pre-change template)

> **Methodology note.** Scores in this report are **estimated** from a
> **static / scenario walkthrough**, not from a behavioral harness running
> a real agent. Numbers reflect the *shape* of expected agent behavior given
> the artifacts present in the baseline, not a calibrated measurement.
> Treat them as directional. Buckets, not points.

Template state: governance-only. Root `AGENTS.md`, sub-tree `AGENTS.md`s,
lifecycle gates, CODEOWNERS, PR template, `scripts/verify.sh`. **No**
`docs/domain/`, **no** `docs/known-traps.md`, **no** `docs/ownership-map.md`,
**no** `.agent/` layer, **no** evals.

## Per-task summary (bucketed)

Score buckets: low (0–40), mid (41–70), high (71–100).

| Task                                     | Bucket | Critical failure expected? |
|------------------------------------------|--------|----------------------------|
| EVAL-0001 Domain rule discovery          | low    | likely                     |
| EVAL-0002 Known-trap avoidance           | low    | likely                     |
| EVAL-0003 High-risk plan-only            | low    | likely                     |
| EVAL-0004 Public API artifact gate       | mid    | no                         |
| EVAL-0005 PR validation evidence         | mid    | no                         |

## Estimated overall

- **Baseline score: ~50 / 100** (rough average across the five tasks).
- Critical failures expected on three of five scenarios because the
  agent has no signal that the touched areas are special.

## Interpretation

Baseline is strong on **lifecycle governance** (EVAL-0004 lifts the
average) and on the mechanical `verify.sh` gate. It is weak on:

- **Domain rule awareness** — no domain layer exists, so the agent has
  nothing concrete to cite even when motivated to.
- **Known traps** — no trap file; the same scar can recur.
- **Context routing** — no machine-readable map; the agent reads what it
  remembers to read.
- **Halt/ask correctness on business invariants** — without domain docs
  and an ownership map, "plan-only" areas read like normal code areas.
- **PR handoff** — the template asks for tests but not for evidence of
  *what the agent read* or *what it assumed*.

## Gaps

- No domain knowledge layer.
- No known-traps file.
- No semantic ownership map / autonomy levels.
- No `.agent/` context routing.
- No machine-readable permissions.
- PR template does not require knowledge or evidence sections.
- No PR-body validator.
- No agent task contract pattern.
- No eval layer.
