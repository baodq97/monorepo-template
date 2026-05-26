---
id: DOMAIN-0003
title: Permission model
risk: Critical
status: draft
owner: TBD
date: 2026-05-26
related_prds: []
related_rfcs: []
related_adrs: []
---

# Permission model

## Purpose

Authorization decides what a principal may do, and tenant isolation prevents
one tenant's data from being visible or mutable by another. Both must be
enforced on the **server side**, at a single, auditable boundary.

## Invariants

- Every protected operation is authorized at the **backend/domain boundary**.
- Tenant isolation is enforced in the **data access layer** (every query is
  scoped by `tenant_id`; no global reads from authenticated user paths).
- **UI hiding is not authorization.** A hidden button is a UX nicety; the
  API endpoint behind it must still refuse the request.
- A new endpoint is **deny-by-default** until an authorization rule is wired.

## Allowed customization

- Adding a role / scope and wiring it to existing rule evaluation.
- Replacing the rule engine via an `AuthorizationAdapter` interface
  (lifecycle: RFC + ADR).

## Forbidden customization

- Trusting client-supplied `tenantId`, `role`, or `userId` for
  authorization decisions.
- Skipping the auth check on "internal" endpoints — they leak.
- Implementing a permission check **only** in the frontend.
- Cross-tenant joins or admin-style queries from request-handler code.

## Extension points

- `AuthorizationAdapter` — evaluates `(principal, action, resource)`.
- Repository / data-access layer — applies `tenant_id` scoping universally.

## Edge cases

- Background jobs / cron — must run with an explicit service principal,
  not a "system bypass".
- Multi-tenant admins — explicit `cross_tenant` scope, never implicit.
- Webhooks / inbound integrations — authenticate the source, then map to
  a principal *before* doing work.

## Examples

Pseudocode (illustrative — substitute your language's equivalent).

Allowed:

```text
authz.require(principal, "invoice.read", {tenant_id, invoice_id})
return repo.invoices.find_scoped(tenant_id, invoice_id)
```

Forbidden:

```text
# UI layer
if user.is_admin: show delete_button     # UI-only "permission"

# API handler
return repo.invoices.find_any(id)        # not scoped by tenant
```

## Tests that should protect this rule

- Authorization contract test per endpoint (allowed roles vs denied roles).
- Tenant-isolation test: principal of tenant A receives 404/403 for tenant
  B's resources, even with a valid ID.
- Boundary lint: data-access functions reject calls without a `tenantId`.

## Agent autonomy

`plan-only`. Authorization and isolation changes require explicit human
approval and the artifact gate appropriate to the change class.

## Related docs

- `docs/known-traps.md` → KT-0002
- `docs/ownership-map.md`
