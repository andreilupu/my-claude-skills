# Contributing

## Creating a New Skill

### 1. File Structure

Create a new folder in `skills/` with a `SKILL.md` file:

```
skills/
├── diagnose-request/
│   └── SKILL.md
├── your-new-skill/
│   └── SKILL.md
└── ...
```

### 2. Frontmatter

Every skill needs YAML frontmatter with `name` and `description`:

```yaml
---
name: skill-name
description: "Use when [triggering conditions for this skill]"
---
```

The `description` should start with "Use when" and describe the conditions that trigger the skill, not a summary of the workflow.

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
1. Symlinking the skill folder to `~/.claude/skills/`
2. Invoking `/your-skill` in Claude Code or letting it auto-trigger
3. Verifying it handles edge cases

## Submitting

1. Fork this repository
2. Create a branch: `git checkout -b add/skill-name`
3. Add your skill folder to `skills/`
4. Update `README.md` with the skill in the table
5. Submit a pull request
