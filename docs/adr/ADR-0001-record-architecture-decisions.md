---
id: ADR-0001
title: Record architecture decisions using ADRs
status: accepted
owner: TBD          # human operator may fill on initial setup; agents leave TBD (see root AGENTS.md § Agent constraints)
date: 2026-05-16
supersedes: null
superseded_by: null
related_prds: []
related_rfcs: []
---

## Context

Architecture choices (DB, service split, framework) decay into Slack/PR comments. Agents and new humans can't recover the *why*. We need a versioned, in-repo format.

## Decision

Use **Architecture Decision Records** (Nygard format, lite) under `docs/adr/`:

- One file per decision: `ADR-<id>-<slug>.md`, monotonic IDs.
- States: `proposed → accepted → superseded | deprecated`.
- Accepted ADRs are immutable. Change = new ADR with `supersedes:`.
- PRs touching architecture link the ADR ID.

## Alternatives

| Option | Pros | Cons | Why rejected |
|---|---|---|---|
| Confluence / Notion | Nice UI | Out of repo, drifts from code, agents can't read | Rejected |
| PR comments only | Zero overhead | Vanishes when PR ages | Rejected |
| RFCs only, no ADRs | Fewer artifacts | Can't tell "in discussion" from "decided" | Rejected |
| ADR + RFC split | Clear stages, agent-friendly | One more doc type | **Accepted** |

## Consequences

### Positive
- Faster onboarding for humans + agents — grep `docs/adr/`.
- Decisions can be revisited with full context.

### Negative
- Extra step per architecture change. Mitigation: PR template + CI rule for `infra/` and new services.

### Neutral
- Need periodic sweep of stale `proposed` ADRs.

## References
- Michael Nygard, *Documenting Architecture Decisions* (2011)
- adr.github.io
