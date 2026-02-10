---
description: Finalize development and create PR. Verification loop → code review → commit → PR.
---

# Finalize and Create PR

Prerequisite: implementation complete via `/orchestrate:impl`.

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

## 1. Verification Loop (max 3 iterations)

```
LOOP:
  1. Lint:  {PROFILE.verification.lint}
  2. Build: {PROFILE.verification.build}  → fail? fix, RESTART
  3. Test:  {PROFILE.verification.test}   → fail? fix, RESTART
  4. All green → EXIT
```

Each iteration starts from step 1. After 3 failures, stop and report to user.

## 2. Code Review (parallel agents)

Launch `security-reviewer` and `code-reviewer` in parallel on changed files.

CRITICAL/HIGH issues found → fix and re-run verification loop (step 1).

## 3. Commit

```bash
git add {specific files only}
git commit  # Follow PROFILE.conventions.commit_format. Add JIRA key if Jira mode.
```

## GATE: PR Confirmation

**STOP.** Present verification results (lint/build/test/reviews) and commit summary. Ask user to confirm before push/PR.

## 4. Create PR

```bash
git push -u origin {branch}
gh pr create --title "{type}({scope}): {description} {JIRA-KEY?}" --body "..."
```

PR body follows `rules/common/pull-request.md` template. Standalone mode: omit JIRA key.

## 5. Update Jira (Jira mode only)

```typescript
mcp__jira__jira_transition_issue({ issue_key: "{JIRA-KEY}", transition: "In Review" })
```

## 6. Output & Cleanup Reminder

Report: verification results, PR URL, branch info, and cleanup command:
- Worktree: `git gtr rm {branch} --delete-branch --yes`
- Branch: `git checkout main && git pull && git branch -d {branch}`
