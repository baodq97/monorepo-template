---
id: US-NNNN
title: <one-line user story title>
status: open                    # open | in_progress | done | dropped
priority: P0                    # P0 must-have | P1 should-have | P2 nice-to-have
owner: TBD
parent: RFC-NNNN                # the accepted RFC this US slices
blocks: []                      # other US IDs that wait on this one
service: <subtree>              # services/<name> | apps/<name> | packages/<name>
date: YYYY-MM-DD
---

> Pattern: `docs/patterns/user-story-backlog.md`. Adopt for multi-implementor
> work or budget-bounded agent runs. Solo small features may skip.

## Acceptance criteria

- [ ] One observable bullet, ≤3 total.
- [ ] Each AC names the failure mode it kills.

## Files to touch

- `path/to/file.ts` — create | modify
- `path/to/test.ts` — create

## Test name

`<command that runs the canonical test for this US>`

## Out of scope

- Things this US explicitly does NOT do (kills scope creep at PR time).
