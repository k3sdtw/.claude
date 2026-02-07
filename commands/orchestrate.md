---
description: Full orchestrated workflow. Requirements → branch → plan → expert review → implement → verify → PR. Jira optional.
---

# Orchestrate Development Workflow

End-to-end development pipeline from requirements to Pull Request.
Supports both Jira-tracked and standalone development.

## Mode Detection

Determine the mode from user input:

| Input | Mode | Example |
|-------|------|---------|
| Jira key (`[A-Z]+-[0-9]+`) | **Jira mode** | `/orchestrate GIFCA-123` |
| `--no-jira` flag | **Standalone mode** | `/orchestrate --no-jira add login feature` |
| Feature description only | **Ask user** | `/orchestrate add login feature` |

When mode is ambiguous, ask:

```
Is this tracked in Jira?
- Yes → provide the issue key or I'll create one
- No  → standalone mode (no Jira integration)
```

Set `MODE = jira | standalone` and carry it through all phases.

---

## Mandatory Rules

1. **Always create a separate workspace.** Both Jira and standalone mode MUST work on a dedicated worktree or branch. Never develop on main.
2. **Never skip a gate without explicit user approval.**
3. **Expert reviews are always parallel after plan confirmation.**

---

## Gate Rules

```
[Phase 1: Start]    →  GATE 1: Plan Confirmation
                           ↓
[Phase 2: Review]   →  GATE 2: Expert Approval
                           ↓
[Phase 3: Impl]     →  (automatic)
                           ↓
[Phase 4: Done]     →  GATE 3: PR Confirmation
```

---

## Phase 1: Start

### 1-1. Issue Setup

**Jira mode:**
- Existing key provided → fetch via `mcp__jira__jira_get_issue`
- No key → create after Q&A (confirm project key with user first)

**Standalone mode:**
- Skip entirely. No issue creation.

### 1-2. Requirements Q&A

Conduct interactive interview (both modes):

- Purpose and user value
- API endpoint spec (method, path, request/response)
- Business rules and validation logic
- Error handling scenarios
- External service integrations

**Output:** Structured requirements document

### 1-3. Create Jira Issue

**Jira mode only** (skip if existing key was provided):

```typescript
mcp__jira__jira_create_issue({
  project_key: "{confirm with user}",
  summary: "{feature name}",
  issue_type: "Task",
  description: "{Task template format}"
})
```

**Standalone mode:** skip.

### 1-4. Workspace Detection

Detect whether the repository uses a worktree structure:

```bash
# Check if git gtr is available and current repo is a worktree-managed workspace
git gtr list 2>/dev/null
```

| Condition | Workspace Type |
|-----------|---------------|
| `git gtr list` succeeds and shows worktree entries | **Worktree** |
| `.git` is a file (not a directory) | **Worktree** |
| Otherwise | **Branch** |

Set `WORKSPACE = worktree | branch` and carry it through all phases.

### 1-5. Create Workspace (MANDATORY)

**Always work on a separate workspace, regardless of mode.**

Branch naming: use kebab-case, descriptive slug (e.g. `add-login-endpoint`).

**Worktree mode:**

```bash
# Jira mode
git gtr new {JIRA-KEY}-{feature-slug}

# Standalone mode
git gtr new {feature-slug}
```

> Auto-runs: `.env` copy + `pnpm install` (when using gtr)
> After creation, **cd into the new worktree directory** to continue work there.

**Branch mode:**

```bash
# Jira mode
git checkout -b {JIRA-KEY}-{feature-slug}

# Standalone mode
git checkout -b {feature-slug}
```

### 1-6. Write Plan

**Jira mode:** Create `plans/{jira-key}.md`
**Standalone mode:** Create `plans/{feature-slug}.md`

Plan contents:
- Jira link (Jira mode only)
- Requirements summary
- Affected layers (db, core, app)
- Implementation phases (Domain → Infra → App → Test)
- Parallel agent assignment table
- Risk assessment

---

## GATE 1: Plan Confirmation

**STOP and ask the user:**

```
Plan written to plans/{plan-file}.
Should I proceed to expert review?
- Yes → continue
- Need changes → edit and re-confirm
```

**Do NOT proceed without user confirmation.**

---

## Phase 2: Expert Review (4 Parallel Agents)

After plan confirmation, launch **4 expert review agents in parallel**.
Each agent reviews the plan from its specialized perspective.

### 2-1. Launch Parallel Expert Reviews

```
Agent 1 — Schema Designer:
  Review the plan for database/schema concerns:
  - Table structure and relationships
  - Index strategy
  - Migration safety
  - Data integrity constraints
  - Naming conventions for tables/columns

Agent 2 — Architect:
  Review the plan for architectural fitness:
  - Hexagonal architecture layer separation
  - Correct dependency direction (Presentation → App → Domain ← Infra)
  - DI with Symbol tokens
  - Entity immutability pattern (private constructor + factory)
  - Bounded context boundaries
  - Domain event needs

Agent 3 — Code Reviewer:
  Review the plan for implementation quality:
  - Requirements completeness (all endpoints, error cases, validation)
  - Correct implementation order (Domain → Infra → App)
  - Parallel agent work distribution soundness
  - No file conflicts between agents
  - Naming conventions
  - E2E test scenario coverage

Agent 4 — Security Reviewer:
  Review the plan for security concerns:
  - Authentication/authorization requirements
  - Input validation strategy
  - SQL injection prevention
  - Sensitive data exposure risks
  - Rate limiting needs
  - OWASP Top 10 relevance
```

