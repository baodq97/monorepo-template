# AGENTS.md — /infra

Delta only. **This is production.** Rules harden here.

## Layout

```
infra/
  modules/      reusable IaC modules
  envs/
    dev/        agents may iterate freely
    staging/    PR review required
    prod/       ADR + ≥2 CODEOWNERS approvals
```

## Hard rules

- **Never apply by hand to `prod`** — CI pipeline with approval gate only.
- **Never delete stateful resources** (DB, bucket, queue). Detach from IaC state and re-import rather than destroy-and-recreate.
- **Never store secrets in IaC** — reference from Vault/SSM.
- **Never disable** backup, encryption, audit log.
- IaC plan in PR must be clean. Drift = blocker.

## Agent workflow

1. Read `envs/<env>/README.md` for blast radius.
2. Change in `modules/` → apply to `dev` → promote.
3. Prod change = standalone PR, no app code mixed.
4. Paste IaC plan diff (e.g. `terraform plan`, `pulumi preview`, `cdk diff`) in PR description.

## Tagging & cost

- Every resource tagged: `owner`, `env`, `cost-center`, `data-class`.
- Expensive resources need ADR justification. The team picks the threshold and records it in `infra/AGENTS.md` (e.g. ">$100/month") once cost reality is known; until then, reviewer judgement.
- RPO/RTO declared in each env README.
