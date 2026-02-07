---
name: change-verification
description: Post-change verification pipeline - batch parallel edits, build check, and E2E tests after refactoring
trigger: auto
domain: workflow
confidence: 0.83
evolved_from:
  - build-verify-after-changes
  - e2e-test-after-refactor
  - batch-edits-same-pattern
---

# Change Verification

Auto-triggered skill that enforces a consistent verification pipeline after code changes.

## Rules

### 1. Batch Edits for Same Pattern

When applying the same structural change across multiple files, issue all Edit calls in a single message for parallel execution.

**Trigger:** Renaming fields, updating output interfaces, applying consistent DTO changes, updating test assertions.

```
# GOOD: All edits in one message
Edit(use-case-1.ts) + Edit(use-case-2.ts) + Edit(use-case-3.ts)

# BAD: One edit per turn
Edit(use-case-1.ts) → Edit(use-case-2.ts) → Edit(use-case-3.ts)
```

**Exception:** When edits depend on each other's results.

### 2. Build Verification After Changes

Run `pnpm build` and `pnpm biome check .` after completing a set of code changes.

**Trigger:** After editing multiple source files, before running E2E tests, after any refactoring session.

```bash
pnpm build && pnpm biome check .
```

**Exception:** Single file typo fixes may skip to direct test run.

### 3. E2E Tests After Refactoring

Always run E2E tests after refactoring, not just build verification. TypeScript compilation does not catch runtime/serialization issues.

**Trigger:**
- After changing Use Case Output interfaces
- After modifying Response DTOs (especially nested structures with `@Type()`)
- After any API response shape change

```bash
cd services/api && npx jest --config ./test/jest-e2e.config.js --testPathPatterns='pattern'
```

**Why:** `@Type()` decorator issues, `plainToInstance()` serialization problems, and missing `@Expose()` decorators only fail at runtime.

**Exception:** Pure domain entity changes without API impact.

## Verification Pipeline

```
1. Apply changes (batch parallel edits when possible)
         │
         ▼
2. Build check: pnpm build
         │
         ▼
3. Lint check: pnpm biome check .
         │
         ▼
4. E2E tests: npx jest --testPathPatterns='affected-domain'
         │
         ▼
5. Ready for commit
```
