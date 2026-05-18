# AGENTS.md — /services

Delta only. Each service deploys independently, has on-call.

## New service

1. RFC required (new boundary = architectural) — **except** internal tool / prototype / single-deployable app where an ADR for the runtime decision suffices (mirror of `apps/AGENTS.md` carve-out).
2. ADR `proposed` before code (runtime, DB, queue); `accepted` on consensus.
3. Create `services/<name>/` with the stack's minimal layout (`<manifest>`, `src/`, `tests/`, `README.md`). An optional `AGENTS.md` (delta only) only if the service has rules that diverge from this file — most do not.
4. Runbook for top-3 failure modes before GA.
5. CODEOWNERS: add `/services/<name>/` per root § Agent constraints; on-call rotation declared in service `README.md`.
6. RED-or-equivalent dashboard before prod traffic. (Concrete shape: [`docs/patterns/observability.md`](../docs/patterns/observability.md) if adopted; otherwise document the chosen shape in the service `README.md`.)

## Contract

- Public API via `packages/sdk/<service>`. Consumers don't call raw HTTP/gRPC.
- **Bootstrap carve-out** — until `packages/sdk/<service>` exists, expose a typed client module **inside the service's repo path** (e.g. `services/<x>/client/`) that consumers import; promotion to `packages/sdk/<service>` is mechanical once a second consumer arrives (see [`packages/AGENTS.md` § Promotion rule](../packages/AGENTS.md#promotion-rule)). Raw HTTP/gRPC calls from consumers are still forbidden.
- Breaking schema → version endpoint (`/v2/…`) per RFC migration policy.
- OpenAPI / proto is source of truth. Generated code, never hand-edited.

## Observability (mandatory in principle)

Every service must emit structured logs, metrics, and traces; every alert links to a runbook. The concrete field set + RED-vs-USE choice is an opt-in pattern — see [`docs/patterns/observability.md`](../docs/patterns/observability.md) if you want a uniform prescription across services.

## Data

- Migrations forward-only — no destructive `DROP`/`ALTER` without a follow-up forward migration. "Rollback plan" in PR = the compensating forward migration, not a reversal.
- Prod schema change → ADR + owner approval.
- PII fields tagged at the schema level; logger redacts via tag.

## Test

- Unit for domain logic.
- Integration against a real DB instance (Testcontainers, pytest-docker, embedded server, ephemeral local container — pick per stack). No DB mocks.
- Consumer contract test on API change.
- Load test before GA (target in RFC).
- **Production-parity test (mandatory)** — at least one test exercises the **same artifact `<run>` launches** (process-level singleton / compiled binary / exported handler), driven through the public interface (HTTP / RPC / CLI), and asserts a documented happy-path. A test that builds its own copy with hand-seeded config proves the factory, not the shipped artifact. Failure patterns this rule kills:
  1. Default in-process DB / cache that works single-threaded but breaks under the prod server's thread/process model.
  2. Empty seed-data defaults (no tenants / keys / config) — shipped artifact unrunnable until someone writes a separate dev entry.
  3. Hard external deps (DB / cache / queue) with no fallback — tests monkey-patch, prod fails at boot.
- **Dev-mode runnable on fresh clone (mandatory)** — `<install> && <run>` on a fresh clone must reach a happy-path via (a) embedded alternatives behind an env flag, and/or (b) `compose.yml` or equivalent whose `up` is the parity test's setup, plus (c) seed data injectable via env / `dev-seed` command / checked-in `dev.config.<ext>`. Test-fixture monkey-patches do not count.
