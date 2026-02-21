# My Claude Skills

A collection of custom skills for [Claude Code](https://claude.ai/claude-code).

## Installation

### Option 1: Symlink to global skills (recommended)

```bash
# Link individual skills to your global skills directory
ln -s /path/to/my-claude-skills/skills/diagnose-request ~/.claude/skills/diagnose-request
ln -s /path/to/my-claude-skills/skills/commit ~/.claude/skills/commit
ln -s /path/to/my-claude-skills/skills/prepare-pr ~/.claude/skills/prepare-pr
ln -s /path/to/my-claude-skills/skills/wordpress-plugins-repo-worktrees ~/.claude/skills/wordpress-plugins-repo-worktrees
```

### Option 2: Copy to project

Copy any skill folder to your project's `.claude/skills/` directory.

### Option 3: Use as a reference

Clone this repo and manually copy skills as needed.

## Available Skills

| Skill | Description |
|-------|-------------|
| [diagnose-request](skills/diagnose-request/SKILL.md) | Diagnose slow HTTP requests by breaking down timing (DNS, TLS, TTFB, transfer) and identifying bottlenecks |
| [commit](skills/commit/SKILL.md) | Prepare and create commits with proper analysis, linting, and clear commit messages |
| [prepare-pr](skills/prepare-pr/SKILL.md) | Prepare and create pull requests using the project's PR template from `.github/` |
| [wordpress-plugins-repo-worktrees](skills/wordpress-plugins-repo-worktrees/SKILL.md) | Manage git worktrees in a WordPress plugins monorepo (when `wp-content/plugins` is the git repo) with wp-config.php integration |

## Usage

Skills are automatically loaded by Claude Code when relevant, or can be invoked explicitly:

- Via slash command: `/diagnose-request https://example.com/api/health`
- Via the Skill tool in agent contexts

## Skill Format

Skills use a folder-based structure with a `SKILL.md` file and YAML frontmatter:

```
skills/
├── diagnose-request/
│   └── SKILL.md
├── commit/
│   └── SKILL.md
├── prepare-pr/
│   └── SKILL.md
└── wordpress-plugins-repo-worktrees/
    └── SKILL.md
```

```markdown
---
name: skill-name
description: "Use when [triggering conditions]"
---

# Skill Title

Instructions for Claude to follow...
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on creating new skills.

## License

MIT
