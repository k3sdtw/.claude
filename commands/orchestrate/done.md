---
description: Finalize development and create PR. Verification loop → code review → commit → PR.
---

# Finalize and Create PR

Prerequisite: implementation complete via `/orchestrate:impl`.

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
BRANCH=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['branchName'])")
PLAN_FILE=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['planFile'])")

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
{ "currentPhase": "done", "updatedAt": "{now}" }
```

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

Read `JIRA_KEY` and `BRANCH` from state JSON (already loaded in State Guard).

```bash
git add {specific files only}
git commit  # Follow PROFILE.conventions.commit_format. Add JIRA key if Jira mode.
```

## GATE 3: PR Confirmation

**STOP.** Present verification results (lint/build/test/reviews) and commit summary. Ask user to confirm before push/PR.

On confirmation → update state JSON:
```jsonc
{
  "gates": { "prConfirmed": true },
  "updatedAt": "{now}"
}
```

## 4. Create PR

Read `BRANCH` and `JIRA_KEY` from state JSON.

```bash
git push -u origin {BRANCH}
gh pr create --title "{type}({scope}): {description} {JIRA_KEY?}" --body "..."
```

PR body follows `rules/common/pull-request.md` template. Standalone mode (`JIRA_KEY` is null): omit JIRA key.

After PR creation, update state JSON:
```jsonc
{
  "pullRequest": {
    "url": "{PR URL from gh output}",
    "number": {PR number}
  },
  "currentPhase": "completed",
  "updatedAt": "{now}"
}
```

## 5. Update Jira (Jira mode only)

Read `JIRA_KEY` from state JSON. Skip if null.

```typescript
mcp__jira__jira_transition_issue({ issue_key: "{JIRA_KEY}", transition: "In Review" })
```

## 6. Output & Cleanup Reminder

Report: verification results, PR URL, branch info, and cleanup command:
- Worktree: `git gtr rm {BRANCH} --delete-branch --yes`
- Branch: `git checkout main && git pull && git branch -d {BRANCH}`
