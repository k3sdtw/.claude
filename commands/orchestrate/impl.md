---
description: Implement with parallel agents. Plan-based Domain/Infra/App layer development.
---

# Parallel Agent Implementation

Implement approved plan using parallel agents. Prerequisite: plan approved via `/orchestrate:review`.

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
