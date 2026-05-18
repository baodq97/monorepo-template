# AGENTS.md — /docs

Delta only.

## Scope

- `product/` — PRDs, OKRs, roadmap
- `rfc/` — proposals in discussion
- `adr/` — accepted decisions
- `issues/` — User stories (US-NNN), the prioritized backlog that breaks down an accepted RFC into tickets an implementor can pick up. *(See `docs/patterns/user-story-backlog.md` — adopt for multi-implementor work; small features can skip and put the breakdown inside the PR description.)*
- `runbooks/` — on-call playbooks
- `postmortems/` — incident retros (created on first incident; runbook template's post-incident checklist references this folder)

## File rules

- Name: `<ID>-<kebab-slug>.md` (e.g. `ADR-0007-pick-postgres.md`).
- IDs monotonic; never reuse. Retire via `status: deprecated|superseded`.
- YAML front-matter required (see `_TEMPLATE.md`).
- Update `INDEX.md` on add or status change.

## Lifecycle

```
PRD  draft → approved → shipped | dropped
RFC  draft → proposed → accepted | rejected | withdrawn
ADR  proposed → accepted → superseded | deprecated
US   open → in_progress → done | dropped         # docs/issues/ — see pattern
PM   draft → published
```

- **Accepted ADR body is immutable.** New decision → new ADR with `supersedes:`. Front-matter **metadata** (`superseded_by`, `related_*`, `last_drill`) may be updated post-acceptance to maintain back-links; only the body and the original `Decision` paragraph are frozen.
- **Rejected RFC stays** — org knowledge.

## Status transitions

- **Doc owner flips status** (see root [§ Ownership & handoffs](../AGENTS.md#ownership--handoffs)).
- Signal = ≥1 CODEOWNER of `docs/<type>/` approves the PR; no unresolved objections within the team's review window (lazy consensus).
- **Agents never self-flip.** Propose the target status in PR body; let the doc owner apply it.
- **Solo / single-CODEOWNER mode** — when the same human is doc owner and the only CODEOWNER, "review" collapses to a written 24h cool-off: open PR, sleep on it, re-read diff next day, then flip. Document the choice in the PR body so the convention is explicit.
- Reverting `accepted` → anything: forbidden. Supersede with a new doc instead.

## Authoring rules

1. Copy `_TEMPLATE.md`; never start blank.
2. Front-matter complete: `status`, `owner`, `date` (YYYY-MM-DD).
3. Every decision: `Alternatives` + `Consequences`/`Trade-offs`.
4. PR description cites the artifact ID. (Reverse link from artifact → PR is best-effort, not required — git history is the source of truth.)
