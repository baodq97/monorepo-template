# Contributing

This repo's conventions live in [`AGENTS.md`](./AGENTS.md). Read the **nearest**
`AGENTS.md` to the file you're editing (closest-wins). User instructions in a
PR or chat override the file.

## Quick links

- Change-class ladder (Issue → RFC → ADR → Code): [`AGENTS.md` § Lifecycle](./AGENTS.md#lifecycle--gates-by-change-class)
- Ownership rules: [`AGENTS.md` § Ownership & handoffs](./AGENTS.md#ownership--handoffs)
- Self-check before declaring done: [`AGENTS.md` § Agent self-check](./AGENTS.md#agent-self-check)
- Commit + PR format: [`AGENTS.md` § Commit & PR](./AGENTS.md#commit--pr)
- Security: [`SECURITY.md`](./SECURITY.md)

## Bootstrap a fresh clone

```bash
bash scripts/bootstrap.sh <project-name> '@owner'
bash scripts/verify.sh
```

## Quarterly audit

Run `bash scripts/audit.sh` every quarter. It is
read-only and reports:

- ADR/RFC stuck in `proposed` for >90 days.
- Postmortem action items still marked TODO.
- Distinct CODEOWNERS handles to verify against current org membership.
- Toolchain placeholders still in the Commands table.
- Template version (helps detect drift from the upstream template).

## Non-code contributions

- **Docs (PRD / RFC / ADR / Runbook / Postmortem):** copy the matching
  `_TEMPLATE.md` in `docs/<type>/`, fill front-matter, update `INDEX.md`,
  open a PR. Status flips happen post-merge by the doc owner.
- **Bug reports / feature requests:** use the templates in
  `.github/ISSUE_TEMPLATE/`.
