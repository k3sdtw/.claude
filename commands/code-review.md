---
description: "Code review for PR or local changes. Pass PR number/URL for PR review, or omit for local diff review."
---

# Code Review

Analyze PR or local changes and perform a comprehensive code review.

## Argument Detection

- If `$ARGUMENTS` is a PR number (e.g. `123`) or PR URL (e.g. `https://github.com/owner/repo/pull/123`) → **PR Review Mode**
- If `$ARGUMENTS` is empty or not a PR reference → **Local Review Mode**

---

## PR Review Mode

### 1. Gather PR Metadata

```bash
# Extract PR number from URL if needed
gh pr view $PR_NUMBER --json title,body,baseRefName,headRefName,additions,deletions,changedFiles
```

### 2. List Changed Files

```bash
gh pr view $PR_NUMBER --json files --jq '.files[].path'
```

### 3. Analyze Diff Per File

```bash
gh pr diff $PR_NUMBER
```

For each changed file:
- Parse per-file hunks from the diff output
- Review changed lines only (not entire file)
- Read original file when surrounding context is needed

### 4. Apply Review Checklist

Run through the checklist below against changed code:

**Security (CRITICAL):**
- Hardcoded credentials, API keys, tokens
- SQL injection / NoSQL injection
- XSS vulnerabilities
- Missing input validation at system boundaries
- Insecure dependencies
- Path traversal risks
- Sensitive data leaked in logs or error messages

**Architecture (HIGH):**
- Hexagonal architecture layer violation (e.g. domain depending on infra)
- Dependency direction violation
- Anemic domain model (business logic living in use case/service)
- God class / God use case
- Circular dependencies between modules

**Code Quality (HIGH):**
- Functions > 50 lines
- Files > 800 lines
- Nesting depth > 4 levels
- Missing error handling
- console.log / debugger statements left in production code
- Duplicated logic that should be extracted

**Naming & Conventions (MEDIUM):**
- Abstract/vague names (Info, Data, Item, Manager, Handler, etc.)
- Inconsistent naming patterns
- Convention violations per project CLAUDE.md

**Testing (MEDIUM):**
- New business logic without tests
- Tests covering implementation details instead of behavior
- Hardcoded test IDs
- Test interdependence

**Best Practices (LOW):**
- Unnecessary mutation (prefer immutable)
- Over-engineering / premature abstraction
- Dead code or unused imports
- Missing type annotations on public APIs

### 5. Generate Review Report

```markdown
## Code Review: PR #$PR_NUMBER

### Summary
- **Title**: {title}
- **Scope**: {changedFiles} files (+{additions} -{deletions})
- **Verdict**: ✅ Approved / ⚠️ Changes Requested / 🚫 Blocked

### Findings

#### 🚫 CRITICAL
| # | File | Line | Issue | Suggestion |
|---|------|------|-------|------------|
| 1 | `path/to/file.ts` | L42 | Description | Fix proposal |

#### ⚠️ HIGH
| # | File | Line | Issue | Suggestion |
|---|------|------|-------|------------|

#### 💡 MEDIUM
| # | File | Line | Issue | Suggestion |
|---|------|------|-------|------------|

#### 📝 LOW / Nit
| # | File | Line | Issue | Suggestion |
|---|------|------|-------|------------|

### Positive Highlights
- {Note anything well-done if applicable}

### Verdict
{If CRITICAL/HIGH issues exist → request changes. Otherwise → approve.}
```

### 6. Submit Review to PR (Optional)

If the user requests it, post the review via `gh` CLI:

```bash
# Comment-only review
gh pr review $PR_NUMBER --comment --body "review content"

# Approve
gh pr review $PR_NUMBER --approve --body "LGTM"

# Request changes
gh pr review $PR_NUMBER --request-changes --body "review content"
```

---

## Local Review Mode

### 1. Collect Changed Files

```bash
git diff --name-only HEAD
git diff --cached --name-only
```

### 2. Analyze Diff

```bash
git diff HEAD
git diff --cached
```

### 3. Apply Review Checklist

Same checklist as PR Review Mode above.

### 4. Generate Review Report

```markdown
## Code Review: Local Changes

### Summary
- **Scope**: {N} files changed
- **Verdict**: ✅ Clean / ⚠️ Issues Found / 🚫 Blocked

### Findings
{Same table format as above}

### Verdict
{If CRITICAL/HIGH found → fix before committing}
```

---

## Verdict Criteria

| Result | Condition |
|--------|-----------|
| 🚫 **Blocked** | 1+ CRITICAL issues |
| ⚠️ **Changes Requested** | 1+ HIGH issues |
| ✅ **Approved** | Only MEDIUM/LOW or no issues |

## Rules

- Review only changed code (existing issues in untouched code are separate concerns)
- Do not flag behavior guaranteed by the framework
- Subjective style opinions go under LOW / Nit
- Never approve code with security vulnerabilities

## Examples

```
/code-review
```
→ Review local uncommitted changes

```
/code-review 42
```
→ Review PR #42

```
/code-review https://github.com/owner/repo/pull/42
```
→ Review PR by URL
