# Security Policy

## Reporting a vulnerability

**Do not open a public GitHub issue for security problems.**

Email the maintainers (see `CODEOWNERS` for current handles) with:

- A description of the issue and its impact.
- Steps to reproduce or a proof-of-concept.
- Affected versions / paths.

We aim to acknowledge within **3 business days** and provide a remediation
plan within **10 business days** for confirmed reports.

## Coordinated disclosure

We follow a 90-day coordinated-disclosure window. If you wait, we will credit
you in the fix commit and any advisory.

## Scope

- Source code under this repository.
- Configuration in `infra/` (modules + envs).
- The decision artifacts in `docs/` (e.g. an ADR exposing a secret in
  examples is in scope).

## Secret hygiene (recommended local setup)

This template ships **no CI**. To compensate, run a secret scanner locally
before every push:

- [`gitleaks`](https://github.com/gitleaks/gitleaks) — `gitleaks protect --staged`
- [`trufflehog`](https://github.com/trufflesecurity/trufflehog) — `trufflehog git file://.`

A pre-commit hook is the most reliable place to wire either of these. Add it
when you set up your toolchain (record the choice in an ADR if multiple
contributors share the repo).

## What's already enforced

- `.gitignore` excludes `.env*` (except `.env.example`).
- `scripts/verify.{sh,ps1}` fails the build if a `.env*` file is committed.
- `infra/AGENTS.md` forbids secrets in IaC; references must point to a
  secret manager (Vault / SSM / KMS).
