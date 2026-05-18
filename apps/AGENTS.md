# AGENTS.md — /apps

Delta only.

## New app

1. PRD approved (or ADR for internal tool / prototype).
2. Create `apps/<name>/` with the chosen stack's minimal layout — typically `<manifest>` (`package.json` / `pyproject.toml` / `go.mod` / etc.), `src/`, `tests/`, `README.md`, and an `AGENTS.md` (delta only — most apps need none). No pre-built scaffold ships; mimic neighbor apps once any exist.
3. Add to workspace config if the toolchain has one (pnpm `workspaces`, uv `tool.uv.workspace.members`, cargo `members`, …); otherwise skip.
4. CODEOWNERS: add `/apps/<name>/` per root § Agent constraints.
5. Update root README if the app introduces a user-visible surface.

## Rules

- No direct import from `services/` — go through `packages/sdk` **once it exists**. Until then, call services via their typed HTTP/gRPC client and isolate the call in one module per service.
- All env vars declared in `packages/config` **once it exists**. Until then, isolate env access in one module (`src/env.<ext>`) with explicit types; the migration to `packages/config` is mechanical when ≥2 apps share the surface (see [`packages/AGENTS.md`](../packages/AGENTS.md#promotion-rule)).
- New features behind flag until PRD GA criteria met.
- UI change → before/after screenshots in PR.

## Test stratification

| Type | When |
|---|---|
| Unit (component) | Any branching logic |
| Integration | Multi-step flows |
| E2E | Critical journeys in PRD |
| Visual regression | Design-system components |

E2E runs nightly + pre-release; does not block PRs.
