# Pattern — `modules/` (optional)

> **This is a pattern reference, not an active part of the repo.** The `modules/` folder does not exist by default. Adopt this pattern only when the conditions below are met. On adoption: create `modules/` at the repo root and copy this file to `modules/AGENTS.md`.
>
> **On adoption — replace this entire callout** (the line above and this one) at the top of `modules/AGENTS.md` with the two lines below, then delete this instruction:
>
> ```markdown
> # AGENTS.md — modules/
> Adopted YYYY-MM-DD via ADR-NNNN. Pattern source: [`docs/patterns/modules.md`](../docs/patterns/modules.md).
> ```

## What a module is — and is not

A **module** in this pattern is a **commercial unit** — something you can sell, license, gate behind an entitlement SKU, or ship to a customer separately. It is **not** a deployment unit and **not** a runtime mechanism. Examples of what a module represents:

- A product tier / SKU (e.g. "Vendor Management add-on").
- A feature pack a tenant opts into.
- A white-labelled capability sold to a different segment.

A module **may** map 1:1 to a bounded context, or several modules may live inside one bounded context, or one module may span several bounded contexts. **Grouping is a design choice, not a rule.**

## What this pattern leaves open (on purpose)

The pattern fixes the **commercial boundary** and the **logical isolation rules**. It deliberately does **not** fix:

- **How a module is wired at runtime** — module loader, plugin host, package import, separate process, separate deployable, dynamic assembly load, …
- **Whether modules share one deployable or many** — single host with N modules, host per module, hybrid; all valid.
- **Transport between modules** — in-process events, queue, HTTP, RPC; whichever the runtime decision picks.
- **Build/packaging** — one artifact per module, one artifact for all, per-tenant bundles; any of these works.

Those are runtime / architecture decisions. Record them in an **ADR** when picked. The pattern stays the same regardless.

## When to add `modules/`

Adopt when at least one is true:

- **Sold separately** — different SKU, tier, or customer segment buys this capability.
- **Licensed separately** — different commercial terms (on-prem, white-label, regional reseller, OEM).
- **Optionally enabled per tenant** — needs entitlement / feature-flag gating distinct from the core.
- **Owned end-to-end by a distinct team** with its own commercial lifecycle.

Not reasons:
- "It's a different technical concern" → folder, not module.
- "Might scale differently later" → defer; split when you actually need to.
- "Different author wrote it" → folder + CODEOWNERS is enough until commercial lifecycle differs.

If you cannot answer **"who buys this?"** you do not have a module yet.

## Layout per module (toolchain-agnostic)

```
modules/<X>/
  module.json              # commercial + ownership metadata
  AGENTS.md                # required only if the module has CI-special rules,
                           # distinct ownership from modules/AGENTS.md, or
                           # non-trivial deltas. Otherwise skip — closest-wins
                           # falls back to modules/AGENTS.md.
  README.md                # what this module sells / does
  <backend>/               # source + tests for the backend side (if any)
  <frontend>/              # source + tests for the UI side (if any)
  migrations/              # this module's own schema migrations (if it owns data)
```

Concrete subfolder names depend on the chosen toolchain — record them in an ADR.

## `module.json` shape

```json
{
  "name": "<X>",
  "version": "0.1.0",
  "owner": "@github-handle-or-team",
  "entitlement_sku": "module-<x>",
  "depends_on": [],
  "status": "active"
}
```

`status`: `active` | `retired`. Retired modules keep their data queryable — see § Retirement.

## Creating a new module

1. **PRD or feature ticket approved** (see root [AGENTS.md §Lifecycle](../../AGENTS.md)).
2. Copy the module template (project-specific scaffold — TBD per toolchain).
3. Populate `module.json` — including who buys this.
4. Add CODEOWNERS entry for `/modules/<X>/`.
5. Wire the module per the project's **runtime decision** (loader registration, workspace manifest, etc.). The wiring lives in code, not in this pattern.

## Isolation rules (the whole reason modules exist)

These are **logical** rules — independent of how modules are wired at runtime. Enforce with arch-tests in CI where possible, otherwise via code review.

- **No direct cross-module imports.** Module `<X>` source must not reference symbols from module `<Y>` source. (Both could end up in the same process; this rule still holds.)
- **Cross-module communication = explicit message contract.** Whether the transport is in-process events, a queue, or HTTP, the contract is declared and versioned. The transport is a runtime decision; the contract discipline is not.
- **Cross-module entity references = ID only.** No foreign keys, no navigation properties across module boundaries.
- **Each module owns its schema.** Separate migration history per module — even if physically the same database. Schemas are commercial boundaries, not just technical ones.
- **Domain layer stays pure.** No framework / ORM leakage into domain types.
- **One declared public surface per module.** Public API / UI exports are listed explicitly; everything else is internal.

## Implementation is deferred

How a module is **executed** — loaded by a host, packaged as a plugin, deployed as its own service, imported as a workspace package, dynamically discovered at boot — is a runtime architecture decision recorded in an ADR (e.g. `ADR-NNNN: Module runtime mechanism`). Different projects will pick different mechanisms. **The same `modules/` layout and isolation rules apply regardless.**

If the runtime decision later changes (e.g. from "loaded into one host" to "each module is its own service"), the change is:

1. A new ADR superseding the runtime ADR.
2. Mechanical refactor of wiring code.
3. Possibly a transport swap (in-process bus → network) — but the contracts already exist, so this is a swap, not a rewrite.

The commercial boundary does not move. That is the point of the pattern.

## Retirement

Modules can be retired but data must be preserved:

1. Mark `module.json` `status: retired`.
2. Disable entitlement SKU for new buyers; existing tenants get read-only access.
3. Mutating endpoints return `410 Gone`; read endpoints continue to serve.
4. ADR documenting retirement decision + sunset date.
5. After sunset: data-export tool offered; module code can be removed; data archived per retention policy.

## Anti-patterns

- ✗ Creating `modules/` with one module because "we might add more" — wait until the second commercial unit is real.
- ✗ Treating "module" as a synonym for "service" or "deployable" — the commercial meaning is the point; runtime mechanism is separate.
- ✗ Cross-module direct imports — go through the declared contract.
- ✗ Two modules sharing one schema / migration history.
- ✗ Reading another module's tables directly — use the contract.
- ✗ Bundling two unrelated commercial units in one module — split or rename.
- ✗ Letting the runtime decision (loader, plugin, separate service) leak into the module's domain code.
