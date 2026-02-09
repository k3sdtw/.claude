# Project Bootstrap: Full .claude Directory Scaffolding

You are a senior prompt engineer and software architect. Perform a comprehensive analysis of this codebase and build the entire `.claude/` directory so that Claude Code can operate at peak performance within this project.

---

## Phase 1: Deep Codebase Analysis (MUST complete before any file generation)

Execute all 10 analyses below using **parallel subagents (Explore)**. Each analysis is independent and can run concurrently.

### Analysis 1: Project Metadata
- Scan all package manifests: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `build.gradle`, `pom.xml`, `Gemfile`, `composer.json`, `*.csproj`, etc.
- Project name, description, version, license
- Full dependency list with versions (dependencies, devDependencies, peerDependencies)
- Scripts/commands section (build, test, lint, dev, start, deploy, etc.)
- Monorepo detection: check for `workspaces`, `lerna.json`, `turbo.json`, `nx.json`, `pnpm-workspace.yaml`

### Analysis 2: Tech Stack Detection
- Languages: file extension distribution (`.ts`, `.tsx`, `.py`, `.go`, `.rs`, `.java`, etc.)
- Frameworks: Next.js (`next.config`), Nuxt (`nuxt.config`), SvelteKit, Remix, Django, FastAPI, Spring, Rails, Laravel, etc.
- Database: detect ORM/ODM (Prisma, TypeORM, SQLAlchemy, GORM, Diesel, ActiveRecord) + schema files
- State management: Redux, Zustand, Jotai, Recoil, Pinia, Vuex, etc.
- Testing: Jest, Vitest, pytest, Go testing, RSpec, PHPUnit, etc. + config files
- CI/CD: `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `Dockerfile`, `docker-compose.yml`
- Infrastructure: Terraform, Pulumi, CDK, Kubernetes manifests, serverless configs

### Analysis 3: Directory Structure & Architecture Patterns
- Full directory tree (2-3 depth)
- Detect architecture patterns:
  - Layered (controller/service/repository)
  - Clean Architecture (domain/application/infrastructure/presentation)
  - Modular (feature-based / domain-based grouping)
  - MVC, MVVM, Hexagonal
- Entry point files (main, index, app, server)
- Shared code locations (shared, common, lib, utils, packages)

### Analysis 4: Code Style & Conventions
- Linter/formatter configs: `.eslintrc*`, `.prettierrc*`, `biome.json`, `.editorconfig`, `ruff.toml`, `.golangci.yml`, `rustfmt.toml`, `.rubocop.yml`
- Naming patterns: file names (kebab/camel/pascal/snake), variables, functions, classes, constants
- Import style: absolute path aliases (`@/`, `~/`, `#`), barrel exports usage
- Type system: TypeScript strict mode, `any` usage frequency, generics usage
- Export patterns: named vs default, re-export patterns
- Async patterns: async/await, Promise, callback, RxJS
- Error handling patterns: try-catch style, custom error classes, Result/Either pattern

### Analysis 5: Testing Patterns
- Test file location patterns: `__tests__/`, `*.test.*`, `*.spec.*`, `tests/`, `test/`
- Test structure: describe/it patterns, nesting depth
- Mocking strategy: jest.mock, vi.mock, factory patterns, fixture files
- Test utilities/helpers location
- E2E tools: Playwright, Cypress, Selenium
- Coverage configuration and thresholds

### Analysis 6: API & Endpoint Patterns
- API routing structure (file-based vs explicit registration)
- Request/response schema definition (Zod, Joi, class-validator, Pydantic, JSON Schema)
- Authentication/authorization patterns (JWT, Session, OAuth, API Key)
- Middleware chain
- Error response format
- API versioning strategy
- OpenAPI/Swagger spec presence

### Analysis 7: Data Models & Schema
- Full analysis of ORM schema/model files
- Entity relationships (1:1, 1:N, M:N)
- Migration history presence
- Seed data patterns
- Soft delete, timestamps, audit trail patterns

### Analysis 8: Git History & Workflow
- `git log --oneline -50` to analyze recent commit message patterns
- Commit message convention (Conventional Commits, free-form, Jira numbers, etc.)
- Branch naming patterns: analyze `git branch -a`
- `.gitignore` patterns
- PR template presence (`.github/PULL_REQUEST_TEMPLATE.md`)
- CODEOWNERS file

### Analysis 9: Environment & Config Management
- Environment variable patterns: `.env.example`, `.env.local`, `.env.development`, etc.
- Config management approach (dotenv, config files, environment-based splitting)
- Secret management hints: Vault, AWS SSM, GCP Secret Manager
- Docker configuration analysis

