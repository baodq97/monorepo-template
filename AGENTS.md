# AGENTS.md — <project>

> A README for coding agents. Closest `AGENTS.md` wins. User prompts override.

## Layout

```
apps/           end-user apps
services/       deployable backend hosts (start with one)
packages/       shared libs (sdk, ui, config)
infra/          IaC
docs/
  product/     PRDs, OKRs, roadmap
  rfc/         proposals (in discussion)
  adr/         decisions (accepted)
  issues/      User-Story backlog (US-NNN, optional — see user-story-backlog pattern)
  postmortems/ incident postmortems (PM-NNNN)
  runbooks/    on-call playbooks
scripts/        dev scripts
.github/        PR template, CODEOWNERS
```

Doc chain: `PRD → RFC → ADR → Issue (US) → Code`. `docs/issues/` is optional — small features can skip and put the breakdown in the PR description; adopt when work spans multiple implementors or agents.

Sub-areas have their own `AGENTS.md` for **deltas only**. Do not repeat root rules.

Optional patterns (adopt when their conditions are met) live in [`docs/patterns/`](./docs/patterns/):
- [`decision-lifecycle.md`](./docs/patterns/decision-lifecycle.md) — explicit driver/input/output per stage; opt in for multi-team or eval pipelines.
- [`observability.md`](./docs/patterns/observability.md) — uniform RED + log field shape across services.
- [`refactoring.md`](./docs/patterns/refactoring.md) — numeric LoC thresholds for PR-review triggers.
- [`modules.md`](./docs/patterns/modules.md) — sellable bounded contexts inside one host.
- [`agent-halt-document.md`](./docs/patterns/agent-halt-document.md) — `.pr/<branch>.md` blocker-note convention for non-interactive agent runs (CI / eval / batch).
- [`autonomous-ceiling-handoff.md`](./docs/patterns/autonomous-ceiling-handoff.md) — `docs/product/<name>-status.md` handoff doc when a multi-PR agent burst reaches its autonomous ceiling.
- [`user-story-backlog.md`](./docs/patterns/user-story-backlog.md) — `docs/issues/US-NNN-*.md` prioritized backlog (P0/P1/P2 + `blocks:`) for multi-implementor or budget-bounded agent work.

## Commands

| Task | Cmd |
|---|---|
| install | `<install>` |
| dev | `<dev>` |
| build | `<build>` |
| run (production-parity entry) | `<run>` |
| lint | `<lint>` |
| typecheck | `<typecheck>` |
| test (one pkg) | `<test-one>` |
| test (all) | `<test-all>` |
| codegen | `<codegen>` |

> TODO: fill in once toolchain is chosen. Examples: `pnpm install` / `uv sync` / `go mod tidy` / `cargo build`.

## Lifecycle — gates by change class

Pick the **highest-matching row**; that gate plus every lighter gate apply. Small changes need only Issue/PR.

| Change class | Gate (in addition to Issue/PR) |
|---|---|
| Bugfix, copy, refactor <200 LoC | — (Issue/PR only) |
| New feature or public-API change | RFC accepted **before** code |
| Arch / vendor / runtime decision | ADR `proposed` before code, `accepted` on consensus |
| Revenue / legal / compliance impact | PRD approved **before** RFC |

**"Public API" = anything consumed outside the owning module / package / service** — exported symbols of a `packages/<pkg>`, HTTP/RPC routes of a `services/<x>`, CLI flags of an `apps/<x>` binary. Internal helpers and `/healthz`-style observability conventions are not public API.

Max path: `PRD → RFC → ADR → Issue/PR → Code`. Most changes touch only the tail.

Above threshold without the artifact → **stop, ask user**.

**LoC is not the only signal.** A <200 LoC diff that changes behavior at a **system boundary** (auth, crypto, retry/timeout policy, IO contract, public schema) is treated as one class higher than its size suggests. When in doubt, classify up.

**Spike / experimental lane.** Throwaway exploration is allowed on a `spike/<slug>` branch with no lifecycle artifact required, **provided** (a) the branch is deleted within 14 days, (b) it is never merged to `main`, and (c) any production-worthy outcome is re-implemented through the normal class → gate path. Spikes do not bypass the gates; they precede them.

## Ownership & handoffs

