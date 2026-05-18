# `<project>` — Monorepo Template

A **toolchain-agnostic monorepo skeleton** with a built-in decision lifecycle (PRD → RFC → ADR → Code) and AI-coding-agent conventions. Clone, rename `<project>` + `@OWNER`, pick a toolchain, ship.

---

## Why this template exists

Most monorepo templates ship a *toolchain* (Turborepo, Nx, Rush, Bazel...) and assume the team already agrees on **how decisions get made and recorded**. In practice, the toolchain is the easy part — the hard part is:

- New architecture choices die in Slack threads and PR comments.
- "Why did we pick X?" has no answer 6 months later.
- AI coding agents have no canonical place to learn project rules.
- Onboarding = tribal knowledge transfer.

This template inverts the order: **governance + lifecycle first, toolchain second**. The folder tree, lifecycle gates, and agent conventions stay; you bolt your stack of choice on top.

## Why pick this template

Choose it when you want:

| You want… | This template gives you… |
|---|---|
| Decisions captured in-repo, not in Notion / Slack | `docs/adr/` (immutable, Nygard-lite) + `docs/rfc/` (in-discussion) |
| A gate between "tweak" and "architecture change" | Lifecycle table in `AGENTS.md` — change class → required artifact |
| AI agents (Claude Code, Codex, Cursor) that follow project rules | `AGENTS.md` per sub-tree, closest-wins rule, `CLAUDE.md` → `AGENTS.md` |
| Pre-wired GitHub plumbing | `CODEOWNERS`, PR template linking Issue/RFC/ADR |
| Freedom to pick the stack later | No `package.json`, no `*.sln`, no lockfile — just structure + docs |

**Skip it** if you need an opinionated, batteries-included stack (Turborepo + Next + Prisma, etc.) — this is the layer *under* that.

