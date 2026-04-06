# Pattern: REST API Deployment

Use this pattern when WP-CLI is not available — shared hosting, WordPress.com, or remote servers where only HTTP access is possible.

## Prerequisites

Create an Application Password in WP Admin → Users → Profile → Application Passwords. Store credentials in a `.env` file:

```bash
WP_SITE_URL=https://your-site.com
WP_USERNAME=your-username
WP_APP_PASSWORD=xxxx xxxx xxxx xxxx xxxx xxxx
```

**NEVER commit `.env` to git. Add it to `.gitignore`.**

**Finding your username:** If you're unsure which username WordPress expects, query `GET /wp-json/wp/v2/users` — look for the `slug` field, not the display name.

## Push templates and template parts

```bash
# Load .env — use source, NOT export $(xargs), which breaks on passwords with spaces
set -a; source .env; set +a

push_template() {
  local file="$1" endpoint="$2" label="$3"
  python3 -c "import json,sys; print(json.dumps({'content': sys.stdin.read()}))" < "$file" > /tmp/wp-update.json
  curl -s -X POST "$WP_SITE_URL/wp-json/wp/v2/$endpoint" \
    -u "$WP_USERNAME:$WP_APP_PASSWORD" \
    -H "Content-Type: application/json" \
    -d @/tmp/wp-update.json \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print('$label:', d.get('slug', d.get('code','ERROR')))"
  rm -f /tmp/wp-update.json
}

# Templates
push_template templates/front-page.html "templates/{theme-slug}//front-page" "front-page"
push_template templates/index.html       "templates/{theme-slug}//index"      "index"
push_template templates/single.html      "templates/{theme-slug}//single"     "single"
push_template templates/page.html        "templates/{theme-slug}//page"       "page"
push_template templates/archive.html     "templates/{theme-slug}//archive"    "archive"
push_template templates/404.html         "templates/{theme-slug}//404"        "404"

# Template parts
push_template parts/header.html "template-parts/{theme-slug}//header" "header"
push_template parts/footer.html "template-parts/{theme-slug}//footer" "footer"
```

> **Note:** once pushed via REST API, templates are stored as `custom` source in the database and override the theme files. To revert to the theme file version, delete the custom template via WP Admin → Appearance → Editor → Templates.

## Seed Script: REST API (`seed-content-api.sh`)

Generate this script when repeating content sections were identified and WP-CLI is unavailable. Requires `curl` and `python3`.

