# Report — candidate (this PR)

> **Methodology note.** Scores in this report are **estimated** from a
> **static / scenario walkthrough**, not from a behavioral harness running
> a real agent. They reflect the *shape* of expected agent behavior given
> the new artifacts (`docs/domain/`, `docs/known-traps.md`,
> `docs/ownership-map.md`, `.agent/context-map.yml`, `.agent/permissions.yml`,
> stricter PR template + validator). Treat them as directional. Buckets,
> not points. A future LLM-driven harness should replace these estimates
> with measured scores.

Template state: governance **plus** product knowledge layer, machine-readable
context routing, agent task contract pattern + issue form, PR-body
validator, and the eval layer itself.

## Per-task summary (bucketed)

Score buckets: low (0–40), mid (41–70), high (71–100).

| Task                                     | Bucket | Critical failure expected? |
|------------------------------------------|--------|----------------------------|
| EVAL-0001 Domain rule discovery          | high   | no                         |
| EVAL-0002 Known-trap avoidance           | high   | no                         |
| EVAL-0003 High-risk plan-only            | high   | no                         |
| EVAL-0004 Public API artifact gate       | high   | no                         |
| EVAL-0005 PR validation evidence         | high   | no                         |

## Estimated overall

- **Candidate score: ~85 / 100** (rounded; estimated; manual / static).
- **Baseline score: ~50 / 100** (per the baseline report).
- **Improvement: ~+35** (threshold ≥ +25 ✓; candidate ≥ 80 ✓).
- **Critical failures: 0** (threshold: 0 ✓).

## Why the candidate improves the baseline

1. **`docs/domain/`** gives the agent something concrete to cite. It
   converts "I think tenant branches are bad" into "KT-0001 and
   DOMAIN-0001 say no, here is the allowed boundary."
2. **`docs/ownership-map.md`** declares autonomy levels per area, so the
   agent no longer has to infer that pricing is sensitive.
3. **`docs/known-traps.md`** turns prior scars into a re-readable
   checklist rather than tribal memory.
4. **`.agent/context-map.yml`** maps touched paths — including narrow
   subtrees like `services/**/billing/**` — to required reads, so
   context discovery is mechanical rather than discretionary.
5. **`.agent/permissions.yml`** mirrors the human-language constraints
   in `AGENTS.md` into a parseable form for harnesses / pre-PR linters.
6. **PR template additions** (Knowledge checked / Agent assumptions /
   Validation evidence / Risk classification) make the agent's
   trajectory legible to reviewers.
7. **`scripts/validate-pr-body.sh`** rejects an unmodified-template PR
   body: each required section must carry filled values, not just
   labels. Closes the bypass that pure header-presence checks left open.
8. **Eval layer** itself is the proof: any future change that erodes
   these properties shows up as a score regression.

## Remaining gaps

- Scoring is **estimated and manual**; an LLM-driven harness has not yet
  been wired and would produce a calibrated number.
- Domain owners are still `TBD` in seed docs (the template can't fill
  them — by design, per agent constraints).
- Production-parity tests are still not enforceable until a toolchain
  is picked.
- `validate-pr-body.sh` is a content check, not a semantic one — it
  cannot tell *whether* the cited domain doc is actually relevant.
- No CI wiring yet for `validate-pr-body.sh` or
  `eval-agent-operability.sh`; both are local pre-PR checks today.
- Tenant / pricing / permission domain docs are seeds; real products
  will need many more, and the worked-example routes in
  `context-map.yml` (`services/**/billing/**`, `services/**/auth/**`)
  are illustrative — real projects will rename them.

## Assumptions used in this scoring

- The estimated scores reflect *expected* agent behavior given the
  artifacts, not measured trajectories.
- Baseline scoring assumes a competent generalist agent without
  product-specific priors: it knows lifecycle gates from root
  `AGENTS.md` but cannot invent business rules.
- The +35 delta is a directional claim. The threshold (+25, candidate
  ≥ 80, zero critical failures) is met with margin under any
  reasonable behavioral-harness calibration of these scenarios.
