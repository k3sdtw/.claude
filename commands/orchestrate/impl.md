---
description: Implement with parallel agents. Plan-based Domain/Infra/App layer development.
---

# Parallel Agent Implementation

Implement approved plan using parallel agents. Prerequisite: plan approved via `/orchestrate:review`.

## 0. Worktree Guard (MUST run first)

```bash
# Find plan and extract worktree path
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

## 1. Load Plan

Get branch name (`git branch --show-current`), read `plans/{identifier}.md`, extract agent assignments from "Parallel Agent Assignment" section.

## 2. Execute by Phase (from plan)

Respect dependency order defined in the plan. Typical pattern:

**Phase A (parallel):** Domain + Infrastructure agents
- Domain: Entity (private constructor + factory), Repository Interface (Symbol token), Domain Error
- Infra: Mapper (toDomain/toPersistence), Repository Impl (uses Mapper)

**Phase B (sequential, after A):** Application agent
- Use Case, Controller, DTOs, Module registration, E2E Tests

Launch via Task tool with `subagent_type: "general-purpose"`. Each agent follows file templates, naming conventions, and paths specified in the plan.

## 3. Integration Verification

After all agents complete:
```bash
{PROFILE.verification.lint}
{PROFILE.verification.build}
{PROFILE.verification.test}
```

Build/test failure → fix and re-verify (max 3 attempts). Use `build-error-resolver` agent if needed.

## Done Criteria

- All agents completed
- Build passes
- Tests pass

→ Next: `/orchestrate:done`
