---
name: efficient-navigation
description: Optimize codebase exploration with parallel reads, search-first patterns, and Explore agent for open-ended questions
trigger: auto
domain: workflow
confidence: 0.80
evolved_from:
  - parallel-file-reads
  - read-before-edit
  - grep-before-edit-search
  - explore-agent-for-codebase
---

# Efficient Navigation

Auto-triggered skill that optimizes how the codebase is explored and files are accessed.

## Rules

### 1. Parallel File Reads

When multiple files need to be read, issue all Read calls in a single message for parallel execution.

**Trigger:** When exploring a feature across layers (use case, DTO, controller, test).

```
# GOOD: Single message with parallel reads
Read(use-case.ts) + Read(response.dto.ts) + Read(controller.ts) + Read(e2e-spec.ts)

# BAD: Sequential reads one at a time
Read(use-case.ts) → Read(response.dto.ts) → Read(controller.ts)
```

**Exception:** When one file's content determines which other files to read.

### 2. Read Before Edit

Always read the target file before editing it. The Edit tool requires a prior Read.

**Trigger:** Before any code modification.

**No exceptions** — this is a hard requirement of the Edit tool.

### 3. Grep/Glob Before Edit

When searching for patterns across the codebase, use Grep or Glob first to identify target files, then Read, then Edit.

**Trigger:** When looking for similar patterns across files, or finding all files affected by a refactoring.

```
# GOOD: Search → Read → Edit
Grep('flatPrefix') → Read(matched files) → Edit(each file)

# BAD: Guess files and start editing
Edit(file1) → Edit(file2) → miss file3
```

**Exception:** When you already know exactly which files to modify.

### 4. Explore Agent for Open-Ended Questions

For open-ended codebase exploration, use Task tool with `subagent_type=Explore` instead of manual Grep/Read iterations.

**Trigger:**
- "Where is X used?"
- "Which files use this pattern?"
- Auditing codebase for consistency

**Exception:**
- Searching for a specific known file/class name → use Glob
- Searching within 2-3 known files → use Read

## Priority Order

1. **Known file** → Read directly
2. **Known pattern, unknown files** → Grep/Glob → Read → Edit
3. **Open-ended exploration** → Explore agent
4. **Multiple related files** → Parallel Read in single message
