---
id: PM-XXXX
title: <e.g. "Checkout 500s for 23 minutes">
status: draft       # draft | published
owner: TBD          # agent: leave TBD; propose owner in PR body
date: YYYY-MM-DD
incident_start: YYYY-MM-DDTHH:MMZ
incident_end: YYYY-MM-DDTHH:MMZ
severity: SEV1 | SEV2 | SEV3
services: []
related_runbooks: []
related_adrs: []
---

## Summary
2-4 sentences. What broke, who saw it, how long, what fixed it.

## Impact
Users / revenue / SLO budget burnt. Quantify.

## Timeline (UTC)
| Time | Event |
|------|-------|
| T-?? | Signal first appeared (often before the page) |
| T+00 | Page fires |
| T+?? | Mitigation start |
| T+?? | Mitigation complete |
| T+?? | Resolved / monitoring confirms |

## Root cause
What allowed this to happen. Not "who" — "what mechanism."

## Contributing factors
Defensive layers that should have caught it earlier and didn't. Each one is a separate finding.

## What went well
Specific things — fast detection, good runbook, ready dashboards. Reinforces good practice.

## Action items
Numbered, each with owner + ticket link. Distinguish **prevent recurrence** vs **reduce blast radius** vs **shorten MTTR**.

| # | Action | Type | Owner | Ticket |
|---|--------|------|-------|--------|
| 1 | | prevent / blast / mttr | | |

## Lessons (org-level)
Patterns worth surfacing beyond this incident. Candidate ADR / RFC inputs.