**Best fit:** 3-30 engineers, or solo devs willing to invest in lightweight discipline. Solo at very small scale may find the PRD/RFC/ADR ladder heavy; see [`docs/AGENTS.md` § Status transitions](./docs/AGENTS.md#status-transitions) — solo/single-CODEOWNER carve-out applies.

## How it works

### 1. The folder shape encodes the dependency graph

```
apps/      ──►  packages/                              end-user apps depend on shared libs
services/  ──►  packages/                              backend hosts depend on shared libs
packages/                                              libs depend on nothing in the repo
infra/                                                 IaC, separate blast radius
docs/{product,rfc,adr,issues,postmortems,runbooks}     why · proposing · decided · tickets · post-incident · on-call
scripts/                                               dev/ops one-offs
.github/                                               CODEOWNERS, PR template
```

The doc chain reads left-to-right: **PRD → RFC → ADR → Issue (US) → Code**. `docs/issues/` holds the prioritized User-Story backlog when a feature needs multi-agent or multi-implementor breakdown (optional — small features can skip and put the breakdown in the PR description). See [`docs/patterns/user-story-backlog.md`](./docs/patterns/user-story-backlog.md).

One-way dependencies. `packages/` can't depend on `apps/` or `services/`. Enforce later with arch-tests when you pick a toolchain.

> **`services/` is plural — that does not mean "use microservices".** Default to **one** deployable host with well-bounded modules inside it (a modular monolith). Add a second `services/<host>` only when there is a real driver — most commonly:
>
> - **You want to sell / license / deploy a module separately** (different customer tier, on-prem package, white-label).
> - **Hard regulatory or data-residency boundary** that forbids co-deploying.
> - **A team owns it end-to-end** with its own release cadence.
>
> "Scale it independently" and "different tech stack" are usually rationalizations, not reasons. If you can't name the buyer / regulator / team driving the split, don't split.

> **The `modules/` pattern (optional, not pre-created).** A **module** in this template means a **commercial unit** — something you can sell, license, or gate behind an entitlement SKU — not a deployment unit and not a runtime mechanism. A module *may* map to a bounded context, but grouping is a design choice, not a rule. The pattern fixes the commercial boundary and the logical isolation rules (own schema, no cross-module imports, ID-only references, declared contracts). **How modules are wired at runtime — module loader, plugin host, packages, separate services, anything else — is a later decision** recorded in an ADR. The template ships **without** a `modules/` folder; adopt the pattern only when you have ≥2 sellable units. See [`docs/patterns/modules.md`](./docs/patterns/modules.md).

### 2. Decisions follow a class → gate ladder

| Change class | Gate (in addition to Issue/PR) |
|---|---|
| Bugfix, copy, refactor <200 LoC | — |
| New feature or public-API change | **RFC accepted before code** |
| Arch / vendor / runtime decision | **ADR (`proposed` before code, `accepted` on consensus)** |
| Revenue / legal / compliance impact | **PRD approved before RFC** |

Pick the highest matching row; lighter gates also apply. Above threshold without the artifact → stop and ask.

### 3. AI agents read `AGENTS.md`, closest wins

- Root `AGENTS.md` = global rules.
- Sub-tree `AGENTS.md` (e.g. `services/AGENTS.md`) = **deltas only**, no repetition.
- `CLAUDE.md` is a one-line pointer to `AGENTS.md` so Claude Code picks it up automatically.

When an agent edits `services/api/src/Foo.cs`, it reads `services/api/AGENTS.md` → `services/AGENTS.md` → root `AGENTS.md`. Closest file wins on conflicts.

### 4. Templates are pre-seeded for every doc type

| Folder | Template | Use for |
|---|---|---|
| `docs/product/` | `_TEMPLATE.md` | PRDs, OKRs |
| `docs/rfc/` | `_TEMPLATE.md` | Proposals while debating |
| `docs/adr/` | `_TEMPLATE.md` | Decisions once accepted (immutable) |
| `docs/issues/` | `_TEMPLATE.md` | User Stories (`US-NNN`) — prioritized backlog with `priority` + `blocks:` dependency graph |
| `docs/postmortems/` | `_TEMPLATE.md` | Incident postmortems (`PM-NNNN`) with action items |
| `docs/runbooks/` | `_TEMPLATE.md` | On-call playbooks |

Each folder has an `INDEX.md` to keep the catalog scannable. ADR-0001 is included as the seed decision ("we use ADRs") and as a live example of the format.

### 5. No CI ships in this template

CI is intentionally omitted — it depends on the toolchain you pick. Add `.github/workflows/` after step 3 below; at minimum wire `lint / typecheck / test` for your stack plus any gate you want for `infra/envs/prod/**` (e.g. require an `ADR-NNNN` reference in the PR body).

---

## Using this template

1. **Clone** (or click "Use this template" on GitHub).
2. **Bootstrap placeholders** — one command:
   ```bash
   bash scripts/bootstrap.sh my-project '@my-org/eng'
   # or PowerShell:
   pwsh scripts/bootstrap.ps1 -Project my-project -Owner '@my-org/eng'
   ```
   This rewrites `<project>` in `README.md` + `AGENTS.md`, replaces `@OWNER` in `.github/CODEOWNERS`, and fills the `owner:` line of `ADR-0001`.
3. **Verify** — `bash scripts/verify.sh` (or `pwsh scripts/verify.ps1`). Should report `verify: OK`.
4. **Pick a toolchain** — add `package.json` / `*.sln` / `pyproject.toml` / etc. Update the Commands table in `AGENTS.md` to match.
5. **Add CI** — create `.github/workflows/` for your toolchain (lint / typecheck / test, plus any gate you want for `infra/envs/prod/**`). Wire `scripts/verify.{sh,ps1}` as a CI step.
6. **Enable branch protection** on `main` (or your default branch) in GitHub repo settings:
   - **Require a pull request before merging**
   - **Require review from CODEOWNERS** ← without this, `CODEOWNERS` is documentation, not enforcement
   - Optional: **Require status checks to pass** (wire to your CI from step 5)
7. **Write your first ADR** — record the toolchain choice as `ADR-0002`. (ADR-0001 is "we use ADRs"; ADR-0002 should be your stack.)
8. **Ship.**

After bootstrap, schedule a **quarterly audit**: `bash scripts/audit.sh` (or `pwsh scripts/audit.ps1`). It surfaces stale `proposed` ADRs, open postmortem action items, and CODEOWNERS handles to verify.

## Layout reference

| Path | Contents |
|---|---|
| [`apps/`](./apps/) | End-user apps |
| [`services/`](./services/) | Deployable backend hosts — **start with one**, split only when you have a real reason (see below) |
| [`packages/`](./packages/) | Shared libs (SDK, UI, config) |
| [`infra/`](./infra/) | IaC |
| [`docs/product/`](./docs/product/) | PRDs, OKRs, roadmap |
| [`docs/rfc/`](./docs/rfc/) | Proposals (in discussion) |
| [`docs/adr/`](./docs/adr/) | Accepted decisions (immutable) |
| [`docs/issues/`](./docs/issues/) | User-Story backlog (`US-NNN` tickets, P0/P1/P2, `blocks:` graph) |
| [`docs/postmortems/`](./docs/postmortems/) | Incident postmortems (`PM-NNNN`) |
| [`docs/runbooks/`](./docs/runbooks/) | On-call playbooks |
| [`scripts/`](./scripts/) | Dev scripts |
| [`.github/`](./.github/) | CODEOWNERS, PR template |

Sub-areas carry their own `AGENTS.md` for local deltas.

## For contributors

Read [`AGENTS.md`](./AGENTS.md) — conventions, lifecycle ladder, commit/PR rules, refactor guardrails, sandbox rules.

## For AI coding agents

`CLAUDE.md` → `AGENTS.md`. Read the **nearest** `AGENTS.md` to the file being edited. Closest wins. User prompts override.
