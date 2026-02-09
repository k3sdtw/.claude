# Sync .claude Documentation with Current Codebase

You just finished a significant piece of work. Now synchronize the `.claude/` documentation with the current state of the codebase.

## Step 1: Detect What Changed

Run `git diff --name-only HEAD~5` (or use $ARGUMENTS if a specific range is given) to identify recently changed files. Group them by package if this is a monorepo.

## Step 2: Check Each Documentation Layer

For each area of change, verify the corresponding documentation is still accurate:

### 2.1 CLAUDE.md (root)
- Are all listed commands still valid? Run each one with `--help` or `--dry-run` if possible.
- Does the directory structure section still match reality?
- Is the package registry still accurate (monorepo)?
- Are there new gotchas discovered during recent work?

### 2.2 Per-Package CLAUDE.md (monorepo only)
- For each package with changed files, read its CLAUDE.md.
- Do the listed commands still work?
- Do the "Key Patterns" still match the actual code?
- Are internal dependency descriptions still accurate?

### 2.3 rules/
- `code-style.md`: Check if linter configs changed. If `.eslintrc`, `.prettierrc`, `biome.json`, or similar were modified, update the natural-language rules.
- `architecture.md`: Check if new directories, layers, or modules were added.
- `testing.md`: Check if test configs or patterns changed.
- `git-workflow.md`: Check recent commit messages — has the convention drifted?
- `monorepo-workflow.md`: Check if dependency graph changed (new packages, new cross-package deps).

### 2.4 skills/
- For each skill, verify that "Reference Files" still exist and still exemplify the pattern.
- If a pattern has evolved (e.g., new error handling approach), update the skill.
- If a new domain area was added that has no skill, flag it.

### 2.5 agents/
- Check if agent checklists reference patterns that still exist.
- Check if per-package details in agent prompts are still accurate.

### 2.6 commands/
- Verify that commands reference correct branch names, test commands, and build commands.

## Step 3: Apply Updates

For each discrepancy found:
1. State what's out of date and why
2. Show the proposed update
3. Apply the fix

## Step 4: Report

```
## Documentation Sync Report

### Files Changed Since Last Sync
[list of changed files, grouped by package]

### Documentation Updates Made
- [file]: [what was updated and why]
- [file]: [what was updated and why]

### No Changes Needed
- [file]: still accurate

### New Documentation Suggested
- [ ] Consider adding a skill for [new pattern detected]
- [ ] Consider adding [new gotcha] to [package] CLAUDE.md

### Stale Content Removed
- [file]: removed reference to [deleted file/pattern]
```

## Rules
- Only update what's actually stale. Don't rewrite things that are still correct.
- If unsure whether something changed, check the actual code before updating.
- Keep the same concise style — don't inflate documents during sync.
- Never add generic advice. Only project-specific facts.
