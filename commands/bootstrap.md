# Project Bootstrap: Full .claude Directory Scaffolding

You are a senior prompt engineer and software architect. Perform a comprehensive analysis of this codebase and build the entire `.claude/` directory so that Claude Code can operate at peak performance within this project.

**Mode**: If $ARGUMENTS contains "full", generate everything. Otherwise default to "minimal" (core files only, skills/agents/commands generated on-demand later).

ultrathink

---

## Phase 0: Monorepo Detection (MUST run first)

Before any deep analysis, determine the project topology.

### Step 0.1: Check for monorepo signals
Search for these files at the project root:
- `pnpm-workspace.yaml`
- `package.json` → `workspaces` field
- `lerna.json`
- `turbo.json`
- `nx.json` / `nx.json` → `projects`
- `rush.json`
- Yarn Berry `.yarnrc.yml` → `nodeLinker`
- Python: multiple `pyproject.toml` files in subdirectories
- Go: `go.work` file
- Rust: `Cargo.toml` → `[workspace]` section
- Java/Kotlin: multi-module `settings.gradle` or parent `pom.xml` with `<modules>`
- .NET: `*.sln` file referencing multiple `*.csproj`

### Step 0.2: If monorepo detected, enumerate all packages
Build a **Package Registry** — a complete map of every package/app/service:

```
PACKAGE REGISTRY
================
[package-name]
  path:       apps/web
  type:       app | package | service | library | config
  language:   TypeScript
  framework:  Next.js 14
  has_tests:  true
  test_cmd:   pnpm test
  build_cmd:  pnpm build
  depends_on: [@repo/shared, @repo/db, @repo/ui]
  depended_by: []

[package-name-2]
  path:       packages/shared
  type:       library
  ...
```

For each entry, read its own `package.json` (or equivalent manifest) to extract:
- Name, type (app vs library vs config)
- Own dependencies (internal cross-references + external)
- Own scripts (dev, build, test, lint)
- Own tech stack (may differ from root — e.g., one package uses React, another uses Vue)

### Step 0.3: Map cross-package dependencies
Build a dependency graph:
```
@repo/web → @repo/ui → @repo/shared
@repo/web → @repo/api-client → @repo/shared
@repo/api → @repo/db → @repo/shared
```
Identify:
- **Shared foundations**: packages that many others depend on (high fan-in)
- **Leaf apps**: packages nothing depends on (zero fan-out)
- **Circular dependencies**: flag as warnings

### Step 0.4: Determine topology type
Classify as one of:
- **Polyglot monorepo**: multiple languages (e.g., TS frontend + Python backend)
- **Fullstack JS/TS monorepo**: apps + packages, single language
- **Library monorepo**: multiple publishable packages
- **Microservices monorepo**: independent deployable services
- **Hybrid**: combination of the above

Store the Package Registry and topology — all subsequent phases reference it.

> **If NOT a monorepo**: Skip all per-package sections in all phases. Generate a single flat structure (one CLAUDE.md at root, no per-package files).

---

## Phase 1: Codebase Analysis

Analysis is split into priority tiers. In minimal mode, run only Tier 1. In full mode, run all tiers.

**CRITICAL**: For every pattern detected, extract 1-2 ACTUAL code snippets from this codebase. These will be used verbatim in generated files. Do NOT write generic examples — use only code that exists in this project.

### Tier 1: REQUIRED (always run, both modes)

Run these as **parallel Explore subagents**. In a monorepo, repo-wide analyses run once; per-package analyses run for EACH package.

**Analysis 1: Root metadata & tooling** (repo-wide)
- Root manifest (scripts, workspaces config)
- Monorepo orchestrator config (Turbo tasks, Nx targets, Lerna config)
- Shared linter/formatter configs at root level
- Package manager + version (npm/pnpm/yarn/bun + lockfile)
- Detect the default branch: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || echo "main"`

**Analysis 2: Tech stack & architecture** (per-package in monorepo, else repo-wide)
For each package/project, detect:
- Framework (Next.js, Fastify, Django, etc.) + version
- Architecture pattern (layered, modular, MVC, etc.)
- Directory structure (2-3 depth, from actual `find` or `ls`)
- Entry points
- Package-specific linter overrides
- Import alias patterns (`@/`, `~/`, `#` etc.)

