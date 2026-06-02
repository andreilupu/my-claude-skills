---
name: wp-push-content-to-live
description: Use when creating, updating, or deleting content (posts, pages, taxonomy, menus, custom post types) on a live WordPress site via the REST API, authenticating with an Application Password stored in a .env file that must be used but never read. Triggers on "publish to WordPress", "push a post/page to my site", "create a draft on my WP site", "upload content to WordPress via REST".
---

# Push Content to a Live WordPress Site (REST API)

Create and manage content on a live WordPress site through the `wp/v2` REST API.
The Application Password lives in a `.env` file you **use but never read**. All
API access goes through `wp-api.sh`, which is the only code that touches the
credential.

## Secret-handling iron rules (NON-NEGOTIABLE)

1. **Never read the credential.** Do not `Read`, `cat`, `grep`, `head`, `tail`,
   or `echo` `.env` or any credential value. All API calls go through
   `wp-api.sh`, which sources `.env` inside its own process.
2. **Never pass the token on a command line or in a URL.** Only `wp-api.sh`
   references it, via `curl -u`.
3. **Never run the wrapper with tracing or verbose.** No `bash -x`, no `curl -v`.
4. **If you must reference a credential for debugging, name the key only**
   (e.g. "`WP_APP_PASSWORD` is unset"), never the value.
5. **If `.env` is missing, ask the user to create it** from `.env.example`. Do
   not hunt for credentials elsewhere.

## Workflow

1. **Preflight** — verify auth without reading anything:
   ```bash
   bash wp-api.sh whoami
   ```
   If it errors with "env file not found", tell the user to copy `.env.example`
   to `.env` and fill it in (Application Password from WP Admin → Users →
   Profile → Application Passwords), then stop until they confirm. Do not read
   `.env` afterward.
2. **Build the payload** ad-hoc from the conversation. See `reference.md` for
   endpoints and field names.
3. **Draft-first (hard rule)** — posts and pages are created as
   `"status":"draft"` unless the user explicitly says to publish.
4. **Preview when unsure** — show exactly what will be sent before a write:
   ```bash
   bash wp-api.sh --dry-run POST posts '{"title":"My Post","status":"draft"}'
   ```
5. **Send** — for example:
   ```bash
   bash wp-api.sh POST posts '{"title":"My Post","content":"<p>Hi</p>","status":"draft"}'
   ```
6. **Destructive ops** — confirm every `DELETE` with the user first. Default
   behavior trashes (recoverable). Only add `--force` (permanent) if the user
   explicitly insists.
7. **Media (reference only)** — you may reference already-uploaded media by ID
   (e.g. `"featured_media": 123`) or `GET media` to find one. Uploading new
   images is out of scope — that belongs to the planned `wp-media-upload` skill.
8. **Idempotency (optional)** — when the user wants no duplicates, `GET` by
   `slug` before creating and update or skip accordingly.
9. **Report** — surface the returned ID, status, and edit/permalink.

## Wrapper reference

```
bash wp-api.sh whoami
bash wp-api.sh GET <endpoint> [--query "k=v&k2=v2"]
bash wp-api.sh POST <endpoint> '<json>'|@file.json
bash wp-api.sh PUT  <endpoint> '<json>'|@file.json
bash wp-api.sh DELETE <endpoint> [--force]
bash wp-api.sh --dry-run <METHOD> <endpoint> ['<json>']
```

Override the credential file location with `WP_ENV_FILE=/path/to/.env`.

## Out of scope

Media/binary upload (see `wp-media-upload`), markdown/manifest ingestion,
bulk import, OAuth/JWT auth, XML-RPC, WP-CLI.

## Verification

This skill writes to a live site — there are no integration tests against real
WordPress. The wrapper's guarantees are covered by `tests/wp-api.test.sh`
(run `bash tests/wp-api.test.sh`). For a real site, verify with `whoami` and a
draft-create round-trip the user confirms in wp-admin.
