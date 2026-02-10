---
description: Expert review of the plan. Context-aware agent groups (backend/frontend/fullstack) review and approve.
---

# Expert Plan Review

Review plan with parallel expert agents selected by project context.
Prerequisite: plan from `/orchestrate:start`.

## 0. Worktree Guard (MUST run first)

```bash
# Read worktree path from plan
PLAN_FILE=$(ls -t plans/*.md 2>/dev/null | head -1)
WORKTREE_PATH=$(grep "^Worktree:" "$PLAN_FILE" | awk '{print $2}')

# If not in worktree, cd into it
if [ -n "$WORKTREE_PATH" ] && [ "$(pwd)" != "$WORKTREE_PATH" ]; then
  cd "$WORKTREE_PATH"
fi

# Verify not on main
if [ "$(git branch --show-current)" = "main" ]; then
  echo "ERROR: On main branch. Must cd into worktree first."
  exit 1
fi
```

If `Worktree:` field is missing from plan or path doesn't exist → STOP and ask user for worktree path.

## 1. Locate Plan

Read most recent `plans/*.md` or user-specified plan.

## 2. Select Agent Group

Determine group from context. Use the FIRST match:

| Condition | Group |
|-----------|-------|
| `--group backend` or `--group frontend` flag | As specified |
| `PROFILE[meta.type]` is set | Use profile value |
| `nest-cli.json` or `src/main.ts` exists | BACKEND |
| `next.config.*` or `app/layout.tsx` exists | FRONTEND |
| Both detected | FULLSTACK |
| None detected | Ask user |

## 3. Agent Group Definitions

### BACKEND_GROUP (5 agents)

| # | Agent Type | Review Focus |
|---|-----------|-------------|
| 1 | `schema-designer` | Table structure, relationships, indexes, migration safety, constraints, naming |
| 2 | `architect` | Layer separation, dependency direction, DI tokens, bounded context, domain events |
| 3 | `api-designer` | REST conventions, error response format, pagination, versioning, DTO boundaries |
| 4 | `security-reviewer` | SQL injection, auth/authz bypass, rate limiting, sensitive data exposure, input validation |
| 5 | `performance-reviewer` | N+1 queries, missing indexes, caching strategy, connection management, transaction scope |

### FRONTEND_GROUP (4 agents)

| # | Agent Type | Review Focus |
|---|-----------|-------------|
| 1 | `architect` | Component structure, state management, routing, code splitting, module boundaries |
| 2 | `ux-reviewer` | Accessibility (a11y), responsive design, loading/error/empty states, interaction patterns |
| 3 | `security-reviewer` | XSS, CSP, token storage, CORS, third-party script risks, sensitive data in client |
| 4 | `performance-reviewer` | Bundle size, rendering optimization, lazy loading, request waterfall, memory leaks |

### FULLSTACK_GROUP (6 agents)

All BACKEND_GROUP agents + `ux-reviewer` from FRONTEND_GROUP.
(Schema/Architect/API/Security cover both layers; add UX for frontend surface.)

## 4. Launch Reviews (Parallel)

Launch ALL agents in the selected group simultaneously via Task tool.

Each agent prompt:
```
Review the plan at plans/{plan-file}.md.
Focus: {review focus from group table above}
Report: [CRITICAL/HIGH/MEDIUM/LOW] Finding → Recommendation. "No concerns" if clean.
```

## 5. Aggregate & Fix

Present unified report with severity counts per agent.
CRITICAL/HIGH found → fix plan, report changes.

## 6. Approve

When all CRITICAL/HIGH resolved, update plan:
```
Status: Plan approved — proceed with /orchestrate:impl
Approved: {date}
Reviews: {Agent1} OK | {Agent2} OK | ...
```

**GATE: Ask user confirmation before proceeding.**

→ Next: `/orchestrate:impl`
