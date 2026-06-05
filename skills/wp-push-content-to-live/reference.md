# Reference: WordPress REST content operations

## Credential setup

1. In WP Admin → Users → Profile → Application Passwords, create one (e.g.
   named "claude-content").
2. Copy `.env.example` to `.env` and fill in:
   ```bash
   WP_SITE_URL=https://your-site.com
   WP_USERNAME=your-user-slug
   WP_APP_PASSWORD="xxxx xxxx xxxx xxxx xxxx xxxx"
   ```
3. `.env` is git-ignored. Never commit it. Claude never reads it — only
   `wp-api.sh` sources it.

`WP_USERNAME` must be the user's **login name** (`user_login`) — the value the
authorize flow returns and that Basic Auth expects, not the display name. It
usually matches the `slug` from `GET /wp-json/wp/v2/users`, but the login name
is authoritative.

## Get credentials with `wp-connect.sh` (assisted)

Instead of creating the password by hand, use the WordPress authorize flow — the
password is written straight to `.env`, never shown to Claude:

```bash
bash wp-connect.sh url https://your-site.com   # prints an authorize URL to open + approve
bash wp-connect.sh listen                       # catches the redirect, writes .env
```

- Run both steps with the same `--port` if you override the default (9789).
- `--force` overwrites an existing credential in `.env`.
- `--env-file PATH` (or `WP_ENV_FILE`) targets a different `.env` location.
- Requires the site to be HTTPS with Application Passwords enabled; the `url`
  step checks and reports if not.

## Wrapper usage

```bash
bash wp-api.sh whoami                                  # preflight auth check
bash wp-api.sh GET posts --query "per_page=5&status=draft"
bash wp-api.sh POST posts '{"title":"Hi","status":"draft"}'
bash wp-api.sh POST posts @payload.json                # payload from a file
bash wp-api.sh PUT posts/42 '{"status":"publish"}'
bash wp-api.sh DELETE posts/42                          # trash (recoverable)
bash wp-api.sh DELETE posts/42 --force                  # permanent
bash wp-api.sh --dry-run POST posts '{"title":"Hi"}'    # preview, sends nothing
```

Override the credential file location with `WP_ENV_FILE=/path/to/.env`.

## Common `wp/v2` endpoints

| Resource | Endpoint | Notes |
|---|---|---|
| Posts | `posts`, `posts/{id}` | Main content type |
| Pages | `pages`, `pages/{id}` | Static pages |
| Media | `media`, `media/{id}` | **Read/reference only** here — upload is out of scope |
| Categories | `categories`, `categories/{id}` | Taxonomy |
| Tags | `tags`, `tags/{id}` | Taxonomy |
| Menus | `menus`, `menu-items` | WP 5.9+ |
| Users | `users`, `users/me` | `users/me` for auth check |
| Comments | `comments`, `comments/{id}` | |
| Taxonomies | `taxonomies` | Discover registered taxonomies |
| Post types | `types` | Discover registered CPTs and their REST bases |
| Settings | `settings` | Site settings (auth required) |
| Templates | `templates`, `template-parts` | FSE block templates |

For a custom post type, find its REST base via `GET types`, then use that base
as the endpoint (e.g. `GET book` for a `book` CPT with `rest_base: "book"`).

## Post / page payload fields

| Field | Type | Notes |
|---|---|---|
| `title` | string | |
| `content` | string (HTML) | Rendered block/HTML content |
| `excerpt` | string | |
| `status` | string | `draft` (default here), `publish`, `pending`, `private` |
| `slug` | string | URL slug |
| `author` | int | User ID |
| `categories` | int[] | Category IDs (not slugs) |
| `tags` | int[] | Tag IDs |
| `featured_media` | int | Attachment ID of an already-uploaded image |
| `meta` | object | Registered meta fields only |
| `date` | string | ISO 8601; omit to use now |

## Idempotency pattern

Before creating, check for an existing item by slug:

```bash
bash wp-api.sh GET posts --query "slug=my-post&status=any"
```

If the array is non-empty, `PUT posts/{id}` to update instead of creating a
duplicate; if empty, `POST posts`.

## Category-ID drift across environments

Category/tag IDs differ between local, staging, and production. After creating a
category on a given site, query its live ID and use that in payloads:

```bash
bash wp-api.sh GET categories --query "slug=case-studies"
# → use the returned id in "categories":[<id>]
```

## Auth troubleshooting

| Symptom | Cause / fix |
|---|---|
| `401 Unauthorized` | Wrong username (use the slug) or wrong Application Password. |
| `403 Forbidden` | User lacks the capability for that operation/status. |
| `rest_cannot_create` | User can't publish — try `status:draft` or a higher-privilege user. |
| Password "looks wrong" | Application Passwords contain spaces — quote the value in `.env`, or paste it with spaces removed. |
| Body shows `rendered`/`raw` empty | Use `--query "context=edit"` (auth required) to get unfiltered content. |
