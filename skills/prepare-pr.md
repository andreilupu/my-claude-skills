---
name: prepare-pr
description: "Prepare and create pull requests using the project's PR template"
---

# Prepare Pull Request

Prepare and create a pull request using the project's PR template from `.github/`.

## Step 1: Analyze Branch & Changes

Run these commands to understand the current state:

```bash
git branch --show-current
git log main..HEAD --oneline 2>/dev/null || git log master..HEAD --oneline
git diff main..HEAD --stat 2>/dev/null || git diff master..HEAD --stat
```

## Step 2: Run Linters (If Available)

Check what types of files changed:

```bash
git diff main..HEAD --name-only 2>/dev/null || git diff master..HEAD --name-only
```

### Detect Project Linters

Look for linter configurations in the project:
- `package.json` → check for `lint` scripts
- `composer.json` → check for `phpcs` or similar
- `.eslintrc*`, `biome.json`, `.prettierrc` → JS/TS linting
- `phpcs.xml*` → PHP linting

Run appropriate linters based on what's configured. If linters fail:
1. **STOP** - Do not create the PR
2. Show errors and offer to auto-fix
3. Re-run linters after fixes
4. Only proceed when all linters pass

## Step 3: Find the PR Template

Look for a PR template in the project:

```bash
# Check common locations
ls -la .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null || \
ls -la .github/pull_request_template.md 2>/dev/null || \
ls -la .github/PULL_REQUEST_TEMPLATE/ 2>/dev/null || \
ls -la docs/PULL_REQUEST_TEMPLATE.md 2>/dev/null || \
ls -la PULL_REQUEST_TEMPLATE.md 2>/dev/null
```

**Read the template** and use it as the structure for the PR body. Fill in the sections based on your analysis of the changes.

If no template is found, use a simple format:
```markdown
## Summary
{Brief description of changes}

## Changes
- {List of changes}

## Testing
{How to test these changes}
```

## Step 4: Extract Issue References

### From Branch Name
Look for issue patterns in the branch name:
- `GH-123`, `issue-123` → `Closes #123`
- `fix/123-description` → `Fixes #123`
- `feature/something` → No automatic issue (prompt user if needed)

### From Commit Messages
Scan commit messages for patterns like:
- `#123`, `GH-123`
- `Closes #123`, `Fixes #123`

## Step 5: Check if Branch is Pushed

```bash
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "not pushed"
```

If not pushed, remind the user to push before creating the PR.

## Step 6: Generate PR Content

Based on your analysis:

1. **Read the PR template** from `.github/` and fill in each section
2. **Analyze the diff** to understand what changed
3. **Review commit messages** for context
4. **Generate testing steps** based on changed files/components
5. **Flag any risks** if changes touch critical areas (auth, payments, database, etc.)

### PR Title Guidelines
- Clear and revealing (same as commit messages)
- Should describe the main change
- Keep under 72 characters

## Step 7: Output the PR Template

**IMPORTANT**: Always output the PR body inside a markdown code block so the user can copy it with formatting preserved.

Format the output like this:

~~~
**PR Title suggestion:** {Clear, revealing title}

```markdown
{Filled-in PR template content}
```
~~~

The triple backticks with `markdown` language identifier ensures the user can copy the raw markdown.

### After Outputting Template

Remind user to:
1. Push the branch if not already pushed: `git push -u origin {branch}`
2. Go to GitHub and create a new PR
3. Copy the markdown from the code block above
4. Paste into the PR description
5. Complete any checklist items
6. Add screenshots if UI changes were made
7. Request reviewers

## Important Notes

- **Never** generate a PR template without running linters first (if available)
- **Always** remind user to push branch before creating PR
- **Always** include issue references when available
- **Always** read and use the project's PR template if one exists
- Output the template inside a markdown code block for easy copying
