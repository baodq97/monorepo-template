# Pattern — Refactor thresholds (opt-in heuristics)

> **Pattern reference, not core harness.** Root `AGENTS.md` only says "a module that's grown too large → consider splitting." Adopt this pattern when the team wants explicit numeric triggers in PR review.

## Why opt-in

Industry sources (Fowler, *Refactoring*; Martin, *Clean Code*) measure module health by **cohesion** and **cyclomatic complexity**, not absolute line count. A 1,200-line module with one well-named responsibility is healthier than three 300-line modules with tangled dependencies. Hard LoC thresholds are a *heuristic for review prompts*, not a quality measure.

## When to adopt

- PR review queue is large and a numeric trigger speeds triage.
- The team has agreed that the chosen language's idiomatic module size is broadly stable (e.g. backend services in Go, Python, Java).
- Architecture tests in CI need a deterministic signal.

Skip if your stack varies widely (a 500-line Rust file ≠ a 500-line YAML file) or the team prefers complexity-based metrics.

## Suggested thresholds

| Trigger | Action |
|---|---|
| Module > 500 LoC | Reviewer asks: "Should this split?" — author justifies or splits |
| Module > 800 LoC | Author must justify in PR description; reviewer approves only with that justification |
| Function > 50 LoC | Same heuristic at function scope |
| File > 1,000 LoC | Hard block unless the file is generated |

Numbers are starting points. Tune per language / per repo.

## Companion rules

Core rules already in root `AGENTS.md` § Refactor guardrails + § Coding rules apply; this pattern adds the numeric LoC layer on top. The companion rules ("no single-use helpers", "comments explain why", promotion-to-`packages/`) are **not duplicated here** — read them in the root file once.

## Lighter alternative

Replace LoC thresholds with a complexity-based linter (e.g. cyclomatic complexity ≤ 15, cognitive complexity ≤ 25). Configure once in CI; review never has to count lines.
