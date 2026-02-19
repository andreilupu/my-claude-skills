# My Claude Skills

A collection of custom skills (slash commands) for [Claude Code](https://claude.ai/claude-code).

## Installation

### Option 1: Symlink to global commands (recommended)

```bash
# Link individual skills to your global commands
ln -s /path/to/my-claude-skills/skills/diagnose-request.md ~/.claude/commands/diagnose-request.md
```

### Option 2: Copy to project

Copy any skill file to your project's `.claude/commands/` directory.

### Option 3: Use as a reference

Clone this repo and manually copy skills as needed.

## Available Skills

| Skill | Description |
|-------|-------------|
| [diagnose-request](skills/diagnose-request.md) | Diagnose slow HTTP requests by breaking down timing (DNS, TLS, TTFB, transfer) and identifying bottlenecks |

## Usage

Once installed, invoke skills with `/skill-name`:

```
/diagnose-request https://example.com/api/health
```

## Skill Format

Skills are markdown files with YAML frontmatter:

```markdown
---
name: skill-name
description: Brief description shown in autocomplete
argument-hint: <required> [optional]
---

# Skill Title

Instructions for Claude to follow...
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on creating new skills.

## License

MIT