**Analysis 3: Commands & scripts** (per-package + root)
- Dev, build, test, lint commands (VERIFY each by checking they exist in scripts)
- Migration commands, seed commands
- Deployment scripts
- For monorepos: per-package commands AND root pipeline commands

**Analysis 4: Risk & security patterns** (repo-wide + per-package)
- Sensitive file paths: `.env`, `.env.*`, `**/secrets/**`, credentials, API keys
- Dangerous scripts in package.json: `drop`, `reset`, `destroy`, `nuke`, `clean:all`
- Production URLs/endpoints in config files
- Database connection strings
- Files that should NEVER be edited by the agent
- Default branch name (for branch protection hook)

### Tier 2: RECOMMENDED (run in full mode, skip in minimal)

**Analysis 5: Git history & workflow** (repo-wide)
- `git log --oneline -30` — commit message convention (detect: conventional commits, gitmoji, etc.)
- `git branch -a | head -20` — branch naming patterns
- PR templates, CODEOWNERS
- `.gitignore` patterns

**Analysis 6: Code style & naming** (per-package)
- Naming patterns: files, functions, variables, components
- Export patterns (named vs default, barrel files)
- Comment style and density
- Actual code examples for each detected pattern

**Analysis 7: Testing patterns** (per-package)
- Test framework (Vitest, Jest, Playwright, pytest, etc.)
- Test file locations and naming conventions
- Mocking/stubbing patterns
- Fixture patterns
- Coverage config

### Tier 3: EXTENDED (run in full mode only, AND only if relevant stack detected)

**Analysis 8: API / interface patterns** (if API code exists)
- Routes, endpoints, schema definitions
- Auth/authz patterns
- Error handling patterns, error response shape
- Validation patterns

**Analysis 9: Data models** (if ORM/DB code exists)
- ORM schemas, migration structure
- Entity relationships
- Query patterns

**Analysis 10: Documentation & ADRs** (repo-wide)
- README structure
- ADRs, CONTRIBUTING, CHANGELOG
- Inline doc conventions (JSDoc, docstrings, etc.)

---

## Phase 2: Synthesize & Plan

Consolidate all results into two distinct categories.

### 2.1 What goes where

```
CLAUDE.md LOADING MECHANICS:

1. STARTUP: Claude walks UPWARD from CWD → root, loads all CLAUDE.md files found
2. LAZY LOAD: Subdirectory CLAUDE.md files load ONLY when Claude accesses files there
3. SIBLING ISOLATION: Working in apps/web/ will NOT load packages/api/CLAUDE.md
4. .claude/ IS ROOT-ONLY: settings.json, skills, agents, commands live at repo root

Therefore:
- Root CLAUDE.md   → HARD LIMIT 200 lines. Table of contents, not encyclopedia.
                     Package registry, dependency graph, root commands, pointers to rules/.
- {pkg}/CLAUDE.md  → HARD LIMIT 150 lines per file. Package-specific only.
                     Never repeat what root CLAUDE.md says.
- .claude/rules/   → Detailed conventions, separated by concern.
- .claude/skills/  → Package-aware workflows (full mode only).
- .claude/agents/  → Package-context-aware subagents (full mode only).
- .claude/commands/ → Package-detecting commands (full mode only).
```

### 2.2 Danger map

From Analysis 4, build the complete danger map:
```
DENY LIST (for settings.json):
  Read:  [list of sensitive file paths]
  Write: [list of files that should never be edited]

HOOK BLOCKS (for PreToolUse):
  Bash:  [dangerous commands detected from scripts]
  Edit:  [branch protection, protected files]

STOP HOOKS:
  Session end: auto-update claude-progress.txt
```

