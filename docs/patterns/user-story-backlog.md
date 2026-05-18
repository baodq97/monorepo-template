# Pattern — Prioritized US backlog (between RFC and Code)

> **Pattern reference, not core harness.** Root `AGENTS.md` says
> `Max path: PRD → RFC → ADR → Issue/PR → Code`. The "Issue" stage is where an
> accepted RFC turns into something a single implementor can pick up in one
> sitting. Skip for solo small features. Adopt when ≥2 implementors share an
> RFC, or when a non-interactive agent will do the work and must know what to
> finish first under a budget cap.

## Why opt-in

A solo developer working a small feature can keep the breakdown in their head
or in the PR description. The cost of opening 8 ticket files for a 200-LoC
change is real overhead. But the moment a feature is sliced across two or more
implementors — or one implementor is an agent on a budget — the breakdown has
to be **written down and prioritized** before code starts. Otherwise:

1. Implementor A and B duplicate scaffolding work, conflict on `package.json`.
2. The agent burns its whole budget on F3 (nice-to-have) and never delivers F1
   (the smoke-test target).
3. Reviewer can only judge "did the whole branch land?" — not "which slice".

## The rule

When this pattern is active, an **accepted** RFC must be followed by a
prioritized US backlog under `docs/issues/` **before any implementor starts**.

Each US is one file: `docs/issues/US-NNN-<kebab-slug>.md`. Required
front-matter and body:

```markdown
---
id: US-NNN
title: <one line>
status: open                  # open | in_progress | done | dropped
priority: P0                  # P0 must-have | P1 should-have | P2 nice-to-have
owner: TBD
parent: RFC-XXXX              # the accepted RFC this US slices
blocks: [US-NNN, ...]         # other US that cannot start until this one is done
service: billing-api          # subtree this US lands in (one of services/* | apps/* | packages/*)
date: YYYY-MM-DD
---

## Acceptance criteria

- [ ] One bullet, observable, ≤3 bullets total.
- [ ] Failure mode the AC kills (so reviewer knows what to grep for).

## Files to touch

- `services/billing-api/src/routes/meter.ts` — create
- `services/billing-api/tests/meter.test.ts` — create

## Test name

`vitest -t "POST /v1/meter accepts valid event"`

## Out of scope

What this US explicitly does NOT do (kills scope creep at PR time).
```

## Priority semantics (enforced by reviewer)

- **P0 — must-have.** Foundation (scaffold, healthz, smoke test) or the
  feature's vertical-slice MVP. Missing P0 → reviewer **must** reject.
- **P1 — should-have.** Expected for full RFC delivery. Missing P1 → verdict
  `SHIP-WITH-CAVEATS` is acceptable.
- **P2 — nice-to-have.** Defer is OK; no penalty. Becomes a follow-up US.

`blocks:` is a dependency, not a priority. A P0 US can `blocks: US-002` where
US-002 is also P0 — meaning they're both required but ordered.

## Implementor workflow with backlog

1. Read `docs/issues/backlog.md` (the index) to see open US assigned to your
   service subtree.
2. Pick US in priority order: every P0 before any P1; within priority, respect
   `blocks:` order.
3. After each US lands: commit (`feat(scope): US-NNN <title>`), run the US's
   stated test, then move on.
4. When budget pressure looms: **finish the current US**, then halt-and-document
   (`docs/patterns/agent-halt-document.md`) listing which US are done, which
   remain, and which US blocks downstream work.

## Backlog index (`docs/issues/INDEX.md`)

| ID | Title | Priority | Status | Service | Blocks | Parent |
|---|---|---|---|---|---|---|
| US-001 | Scaffold billing-api with healthz | P0 | open | billing-api | — | RFC-0001 |
| US-002 | POST /v1/meter | P0 | open | billing-api | US-001 | RFC-0001 |
| US-005 | Production-parity smoke test | P0 | open | billing-api | US-001 | RFC-0001 |
| US-003 | GET /v1/usage/:id | P1 | open | billing-api | US-002 | RFC-0001 |

## Authoring this backlog

A TechLead (human or agent) writes the backlog in one PR per RFC, before any
implementor branches off. The PR must:

- Cite the parent RFC ID in the description.
- Pass `bash scripts/verify.sh` (which now checks `docs/issues/` front-matter +
  INDEX sync the same way it checks PRDs/RFCs/ADRs).
- Use `owner: TBD` on every US; never self-assign.

## Failure modes this kills

1. **Budget-exhausted implementor with nothing usable** — without P0 ordering,
   an agent under a $7 budget can burn it on F3 invoicing while never delivering
   the F1 endpoint the smoke test checks.
2. **Two implementors duplicating scaffolding** — without a US owning "set up
   `package.json` + `tsconfig.json`", every implementor in a parallel batch
   writes their own and they conflict at merge.
3. **Granularity-1 reviews** — without per-US verdicts, reviewer can only say
   "branch good" or "branch bad". With them, reviewer says "P0 US-001/002/005
   met, P1 US-003 missing → SHIP-WITH-CAVEATS".

## Interaction with root rules

`docs/issues/US-NNN` is the artifact named "Issue" in root `AGENTS.md`
§ Lifecycle. The lifecycle ladder is unchanged; this pattern only formalizes
*how* the Issue stage is written when more than the PR description needs it.
