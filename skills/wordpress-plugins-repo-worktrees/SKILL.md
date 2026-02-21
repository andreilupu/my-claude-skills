---
name: wordpress-plugins-repo-worktrees
description: "Use when managing git worktrees in a WordPress plugins monorepo — switching, creating, or listing worktrees that need wp-config.php integration"
---

# WordPress Plugins Repo Worktree Orchestration

## Overview

**Prerequisites:** This skill applies when `wp-content/plugins` itself IS the git repository (a monorepo containing multiple plugins), NOT when individual plugins have their own repos.

Git worktrees allow multiple branches checked out simultaneously in separate directories. **In WordPress, you must ALSO update `wp-config.php` to tell WordPress which worktree to use as the plugins folder.**

**Core principle:** Git worktrees + WordPress config = complete branch switching.

## Critical Integration Point

WordPress uses these constants to locate plugins:
- `WP_PLUGIN_DIR` - filesystem path
- `WP_PLUGIN_URL` - URL path

A custom `ACTIVE_PLUGINS_WORKTREE` constant controls which worktree WordPress uses.

**Switching worktrees means:**
1. Git worktree exists (or create it)
2. Update `ACTIVE_PLUGINS_WORKTREE` in wp-config.php

## Quick Reference

| Action | Git Command | WordPress Config |
|--------|-------------|------------------|
| List worktrees | `git worktree list` | Check `ACTIVE_PLUGINS_WORKTREE` value |
| Switch worktree | (none - already exists) | Update `ACTIVE_PLUGINS_WORKTREE` |
| Create worktree | `git worktree add ../plugins-name branch` | Update config if switching to it |
| Remove worktree | `git worktree remove ../plugins-name` | Switch to different worktree first |

## wp-config.php Structure

Location: `{wordpress-root}/wp-config.php`

```php
/**
 * Git Worktree Support
 * Available worktrees listed in comments
 */
define( 'ACTIVE_PLUGINS_WORKTREE', 'plugins-feature-name' );

// Set custom plugins directory based on worktree
define( 'WP_PLUGIN_DIR', __DIR__ . '/wp-content/' . ACTIVE_PLUGINS_WORKTREE );

// Dynamically build plugin URL
$_mi_scheme = ( ! empty( $_SERVER['HTTPS'] ) && $_SERVER['HTTPS'] !== 'off' ) ? 'https' : 'http';
$_mi_host   = $_SERVER['HTTP_HOST'] ?? 'localhost';
define( 'WP_PLUGIN_URL', $_mi_scheme . '://' . $_mi_host . '/wp-content/' . ACTIVE_PLUGINS_WORKTREE );
```

## Workflows

### List Worktrees (show status)

```bash
# 1. List git worktrees
cd wp-content/plugins && git worktree list

# 2. Check which one WordPress is using
grep "ACTIVE_PLUGINS_WORKTREE" wp-config.php
```

Report BOTH - git worktrees available AND which one WordPress is configured to use.

### Switch to Existing Worktree

1. Verify worktree exists: `git worktree list`
2. Edit wp-config.php: change `ACTIVE_PLUGINS_WORKTREE` value
3. Update the comment listing available worktrees if needed
4. Confirm: show new value

### Create New Worktree

```bash
# From existing branch
git worktree add ../plugins-feature-name existing-branch

# From new branch based on another
git worktree add -b new-branch ../plugins-new-branch base-branch
```

**Naming convention:** `plugins-{short-description}` (e.g., `plugins-auth-fix`, `plugins-ui-redesign`)

After creation:
1. Update wp-config.php comments to list new worktree
2. Ask user if they want to switch to it

### Remove Worktree

1. Check if it's the active WordPress worktree
2. If active, switch to different worktree first
3. `git worktree remove ../plugins-name`
4. Update wp-config.php comments

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Only running git commands | MUST also update wp-config.php |
| Forgetting to update comments | Keep worktree list in comments current |
| Creating worktree for already-checked-out branch | Switch main worktree to different branch first |
| Removing active worktree | Switch WordPress to different worktree before removing |

## Directory Structure Example

```
wp-content/
├── plugins/              # main/master branch (primary git worktree)
├── plugins-feature-x/    # feature/x branch
├── plugins-bugfix-123/   # bugfix/123 branch
└── themes/
```

## Error Handling

**"Branch already checked out"**: The branch is in another worktree. Either use that worktree or checkout a different branch in the conflicting worktree.

**"Assets not found after switch"**: Built assets may not exist in new worktree. Run build commands (`npm run build`) in the worktree.

## Claude Code Native Worktrees

Claude Code has a native `--worktree` flag for **isolated Claude sessions**:

```bash
# Start Claude in an isolated worktree
claude --worktree feature-auth
claude -w bugfix-123
```

**Key differences:**
| Feature | `claude --worktree` | WordPress Worktrees (this skill) |
|---------|---------------------|----------------------------------|
| Purpose | Isolated Claude sessions | WordPress plugin development |
| Location | `.claude/worktrees/` | `wp-content/plugins-*` |
| WordPress integration | None | Updates `wp-config.php` |
| Cleanup | Auto on exit | Manual |

**Combined usage:** Run `claude -w session-name` from inside a `plugins-*` worktree for isolated development with WordPress integration.

## Red Flags - Common Mistakes

These thoughts mean STOP - you're missing the WordPress integration:

| Thought | Reality |
|---------|---------|
| "I'll just use git checkout" | NO - use worktrees, they allow parallel branches |
| "Switching worktree is done" after git commands | NO - you must ALSO update wp-config.php |
| "Active worktree = current directory" | NO - active = what `ACTIVE_PLUGINS_WORKTREE` says |
| "git worktree list shows everything" | NO - also check wp-config.php for WordPress state |

**All worktree operations require BOTH git commands AND wp-config.php updates.**