---

## Phase 3: Generate Files

### --- CORE FILES (both minimal and full mode) ---

### 3.1 Root CLAUDE.md

**HARD LIMIT: 200 lines. This is a table of contents, not a manual.**

```markdown
# [Project Name]

## Overview
[1-2 lines. What this project/monorepo does]

## Tech Stack
[Key technologies, versions — one line each]

## [IF MONOREPO] Package Registry
| Package | Path | Type | Stack |
|---------|------|------|-------|
| ... | ... | ... | ... |

## [IF MONOREPO] Dependency Graph
[package] → [dependency], [dependency]

## Commands
[Only the most essential commands, verified working]
- `[cmd]` — dev
- `[cmd]` — test
- `[cmd]` — build
- `[cmd]` — lint

## [IF MONOREPO] Per-Package Commands
| Package | Dev | Test | Build |
|---------|-----|------|-------|
| ... | ... | ... | ... |

## Key Rules
- [3-5 most critical project-specific rules only]
- [No generic advice like "write clean code"]

## Hard Stops
- [Things the agent must NEVER do in this specific project]

## Detailed Conventions → .claude/rules/
- Code style: .claude/rules/code-style.md
- Architecture: .claude/rules/architecture.md
- Testing: .claude/rules/testing.md
- Git workflow: .claude/rules/git-workflow.md
[IF MONOREPO]:
- Monorepo workflow: .claude/rules/monorepo-workflow.md

## [IF MONOREPO] Cross-Package Workflow
- When modifying shared types in `[path]`, check dependents: [list]
- After schema changes in `[path]`, run migrations then rebuild
- Shared config at `[path]` — changes affect all packages
```

### 3.2 Per-Package CLAUDE.md (monorepo only)

For **each package** in the registry, generate `{package-path}/CLAUDE.md`.

**HARD LIMIT: 150 lines per file. Package-specific info only.**

```markdown
# [Package Name]

## Role
[What this package does in the monorepo. 1-2 lines]

## Stack
[Only if different from or extending root — don't repeat]

## Commands (run from this directory)
- `[cmd]` — dev
- `[cmd]` — test
- `[cmd]` — build

## Structure
[2-3 depth directory structure from actual filesystem]

## Architecture
[Package-specific patterns. Actual code example from this package]

## Key Patterns
[With ACTUAL code snippets from this package's files]

## Internal Dependencies
- Uses `@repo/shared`: [what specifically]
- Uses `@repo/ui`: [what specifically]

## Gotchas
[Package-specific traps discovered in analysis]
```

### 3.3 .claude/settings.json

```jsonc
{
  "permissions": {
    "deny": [
      // From Analysis 4 danger map — sensitive files
    ]
  },
  "hooks": {
    "PreToolUse": [
      // Hook 1: Branch protection
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "[ \"$(git branch --show-current)\" != \"[DETECTED-DEFAULT-BRANCH]\" ] || { echo 'Cannot edit on [DETECTED-DEFAULT-BRANCH] branch' >&2; exit 2; }",
            "timeout": 5
          }
        ]
      },
      // Hook 2: Dangerous command prevention
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "[GENERATED SAFETY SCRIPT — see 3.3.1]",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      // Hook 3: Auto-save progress on session end
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "[GENERATED PROGRESS SCRIPT — see 3.3.2]",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

#### 3.3.1 Generate .claude/hooks/safety-check.sh

Based on Analysis 4 findings, generate a project-specific safety script:

```bash
#!/bin/bash
# Auto-generated from codebase analysis. Add rules as agent makes mistakes.
INPUT="$1"

# Dangerous deletions
if echo "$INPUT" | grep -qE 'rm\s+-rf\s+(/|~|\$HOME|\./)'; then
  echo "BLOCKED: Dangerous delete" >&2; exit 2
fi

# Force push
if echo "$INPUT" | grep -qE 'git\s+push.*--force'; then
  echo "BLOCKED: Force push" >&2; exit 2
