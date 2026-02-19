---
name: commit
description: "Prepare and create commits with proper analysis and linting"
argument-hint: "[optional commit message]"
---

# Commit Preparation

Prepare and create a well-structured commit.

## Step 1: Analyze Current State

Run these commands to understand the current state:

```bash
git status
git diff --staged
git branch --show-current
```

## Step 2: Review Staged Changes

Ensure the staged changes are:
- **Focused**: Related to a single logical change
- **Complete**: All necessary files are staged
- **Clean**: No debug code, console.logs, or commented-out code
- **Appropriate**: Match the branch's purpose

If changes appear unrelated or too large, suggest splitting into multiple commits.

## Step 3: Run Linters (If Available)

Check what types of files are staged:

```bash
git diff --staged --name-only
```

### Detect Project Linters

Look for linter configurations in the project:
- `package.json` → check for `lint` scripts
- `composer.json` → check for `phpcs` or similar
- `.eslintrc*`, `biome.json`, `.prettierrc` → JS/TS linting
- `phpcs.xml*` → PHP linting

Run appropriate linters based on what's configured. If linters fail:
1. **STOP** - Do not proceed with the commit
2. **Show the errors** to the user clearly
3. **Offer to auto-fix** if available
4. **After fixes**, re-run linters to verify
5. **Only proceed** when all linters pass

### Skip Linting (Emergency Only)

If the user explicitly requests to skip linting (e.g., `--no-lint`), warn them that this is not recommended and proceed only with their confirmation.

## Step 4: Compose Commit Message

### Format

```
{Clear, revealing subject line} (max 72 chars)

{Optional body explaining what and why, wrapped at 72 chars}

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Guidelines

1. **Subject line** (most important):
   - Be **clear and revealing** - the reader should understand the change without reading the diff
   - Use imperative mood ("Fix bug" not "Fixed bug")
   - Keep under 72 characters
   - Capitalize first letter
   - No period at the end
   - Focus on **what** the change accomplishes, not how

2. **Body** (optional but recommended for complex changes):
   - Explain *what* changed and *why*
   - Wrap at 72 characters
   - Separate from subject with blank line

### Good vs Bad Subject Lines

| Bad (vague) | Good (revealing) |
|-------------|------------------|
| Fix bug | Fix datepicker dropdown spacing regression |
| Update styles | Remove gap between datepicker trigger and popup |
| Changes to reports | Add min-height to report container |
| Refactor code | Extract date range logic into useDateRange composable |
| WIP | Add product performance metrics to dashboard |

### Examples

**Bug fix:**
```
Fix datepicker dropdown spacing regression

Remove the 6px margin-top gap between the datepicker trigger and popup,
add min-height to container to ensure datepicker fits.

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Feature addition:**
```
Add product performance report to dashboard

Introduces a new report showing product-level metrics including
revenue, quantity sold, and conversion rates.

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Step 5: Create the Commit

If the user provided a message via $ARGUMENTS, use it as the basis for the commit message.

Otherwise, compose an appropriate message based on:
1. The staged changes (to describe what changed)
2. The branch name (for context)
3. Recent commit history (to match style)

Create the commit:

```bash
git commit -m "$(cat <<'EOF'
{Clear, revealing subject}

{Body if needed}

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

## Step 6: Post-Commit

After committing:
1. Show the commit with `git show --stat HEAD`
2. Remind user to push when ready: `git push -u origin {branch}`

## Important Notes

- Never amend commits without explicit user request
- Never force push
- Never commit sensitive data (.env files, API keys, credentials)
- If pre-commit hooks fail, help fix the issues and create a NEW commit
