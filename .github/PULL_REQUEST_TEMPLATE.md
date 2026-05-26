<!-- Title: type(scope): summary  (Conventional Commits) -->

<!--
TRIVIAL LANE: if this PR is a typo/doc/dependency-bump/comment-only diff,
add the line `triv: true` in "What & Why" and skip the Checks / Test plan
sections (still tick "Read nearest AGENTS.md" and "Ran verify locally").
-->

## What & Why
<!-- 1–3 lines. -->

## Linked artifacts
<!-- Required if touching architecture / public API / infra -->
- PRD: PRD-XXXX
- RFC: RFC-XXXX
- ADR: ADR-XXXX
- Issue: #…

## Type
- [ ] feat
- [ ] fix
- [ ] refactor (no behavior change)
- [ ] chore / infra / docs
- [ ] breaking (attach migration guide)

## Checks
- [ ] Read nearest `AGENTS.md`
- [ ] Ran `scripts/verify.sh` locally; output clean
- [ ] Touched `packages/` shared → version bumped per chosen tool
- [ ] Touched `services/<x>` public API → SDK bumped
- [ ] Touched `infra/envs/prod/**` → ADR linked + `plan` pasted below
- [ ] Touched schema/proto → ran `<codegen>`, committed output
- [ ] **Security impact** considered (auth, crypto, PII, secrets, deps) — describe below if any

## Test plan
- [ ] Unit tests added/updated
- [ ] Manual test (steps)
- [ ] Lint + typecheck pass
- [ ] (UI) before/after screenshots

## Risk & rollback
<!-- How does this fail? How to revert (commit / flag / IaC rollback)? -->

## Knowledge checked
<!-- Required for behavior changes. Be specific (paths + ids). -->
- Nearest AGENTS.md:
- Context map entries:
- Domain docs:
- ADR/RFC/PRD:
- Known traps:
- Ownership map:

## Agent assumptions
<!--
  One bullet per assumption. Use "Assumption: None" when no domain invariant
  is relied upon. Value MUST appear on the same line as the label — the
  validation script rejects labels whose value is on the next line.
-->
- Assumption:
- Why it is safe:
- What would invalidate it:

## Validation evidence
<!-- Exact commands + exact results. No "tests pass" without output. -->
- Command:
- Result:
- Untested areas:

## Risk classification
- [ ] low
- [ ] medium
- [ ] high
- [ ] critical
