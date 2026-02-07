---
description: Full orchestrated workflow. Requirements → branch → plan → expert review → implement → verify → PR. Jira optional. Profile-driven.
---

# Orchestrate Development Workflow

End-to-end development pipeline from requirements to Pull Request.
Supports both Jira-tracked and standalone development.
**Project-specific conventions are loaded from a profile**, not hardcoded here.

---

## Profile Loading (MUST be first step)

Before starting any phase, load the project profile:

### Detection Order

1. `--profile {name}` flag → load `profiles/{name}.md`
2. Auto-detect from project root:

| Detected File | Inferred Profile |
|---------------|-----------------|
| `nest-cli.json`, `src/main.ts` | Search for NestJS backend profile |
| `next.config.*`, `app/layout.tsx` | Search for Next.js frontend profile |
| `package.json` → `"react"` in deps | Search for React frontend profile |
| `pyproject.toml`, `manage.py` | Search for Python backend profile |
| `go.mod` | Search for Go profile |
| `Cargo.toml` | Search for Rust profile |

3. If no profile found or ambiguous → **ask user**:

```
No project profile detected. Which profile should I use?
- {list available profiles from profiles/ directory}
- Create a new profile (I'll analyze the codebase)
```

### Profile Contract

Every profile MUST define these sections (see bootstrap.md for generation):

```
[meta]          → project type, framework, architecture
[experts]       → expert reviewer definitions (4 agents)
[phases]        → implementation phase breakdown & agent assignments
[verification]  → build, lint, test commands
[conventions]   → commit format, branch naming, file naming
```

Set `PROFILE = {loaded profile}` and carry it through all phases.

---

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

1. **Always load a profile first.** Never start implementation without a resolved profile.
2. **Always create a separate workspace.** Both Jira and standalone mode MUST work on a dedicated worktree or branch. Never develop on main.
3. **Never skip a gate without explicit user approval.**
4. **Expert reviews are always parallel after plan confirmation.**

---

## Gate Rules

```
[Profile Load]         →  (automatic)
                            ↓
[Phase 1: Start]       →  GATE 1: Plan Confirmation
                            ↓
[Phase 2: Review]      →  GATE 2: Expert Approval
                            ↓
[Phase 3: Impl]        →  (automatic)
                            ↓
[Phase 4: Done]        →  GATE 3: PR Confirmation
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

Conduct interactive interview (both modes).

**Common questions (always ask):**
- Purpose and user value
- Scope boundaries (what's in / out)
- Error handling scenarios
- External service integrations

**Profile-specific questions (loaded from PROFILE):**
- The profile MAY define additional Q&A prompts under `[requirements_qa]`
- Example: backend profiles may ask about API endpoint spec, DB schema changes
- Example: frontend profiles may ask about UI/UX spec, responsive breakpoints, state management needs

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
If the profile defines a branch prefix convention, apply it.

**Worktree mode:**

```bash
# Jira mode
git gtr new {JIRA-KEY}-{feature-slug}

# Standalone mode
git gtr new {feature-slug}
```

> Auto-runs: `.env` copy + dependency install (when using gtr)
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
- **Profile used** (name and key conventions)
- Requirements summary
- Affected layers (loaded from `PROFILE[phases]`)
- Implementation phases (loaded from `PROFILE[phases]`)
- Parallel agent assignment table (loaded from `PROFILE[phases]`)
- Risk assessment

---

## GATE 1: Plan Confirmation

**STOP and ask the user:**

```
Plan written to plans/{plan-file}.
Profile: {profile name}
Should I proceed to expert review?
- Yes → continue
- Need changes → edit and re-confirm
```

**Do NOT proceed without user confirmation.**

---

## Phase 2: Expert Review (4 Parallel Agents)

After plan confirmation, launch **4 expert review agents in parallel**.
**Agent definitions are loaded from `PROFILE[experts]`.**

### 2-1. Launch Parallel Expert Reviews

Load all 4 expert agents from the profile. Each profile defines:
- Agent name and role
- Review focus areas
- Checklist items specific to the project's architecture and conventions

```
Agent 1 — {PROFILE.experts[0].name}:
  {PROFILE.experts[0].review_focus}

Agent 2 — {PROFILE.experts[1].name}:
  {PROFILE.experts[1].review_focus}

