# Pattern — Halt-and-document (for non-interactive agent runs)

> **Pattern reference, not core harness.** Root `AGENTS.md` says "above threshold without the artifact → **stop, ask user**." That assumes an interactive session. Adopt this pattern when agents run **non-interactively** (CI, scheduled jobs, evals, batch pipelines) and there is no user to answer.

## Why opt-in

The default "halt, ask user" is correct for IDE-driven sessions where a human is reading along. In non-interactive contexts, "halt and ask" silently means **exit with no progress** — the agent stops, no one answers, and downstream work loses context. The fix is to make the halt *documented and addressable* by the next reader (human or coordinator agent) instead of merely silent.

## When to adopt

- Agents are invoked by scripts, schedulers, or eval harnesses (`claude -p`, batch SDKs, cron).
- A coordinator agent or human reviewer reads the workspace after a batch to triage halts.
- You want a uniform shape for "I stopped because…" notes across many roles.

Skip if every agent run is human-supervised and halting in chat is acceptable.

## The rule

When an agent would otherwise halt and ask the user, it must instead:

1. **Create the branch** that the role's prompt specified (even if otherwise empty).
2. **Commit whatever partial work exists** — even just stub files or a single placeholder.
3. **Write a `.pr/<branch>.md` PR description** (or equivalent local-PR convention file) containing a `## Blocker` section. Include:
   - One-line summary of what is blocked.
   - Citation: the rule, artifact, or §Open Question that surfaced the block.
   - A concrete `Decision required: …` statement naming what must be answered to proceed.
   - Any assumption the agent considered making (with `ASSUMPTION:` marker) and why it didn't.
4. **Exit cleanly** (zero). The orchestrator's review/grader phase detects the `## Blocker` section and routes to a coordinator role for resolution.

## Why a separate branch + commit

Empty / partial branches preserve evidence. Without a branch and PR file, the work simply vanishes when the process exits; with them, the next agent or human can pick up exactly where the previous agent stopped — including its half-built artifacts.

## Coordinator role (companion)

When this pattern is active, define a coordinator role (e.g. `roles/teamlead.md`) whose job is:

- Read all `.pr/<branch>.md` files with `## Blocker` sections after a batch.
- Resolve blockers by amending the relevant RFC/ADR/PRD (proposing `proposed → accepted` flips via PR body, not by self-flip), or by issuing a documented decision the implementor can re-run against.
- Re-dispatch the original implementor with the resolution in its context.

Coordinator's tool whitelist mirrors a senior reviewer's: read everything, write only docs/PR files, never edit implementation code.

## Failure modes this kills

1. **Silent-exit black holes** — agent stops, no record of why, weeks pass before anyone notices the missing service.
2. **Cascading halts** — Service-A halts on auth, Service-B halts on missing service-RFC, Frontend halts on missing SDK; downstream phases run blind. With this pattern, each halt is visible and resolvable in one coordinator sweep.
3. **Ad-hoc assumption drift** — without an `ASSUMPTION:` marker convention, agents that *do* proceed bury their assumptions in code comments where the next reader never sees them.

## Interaction with root rules

This pattern **does not loosen** the lifecycle gates in root `AGENTS.md` § Lifecycle. PRDs/RFCs/ADRs still gate the work. The pattern only changes *how an agent fails the gate* — explicitly and with a recoverable trace, instead of silently.
