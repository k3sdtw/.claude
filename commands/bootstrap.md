# Project Bootstrap: Full .claude Directory Scaffolding

You are a senior prompt engineer and software architect. Perform a comprehensive analysis of this codebase and build the entire `.claude/` directory so that Claude Code can operate at peak performance within this project.

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

## Phase 1: Deep Codebase Analysis

Run **parallel Explore subagents** for each analysis. In a monorepo, certain analyses must be performed **per-package** while others are repo-wide.

### Repo-wide analyses (run once)

**Analysis 1: Root metadata & tooling**
- Root manifest (scripts, workspaces config)
- Monorepo orchestrator config (Turbo tasks, Nx targets, Lerna config)
- Shared linter/formatter configs at root level
- Root-level CI/CD pipelines (`.github/workflows/`, etc.)
- Docker Compose, K8s manifests, infra-as-code

**Analysis 2: Git history & workflow**
- `git log --oneline -50` — commit message convention
- `git branch -a` — branch naming patterns
- PR templates, CODEOWNERS
- `.gitignore` patterns

**Analysis 3: Environment & secrets**
- `.env.example`, `.env.*` patterns at root and per-package
- Docker configs
- Secret management hints

**Analysis 4: Shared code & cross-cutting concerns**
- Shared packages/libraries that multiple apps import
- Shared types/interfaces/schemas
- Shared configs (ESLint presets, TS configs, test utils)
- Shared CI/CD steps or reusable workflows

### Per-package analyses (run for EACH package in registry)

**Analysis 5: Package tech stack & architecture** (per package)
For each package, detect:
- Framework (Next.js, Fastify, Django, etc.)
- Architecture pattern (layered, modular, MVC, etc.)
- Directory structure (2-3 depth)
- Entry points

**Analysis 6: Package code style** (per package)
- Package-specific linter overrides (many monorepos have per-package eslint configs)
- Naming patterns specific to this package
- Import alias patterns (may differ: `@/` in one app, `~/` in another)
- Export patterns

**Analysis 7: Package testing patterns** (per package)
- Test framework (may differ per package)
- Test file locations
- Mocking patterns
- Coverage config

**Analysis 8: Package API / interface patterns** (per package, if applicable)
- Routes, endpoints, schemas
- Auth patterns
- Error handling

**Analysis 9: Package data models** (per package, if applicable)
- ORM schemas, migrations
- Entity relationships

**Analysis 10: Documentation & comments** (repo-wide)
- README structure at root and per-package
- ADRs, CONTRIBUTING, CHANGELOG

---

## Phase 2: Synthesize & Plan

Consolidate all results into two distinct categories:

### 2.1 Repo-wide conventions (goes in root CLAUDE.md + root rules/)
- Conventions that apply everywhere (commit messages, branch naming, shared lint rules)
- Cross-package workflow (how to add a new package, how to handle shared types)
- Root-level commands (turbo/nx pipelines)

### 2.2 Per-package conventions (goes in each package's CLAUDE.md)
- Package-specific tech stack, architecture, commands
- Package-specific conventions that differ from root
- Package-specific gotchas

### 2.3 Decide what goes where

```
CLAUDE.md LOADING MECHANICS (critical for monorepo design):

1. STARTUP: Claude walks UPWARD from CWD → root, loads all CLAUDE.md files found
2. LAZY LOAD: Subdirectory CLAUDE.md files load ONLY when Claude accesses files there
3. SIBLING ISOLATION: Working in apps/web/ will NOT load packages/api/CLAUDE.md
4. .claude/ IS ROOT-ONLY: settings.json, skills, agents, commands live at repo root

Therefore:
- Root CLAUDE.md   → universal conventions, repo-wide commands, package registry
- {pkg}/CLAUDE.md  → package-specific stack, commands, patterns, gotchas
- Root .claude/     → all skills, agents, commands, settings (shared across packages)
- Skills            → must be package-aware (reference specific package paths)
- Agents            → must accept package context in their workflow
- Commands          → must detect or accept which package they're operating on
```

---

## Phase 3: Generate Files

### 3.1 Root CLAUDE.md

```markdown
# [Project Name]

## Overview
[1-2 lines. What this monorepo contains + orchestrator tool]

## Monorepo Structure
[Topology type]. Managed by [Turbo/Nx/Lerna/pnpm workspaces].

| Package | Path | Type | Stack | Description |
|---------|------|------|-------|-------------|
| @repo/web | apps/web | app | Next.js 14 | Main web application |
| @repo/api | apps/api | service | Fastify | REST API server |
| @repo/shared | packages/shared | library | TypeScript | Shared types & utils |
| ... | ... | ... | ... | ... |

## Dependency Graph
@repo/web → @repo/ui, @repo/shared
@repo/api → @repo/db, @repo/shared

## Root Commands
- `[pkg-mgr] dev` — Start all apps in dev mode
- `[pkg-mgr] build` — Build all packages (topological order)
- `[pkg-mgr] test` — Run all tests across packages
- `[pkg-mgr] lint` — Lint entire monorepo

## Per-Package Commands
| Package | Dev | Test | Build |
|---------|-----|------|-------|
| @repo/web | `[cmd]` | `[cmd]` | `[cmd]` |
| @repo/api | `[cmd]` | `[cmd]` | `[cmd]` |
| ... | ... | ... | ... |

## Cross-Package Workflow
- When modifying shared types in `packages/shared/`, check all dependents: [list]
- After changing `packages/db/` schema, run migrations then rebuild dependents
- Shared ESLint config lives at `packages/config-eslint/` — changes affect all packages

## Repo-Wide Conventions
[Only conventions that genuinely apply everywhere]

## Hard Rules
- Never modify files across multiple packages in a single uncommitted change
  without verifying cross-package type compatibility
- Run `[typecheck command]` after cross-package changes
- [Actual sensitive file paths to deny]
```

