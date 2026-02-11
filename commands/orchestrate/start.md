---
description: Start orchestrate workflow. Jira check → requirements Q&A → (issue creation) → branch setup → plan writing.
---

# Start Orchestrate

## 1. Jira Check

Ask user:
- **Existing key** → fetch via `mcp__jira__jira_get_issue`, skip step 3
- **No key** → create after Q&A (step 3)
- **Standalone** → skip Jira entirely

## 2. Requirements Q&A

Interactive interview (both modes). **Must clarify:**
- Purpose and user value
- API endpoint spec (method, path, request/response)
- Business rules and validation logic
- Error handling scenarios
- External service integrations

Even if issue exists, refine unclear parts. Output: structured requirements document.

## 3. Create Jira Issue (new issue only, skip if existing key or standalone)

Confirm project key with user, then:
```typescript
mcp__jira__jira_create_issue({
  project_key: "{confirm}",
  summary: "{feature}",
  issue_type: "Task",
  description: "## Background\n## Tasks\n## Done Criteria\n## References"
})
```

## 4. Workspace Detection (worktree preferred)

```bash
git gtr list 2>/dev/null
```
- **gtr available** → `WORKSPACE = worktree` (default, always preferred)
- **gtr not installed** → `WORKSPACE = branch` (fallback only)

> If already inside a worktree (`.git` is a file), still set `WORKSPACE = worktree`

## 5. Create Workspace & Enter Worktree (MANDATORY — never develop on main)

**Worktree (default):**

```bash
# 1. Save main repo root for later reference
MAIN_REPO=$(git rev-parse --show-toplevel)

# 2. Create worktree
BRANCH_NAME="{JIRA-KEY}-{slug}"  # or "{slug}" for standalone
git gtr new "$BRANCH_NAME"

# 3. Get worktree path and cd into it
WORKTREE_PATH=$(git worktree list --porcelain | grep -A1 "branch.*$BRANCH_NAME" | head -1 | awk '{print $2}')
cd "$WORKTREE_PATH"

# 4. Verify we are in the worktree (MUST pass before continuing)
[ "$(git branch --show-current)" = "$BRANCH_NAME" ] || echo "ERROR: Failed to enter worktree"
```

- Auto-runs `.env` copy + `pnpm install` via gtr hooks
- **MUST `cd` into worktree and verify before writing the plan**
- All subsequent work (plan writing, file edits) happens inside the worktree

**Branch (only when gtr is not installed):** `git checkout -b {JIRA-KEY}-{slug}` (or `{slug}` for standalone)

## 6. Write Plan + State (inside worktree)

Both files go in `plans/` inside the worktree directory, NOT the main repo.

### 6a. State JSON — `plans/{identifier}.state.json`

**Created first.** This is the single source of truth for all agent-consumable metadata.

```jsonc
{
  "identifier": "{jira-key}" | "{slug}",
  "jiraKey": "{JIRA-KEY}" | null,
  "branchName": "{branch-name}",

  "worktreePath": "{absolute path to worktree}",
  "mainRepoPath": "{absolute path to main repo}",
  "planFile": "{absolute path to plans/{identifier}.md}",

  "profile": "{profile-name}",
  "workspace": "worktree" | "branch",

  "currentPhase": "start",
  "gates": {
    "planConfirmed": false,
    "expertApproved": false,
    "prConfirmed": false
  },

  "expertReviews": {},

  "verification": {
    "lint": null,
    "build": null,
    "test": null,
    "lastRunAt": null
  },

  "pullRequest": {
    "url": null,
    "number": null
  },

  "createdAt": "{ISO 8601 timestamp}",
  "updatedAt": "{ISO 8601 timestamp}"
}
```

### 6b. Plan Markdown — `plans/{identifier}.md`

Human-readable plan. Contents:
- Tracking (Jira link or branch name)
- Profile used
- Requirements summary
- Affected layers (from `PROFILE[phases]`)
- Implementation phases with parallel agent assignment table
- Risk assessment
- Status: "Plan ready — proceed with `/orchestrate:review`"

> **Path/key metadata (worktree, Jira key, branch) lives ONLY in state JSON.** Plan markdown references state JSON for these values. Do NOT duplicate paths in plan markdown headers.

### 6c. Gate 1 — Plan Confirmation

After both files are written, present plan summary and ask user to confirm.
On confirmation → update state JSON:
```jsonc
{
  "gates": { "planConfirmed": true },
  "currentPhase": "review",
  "updatedAt": "{now}"
}
```

## Done Criteria

- Requirements clarified
- Worktree created and **currently inside worktree directory**
- `plans/{identifier}.state.json` created with all fields populated
- `plans/{identifier}.md` written with implementation plan
- Jira confirmed (if Jira mode)
- Gate 1 passed (user confirmed plan)
- Verify: `pwd` outputs worktree path, `git branch --show-current` is NOT main

→ Next: `/orchestrate:review`
