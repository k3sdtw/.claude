---
description: Implement with parallel agents. Plan-based Domain/Infra/App layer development.
---

# Parallel Agent Implementation

Implement approved plan using parallel agents. Prerequisite: plan approved via `/orchestrate:review`.

## 0. State Guard (MUST run first)

```bash
# 1. Find state file
STATE_FILE=$(ls -t plans/*.state.json 2>/dev/null | head -1)
if [ -z "$STATE_FILE" ]; then
  echo "ERROR: No state file found. Run /orchestrate:start first."
  exit 1
fi

# 2. Read from state JSON
WORKTREE_PATH=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['worktreePath'])")
JIRA_KEY=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('jiraKey') or '')")
PROFILE=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['profile'])")
PLAN_FILE=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['planFile'])")
BRANCH=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['branchName'])")

# 3. cd into worktree if needed
if [ "$(pwd)" != "$WORKTREE_PATH" ]; then
  cd "$WORKTREE_PATH"
fi

# 4. Verify not on main
if [ "$(git branch --show-current)" = "main" ]; then
  echo "ERROR: On main branch. Must be in worktree."
  exit 1
fi
```

If state file is missing or worktree path doesn't exist → STOP and ask user.

Update state on entry:
```jsonc
{ "currentPhase": "impl", "updatedAt": "{now}" }
```

## 1. Load Plan

Read plan from `planFile` path in state JSON. Extract agent assignments from "Parallel Agent Assignment" section.

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

## 4. Update State

After verification passes, update state JSON:
```jsonc
{
  "verification": {
    "lint": "pass" | "fail",
    "build": "pass" | "fail",
    "test": "pass" | "fail",
    "lastRunAt": "{ISO 8601 timestamp}"
  },
  "currentPhase": "done",
  "updatedAt": "{now}"
}
```

## Done Criteria

- All agents completed
- Build passes
- Tests pass
- State JSON updated with verification results

→ Next: `/orchestrate:done`
