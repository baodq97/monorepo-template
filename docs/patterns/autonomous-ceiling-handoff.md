# Pattern — Autonomous ceiling handoff (for multi-PR agent bursts)

> **Pattern reference, not core harness.** Sibling to [`agent-halt-document`](./agent-halt-document.md), which covers single-PR halts. This pattern covers the *end of a multi-PR autonomous burst* — when an agent has chained many tasks and finally hits an external blocker it cannot resolve.

## Why opt-in

When a long agent session has produced N coordinated PRs and then stops, the failure is qualitatively different from a single-PR halt:

- The blocker is rarely about the last PR — it is an external dependency (missing API limit, unmerged upstream, security role pending, human approval pending).
- Re-pickup needs more than a PR description: the next reader must understand the **overall progress map**, which blockers compound, and what order to resolve them in.
- Re-pickup happens hours or days later, after context decay. A per-PR file is not discoverable from the project root.

The fix: lift the handoff into the docs tree, where it inherits the existing governance machinery (`INDEX.md`, front-matter, owner, status).

## When to adopt

- Agents run autonomous bursts that produce ≥3 PRs in one session.
- The session can plausibly hit an "I can no longer make progress without external input" ceiling.
- A human reviewer or coordinator agent will pick up the work later, not minutes after.

Skip if every session is single-PR or human-supervised throughout.

## The rule

When an autonomous burst reaches its ceiling, the final act of the session is:

1. **Create or update** `docs/product/<phase-or-feature-name>-status.md` with the front-matter shape from `docs/product/_TEMPLATE.md` (id, title, status, owner: TBD, date).
2. Body MUST contain these sections, in order:

   ```markdown
   ## Completed this session
   <ordered list of PRs merged + their IDs; one line each>

   ## Hard blockers
   <numbered list; each item: what is blocked, by what,
    what unblocks it, who can perform the unblock>

   ## Re-pickup checklist
   <numbered list a fresh agent can follow next session;
    references the blocker numbers it depends on>

   ## Evidence
   <links: PR URLs, commit SHAs, generated artifact paths>
   ```

3. **Set `status: blocked`** in front-matter.
4. **Update `docs/product/INDEX.md`** to match (or run `scripts/rebuild-indexes.py`).
5. **Exit cleanly.** Do not open more PRs after this artifact lands.

## Why integrate with `docs/product/`

- **Discoverability**: `docs/product/INDEX.md` is the catalog already maintained by `scripts/rebuild-indexes.py`.
- **Governance consistency**: front-matter `owner:` and `status:` integrate with the existing self-flip prohibition and `verify.sh` checks. No parallel state machine.
- **Lifecycle alignment**: the handoff is a product-level artifact, not a PR-level one.

A root-level `session-handoff.md` would duplicate this without inheriting the index/status machinery.

## Failure modes this kills

1. **Silent ceiling.** Agent stops, no record of which PR is "current", no map of remaining blockers. Human reconstructs state from `git log`.
2. **Blocker re-discovery.** Without a ceiling doc, the next session re-discovers the same external blocker — wasting a session.
3. **Lost decision context.** Each blocker has one unblock condition; without the doc, the condition gets re-derived (sometimes incorrectly).
4. **Status drift.** Without `status: blocked` in `docs/product/INDEX.md`, the project looks active in the index even though no agent can make progress.

## Interaction with root rules

The agent writes the artifact with `status: blocked` *initially* (not as a flip from another state); subsequent transitions follow the normal doc-owner-flips rule in root `AGENTS.md` § Agent constraints.

Composes with [`agent-halt-document`](./agent-halt-document.md): single-PR halts use that pattern; reaching the burst ceiling uses this one.