Two minimums apply everywhere; the third is opt-in.

- **Doc owner** — declared in `owner:` front-matter of each PRD/RFC/ADR/US/PM/Runbook. Owns status transitions and deprecation calls.
- **Code owner** — declared in `.github/CODEOWNERS`. Owns PR review and merge gate for that path.
- **Service owner** *(opt-in for deployable hosts)* — declared in `services/<x>/AGENTS.md` + runbook front-matter. Owns on-call, SLO, runbook upkeep.

**Status-flip signal** — doc owner flips `status:` after the relevant CODEOWNER approves the PR and no unresolved objections remain (team-defined window).

**RFC gates Stage 7.** When RFC + ADR(s) batch in one PR, RFC `accepted` is the signal coding may begin; ADRs review in parallel. RFC `§Open questions` may flag an ADR as **required before a specific code path** — that ADR must reach `proposed` before the path is implemented.

Need explicit driver/input/output per stage (multi-team coordination, regulated, role-split eval agents)? See [`docs/patterns/decision-lifecycle.md`](./docs/patterns/decision-lifecycle.md).

### Agent constraints (cross-cutting)

- **Never self-assign** as any owner role. When writing a new doc artifact, set `owner: TBD` and propose the owner in the PR body — the human doc owner replaces `TBD` on merge.
- **Never self-flip** a status field. Propose the target status in PR description; the human doc owner flips after consensus.
- **Never self-approve** a PR or act as code owner.
- **Never self-merge** a PR — including `gh pr merge` after another reviewer approved. Merge is the code-owner's act; the agent's job ends at "ready for merge". Auto-merge labels set by a human are fine; the agent does not set them.
- **CODEOWNERS edits** — adding a new entry for a **new path the same PR creates** is allowed (place handle as `@TBD` if no owner exists yet). Modifying or removing an existing entry requires explicit user instruction.
- Halt at § Lifecycle threshold when the required artifact is missing — do not invent it.

## Workflow per task