fi

# [PROJECT-SPECIFIC: Generated from Analysis 4]
# Example: if production DB URLs were found
# if echo "$INPUT" | grep -qiE '[DETECTED-PROD-PATTERN]'; then
#   echo "BLOCKED: Production access" >&2; exit 2
# fi

# [PROJECT-SPECIFIC: Dangerous scripts found in package.json]
# if echo "$INPUT" | grep -qE '[DETECTED-DANGEROUS-SCRIPTS]'; then
#   echo "BLOCKED: Dangerous script" >&2; exit 2
# fi

exit 0
```

#### 3.3.2 Generate .claude/hooks/session-end.sh

```bash
#!/bin/bash
# Auto-update progress file on session end
PROGRESS="claude-progress.txt"
DATE=$(date +"%Y-%m-%d %H:%M")

[ -f "$PROGRESS" ] || exit 0

RECENT=$(git log --oneline -5 2>/dev/null)
if [ -n "$RECENT" ]; then
  echo "" >> "$PROGRESS"
  echo "### Session $DATE" >> "$PROGRESS"
  echo "$RECENT" >> "$PROGRESS"
fi
```

Make hooks executable:
```bash
chmod +x .claude/hooks/*.sh
```

### 3.4 .claude/rules/

Generate **only rules files for which actual patterns were detected**. Each file must contain ACTUAL code examples from this project, not generic advice.

**rules/code-style.md** — Only if actual style patterns were detected
```markdown
# Code Style

## Naming
[ACTUAL patterns from Analysis 6, with real examples]

## Imports
[ACTUAL import patterns, alias conventions, ordering]

## Exports
[ACTUAL export patterns: named vs default, barrel files]

[IF MONOREPO]: Per-package overrides exist for: [list packages with different conventions]
```

**rules/architecture.md** — From Analysis 2
```markdown
# Architecture

## Layer Structure
[ACTUAL layer diagram from this project]

## Module Dependencies
[ACTUAL allowed/forbidden dependency directions]
[In monorepos: cross-package dependency rules]

## Key Patterns
[ACTUAL patterns with code examples from this project]
```

**rules/testing.md** — Only if Analysis 7 was run and patterns detected
```markdown
# Testing

## Framework
[ACTUAL test framework + version]

## File Locations
[ACTUAL test file location pattern from this project]

## Patterns
[ACTUAL mocking/fixture patterns with code examples]

## Running Tests
[ACTUAL commands, verified working]
```

**rules/git-workflow.md** — Only if Analysis 5 was run
```markdown
# Git Workflow

## Commit Convention
[DETECTED from git log: conventional commits, gitmoji, or other]

## Branch Naming
[DETECTED from git branch output]

## PR Process
[DETECTED from PR templates or CONTRIBUTING.md]
```

**rules/monorepo-workflow.md** — ONLY for monorepos
```markdown
# Monorepo Workflow

## Cross-Package Changes
When a change spans multiple packages:
1. Start with lowest-level dependency
2. Build upward through dependency chain
3. Run `[ACTUAL typecheck command]`
4. Run affected tests: `[ACTUAL command]`

## Adding a New Package
[Steps detected from existing package structure and orchestrator config]

## Shared Code Rules
- Types used by 2+ packages → `[ACTUAL shared types path]`
- Utils used by 2+ packages → `[ACTUAL shared utils path]`
- Apps must NOT import from other apps
- Libraries can only depend on other libraries

## Impact Check
Before modifying a shared package: `[ACTUAL command to find dependents]`
```

### 3.5 claude-progress.txt (REQUIRED in both modes)

Generate at project root:

```markdown
# Project Progress

> Read this file at the start of every session.
> Update before ending a session or when completing significant work.

## Completed

## In Progress

## Known Issues

## Next Session
1.

## Architecture Decisions
- [DATE]: Bootstrap — .claude/ directory initialized

## Session Log
```

### 3.6 .claude/LEARNING.md (REQUIRED in both modes)

```markdown
# Harness Evolution Log

> When the agent makes a mistake, record it here and add a rule to prevent recurrence.
> Use `/harness-update` to automate this process.
> This file is the growth journal of this project's harness.

| Date | Failure | Rule Added | Location |
|------|---------|------------|----------|
| [TODAY] | Initial bootstrap | Project-specific rules generated | .claude/rules/ |
```

### --- EXTENDED FILES (full mode only) ---

> The following files are generated ONLY when $ARGUMENTS contains "full".
> In minimal mode, skip to Phase 4.

### 3.7 .claude/skills/

All skills live at root `.claude/skills/` but MUST be **package-aware**. Each SKILL.md:
- Under 300 lines
- Includes Verification section (MANDATORY)
- Uses ACTUAL code examples from this project
- In monorepos: includes per-package sections where patterns differ

Generate only skills that match detected tech stack.

**MANDATORY skill template structure:**

```markdown
---
name: [name]
description: >
  [What it does. Rich trigger keywords for auto-activation.]
---

# [Skill Name]

## Procedure
[Step-by-step. Reference actual project paths and commands.]

## Patterns
[ACTUAL code examples from this project. Not generic.]

[IF MONOREPO]
## Per-Package Notes
- `[package-A]`: [specific differences]
- `[package-B]`: [specific differences]
[END IF]

## Verification (REQUIRED — never skip)
After completing work:
1. Re-read the ORIGINAL requirement (not your own code)
2. Run the relevant test/lint command: `[ACTUAL command]`
3. In monorepos: run typecheck if cross-package changes were made
4. Confirm each requirement is met by test output, not by re-reading your own code
```

**Skills to generate (only if matching tech detected):**

| Condition | Skill |
|-----------|-------|
| Always | `implement-feature/SKILL.md` |
| Always | `fix-bug/SKILL.md` |
| Monorepo detected | `cross-package-change/SKILL.md` |
| API/backend code | `api-endpoint/SKILL.md` |
| React/Vue/Svelte | `component/SKILL.md` |
| ORM/DB code | `db-migration/SKILL.md` |
| CI/CD config | `pipeline/SKILL.md` |

**MONOREPO-SPECIFIC SKILL: cross-package-change/SKILL.md** (REQUIRED for monorepos)
```markdown
---
name: cross-package-change
description: >
  Use when a change impacts multiple packages. Cross-package refactoring,
  shared type changes, dependency updates affecting multiple consumers.
  Triggers: cross-package, shared, breaking change, dependency, monorepo.
---

# Cross-Package Change

## Dependency Graph
[ACTUAL graph from Phase 0]

## Procedure
1. Identify all affected packages using: `[ACTUAL command to find dependents]`
2. Make changes bottom-up: shared → libraries → apps
3. After each layer, run: `[ACTUAL typecheck command]`
4. Search for all usages before changing any public API: `grep -r "[symbol]" [paths]`

## Common Scenarios
### Changing a shared type
[Step-by-step with ACTUAL paths from this project]

### Upgrading a shared dependency
[Step-by-step with ACTUAL commands from this project]

## Verification (REQUIRED — never skip)
1. Run full typecheck: `[ACTUAL command]`
2. Run tests for ALL affected packages: `[ACTUAL command]`
3. Verify no unused imports or broken references remain
```

### 3.8 .claude/agents/

All agents MUST include a **Context Loading** section and be **package-context-aware**.

**MANDATORY agent template structure:**

```yaml
---
name: [name]
description: >
  [Role. When to use. Package-aware behavior.]
tools: [allowed tools]
---
```

```markdown
# [Agent Name]

## Context Loading (read these before starting work)
- Root: CLAUDE.md (for project overview and package registry)
- Package: {relevant-package}/CLAUDE.md (for package-specific rules)
- Rules: .claude/rules/[relevant].md
- Progress: claude-progress.txt (for current project state)

## Role
[What this agent does]

## Procedure
[Step-by-step including package detection]

## Output Format
[Structured output format]
```

**Agents to generate:**

| Agent | When |
|-------|------|
| `code-reviewer.md` | Always |
| `test-writer.md` | Always |
| `refactor-planner.md` | Full mode |
| `security-auditor.md` | If auth/security code detected |

**code-reviewer.md** — Include:
- Package registry for context detection
- Per-package review criteria
- Cross-package review rules (monorepo)
- Output grouped by package then severity

**test-writer.md** — Include:
- Per-package test frameworks, file locations, commands
- Mocking patterns per package
- ACTUAL test examples from this project

### 3.9 .claude/commands/

Commands must handle monorepo context — either auto-detecting package from file paths or accepting via $ARGUMENTS.

**REQUIRED commands (both modes):**

**commands/harness-update.md** (REQUIRED — the most important command)
```markdown
Update the harness based on a failure or new learning.

If $ARGUMENTS is empty, ask: "What went wrong, or what pattern should be added?"

1. Classify the update:
   - Agent made a coding mistake → add to CLAUDE.md or rules/ forbidden patterns
   - Repeated workflow is tedious → create a new skill in .claude/skills/
   - Safety/security gap → add to settings.json deny or hooks
   - Architecture violation occurred → update rules/architecture.md
   - Wrong command was used → update CLAUDE.md commands section

2. Make the change to the correct file

3. Append to .claude/LEARNING.md:
   | [TODAY'S DATE] | [brief failure description] | [rule added] | [file path] |

4. Confirm: "Harness updated. [description of what was added and where]."
```

**REQUIRED commands (full mode only):**

**commands/review.md**
```markdown
Review code changes in the current branch.

1. Run `git diff [DETECTED-DEFAULT-BRANCH]...HEAD --name-only`
2. [IF MONOREPO]: Group changed files by package using the package registry
3. For each affected area, load relevant CLAUDE.md and rules
4. Review for: correctness, security, performance, style compliance
5. [IF MONOREPO + multi-package changes]: Additionally check:
   - Cross-package type compatibility
   - Dependency direction compliance
   - Shared package breaking changes
6. Output: issues grouped by severity (🔴 high / 🟡 medium / 🟢 low)

If $ARGUMENTS provided, focus on those files/packages only.
```

**commands/test-for.md**
```markdown
Write tests for $ARGUMENTS.

1. Determine which package $ARGUMENTS belongs to
2. Read that package's CLAUDE.md + .claude/rules/testing.md
3. Detect test framework and patterns for that package
4. Write tests following the project's ACTUAL test patterns
5. Run: `[CORRECT test command for the detected package]`
6. Verify all new tests pass

Per-package test commands:
[TABLE from Phase 1 Analysis 3]
```

**commands/add-feature.md**
```markdown
Add a new feature: $ARGUMENTS

1. Determine which package(s) this feature belongs to
2. [IF multi-package]: Plan bottom-up (shared → libraries → apps)
3. Load relevant CLAUDE.md files and rules
4. Use implement-feature skill for the workflow
5. After implementation:
   - Run typecheck: `[ACTUAL command]`
   - Run tests: `[ACTUAL command]`
   - Self-review changes before reporting

If unclear which package, ask before proceeding.
```

**commands/check-impact.md** (monorepo only)
```markdown
Analyze impact of changes to $ARGUMENTS.

1. Identify which package $ARGUMENTS belongs to
2. Trace dependency graph to find all dependents (direct + transitive)
3. For each dependent, find specific imports/usages
4. Report:
   - Affected packages (with dependency distance)
   - Risk level per package (high if public API changed, low if internal)
   - Required follow-up actions
   - Suggested test commands for each affected package
```

---

## Phase 4: Validation

After generating all files, perform validation in order.

### 4.1 Structure check
Print the full generated file tree:
```
.claude/
├── CLAUDE.md
├── settings.json
├── LEARNING.md
├── hooks/
│   ├── safety-check.sh
│   └── session-end.sh
├── rules/
│   ├── ...
├── [IF FULL] skills/
│   ├── ...
├── [IF FULL] agents/
│   ├── ...
└── [IF FULL] commands/
    ├── harness-update.md
    ├── ...
[IF MONOREPO]:
apps/web/CLAUDE.md
apps/api/CLAUDE.md
packages/shared/CLAUDE.md
...
claude-progress.txt
```

### 4.2 Consistency validation
- Root CLAUDE.md ≤ 200 lines
- Per-package CLAUDE.md ≤ 150 lines each
- Root CLAUDE.md package registry matches actual workspace packages
- Per-package CLAUDE.md files don't duplicate root-level info
- All referenced file paths in rules/skills actually exist in project

### 4.3 Execution validation (CRITICAL — do not skip)
Run each detected command to verify it works:
```bash
# Verify test command exists
[DETECTED-TEST-CMD] --help 2>/dev/null || echo "WARNING: test command not found"

# Verify lint command exists
[DETECTED-LINT-CMD] --help 2>/dev/null || echo "WARNING: lint command not found"

# Verify build command exists
[DETECTED-BUILD-CMD] --help 2>/dev/null || echo "WARNING: build command not found"

# Verify hooks are executable
test -x .claude/hooks/safety-check.sh || echo "WARNING: safety hook not executable"
test -x .claude/hooks/session-end.sh || echo "WARNING: session hook not executable"
```
If any command fails, fix the CLAUDE.md entry before proceeding.

### 4.4 Summary report

```
## Bootstrap Complete

### Mode: [minimal | full]
### Topology: [single-project | monorepo:[type]]
[IF MONOREPO]: [N] packages detected

### Generated Files
[Full file list with line counts]

### Danger Map
- Denied paths: [count]
- Hook blocks: [count]
- Branch protection: [default-branch]

[IF MONOREPO]:
### Cross-Package Insights
- Highest fan-in: [name] ([N] dependents)
- Unique stacks: [any packages with different frameworks]
- Circular dependencies: [none | list]

### ⚡ Immediate Actions (do now, 5 minutes)
- [ ] Skim CLAUDE.md — is the package registry accurate?
- [ ] Check settings.json deny list — any missing sensitive files?
- [ ] Verify hook permissions: `ls -la .claude/hooks/`

### 📈 First Week
- [ ] When agent makes a mistake → run `/harness-update`
- [ ] After 3 days, review .claude/LEARNING.md for patterns
- [ ] If a workflow repeats 3+ times → promote to a skill
[IF MINIMAL]:
- [ ] When ready for skills/agents/commands → run `/bootstrap full`

### 🚫 Don't Do
- Don't try to perfect every rule upfront
- Don't add generic advice ("write clean code") to any file
- The harness grows by USING it, not by pre-planning it
```

---

## Absolute Rules

1. **No guessing**: If not discovered in analysis, don't generate it.
2. **No generic advice**: No "write clean code" or "follow SOLID" in any file. Every rule must be project-specific.
3. **Use actual code examples**: All examples from actual project files. Zero generic snippets.
4. **Line limits are hard**: Root CLAUDE.md ≤ 200 lines. Per-package ≤ 150 lines. Skills ≤ 300 lines.
5. **CLAUDE.md is a table of contents**: It points to rules/, not contains them.
6. **Monorepo hierarchy is sacred**: Root = repo-wide only. Per-package = package-specific only. Never duplicate.
7. **Package-awareness everywhere**: Every skill, agent, and command must detect and adapt to the correct package context.
8. **Every skill has Verification**: No skill is complete without a Verification section that uses actual test commands.
9. **Every agent has Context Loading**: No agent starts work without reading the relevant CLAUDE.md and rules.
10. **Harness-update is the most important command**: Without it, the harness is static. With it, the harness compounds.
11. **Execution validation is mandatory**: Never report a command without verifying it actually works.
12. **ultrathink**: Think deeply and thoroughly.
