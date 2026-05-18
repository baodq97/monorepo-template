---
id: RB-XXXX
title: <e.g. "DB connection pool exhausted">
service: <name>
severity: SEV1 | SEV2 | SEV3
owner: TBD          # agent: leave TBD; propose owning team / rotation in PR body
date: YYYY-MM-DD
last_drill: YYYY-MM-DD
---

## Symptoms
Observable signals. Paste metric/query.

## Impact
Who, how much.

## Triage
1. Check X at `<dashboard>`.
2. Run `<diagnostic cmd>`.
3. Branch: if A → mitigation 1; if B → mitigation 2.

## Mitigation

### Option 1: <name>
```
<cmd>
```
Side effect: …

### Option 2: <name>
…

## Root cause
After mitigating: log query, trace, recent deploy?

## Post-incident
- [ ] Postmortem in `docs/postmortems/` using `_TEMPLATE.md`
- [ ] ADR if architecture change
- [ ] Update this runbook

## Related
- ADR / dashboard / past incidents
