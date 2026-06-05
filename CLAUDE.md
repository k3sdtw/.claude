# CLAUDE.md

## When writing the code (IMPORTANT) 

- Do not use abstract words for all function names, variable names. (e.g. Info, Data, Item etc..)
- Follow naming conventions: [rules/common/naming-conventions.md](rules/common/naming-conventions.md) — prefer the shortest unambiguous name (e.g. `getList` → `list`, `findUserById` → `find`).
- Use the **namer** agent ([agents/namer.md](agents/namer.md)) when proposing or reviewing identifier names; run `/check-naming` ([commands/check-naming.md](commands/check-naming.md)) to audit existing code.

## DevOps / Infra (AWS · Terraform · EKS · GitHub Actions)

환경: AWS 자원이 **콘솔(legacy) ↔ Terraform**로 분리됨 · 서비스는 **EKS + GitOps(ArgoCD/Flux)** · CI/CD는 **GitHub Actions** · **비용은 MSP 대시보드 별도(harness 범위 밖)**.

- **실행 안전(필독)**: 읽기는 자동, 변경(apply/delete/sync/rerun)은 승인 — [rules/devops/safety.md](rules/devops/safety.md). 대상 account/region/context를 항상 먼저 확인.
- 지식: [rules/devops/](rules/devops/) — terraform · kubernetes · github-actions · aws · safety
- command: `/infra` ([commands/infra.md](commands/infra.md)) — `tf-import` · `drift` · `eks-debug` · `ci-debug` · `inventory`
- agent: **terraform-reviewer** · **eks-doctor** · **cicd-reviewer** · **aws-auditor**
- skill(자동 활성화): **terraform** · **eks** · **github-actions**

# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
