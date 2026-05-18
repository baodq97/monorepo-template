# Pattern — Decision lifecycle (optional ceremony)

> **Pattern reference, not core harness.** Root `AGENTS.md` ships only the change-class gate + the agent-constraint safety rules. Adopt the detailed stage-by-stage handoff below when your team needs explicit driver/input/output per step (multi-team coordination, regulated environments, eval pipelines with role-split agents).

## When to adopt

- ≥3 distinct owner roles in practice (e.g. PM, eng lead, on-call).
- Cross-team handoffs where "who flips status when?" is ambiguous.
- Automated agent pipelines that need a deterministic stage map.
- Audit / compliance need to reconstruct who decided what.

Skip if the change-class table in root `AGENTS.md` is already enough.

## Roles

Three owner roles. May overlap in one person; the **responsibilities are distinct**.

| Role | Declared in | Owns |
|---|---|---|
| **Doc owner** | `owner:` front-matter of PRD/RFC/ADR/Runbook | Status transitions; doc currency; deprecation calls |
| **Code owner** | `.github/CODEOWNERS` path entry | PR review & approval for that path; merge gate |
| **Service owner** | `services/<x>/AGENTS.md` + runbook front-matter | On-call rotation; SLO / error budget; runbook upkeep |

## Stage → driver → I/O → handoff

Max path below; skip rows that don't apply to the change class.

| # | Stage | Driver | Input | Output | Handoff signal |
|--|---|---|---|---|---|
| 1 | Frame problem | Requester / product owner | Problem + evidence | PRD `status: draft` | PR in `docs/product/`; doc owner set |
| 2 | Approve PRD | PRD doc owner | Stakeholder review | PRD `status: approved` | `/docs/product/` CODEOWNER approves PR → doc owner flips status |
| 3 | Propose RFC | RFC doc owner (eng lead) | Approved PRD (or none if no PRD class) | RFC `status: proposed` | PR in `docs/rfc/`; reviewers attached |
| 4 | Accept RFC | RFC doc owner + reviewers | Proposed RFC + feedback | RFC `status: accepted` | ≥1 CODEOWNER approves; no unresolved objections within team's review window → doc owner flips. **Gates Stage 7** even when ADRs are batched; ADRs review in parallel. |
| 5 | Propose ADR *(arch class only)* | ADR doc owner | Accepted RFC + decision point | ADR `status: proposed` | PR in `docs/adr/`; references RFC. If RFC §Open questions flags an ADR as **required before a code path**, that ADR must reach `proposed` before the path is implemented; `accepted` follows on review. |
| 6 | Accept ADR | ADR doc owner + CODEOWNERS | Proposed ADR + review | ADR `status: accepted` (immutable) | CODEOWNER approves → doc owner flips |
| 7 | Implement | Author (human or agent) | Accepted RFC (+ ADR if arch class) | Code + tests + PR | Branch + commits per § Commit & PR |
| 8 | Review | Path code owner(s) | Open PR + green CI | Approval / changes requested | CODEOWNERS auto-routes the PR |
| 9 | Ship | Code owner + author | Approved PR + green CI | Merged to `main`; deployed | If it closes a PRD goal → PRD doc owner flips `status: shipped` post-deploy |
| 10 | Operate | Service owner | Live signals, alerts, incidents | Runbook updates, postmortems, new ADRs on structural change | Service owner drafts postmortem; loops back to Stage 5 if arch impact |

## Lighter alternatives (still valid)

- **Two-role**: collapse Service owner into Code owner for repos with no on-call.
- **Five-stage**: skip 1-2 (no PRD class) and 5-6 (no arch class) — most changes do this.
- **No-handoff-table**: rely on change-class gate + agent constraints only. Suitable for small teams where everyone reviews everything.

The root-level guarantees (closest-wins `AGENTS.md`, agent never self-flips, halt at threshold) remain regardless of which lifecycle option you pick.
