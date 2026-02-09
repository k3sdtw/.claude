---
description: Expert review of the plan. 4 parallel agents (schema, architecture, code, security) review and approve.
---

# Expert Plan Review

Review plan with 4 parallel expert agents. Prerequisite: plan from `/orchestrate:start`.

## 1. Locate Plan

Read most recent `plans/*.md` or user-specified plan.

## 2. Launch 4 Expert Reviews (Parallel Task agents)

All agents report as: `[CRITICAL/HIGH/MEDIUM/LOW] Finding → Recommendation` or "No concerns".

**Agent 1 — Schema Designer** (`schema-designer`):
Review for: table structure/relationships, index strategy, migration safety, data integrity constraints, naming conventions, data type appropriateness.

**Agent 2 — Architect** (`architect`):
Review for: layer separation, dependency direction (Presentation → App → Domain ← Infra), DI tokens, entity immutability, bounded context boundaries, domain events, circular dependencies.

**Agent 3 — Code Reviewer** (`code-reviewer`):
Review for: API endpoint coverage, error handling (400/401/403/404/409), validation rules, E2E test scenarios, implementation order, agent work distribution, file conflicts, naming conventions.

**Agent 4 — Security Reviewer** (`security-reviewer`):
Review for: authentication, authorization, input validation, SQL injection prevention, sensitive data exposure, rate limiting, OWASP Top 10.

## 3. Aggregate & Fix

Present unified report with severity counts. If CRITICAL/HIGH found → fix plan and report changes.

## 4. Approve

When all CRITICAL/HIGH resolved, update plan:
```
Status: Plan approved — proceed with /orchestrate:impl
Approved: {date}
Reviews: Schema OK | Architecture OK | Code OK | Security OK
```

**GATE: Ask user confirmation before proceeding.**

→ Next: `/orchestrate:impl`
