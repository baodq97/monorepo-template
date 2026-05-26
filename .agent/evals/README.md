# Agent operability evals

These evals score how well a coding agent operates **inside this template**.
They are not about model capability in the abstract — they ask: given the
artifacts this repo ships, does an agent route to the right context, halt
in the right places, and produce verifiable PRs?

## Layout

- `scoring.md` — the rubric (100 pts) + pass thresholds + critical failures.
- `tasks/EVAL-NNNN-*.md` — one task per scenario. Each has a prompt and
  the expected behavior of a baseline vs. candidate template.
- `reports/baseline-current-template.md` — score under the **pre-change**
  template (governance only).
- `reports/candidate-after-change.md` — score under **this PR's** template
  (governance + product knowledge layer + evals).
- `scripts/eval-agent-operability.sh` (top-level) — static verifier that
  the eval layer and its dependencies exist.

## Task file structure

All task files follow the same format: **Prompt** (the user request to hand
to the agent), **What we score**, **Expected baseline** (old template),
**Expected candidate** (new template), **Target candidate score**. Keep this
structure when adding new tasks — it allows future parametric runners to parse
them uniformly.

## How to run an eval

The runner (`scripts/eval-agent-operability.sh`) is a static check; it does
**not** call an LLM. To run a behavioral eval:

1. Spin up an agent session pointed at a checkout of this repo.
2. Hand it the exact prompt from a task file.
3. Score its trajectory against `scoring.md`.
4. Record the result in a new report file under `reports/`.

A future iteration may add an LLM-driven harness; the static checks here
guarantee the *inputs* to such a harness are present and well-formed.

## Pass criteria

- Candidate score ≥ 80/100.
- Candidate improves baseline by ≥ 25 points.
- Zero critical failures (see `scoring.md`).
