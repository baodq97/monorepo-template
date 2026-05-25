# Pattern: Agent task contract

**Adopt when** you assign non-trivial implementation work to a coding agent
and want a single, structured brief that the agent can verify itself
against. Small tasks (typo, copy tweak, one-line fix) don't need it.

A task contract turns a free-form "please do X" into a checklist with hard
edges: what is in scope, what isn't, what to read first, what counts as
done, and when to stop and ask.

If the contract conflicts with repo rules (root `AGENTS.md`, lifecycle
gates, ownership-map autonomy), **repo rules win** unless the user
explicitly overrides.

## Template

```markdown
# Agent Task Contract

## Goal
<!-- One sentence. The outcome, not the steps. -->

## Context
<!-- Background the agent needs but can't infer from the repo. -->

## Allowed paths
<!-- Globs. The agent may modify only files matching these. -->

## Forbidden paths
<!-- Globs. The agent must not modify these even if tempted. -->

## Must-read docs
<!-- Ordered list. AGENTS.md, domain docs, ADRs, known-traps entries. -->

## Business rules
<!-- Invariants this task must respect. Link to docs/domain/* entries. -->

## Acceptance criteria
<!-- Observable, verifiable. Each item is a yes/no. -->

## Validation commands
<!-- Exact commands. lint, typecheck, tests, scripts/verify.sh, etc. -->

## Stop conditions
<!-- When the agent must halt and ask:
     - artifact gate missing
     - touches a `plan-only` area without approval
     - unexpected forbidden path involvement
     - unknown trap suspected
-->

## Expected output
<!-- PR branch name, commit style, PR body sections required. -->
```

## Usage

- Author the contract in the issue body (see
  `.github/ISSUE_TEMPLATE/agent-task.yml`) **or** paste it as the first
  message to the agent.
- The agent should re-emit each section in the PR body so reviewers can
  verify the contract was honored end-to-end.
- If the agent halts on a Stop condition, the halt note (and any
  `.pr/<branch>.md` blocker — see `agent-halt-document.md`) should cite
  the exact section that triggered the stop.