**Critical rules for root CLAUDE.md in monorepos:**
- Include the Package Registry table — Claude needs this map to navigate
- Include the dependency graph — Claude must know impact scope of changes
- Cross-package commands table — Claude needs to know how to run things per-package
- Keep package-specific details OUT — those go in per-package CLAUDE.md files
- Under 500 lines

### 3.2 Per-Package CLAUDE.md files

For **each package** in the registry, generate `{package-path}/CLAUDE.md`:

```markdown
# [Package Name]

## Overview
[What this package does. Its role in the monorepo]

## Tech Stack
[Package-specific stack — may differ from other packages]

## Commands (run from this directory)
- `[cmd]` — dev
- `[cmd]` — test
- `[cmd]` — build
- `[cmd]` — lint

## Directory Structure
[This package's internal structure, 2-3 depth]

## Architecture
[Package-specific architecture pattern and layers]

## Key Patterns
[Code patterns specific to THIS package, with actual code examples]

## Internal Dependencies
- Imports from `@repo/shared`: [what it uses]
- Imports from `@repo/ui`: [what it uses]

## Gotchas
[Package-specific traps and caveats]
```

**Per-package CLAUDE.md rules:**
- Under 200 lines each — these lazy-load, so they must be focused
- Only include info that DIFFERS from or EXTENDS the root CLAUDE.md
- Never repeat root-level conventions (Claude already has those from upward loading)
- Always state what shared packages this package depends on and what it imports

