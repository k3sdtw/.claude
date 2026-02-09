# Agent Orchestration

## Available Agents

Located in `~/.claude/agents/`:

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| planner | Implementation planning | Complex features, refactoring |
| architect | System design | Architectural decisions |
| schema-designer | Database schema design | Schema changes, creating |
| api-designer | REST API design review | API endpoint design, contract review |
| tdd-nestjs | NestJS E2E TDD | Backend features, bug fixes |
| tdd-react | React component TDD | Frontend features, components, hooks |
| code-reviewer | Code review | After writing code |
| security-reviewer | Security analysis | Before commits |
| performance-reviewer | Performance review | Query, rendering, bundle optimization |
| ux-reviewer | Frontend UX review | Accessibility, responsive, interaction |
| build-error-resolver | Fix build errors | When build fails |

## Immediate Agent Usage

No user prompt needed:
1. Complex feature requests - Use **planner** agent
2. Code just written/modified - Use **code-reviewer** agent
3. Backend bug fix or feature - Use **tdd-nestjs** agent
6. Frontend bug fix or feature - Use **tdd-react** agent
4. Architectural decision - Use **architect** agent
5. Schema changes or creating - Use **schema-designer** agent

## Parallel Task Execution

ALWAYS use parallel Task execution for independent operations:

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Security analysis of auth.ts
2. Agent 2: Performance review of cache system
3. Agent 3: Type checking of utils.ts

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## Multi-Perspective Analysis

For complex problems, use split role sub-agents:
- Factual reviewer
- Senior engineer
- Security expert
- Consistency reviewer
- Redundancy checker
