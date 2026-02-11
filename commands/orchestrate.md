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

## State Management

Every orchestrate workflow creates and maintains **two files** inside the worktree `plans/` directory:

| File | Purpose |
|------|---------|
| `plans/{identifier}.md` | Human-readable plan (requirements, phases, agent assignments) |
| `plans/{identifier}.state.json` | Machine-readable state for agents and phase transitions |

### State JSON Schema

```jsonc
{
  // Identifiers
  "identifier": "GIFCA-123" | "add-dashboard",     // plan file slug
  "jiraKey": "GIFCA-123" | null,                     // null if standalone
  "branchName": "GIFCA-123-voucher-feature",

  // Paths (absolute)
  "worktreePath": "/Users/.../worktrees/GIFCA-123-voucher-feature",
  "mainRepoPath": "/Users/.../main-repo",
  "planFile": "/Users/.../worktrees/.../plans/GIFCA-123.md",

  // Profile
  "profile": "gifca-backend",                       // loaded profile name
  "workspace": "worktree" | "branch",               // workspace type

  // Pipeline
  "currentPhase": "start" | "review" | "impl" | "done" | "completed",
  "gates": {
    "planConfirmed": false,        // GATE 1: after start
    "expertApproved": false,       // GATE 2: after review
    "prConfirmed": false           // GATE 3: after done
  },

  // Expert Review Results (populated in review phase)
  "expertReviews": {
    // "architect": "approved" | "changes-requested",
    // "security-reviewer": "approved",
    // ...
  },

  // Verification Results (populated in impl/done phases)
  "verification": {
    "lint": null | "pass" | "fail",
    "build": null | "pass" | "fail",
    "test": null | "pass" | "fail",
    "lastRunAt": null | "2026-02-11T10:30:00Z"
  },

  // PR (populated in done phase)
  "pullRequest": {
    "url": null | "https://github.com/...",
    "number": null | 42
  },

  // Timestamps
  "createdAt": "2026-02-11T10:00:00Z",
  "updatedAt": "2026-02-11T10:30:00Z"
}
```

### State Read/Write Rules

1. **Start phase** creates the state JSON (all fields initialized)
2. **Every phase** reads state first, updates `currentPhase` + `updatedAt`, writes back at end
3. **Never parse plan markdown for paths/keys** — always read from state JSON
4. State file is the **single source of truth** for worktree path, Jira key, and pipeline progress
5. Plan markdown is for **humans**; state JSON is for **agents**

## Mandatory Rules

1. Always load profile first
2. Always create separate workspace (never develop on main)
3. **Worktree first** — always use worktree when gtr is available. Branch fallback only when gtr is not installed
4. **Worktree context** — all phases MUST run inside the worktree directory. Every sub-command starts with a State Guard that reads worktree path from state JSON
5. Never skip a gate without user approval
6. Expert reviews always run in parallel
7. **State JSON is authoritative** — agents must read from state JSON, not grep plan markdown

## Pipeline Flow

```
[Profile Load] → automatic
     ↓
[Phase 1: Start]  → create worktree → cd into worktree → write state.json + plan.md → GATE 1
     ↓
[Phase 2: Review]  → state guard → expert review → update state.json → GATE 2
     ↓
[Phase 3: Impl]    → state guard → parallel agents → update state.json → automatic
     ↓
[Phase 4: Done]    → state guard → verify → PR → update state.json → GATE 3
```

Each phase maps to a sub-command. Gates require explicit user confirmation before proceeding.

## State Guard (all phases except Start)

Every sub-command (review/impl/done) MUST begin with:

```bash
# 1. Find state file
STATE_FILE=$(ls -t plans/*.state.json 2>/dev/null | head -1)
if [ -z "$STATE_FILE" ]; then
  echo "ERROR: No state file found. Run /orchestrate:start first."
  exit 1
fi

# 2. Read worktree path from state JSON
WORKTREE_PATH=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['worktreePath'])")

# 3. Verify current directory — auto-recover
if [ "$(pwd)" != "$WORKTREE_PATH" ]; then
  cd "$WORKTREE_PATH"
fi

# 4. Verify branch (not on main)
if [ "$(git branch --show-current)" = "main" ]; then
  echo "ERROR: On main branch. Must be in worktree."
  exit 1
fi

# 5. Read other state fields as needed
JIRA_KEY=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('jiraKey') or '')")
PROFILE=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['profile'])")
```

If state file is missing or worktree path doesn't exist → STOP and ask user.

## Resuming Mid-Workflow

```
/orchestrate:start   → Phase 1 (creates state.json)
/orchestrate:review  → Phase 2 (reads state.json)
/orchestrate:impl    → Phase 3 (reads state.json)
/orchestrate:done    → Phase 4 (reads state.json)
```

All resume context (profile, worktree path, Jira key, gate status) is loaded from state JSON.
No need to parse plan markdown for metadata — state JSON is the single source of truth.

## Examples

```
/orchestrate GIFCA-123                                    # Jira mode, auto-detect profile
/orchestrate GIFCA-456 --profile gifca-frontend           # Jira mode, explicit profile
/orchestrate --no-jira --profile gifca-frontend add dashboard page  # Standalone + profile
/orchestrate add voucher expiration notification           # Auto-detect both
```
