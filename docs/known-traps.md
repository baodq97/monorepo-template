# Known Traps

Known traps are production scars, legacy edge cases, and hidden constraints
that agents must not simplify away. If you find yourself "cleaning up"
something that matches a trap below, **stop** — the ugliness is load-bearing.

Format per entry:

- **Area** — which domain doc owns the rule.
- **Risk** — Low / Medium / High / Critical.
- **Do not** — the exact pattern that re-introduces the bug.
- **Why** — what broke (or would break) in production.
- **Protected by** — the test / lint that catches a regression today (or
  "future" if not yet implemented).
- **Related docs** — domain docs, ADRs, postmortems.

---

## KT-0001: Hardcoded tenant branch in core logic

- **Area:** Tenant customization
- **Risk:** High
- **Do not:** Add `if tenant_id == ...` (or equivalent) inside core business flow.
- **Why:** It creates unbounded customer-specific behavior and makes core
  regression likely. Each new tenant becomes a maintenance trap; refactors
  silently break one customer at a time.
- **Protected by:** Future boundary/lint checks (search for literal tenant IDs
  in core packages).
- **Related docs:**
  - `docs/domain/tenant-customization.md`

## KT-0002: UI-only permission checks

- **Area:** Permission model
- **Risk:** Critical
- **Do not:** Treat hidden UI controls as authorization.
- **Why:** A hidden button is not a closed door. Any client (curl, mobile,
  another internal service) can call the endpoint directly. Backend/API
  boundaries must enforce permissions.
- **Protected by:** Future authorization contract tests per endpoint.
- **Related docs:**
  - `docs/domain/permission-model.md`