1. **Understand** — read nearest `AGENTS.md` + existing tests + follow [§ Product knowledge](#product-knowledge-for-agents) checklist.
2. **Plan** — outline; if above threshold (§ Lifecycle), halt.
3. **Implement** — match neighbor file conventions.
4. **Regenerate** — `<codegen>` if schema/proto/openapi changed.
5. **Verify** — `<lint>` + `<typecheck>` + scoped `<test>`. At least one test must exercise the **same artifact `<run>` launches** (see [`services/AGENTS.md` § Test](./services/AGENTS.md#test) for the rule and the failure patterns it kills; libraries: import and exercise the public API as a consumer).
6. **Document** — version bump per chosen tool + README note for public behavior change + `INDEX.md` row for any new/changed docs artifact (`adr/`, `rfc/`, `product/`, `issues/`, `postmortems/`, `runbooks/`).
7. **Open PR** — link Issue + required artifacts (PRD/RFC/ADR IDs); follow § Commit & PR; hand off to code-owner review.

## Agent self-check

Run before declaring done. Halt at the first ✗ and surface it to the user.

> **Mechanical pre-check** — run `bash scripts/verify.sh` (or `pwsh scripts/verify.ps1`) first. It automates: placeholder cleanup (`@OWNER` / `<project>`), front-matter completeness, INDEX status sync, no leaked `.env*`, and the "sub-tree AGENTS.md stays smaller than root" delta sanity. The remaining items below are judgment calls; verify them manually.

- [ ] Read nearest `AGENTS.md` for every **subtree** touched (top-most ancestor that has one — not every individual file).
- [ ] Change class identified; required artifact (PRD/RFC/ADR) exists or task halted at § Lifecycle threshold.
- [ ] **Toolchain picked** → ran `<lint>` + `<typecheck>` + scoped `<test>` locally; all pass.
- [ ] **Production-parity test** present — *applies to changes in `services/<x>/src/**` and `apps/<x>/src/**` only*. Same artifact `<run>` launches, hit through the public interface, asserts a documented happy-path. Libraries: import and exercise the public API as a consumer. Doc-only / config-only PRs: N/A. Rule + failure patterns: [`services/AGENTS.md` § Test](./services/AGENTS.md#test).
- [ ] **Toolchain not yet picked** → did not execute speculative commands; proposed concrete commands in PR description for the user to verify.
- [ ] Touched `docs/{adr,rfc,product,issues,postmortems,runbooks}/` → `INDEX.md` updated, front-matter complete, **`status:` column in INDEX.md matches each doc's front-matter `status:`** (stale INDEX = rule violation). **Pick `status:` from the per-type lifecycle in [`docs/AGENTS.md` § Lifecycle](./docs/AGENTS.md#lifecycle)** — PRDs start at `draft` (not `proposed`), ADRs start at `proposed`, US start at `open`, etc. Per-type templates carry inline comments showing the valid set.
- [ ] Touched schema/proto/openapi → ran codegen, committed generated output.
- [ ] No new dependency without RFC or PR note.
- [ ] No `.env*`, secret, key, or `.local.*` committed (`git status` verified).
- [ ] PR description links Issue + (if class requires) PRD / RFC / ADR by ID.
- [ ] Did not self-flip any `status:` field; status changes proposed in PR body for the doc owner to apply.
- [ ] All new doc artifacts use `owner: TBD`; proposed owner in PR body (never self-assigned).
- [ ] CODEOWNERS — added entry only for **new** paths this PR creates (with `@TBD` if no owner yet); did not modify existing entries.

Sub-tree `AGENTS.md` may extend this list with deltas.

## Product knowledge for agents

Before modifying behavior, agents must check, in order:

1. Nearest `AGENTS.md`.
2. `.agent/context-map.yml` (if present) — route the touched paths to
   their must-read docs and risk level.
3. Related `docs/domain/*` entries.
4. Related ADR / RFC / PRD.
5. `docs/known-traps.md`.
6. `docs/ownership-map.md`.

If no domain rule exists for a behavior change, **do not guess**. Either:

- halt and ask the user, or
- create a draft domain-gap note (`docs/domain/DOMAIN-NNNN-*.md`,
  `status: draft`, `owner: TBD`) describing the assumption and why.

If `docs/ownership-map.md` marks the area as:

- `implement` — proceed with normal checks.
- `guarded` — cite the required docs and tests in the PR body.
- `plan-only` — produce a plan, not code, unless explicitly approved.
- `forbidden` — do not edit; surface to the user.

## Agent task contract

For agent-assigned implementation work, prefer a task contract (see
[`docs/patterns/agent-task-contract.md`](./docs/patterns/agent-task-contract.md))
containing:

- Goal
- Allowed paths
- Forbidden paths
- Must-read docs
- Acceptance criteria
- Validation commands
- Stop conditions

If the task scope conflicts with repo rules, **repo rules win** unless
the user explicitly overrides.

## Coding rules

- Match neighboring style. Mimic before invent.
- **No new dependency** without RFC or PR note.
- Comments explain **why**, never what.
- **No silent catch.** Every error path either logs with context, rethrows wrapped, or is suppressed explicitly with a one-line comment naming the invariant (`// safe to ignore: cleanup of already-closed handle`). Language idioms that intentionally drop errors (Go `_ = f.Close()`, Rust `let _ = ...`, Python `contextlib.suppress`) count as explicit suppression.
- Generated files (`*.gen.*`, `*.pb.*`, `*_generated.*`) — edit source, then `<codegen>`.

## Refactor guardrails

- A module that's grown too large to hold one responsibility → split. Numeric LoC triggers are opt-in: see [`docs/patterns/refactoring.md`](./docs/patterns/refactoring.md).
- No single-use helpers.
- Promotion to shared `packages/` follows [`packages/AGENTS.md`](./packages/AGENTS.md#promotion-rule).

## Commit & PR

- Conventional Commits: `feat(scope): …`, `fix(scope): …`. Scope = pkg/app name.
- Branch: `feat/<ticket>-<slug>`.
- PR links Issue/RFC/ADR + test plan + screenshot (UI).
- One PR, one purpose. Refactors go separately.
- No `--no-verify`, no skipped hooks.

## Sandbox

- Never commit `.env*`, keys, tokens.
- Never skip local checks (test/lint/typecheck) before opening a PR.
- `infra/envs/prod/**` → ADR + CODEOWNERS approval.
- New env var → `.env.example` + docs.

## Editing this file

Standalone PR. Principle change → attach ADR.
