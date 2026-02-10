---
description: Full orchestrated workflow. Requirements → branch → plan → expert review → implement → verify → PR. Jira optional. Profile-driven.
---

# Orchestrate Workflow

E2E pipeline: requirements → branch → plan → expert review → implement → verify → PR.

## Profile Loading (MUST be first)

**Detection order:**
1. `--profile {name}` → load `profiles/{name}.md`
2. Auto-detect from project root:
   - `nest-cli.json` / `src/main.ts` → NestJS profile
   - `next.config.*` / `app/layout.tsx` → Next.js profile
   - `package.json` with `"react"` → React profile
   - `pyproject.toml` / `manage.py` → Python profile
   - `go.mod` → Go profile
   - `Cargo.toml` → Rust profile
3. Not found → ask user (list `profiles/` or create new)

**Profile must define:** `[meta]` `[experts]` `[phases]` `[verification]` `[conventions]`

Set `PROFILE` and carry through all phases.

## Mode Detection

| Input | Mode |
|-------|------|
| Jira key (`[A-Z]+-[0-9]+`) | Jira |
| `--no-jira` flag | Standalone |
| Feature description only | Ask user |

Set `MODE = jira | standalone`.

## Mandatory Rules

1. Always load profile first
2. Always create separate workspace (never develop on main)
3. **Worktree first** — always use worktree when gtr is available. Branch fallback only when gtr is not installed
4. **Worktree context** — all phases MUST run inside the worktree directory. Every sub-command starts with a Worktree Guard that verifies `pwd` matches the worktree path stored in the plan file
5. Never skip a gate without user approval
6. Expert reviews always run in parallel

## Pipeline Flow

```
[Profile Load] → automatic
     ↓
[Phase 1: Start]  → create worktree → cd into worktree → GATE 1: Plan Confirmation
     ↓
[Phase 2: Review]  → worktree guard → GATE 2: Expert Approval
     ↓
[Phase 3: Impl]    → worktree guard → automatic
     ↓
[Phase 4: Done]    → worktree guard → GATE 3: PR Confirmation
```

Each phase maps to a sub-command. Gates require explicit user confirmation before proceeding.

## Worktree Guard (all phases except Start)

Every sub-command (review/impl/done) MUST begin with:

```bash
# 1. Read worktree path from plan file
WORKTREE_PATH=$(grep "^Worktree:" plans/*.md | head -1 | awk '{print $2}')

# 2. Verify current directory
if [ "$(pwd)" != "$WORKTREE_PATH" ]; then
  cd "$WORKTREE_PATH"  # Auto-recover: cd into worktree
fi

# 3. Verify branch (not on main)
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "main" ]; then
  echo "ERROR: On main branch. Must be in worktree."
  exit 1
fi
```

If worktree path is missing from plan or directory doesn't exist, STOP and ask user.

## Resuming Mid-Workflow

```
/orchestrate:start   → Phase 1
/orchestrate:review  → Phase 2
/orchestrate:impl    → Phase 3
/orchestrate:done    → Phase 4
```

Profile is re-loaded from plan file's "Profile used" field on resume.
Worktree path is read from plan file's "Worktree" field to auto-`cd` on resume.

## Examples

```
/orchestrate GIFCA-123                                    # Jira mode, auto-detect profile
/orchestrate GIFCA-456 --profile gifca-frontend           # Jira mode, explicit profile
/orchestrate --no-jira --profile gifca-frontend add dashboard page  # Standalone + profile
/orchestrate add voucher expiration notification           # Auto-detect both
```