### 3.3 .claude/settings.json

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./**/env)",
      "Read(./**/env.*)",
      "Read(./**/secrets/**)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "[ \"$(git branch --show-current)\" != \"[actual-default-branch]\" ] || { echo '{\"block\": true, \"message\": \"Cannot edit on [default-branch] branch\"}' >&2; exit 2; }",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### 3.4 .claude/rules/

Generate **only rules that apply**:

**rules/code-style.md** — ONLY repo-wide style rules
- Shared lint/format config rules in natural language
- If packages override the shared config, note: "See per-package CLAUDE.md for overrides"

**rules/architecture.md** — Repo-wide architecture rules
- Cross-package dependency direction rules
- How to add a new package
- Shared code guidelines (when to extract vs keep local)

**rules/testing.md** — Repo-wide test conventions
- If test framework is consistent: document once here
- If frameworks differ per package: document only shared principles, note variations

**rules/git-workflow.md** — From actual git history

**rules/monorepo-workflow.md** — MONOREPO-SPECIFIC (new, required for monorepos)
```markdown
# Monorepo Workflow Rules

## Cross-Package Changes
When a change spans multiple packages:
1. Start with the lowest-level dependency (e.g., @repo/shared)
2. Build upward through the dependency chain
3. Run `[actual typecheck command]` to verify compatibility
4. Run affected tests: `[actual command]`

## Adding a New Package
[Actual steps detected from existing package structure]

## Shared Code Guidelines
- Types used by 2+ packages → move to `[actual shared types path]`
- Utilities used by 2+ packages → move to `[actual shared utils path]`
- Never import from sibling app packages (apps must not import from other apps)
- Libraries can only depend on other libraries, never on apps

## Impact Analysis
Before modifying a shared package, check dependents:
`[actual command, e.g., turbo ls --filter=...depends-on=@repo/shared]`
```

**rules/security.md** — Sensitive file patterns across all packages

### 3.5 .claude/skills/

All skills live at root `.claude/skills/` but MUST be **package-aware**. Each skill's content should reference specific package paths. When patterns differ per package, include per-package sections.

Generate only skills that match detected tech stack. Each SKILL.md:
- Under 300 lines
- Rich trigger keywords in description
- Actual code examples from this project
- Per-package sections where patterns differ
- Reference files with real paths

**Required monorepo-specific skill: skills/cross-package-change/SKILL.md**
```markdown
---
name: cross-package-change
description: >
  Use when a change impacts multiple packages. Cross-package refactoring,
  shared type changes, dependency updates affecting multiple consumers.
  Keywords: cross-package, shared, breaking change, dependency, monorepo
---

# Cross-Package Change Procedure

## Dependency Graph
[Actual graph from Phase 0]

## Step-by-Step
1. Identify all affected packages
2. Make changes bottom-up: shared → libraries → apps
3. After each layer, verify types and tests
4. Search for all usages before changing public APIs

## Common Scenarios
### Adding a field to a shared type
[Step-by-step with actual paths]

### Upgrading a shared dependency
[Step-by-step with actual commands]
```

Other skills (api-design, component-patterns, testing-patterns, etc.) follow standard structure but include per-package context where patterns differ.

### 3.6 .claude/agents/

All agents MUST be **package-context-aware**. System prompts must instruct agents to first determine which package they're operating in, then apply the correct patterns.

**agents/code-reviewer.md** (REQUIRED)
```yaml
---
name: code-reviewer
description: >
  Code review and change analysis. Monorepo-aware — applies correct
  conventions per package. Checks cross-package compatibility.
tools: Read, Grep, Glob
model: sonnet
---
```
System prompt must include:
- Package registry table for context detection
- Per-package review criteria
- Cross-package review rules (dependency direction, breaking changes, consumer updates)
- Output grouped by package then severity

**agents/test-writer.md** (REQUIRED)
System prompt must include per-package test details:
- Which test framework each package uses
- Test file location per package
- Test command per package
- Mocking patterns per package

**agents/refactor-planner.md** (REQUIRED)
System prompt must include cross-package impact analysis.

**agents/security-auditor.md** (if auth/security code detected)

### 3.7 .claude/commands/

Commands must handle monorepo context — either auto-detecting the relevant package from file paths or accepting it via $ARGUMENTS.

**commands/review.md** (REQUIRED)
```markdown
Review code changes in the current branch.

1. Run `git diff [default-branch]...HEAD --name-only` to get changed files
2. Group changed files by package using the package registry
3. For each affected package, use the code-reviewer agent
4. If changes span multiple packages, additionally check:
   - Cross-package type compatibility
   - Dependency direction compliance
   - Shared package breaking changes

If $ARGUMENTS is provided, focus on those files/packages only.
```

**commands/test-for.md** (REQUIRED)
```markdown
Write tests for $ARGUMENTS.

1. Determine which package $ARGUMENTS belongs to by checking its file path
2. Read that package's CLAUDE.md for testing conventions
3. Use the test-writer agent with package-specific context
4. Run the CORRECT test command for that package:
   [per-package test command table]
```

**commands/add-feature.md** (REQUIRED)
```markdown
Add a new feature: $ARGUMENTS

1. Determine which package(s) this feature belongs to
2. If it spans multiple packages, plan bottom-up:
   shared types → libraries → apps
3. For each package, follow that package's architecture pattern
4. After implementation:
   - Run typecheck for cross-package validation
   - Test all affected packages
   - code-reviewer agent for final check
```

**commands/check-impact.md** (REQUIRED for monorepos)
```markdown
Analyze the impact of changes to $ARGUMENTS.

1. Identify which package $ARGUMENTS belongs to
2. Find all dependent packages (direct + transitive)
3. For each dependent, identify which imports/symbols they use
4. Report: affected packages, risk level, required follow-up actions
```

**commands/refactor.md**
**commands/explain.md**

---

## Phase 4: Validation & Report

After generating all files:

1. **Structure check**: Print the full generated file tree including per-package CLAUDE.md files

2. **Consistency validation**:
   - Root CLAUDE.md package registry matches actual workspace packages
   - Dependency graph is accurate
   - Per-package CLAUDE.md commands are correct (test by running them)
   - Per-package CLAUDE.md files don't duplicate root-level info
   - Skill reference files actually exist
   - Agent package-specific checklists match actual patterns
   - All commands reference correct per-package test/build/lint commands

3. **Summary report**:
```
## Bootstrap Complete

### Monorepo Topology
[type]: [N] packages detected

### Package Registry
[table]

### Dependency Graph
[graph]

### Generated Files
- Root CLAUDE.md: [line count]
- Per-package CLAUDE.md: [count] files, [list paths]
- Rules: [count] files
- Skills: [count] files
- Agents: [count] files
- Commands: [count] files

### Cross-Package Insights
- Highest fan-in: [name] (depended on by [N] packages)
- Unique tech stacks: [any packages that differ]
- Circular dependencies: [none / list]

### Recommended Follow-up
- [ ] Review root CLAUDE.md package registry
- [ ] Review each per-package CLAUDE.md for missed gotchas
- [ ] Verify monorepo-workflow.md cross-package rules
- [ ] Test /check-impact on a shared package change
- [ ] Use # key to add repeated instructions during sessions
```

---

## Absolute Rules

1. **No guessing**: If not discovered in analysis, don't generate it.
2. **No generic advice**: No "write clean code" or "follow SOLID" in any file.
3. **Use actual code examples**: All examples from actual project files.
4. **Token efficiency**: No duplication. Per-package CLAUDE.md must not repeat root info.
5. **Monorepo hierarchy is sacred**: Root = repo-wide only. Per-package = package-specific only.
6. **Package-awareness everywhere**: Every skill, agent, and command must determine and adapt to the correct package context.
7. **ultrathink**: Think deeply and thoroughly.
