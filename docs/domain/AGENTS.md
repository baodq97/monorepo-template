# AGENTS.md — docs/domain (delta only)

Inherits root `AGENTS.md`. Additional rules for this directory:

- Domain docs describe **business invariants**, not implementation plans.
- Agents **may** create draft domain docs with `owner: TBD`, `status: draft`.
- Agents **must not** mark domain docs as `approved` / `accepted`. Status flips
  remain a human doc-owner act (see root § Ownership & handoffs).
- Agents **must not invent business rules** and present them as accepted truth.
  If unsure whether a rule exists, halt and ask.
- If a behavior change has no covering domain doc:
  - halt and ask the user, or
  - create a draft **domain-gap note** (`DOMAIN-NNNN`, `status: draft`,
    `owner: TBD`) describing what was assumed and why — never escalate beyond
    `draft` autonomously.
- Domain docs must stay **concise and example-driven**. Prefer a forbidden
  code snippet over a paragraph of prose.
- Update `INDEX.md` when adding/renaming a domain doc.
