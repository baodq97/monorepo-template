---
id: DOMAIN-0002
title: Pricing rules
risk: Critical
status: draft
owner: TBD
date: 2026-05-26
related_prds: []
related_rfcs: []
related_adrs: []
---

# Pricing rules

## Purpose

Pricing is revenue-impacting and legally sensitive. Even small changes can
cause invoicing errors, refund cascades, or contractual breach. This doc
governs what may change, by whom, and through which artifact.

## Invariants

- Pricing **formulas** (rate cards, discount math, tax rounding rules) are
  fixed by an accepted PRD + ADR. They are not patched in place.
- Pricing changes are **never** tenant-overridden via ad-hoc branches.
  Tenant-specific pricing flows through an explicit, audited adapter or
  contract record.
- Currency, rounding, and tax handling follow documented rules; "fix the
  rounding bug" is itself a pricing change.

## Allowed customization

- Tenant **contract record** in a pricing data store (audited, dated).
- Discount **codes** with documented validity windows.
- A `PricingAdapter` implementation behind a fully-specified interface,
  added via the lifecycle (PRD → RFC → ADR).

## Forbidden customization

- Inline `if tenant_id === "..."` discounts.
- Local constants overriding rate cards.
- Silent rounding-mode changes.
- Agent-initiated changes to pricing math, *even* if "obviously correct".

## Extension points

- `PricingAdapter` interface (when introduced).
- Discount-code resolver.
- Tax/locality module.

## Edge cases

- Mid-cycle plan change — prorate per documented rule, not by guess.
- Currency conversion timing — quote at order time vs. invoice time.
- Refunds vs. credits — distinct accounting paths.

## Examples

Pseudocode (illustrative — substitute your language's equivalent).

Allowed (adapter wired in via approved artifact):

```text
price = pricing_adapter.quote(plan, tenant_contract)
```

Forbidden:

```text
if tenant_id == "acme":
    price = price * 0.8   # unauthorised override
```

## Tests that should protect this rule

- Golden-file tests for each rate card (any diff fails CI; expected diffs
  require an artifact link in the PR).
- Property tests on rounding/currency edge cases.
- A boundary lint forbidding literal tenant IDs in pricing modules.

## Agent autonomy

`plan-only`. Agents propose; humans approve and implement (or explicitly
delegate). Do not edit pricing math without an accepted PRD + ADR linked in
the PR.

## Related docs

- `docs/known-traps.md` → KT-0001
- `docs/ownership-map.md`
