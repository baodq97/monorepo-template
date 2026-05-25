# Ownership map

`CODEOWNERS` answers **"who must review changes to this path?"**.
This map answers **"who understands this logic, and what autonomy does a
coding agent have here?"**.

Both are required. CODEOWNERS protects the merge gate; this map protects
the *decision* gate before code is written.

## Agent autonomy levels

| Level       | What the agent may do |
|-------------|-----------------------|
| `implement` | Implement with normal checks (lifecycle, verify, PR). |
| `guarded`   | Implement only after citing the required docs and tests in the PR body. |
| `plan-only` | Produce a plan / proposal, not code, unless explicitly approved. |
| `forbidden` | Do not edit. Halt and surface to the user. |

A level higher up the table includes everything below it. When in doubt,
classify up.

## Map

| Area                          | Business owner | Technical owner | Risk     | Must-read docs                                                                | Agent autonomy |
|-------------------------------|----------------|-----------------|----------|--------------------------------------------------------------------------------|----------------|
| Tenant customization          | TBD            | TBD             | High     | `docs/domain/tenant-customization.md`, `docs/known-traps.md`                   | guarded        |
| Pricing                       | TBD            | TBD             | Critical | `docs/domain/pricing-rules.md`, `docs/known-traps.md`                          | plan-only      |
| Permissions / tenant isolation| TBD            | TBD             | Critical | `docs/domain/permission-model.md`, `docs/known-traps.md`                       | plan-only      |
| Docs / governance             | TBD            | TBD             | Medium   | `AGENTS.md`, `docs/AGENTS.md`                                                  | guarded        |

## How to use this map

1. Identify the **area(s)** your change touches.
2. Read every doc in **Must-read docs** before writing code.
3. Cite those reads in the PR body under **Knowledge checked**.
4. Respect the **Agent autonomy** level — escalate if the level is too
   restrictive for the requested work.

## When to extend the map

Add a row when introducing a new bounded area (a new domain, a new
shared package family, a new infra surface). Owners default to `TBD`;
the human doc owner fills them on merge (per root § Ownership &
handoffs).
