# Contributing

## Creating a New Skill

### 1. File Structure

Create a new `.md` file in the `skills/` directory:

```
skills/
├── diagnose-request.md
├── your-new-skill.md
└── ...
```

### 2. Frontmatter

Every skill needs YAML frontmatter:

```yaml
---
name: skill-name              # Used for /skill-name invocation
description: Brief desc       # Shown in autocomplete
argument-hint: <url> [opts]   # Shows usage hint
disable-model-invocation: false  # Optional, default false
---
```

### 3. Body Structure

Write clear, step-by-step instructions:

```markdown
# Skill Title

Brief overview of what this skill does.

## Step 1: Gather Information

Describe what to check or collect first...

## Step 2: Perform Action

Describe the main action...

## Step 3: Present Results

Describe how to format and present output...
```

### Best Practices

1. **Be explicit** - Claude follows instructions literally
2. **Use code blocks** - Show exact commands to run
3. **Include error handling** - What to do when things fail
4. **Add thresholds** - Define what's "good" vs "bad" for diagnostics
5. **Reference tables** - Quick lookups are helpful

### Testing

Test your skill by:
1. Copying to `~/.claude/commands/`
2. Running `/your-skill` in Claude Code
3. Verifying it handles edge cases

## Submitting

1. Fork this repository
2. Create a branch: `git checkout -b add/skill-name`
3. Add your skill to `skills/`
4. Update `README.md` with the skill in the table
5. Submit a pull request