```bash
#!/bin/bash
# seed-content-api.sh — Create initial content via WordPress REST API
# Usage:
#   1. Fill in .env file and run: bash seed-content-api.sh
#   2. Or pass args: bash seed-content-api.sh https://site.com username "app password"

set -euo pipefail

# Load .env if present — use source, NOT export $(xargs), which breaks on passwords with spaces
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi

SITE_URL="${1:-$WP_SITE_URL}"
USERNAME="${2:-$WP_USERNAME}"
APP_PASSWORD="${3:-$WP_APP_PASSWORD}"

if [ -z "$SITE_URL" ] || [ -z "$USERNAME" ] || [ -z "$APP_PASSWORD" ]; then
  echo "Usage: bash seed-content-api.sh [site-url] [username] [app-password]"
  echo "   Or: fill in .env and run: bash seed-content-api.sh"
  exit 1
fi

SITE_URL="${SITE_URL%/}"
API="$SITE_URL/wp-json/wp/v2"
AUTH="$USERNAME:$APP_PASSWORD"

# Helper: extract JSON field, exit with message on error
json_field() {
  local json="$1" field="$2" value
  value=$(echo "$json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$field',''))" 2>/dev/null)
  if [ -z "$value" ]; then
    echo "ERROR: Could not extract '$field' from response:" >&2
    echo "$json" >&2
    return 1
  fi
  echo "$value"
}

# Test authentication first
echo "Testing authentication..."
AUTH_TEST=$(curl -s "$API/users/me" -u "$AUTH")
AUTH_USER=$(echo "$AUTH_TEST" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('name',''))" 2>/dev/null)
if [ -z "$AUTH_USER" ]; then
  echo "ERROR: Authentication failed."
  echo "$AUTH_TEST"
  exit 1
fi
echo "Authenticated as: $AUTH_USER"

# Create category (idempotent)
CATEGORY_ID=$(curl -s "$API/categories?slug=case-studies" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['id'] if d else '')" 2>/dev/null)
if [ -z "$CATEGORY_ID" ]; then
  RESPONSE=$(curl -s -X POST "$API/categories" -u "$AUTH" -H "Content-Type: application/json" -d '{"name":"Case Studies","slug":"case-studies"}')
  CATEGORY_ID=$(json_field "$RESPONSE" "id") || exit 1
  echo "Created category (ID: $CATEGORY_ID)"
else
  echo "Category exists (ID: $CATEGORY_ID)"
fi

# Helper: upload image and create post
create_post_with_image() {
  local title="$1" content="$2" image_url="$3" filename="$4" alt="$5"

  # Skip if exists
  EXISTING=$(curl -s "$API/posts?search=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$title'''))")&per_page=1" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['id'] if d and d[0]['title']['rendered']=='$title' else '')" 2>/dev/null)
  if [ -n "$EXISTING" ]; then echo "Post '$title' exists, skipping."; return; fi

  # Download image to temp file (required — URLs without file extensions fail)
  local tmp="/tmp/$filename"
  curl -sL "$image_url" -o "$tmp"

  # Convert to WebP for ~30-50% smaller file size (requires Pillow: pip install Pillow)
  local upload_file="$tmp"
  local upload_filename="$filename"
  local content_type="image/jpeg"
  local webp_file="/tmp/${filename%.*}.webp"
  if python3 -c "from PIL import Image; Image.open('$tmp').save('$webp_file', 'webp', quality=85)" 2>/dev/null; then
    upload_file="$webp_file"
    upload_filename="${filename%.*}.webp"
    content_type="image/webp"
    echo "  Converted to WebP: $(du -sh "$webp_file" | cut -f1) (was $(du -sh "$tmp" | cut -f1))"
  fi

  # Upload to media library
  local upload
  upload=$(curl -s -X POST "$API/media" -u "$AUTH" \
    -H "Content-Disposition: attachment; filename=$upload_filename" \
    -H "Content-Type: $content_type" \
    --data-binary "@$upload_file")
  local img_id
  img_id=$(json_field "$upload" "id") || return 1
  curl -s -X POST "$API/media/$img_id" -u "$AUTH" -H "Content-Type: application/json" \
    -d "{\"alt_text\":\"$alt\"}" > /dev/null
  rm -f "$tmp" "$webp_file"

  # Create post
  python3 -c "
import json
print(json.dumps({'title': '''$title''', 'content': '''$content''', 'status': 'publish', 'categories': [$CATEGORY_ID], 'featured_media': $img_id}))
" > /tmp/post.json
  local post
  post=$(curl -s -X POST "$API/posts" -u "$AUTH" -H "Content-Type: application/json" -d @/tmp/post.json)
  local post_id
  post_id=$(json_field "$post" "id") || return 1
  rm -f /tmp/post.json
  echo "Created '$title' (post: $post_id, image: $img_id)"
}

# --- Add your posts here ---
create_post_with_image "Post Title" "Post content here." "https://example.com/image.jpg" "image.jpg" "Alt text"

echo ""
echo "Done! Category ID: $CATEGORY_ID"
echo "Update taxQuery in your templates: \"taxQuery\":{\"category\":[$CATEGORY_ID]}"
echo "Then push the updated template via REST API (see push_template above)"
```

## Category ID drift

The category ID **will differ** between local and production. After seeding on each environment:

1. Get the live category ID:
   ```bash
   curl -s "https://your-site.com/wp-json/wp/v2/categories?slug=case-studies" \
     | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])"
   ```
2. Update the template file: `"taxQuery":{"category":[LIVE_ID]}`
3. Push the updated template via the `push_template` function above.

> **WP-CLI equivalent:** `wp term get category {slug} --by=slug --field=term_id`
