# wp-push-content-to-live

A Claude Code skill for creating and managing content on a **live** WordPress
site via the REST API — using an Application Password that Claude **uses but
never reads**.

## The idea

You drop your credentials in a `.env` file. Claude never opens it. Every API
call goes through one wrapper script, `wp-api.sh`, which sources `.env` inside
its own process and passes the password straight to `curl` — so the token never
appears in the conversation, logs, or command output.

## What it does

- Create/update/delete posts, pages, taxonomy terms, menus, and custom post
  types via the `wp/v2` REST API.
- **Draft-first:** posts/pages default to `draft` unless you say publish.
- **Safe deletes:** `DELETE` trashes (recoverable) unless you pass `--force`.
- **Dry-run:** preview exactly what would be sent before any write.

## Setup

```bash
cp .env.example .env
# edit .env: WP_SITE_URL, WP_USERNAME (slug), WP_APP_PASSWORD (quoted)
bash wp-api.sh whoami   # verify auth
```

Create the Application Password in WP Admin → Users → Profile → Application
Passwords.

## Not included

Media/image upload (planned separate `wp-media-upload` skill, which also
optimizes images), bulk import, OAuth/JWT, XML-RPC, WP-CLI.

## Tests

```bash
bash tests/wp-api.test.sh
```

Tests stub `curl` so they need no network, and assert the password never leaks
into the wrapper's output.

## Install

```bash
ln -s /path/to/my-claude-skills/skills/wp-push-content-to-live ~/.claude/skills/wp-push-content-to-live
```
