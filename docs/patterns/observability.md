# Pattern — Observability (opt-in prescription)

> **Pattern reference, not core harness.** `services/AGENTS.md` requires "structured logs + metrics + traces" as a principle. Adopt this pattern when you want a concrete shape every service follows.

## When to adopt

- ≥2 services where on-call needs to correlate signals quickly.
- SLO-driven team (error budget, alerting on burn rate).
- Multi-tenant systems where per-tenant slicing matters.

Skip if you have one service and the team agrees on its own observability shape.

## Log shape

Structured JSON logs with the following fields on every line:

| Field | Type | When |
|---|---|---|
| `timestamp` | ISO-8601 | always |
| `level` | `debug` / `info` / `warn` / `error` | always |
| `service` | string | always |
| `trace_id` | hex string | when in a request context |
| `request_id` | string | when in a request context |
| `tenant_id` | string | when multi-tenant |
| `user_id` | string | when authenticated |
| `event` | string | always (machine-readable name) |
| `msg` | string | optional human-readable |

PII fields tagged in schema; logger auto-redacts via tag (see `data-governance` pattern when adopting).

## Metrics

- **RED** per route — Rate, Errors, Duration.
- Latency histograms with p50 / p95 / p99.
- Tag dimensions: `route`, `method`, `status_class`, `tenant_id` (if multi-tenant).
- Cardinality budget per service declared in service `README.md`.

## Traces

- Outbound span for every DB / HTTP / queue call.
- Propagate `trace_id` in headers and message metadata.
- Sampling policy declared in service `README.md` (default: head-based at edge, 100% on error).

## Alerts

- Every alert links to a runbook in `docs/runbooks/`.
- Alerts fire on SLO burn rate, not raw symptom thresholds.
- Page-worthy alerts have a tested runbook within 2 weeks of going live.

## RED dashboard

Required before prod traffic for any service adopting this pattern. One dashboard per service showing Rate / Errors / Duration over the last 6h + 7d, sliced by route.

## Lighter alternative

If full RED is overkill: structured logs with `trace_id` + an error-rate alert is the minimum viable. Document the choice in the service `README.md`.
