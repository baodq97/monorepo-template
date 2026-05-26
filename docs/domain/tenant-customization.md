---
id: DOMAIN-0001
title: Tenant customization
risk: High
status: draft
owner: TBD
date: 2026-05-26
related_prds: []
related_rfcs: []
related_adrs: []
---

# Tenant customization

## Purpose

Allow per-tenant behavior **without** turning the core into a tangle of
customer-specific branches. Customization must flow through declared boundaries
so the core stays one shape.

## Invariants

- Core business flow has **no knowledge** of individual tenant identities.
- Every per-tenant difference is expressible as one of: config value,
  feature flag, extension/adapter implementation, or module entitlement.
- Removing a tenant must require **zero** code changes in core.

## Allowed customization

- **Config schema** — tenant config validated against a typed schema.
- **Feature flags** — boolean / variant flags resolved per request.
- **Extension adapter** — interface implemented per tenant where required
  (e.g. `PricingAdapter`, `NotificationAdapter`).
- **Module entitlement** — opt-in/opt-out of a whole bounded module
  (see `docs/patterns/modules.md`).

## Forbidden customization

Pseudocode (illustrative — substitute your language's equivalent):

```text
# FORBIDDEN — hardcoded tenant branch in core logic
if tenant_id == "acme-corp":
    dashboard.show_legacy_widget = true
```

Why: creates unbounded customer-specific behavior; any future refactor risks
regressing a single customer in a non-obvious way.

## Extension points

- `TenantConfig` — typed config bag, schema-validated on load.
- `*Adapter` interfaces under `packages/<domain>/adapters/`.
- Module registry (per `docs/patterns/modules.md`).

## Edge cases

- New tenant onboarded mid-rollout of a flag — flag default must be safe.
- Tenant disabled — config absence must not crash core.

## Examples

Allowed (pseudocode):

```text
cfg = tenant_config.get(ctx.tenant_id)
if cfg.dashboard.legacy_widget:
    render_legacy()
```

Forbidden: see above.

## Tests that should protect this rule

- A **boundary lint / search test** that scans core packages for
  `tenant_id ==`, `tenantId ===`, or equivalent literal comparisons against
  known tenant slugs.
- Contract tests for each `*Adapter` interface.

## Agent autonomy

`guarded`. Agents may implement tenant-customization changes through declared
boundaries (config, flags, adapters), but must cite the invariants and boundary
lint tests in the PR body.

## Related docs

- `docs/known-traps.md` → KT-0001
- `docs/ownership-map.md`
- `docs/patterns/modules.md`
