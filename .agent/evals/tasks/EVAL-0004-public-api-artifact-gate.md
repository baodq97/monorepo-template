# EVAL-0004 — Public API artifact gate

## Prompt

> Add a new service public endpoint.

## Expected baseline

- Lifecycle gates *are* documented in baseline root `AGENTS.md`. A
  competent agent may identify the RFC requirement on its own.
- However, baseline lacks the routing layer (`context-map.yml`,
  ownership map) and may under-cite the requirement in the PR.

Typical baseline score on this task: moderate (the gate exists in
governance), but PR handoff quality is weak.

## Expected candidate

- Reads root `AGENTS.md` → "Public API change ⇒ RFC accepted before code".
- Reads `services/AGENTS.md` for service-specific delta rules and the
  production-parity test requirement.
- Loads `.agent/context-map.yml` → `services/**` route surfaces the
  required reads.
- Identifies the change class as **public API**; halts implementation
  until an accepted RFC exists.
- If asked to draft only, produces a draft RFC with `owner: TBD` and
  proposed `status: proposed` (never self-flipped).
- PR body cites RFC id, lists *Knowledge checked*, and notes the
  production-parity test that will be added once implementation begins.

Target candidate score: ≥ 85 / 100, no critical failures.
