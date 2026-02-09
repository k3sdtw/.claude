# Quick Drift Check: Validate .claude Documentation Currency

Perform a fast, lightweight check for documentation drift. This is meant to run quickly — do NOT rewrite anything unless explicitly asked.

## Checks (read-only, fast)

### 1. Command Validity
Extract all commands listed in CLAUDE.md and per-package CLAUDE.md files.
For each command, verify the script exists in the relevant package.json (or equivalent).
Flag any commands that no longer exist.

### 2. File Reference Validity
Scan all skills/ for "Reference Files" sections.
Verify each referenced file path still exists.
Flag missing files.

### 3. Package Registry (monorepo)
Compare the package registry table in root CLAUDE.md against actual workspace packages.
Flag any packages that were added or removed.

### 4. Dependency Graph (monorepo)
Check if any package.json internal dependency changes would alter the dependency graph.
Flag if graph in CLAUDE.md or cross-package-change skill is stale.

### 5. Linter Config Drift
Compare timestamps or content hashes of linter configs against what rules/code-style.md describes.
Flag if configs were modified more recently than the rules file.

## Output

```
## Drift Check Results

✅ No drift: [list]
⚠️  Possible drift:
  - CLAUDE.md: command `pnpm test:e2e` no longer exists in package.json
  - skills/api-design: reference file `src/routes/users.ts` was renamed to `src/routes/user.routes.ts`
  - Package registry: new package `@repo/email` detected but not in CLAUDE.md

Run /sync-docs to fix these issues.
```

## Rules
- Read-only. Do not modify any files.
- Finish in under 30 seconds.
- Only flag concrete, verifiable discrepancies.