### Analysis 10: Documentation & Comment Patterns
- README.md structure and quality
- JSDoc/TSDoc/docstring usage patterns
- CONTRIBUTING.md, CHANGELOG.md presence
- Inline comment density and style
- ADR (Architecture Decision Records) presence

---

## Phase 2: Synthesize Analysis & Plan Generation

Consolidate all Phase 1 results and determine:

1. **Core conventions list**: Project-specific patterns Claude must know
2. **Required skills by tech stack**: Which domain expertise is needed
3. **Automatable tasks**: What needs deterministic quality enforcement via hooks
4. **Expert role list**: Which subagents are needed
5. **Repetitive workflows**: Which tasks should be extracted as commands

---

## Phase 3: Generate .claude Directory

Create **all** files below. Every file must reflect the actual code patterns, actual commands, and actual directory structure discovered in Phase 1. No generic examples — everything must be **specific to this project**.

### 3.1 CLAUDE.md (Project Root)

**Structure**:
```markdown
# [Actual Project Name]

## Project Overview
[1-2 lines. What the project does + core tech stack]

## Key Commands
[Only actually discovered scripts/commands. No guessing]
- `[actual package manager] [actual script]` — [purpose]

## Directory Structure
[Actual structure. Key directories only, 2-3 depth]

## Code Style Summary
[Only detected conventions. Include rules extracted from linter configs]

## Architecture Core Principles
[Patterns detected from actual code. Concrete patterns, not abstract principles]

## Gotchas
[Actual traps found in the codebase, unusual configs, caveats]

## Hard Rules (Never Do)
[Security and stability constraints]
```

**Writing principles**:
- Strictly under 500 lines
- Do NOT guess. State only discovered facts
- No platitudes like "write clean code"
- Use only actual file paths, actual commands, actual patterns
- Write in English

### 3.2 .claude/settings.json

```json
{
  "permissions": {
    "deny": [
      // .env, secrets, credentials — use actual discovered sensitive file paths
    ]
  },
  "hooks": {
    "PreToolUse": [
      // Protect main/master branch (use actual default branch name)
      // Block dangerous commands
    ],
    "PostToolUse": [
      // Auto-run linter/formatter if detected in the project
    ]
  }
}
```

### 3.3 .claude/rules/ (Auto-loaded Rules)

Generate **only the rule files that apply** based on detected patterns:

**rules/code-style.md** — Linter config + code analysis extracted style rules
- Convert actual ESLint/Prettier/Biome rules to natural language
- Naming conventions (extracted from actual code patterns)
- Import ordering (observed from actual code)
- Recurring patterns found across the codebase

**rules/architecture.md** — Actual layer structure and dependency direction
- Detected architecture pattern
- Where to place new files/modules
- Forbidden dependency directions (e.g., repository must never import controller)

**rules/testing.md** — Actual test structure and patterns
- Test file location rules
- Mocking patterns in active use (extracted from code)
- Actual test utility/helper locations
- Coverage targets (extracted from config)

**rules/git-workflow.md** — Workflow extracted from actual git history
- Actual commit message patterns (with examples)
- Actual branch naming patterns
- PR process (reflect template if found)

**rules/security.md** — Hard security rules
- Sensitive file list (actual paths)
- Auth/authz patterns (if detected)
- Input validation patterns

Each rules file: **under 200 lines**, including actual code examples extracted from the project.

### 3.4 .claude/skills/ (On-demand Domain Knowledge)

Create **only the skills that match the detected tech stack**. Each skill is a single `SKILL.md` file.

Possible skills (generate only those that apply):

| Skill | Generation Condition |
|-------|---------------------|
| `api-design` | REST/GraphQL API exists |
| `db-migration` | ORM + migration system detected |
| `testing-patterns` | Test framework detected |
| `component-patterns` | UI framework (React/Vue/Svelte) detected |
| `state-management` | State management library detected |
| `error-handling` | Custom error patterns detected |
| `auth-patterns` | Auth/authz system detected |
| `deployment` | CI/CD + Docker/K8s detected |
| `performance` | Performance-related tooling detected |

Each SKILL.md structure:
```markdown
---
name: [skill-name]
description: >
  [Concrete description of when this skill is needed. Rich trigger keywords]
---

# [Skill Title]

## Patterns in This Project

### Standard Pattern
[Pattern extracted from actual code. Code examples mandatory]

### Steps When Creating New [entity]
[Step-by-step guide]

### Anti-patterns (Do NOT)
[❌ Wrong example → ✅ Correct example]

### Reference Files
[List of actual file paths that exemplify this pattern]
```

