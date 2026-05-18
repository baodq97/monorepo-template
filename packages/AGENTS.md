# AGENTS.md — /packages

Delta only. Touching shared code → blast radius.

## Promotion rule

Code lands in `packages/` only when:
- **≥2 real consumers** (not "might use later").
- Clear owner in CODEOWNERS.
- Own tests, not consumer-borrowed.

Else: copy-paste twice. Wrong abstraction costs more.

**RFC waiver** — an accepted RFC requiring a stable public API for external integrators (the interface is part of the shipped contract, not speculative reuse) counts as one consumer. Cite the RFC ID in the package `README.md` + PR description; reviewer must acknowledge.

**Bootstrap waiver (first package only)** — on a fresh template with zero `packages/`, the "≥2 consumers" rule is unsatisfiable. The first package may ship with **one real consumer + an RFC describing the long-term API surface**. Subsequent packages must meet the full rule.

## Versioning

- Version bump required for any PR touching `packages/<pkg>/src/**` — use the project's chosen versioning tool (e.g. `changesets`, `release-please`, `cargo set-version`, manual `__version__`).
- Semver. Major bump → ADR.
- Internal-only packages still bump.

## Public API

- Single entry: `src/index.<ext>` (or stack equivalent). No deep imports.
- Breaking change → migration guide in package `CHANGELOG.md`.
- Deprecate one minor before removal.

## New package

1. RFC accepted (shared = wide impact).
2. Create `packages/<name>/` with the chosen stack's minimal layout — `<manifest>`, `src/index.<ext>` (single public entry), `tests/`, `README.md`, `CHANGELOG.md`, optional `AGENTS.md` (delta only). No pre-built scaffold ships; mimic neighbor packages.
3. CODEOWNERS: add `/packages/<name>/` per root § Agent constraints. Add to workspace config if the toolchain has one.
4. README must cover: Purpose, Install, Quick example, API, Stability (alpha|beta|stable).

## Test

- 100% public API covered.
- CI matrix across supported runtime versions.
- Snapshot build output (catches tree-shake / bundling regression where applicable).
