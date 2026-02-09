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

## 4. Workspace Detection

```bash
git gtr list 2>/dev/null
```
- Succeeds or `.git` is a file → `WORKSPACE = worktree`
- Otherwise → `WORKSPACE = branch`

## 5. Create Workspace (MANDATORY — never develop on main)

**Worktree:** `git gtr new {JIRA-KEY}-{slug}` (or `{slug}` for standalone)
- Auto-runs `.env` copy + `pnpm install`
- **cd into new worktree** after creation

**Branch:** `git checkout -b {JIRA-KEY}-{slug}` (or `{slug}` for standalone)

## 6. Write Plan

File: `plans/{jira-key}.md` or `plans/{slug}.md`

Contents:
- Tracking (Jira link or branch name)
- Profile used
- Requirements summary
- Affected layers (from `PROFILE[phases]`)
- Implementation phases with parallel agent assignment table
- Risk assessment
- Status: "Plan ready — proceed with `/orchestrate:review`"

## Done Criteria

- Requirements clarified
- Workspace created
- Plan written
- Jira confirmed (if Jira mode)

→ Next: `/orchestrate:review`