### 2-2. Aggregate Results

Collect all 4 expert reviews and present a unified report:

```markdown
## Expert Review Results

### Schema Design Review
- {findings or "No issues"}

### Architecture Review
- {findings or "No issues"}

### Code Quality Review
- {findings or "No issues"}

### Security Review
- {findings or "No issues"}

### Action Required
1. [CRITICAL] {issue} → {fix}
2. [HIGH] {issue} → {fix}
3. [MEDIUM] {issue} → {suggestion}
```

### 2-3. Apply Fixes

If CRITICAL or HIGH issues found:
1. Fix the plan
2. Report what changed

---

## GATE 2: Expert Approval

**STOP and present review result:**

```
## Expert Review Summary

### Passed
- [Schema] No migration issues
- [Architecture] Layer separation correct
- [Code] All endpoints covered
- [Security] Auth requirements specified

### Fixed (if any)
1. {what was wrong} → {how it was fixed}

Plan is approved for implementation. Proceed?
- Yes → continue
- No → specify what needs more work
```

Update plan status to approved.

**Do NOT proceed without user confirmation.**

---

## Phase 3: Implementation

### 3-1. Load Plan

Read the plan file and extract agent assignments.

### 3-2. Execute Parallel Agents

**Phase 3a — Domain + Mapper (parallel):**

Agent 1 (Domain Layer):
- Entity with private constructor + create()/reconstitute()
- Repository Interface with Symbol token
- Domain Errors extending DomainError
- index.ts exports

Agent 2 (Infrastructure Layer):
- Mapper (toDomain / toPersistence)
- Repository Implementation (after Agent 1 Interface is available)
- index.ts exports

**Phase 3b — Application (sequential, after 3a):**

Agent 3 (Application Layer):
- Use Case with @Transactional()
- Controller with Swagger decorators
- Request/Response DTOs
- Module registration
- E2E Test

### 3-3. Integration Verification

```bash
pnpm biome check --write .
pnpm build
pnpm test:e2e:gifca
```

If build or test fails, fix and re-verify (max 3 attempts).

---

## Phase 4: Finalize

### 4-1. Verification Loop

```
LOOP (max 3 iterations):
  1. pnpm biome check --write .
  2. pnpm build          → fail? fix, RESTART
  3. pnpm test:e2e:gifca → fail? fix, RESTART
  4. All green → EXIT
```

### 4-2. Code Review (parallel agents)

Launch **security-reviewer** and **code-reviewer** in parallel.

If CRITICAL or HIGH issues found → fix and re-run verification loop.

### 4-3. Commit

```bash
git add {specific files only}
git commit -m "<type>(<scope>): <description>"
```

- Stage specific files (never `git add .` or `git add -A`)
- Follow conventional commit format

---

## GATE 3: PR Confirmation

**STOP and present summary:**

```
## Pre-PR Summary

### Verification
- Biome: pass
- Build: pass
- E2E Test: X/Y pass
- Security Review: no critical issues
- Code Review: no critical issues

### Commit
- {commit hash} {commit message}

Ready to create PR and push?
- Yes → create PR
- No → specify what needs adjustment
```

**Do NOT push or create PR without user confirmation.**

---

### 4-4. Create PR

**Jira mode:**
```bash
git push -u origin {branch}
gh pr create --title "{type}({scope}): {description} {JIRA-KEY}" --body "$(cat <<'EOF'
## 개요
{what this PR does}

## 주요 변경사항
- {change 1}
- {change 2}

## 테스트
- [x] E2E 테스트 추가
- [x] 로컬 테스트 완료
- [x] 기존 테스트 통과
EOF
)"
```

**Standalone mode:**
```bash
git push -u origin {branch}
gh pr create --title "{type}({scope}): {description}" --body "$(cat <<'EOF'
## 개요
{what this PR does}

## 주요 변경사항
- {change 1}
- {change 2}

## 테스트
- [x] E2E 테스트 추가
- [x] 로컬 테스트 완료
- [x] 기존 테스트 통과
EOF
)"
```

### 4-5. Update Jira (Jira mode only)

```typescript
mcp__jira__jira_transition_issue({
  issue_key: "{JIRA-KEY}",
  transition: "In Review"
})
```

**Standalone mode:** skip.

---

## Final Output

```markdown
## Development Complete

### Tracking
- {Jira mode: "Jira: GIFCA-123" | Standalone mode: "Branch: add-login-endpoint"}

### Expert Reviews
- Schema: pass
- Architecture: pass
- Code Quality: pass
- Security: pass

### Verification
- Biome: pass
- Build: pass
- E2E Test: X/Y pass

### Pull Request
- URL: {PR URL}
- Title: {PR title}
- Branch: {branch} → main

### Next Steps
1. Request PR review
2. Merge after approval
3. Worktree mode: `git gtr rm {branch} --delete-branch --yes`
   Branch mode: `git branch -d {branch}`
```

---

## Resuming Mid-Workflow

If the session breaks, resume from any phase:

```
/orchestrate:review   → Phase 2
/orchestrate:impl     → Phase 3
/orchestrate:done     → Phase 4
```

## Examples

```
/orchestrate GIFCA-123
```
→ Jira mode: fetch issue → Q&A → branch → plan → expert review → impl → verify → PR

```
/orchestrate add voucher expiration notification
```
→ Ask Jira or standalone → full pipeline

```
/orchestrate --no-jira add health check endpoint
```
→ Standalone mode: Q&A → branch → plan → expert review → impl → verify → PR