Agent 3 — {PROFILE.experts[2].name}:
  {PROFILE.experts[2].review_focus}

Agent 4 — {PROFILE.experts[3].name}:
  {PROFILE.experts[3].review_focus}
```

### 2-2. Aggregate Results

Collect all 4 expert reviews and present a unified report:

```markdown
## Expert Review Results

### {Expert 1 Name} Review
- {findings or "No issues"}

### {Expert 2 Name} Review
- {findings or "No issues"}

### {Expert 3 Name} Review
- {findings or "No issues"}

### {Expert 4 Name} Review
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
- [{Expert 1}] {summary}
- [{Expert 2}] {summary}
- [{Expert 3}] {summary}
- [{Expert 4}] {summary}

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

### 3-2. Execute Agents (from Profile)

**Phase structure is loaded from `PROFILE[phases]`.**

The profile defines:
- Which phases run in parallel vs sequential
- What each agent produces
- Dependencies between phases

Example (the profile controls this, not orchestrate):

```
Phase 3a (parallel) → PROFILE.phases.parallel_first
Phase 3b (sequential, after 3a) → PROFILE.phases.sequential_after
```

Each agent follows the implementation order, file templates, and naming conventions specified in the profile.

### 3-3. Integration Verification

Run verification commands **from `PROFILE[verification]`**:

```bash
{PROFILE.verification.lint}
{PROFILE.verification.build}
{PROFILE.verification.test}
```

If build or test fails, fix and re-verify (max 3 attempts).

---

## Phase 4: Finalize

### 4-1. Verification Loop

```
LOOP (max 3 iterations):
  1. {PROFILE.verification.lint}
  2. {PROFILE.verification.build}   → fail? fix, RESTART
  3. {PROFILE.verification.test}    → fail? fix, RESTART
  4. All green → EXIT
```

### 4-2. Code Review (parallel agents)

Launch **security-reviewer** and **code-reviewer** from `PROFILE[experts]` in parallel.

If CRITICAL or HIGH issues found → fix and re-run verification loop.

### 4-3. Commit

```bash
git add {specific files only}
git commit -m "{PROFILE.conventions.commit_format}"
```

- Stage specific files (never `git add .` or `git add -A`)
- Follow commit convention from profile (e.g., conventional commits, gitmoji, etc.)

---

## GATE 3: PR Confirmation

**STOP and present summary:**

```
## Pre-PR Summary

### Verification
- Lint: pass
- Build: pass
- Test: X/Y pass
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
gh pr create --title "{PROFILE.conventions.commit_format} {JIRA-KEY}" --body "$(cat <<'EOF'
## 개요
{what this PR does}

## 주요 변경사항
- {change 1}
- {change 2}

## 테스트
- [x] 테스트 추가
- [x] 로컬 테스트 완료
- [x] 기존 테스트 통과
EOF
)"
```

**Standalone mode:**
```bash
git push -u origin {branch}
gh pr create --title "{PROFILE.conventions.commit_format}" --body "$(cat <<'EOF'
## 개요
{what this PR does}

## 주요 변경사항
- {change 1}
- {change 2}

## 테스트
- [x] 테스트 추가
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
- {Jira mode: "Jira: {JIRA-KEY}" | Standalone mode: "Branch: {branch}"}

### Profile
- {profile name}

### Expert Reviews
- {Expert 1}: pass
- {Expert 2}: pass
- {Expert 3}: pass
- {Expert 4}: pass

### Verification
- Lint: pass
- Build: pass
- Test: X/Y pass

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

When resuming, the profile is re-loaded from the plan file's "Profile used" field.

## Examples

```
/orchestrate GIFCA-123
```
→ Auto-detect profile → Jira mode: fetch issue → Q&A → branch → plan → expert review → impl → verify → PR

```
/orchestrate GIFCA-456 --profile gifca-frontend
```
→ Load frontend profile → Jira mode: full pipeline with frontend conventions

```
/orchestrate --no-jira --profile gifca-frontend add dashboard page
```
→ Standalone mode + frontend profile: Q&A → branch → plan → expert review → impl → verify → PR

```
/orchestrate add voucher expiration notification
```
→ Auto-detect profile → Ask Jira or standalone → full pipeline