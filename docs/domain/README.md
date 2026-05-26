# Domain knowledge

This directory holds **business invariants** — rules that must hold true regardless of
implementation. Domain docs are the source of truth that agents (and humans) consult
*before* changing behavior.

Domain docs answer:

- What does the business actually require here?
- What can be customized, and through which boundary?
- What must never change without explicit approval?
- What edge cases bit us before?

They do **not** answer:

- How is this implemented today? → code + ADRs
- Why was a technology chosen? → ADR
- What is the roadmap? → `docs/product/`

## Layout

- `INDEX.md` — table of all domain docs.
- `_TEMPLATE.md` — copy this when adding a new domain rule.
- `AGENTS.md` — agent-specific rules for this directory.
- `<rule>.md` — one file per coherent rule / domain area.

## When to add a domain doc

Add one when you discover a business rule that the code currently relies on but is
*nowhere* written down. If you find yourself about to "just hardcode" something
customer-specific or assumption-heavy, stop and write the rule first.

## Authoring rules

- Be short. Examples beat paragraphs.
- Forbidden examples are as important as allowed ones.
- Link related PRDs / RFCs / ADRs in front-matter.
- Mark high-risk areas explicitly (`Risk: High` in body).