**Skill writing principles**:
- Under 300 lines
- description must include rich keywords relevant to the domain
- MUST use actual code examples from this project
- "Reference Files" section with real file paths so Claude can verify patterns directly

### 3.5 .claude/agents/ (Subagents)

Generate **all** of the following agents:

**agents/code-reviewer.md** (REQUIRED)
```yaml
---
name: code-reviewer
description: >
  Use for code review, PR review, and change analysis.
  Checks code quality, bugs, security, performance, and convention compliance.
tools: Read, Grep, Glob
model: sonnet
---
```
- Checklist must reflect this project's actual linter rules, architecture patterns, and test requirements
- Read-only. Must NEVER modify files

**agents/test-writer.md** (REQUIRED)
```yaml
---
name: test-writer
description: >
  Writes test code. Generates unit tests and integration tests
  that match the project's testing conventions.
tools: Read, Write, Edit, Bash, Glob, Grep
model: sonnet
---
```
- Must reflect this project's actual test framework, mocking patterns, and file structure
- Include step to run tests and verify passing after writing

**agents/refactor-planner.md** (REQUIRED)
```yaml
---
name: refactor-planner
description: >
  Refactoring analysis and planning. Read-only — does NOT modify code.
  Analyzes complexity, identifies tech debt, generates step-by-step refactoring plans.
tools: Read, Grep, Glob
model: sonnet
---
```

**agents/security-auditor.md** (if auth/security code detected)
```yaml
---
name: security-auditor
description: >
  Security vulnerability analysis. Detects auth bypass, injection,
  sensitive data exposure, and missing permission checks.
tools: Read, Grep, Glob
model: sonnet
---
```

Each agent system prompt MUST include:
1. This project's tech stack stated explicitly
2. Core conventions summary (distilled from rules)
3. Concrete project-tailored checklist
4. Defined output format
5. Project files/directories to reference

### 3.6 .claude/commands/ (Slash Commands)

**commands/review.md** (REQUIRED)
```markdown
Review the current branch's changes.
Analyze the diff against [actual default branch] and
use the code-reviewer agent for inspection.
If $ARGUMENTS is provided, focus review on those files/directories only.
```

**commands/test-for.md** (REQUIRED)
```markdown
Write tests for $ARGUMENTS.
Use the test-writer agent.
First analyze the target code, then write tests following this project's testing conventions.
After writing, verify all tests pass with [actual test command].
```

**commands/add-feature.md** (REQUIRED)
```markdown
Add a new feature: $ARGUMENTS

Procedure:
1. Analyze requirements and determine impact scope
2. Create implementation plan aligned with this project's architecture pattern
3. Write code following [actual layer structure]
4. Write tests (delegate to test-writer agent)
5. Self-review via code-reviewer agent
6. Verify lint/format passes
```

**commands/refactor.md**
```markdown
Refactor $ARGUMENTS.

1. Use refactor-planner agent for analysis and planning
2. Present the plan to the user and request approval
3. After approval, execute step by step
4. Verify tests pass after each step
5. Final verification via code-reviewer agent
```

**commands/explain.md**
```markdown
Explain $ARGUMENTS in the context of this codebase.

1. Explore related files to understand the full flow
2. Describe the data flow (input → processing → output)
3. Map dependencies with other modules
4. Highlight any gotchas or traps
```

---

## Phase 4: Validation & Report

After generating all files, perform the following:

1. **File structure check**: Print the generated `.claude/` directory tree
2. **Consistency validation**:
   - Verify that commands listed in CLAUDE.md actually exist
   - Spot-check that rules match actual code patterns
   - Confirm that skill reference files actually exist
   - Verify that agent tool restrictions are appropriate
3. **Summary report**:

```
## Bootstrap Complete

### Detected Tech Stack
[list]

### Generated Files
[file tree]

### Core Conventions Summary
[5 lines max]

### Recommended Follow-up Actions
- [ ] Review CLAUDE.md and add project-specific gotchas
- [ ] Review rules/ files with your team
- [ ] Check settings.json deny list for any missed sensitive files
- [ ] During work sessions, use # key to add frequently repeated instructions to memory
```

---

## Absolute Rules

1. **No guessing**: If it wasn't discovered in analysis, don't generate it. Never fabricate scripts or describe patterns that don't exist.
2. **No generic advice**: Never include platitudes like "write clean code", "follow SOLID principles", or "use meaningful names" in any file.
3. **Use actual code examples**: All examples must be extracted from actual files in this project.
4. **Token efficiency**: Keep each file concise to avoid wasting context window. No duplication across files.
5. **English throughout**: All descriptions, comments, and instructions in English. Code and commands remain as-is.
6. **ultrathink**: Given the complexity of this task, think deeply and thoroughly.
