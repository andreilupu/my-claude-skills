#!/usr/bin/env bash
#
# wp-api.sh — the SOLE trust boundary for WordPress REST API calls.
# Sources credentials from .env inside THIS process only and never prints them.
#
# Credentials come from $WP_ENV_FILE (default: <script dir>/.env):
#   WP_SITE_URL, WP_USERNAME, WP_APP_PASSWORD

set +x                       # never trace; credentials must not leak into output
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${WP_ENV_FILE:-$SCRIPT_DIR/.env}"

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
  cat >&2 <<'EOF'
Usage:
  wp-api.sh whoami
  wp-api.sh GET <endpoint> [--query "k=v&k2=v2"]
  wp-api.sh POST <endpoint> '<json>'|@file.json
  wp-api.sh PUT  <endpoint> '<json>'|@file.json
  wp-api.sh DELETE <endpoint> [--force]
  wp-api.sh --dry-run <METHOD> <endpoint> ['<json>']
EOF
  exit 2
}

# --- Parse arguments (flags anywhere; positionals collected in order) ---
DRY_RUN=0
FORCE=0
QUERY=""
POSITIONAL=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --force)   FORCE=1; shift ;;
    --query)   [ $# -ge 2 ] || die "--query needs a value"; QUERY="$2"; shift 2 ;;
    -h|--help) usage ;;
    *)         POSITIONAL+=("$1"); shift ;;
  esac
done

[ "${#POSITIONAL[@]}" -ge 1 ] || usage

# --- Resolve method / endpoint / data ---
CMD="${POSITIONAL[0]}"
if [ "$CMD" = "whoami" ]; then
  METHOD="GET"; ENDPOINT="users/me"; DATA=""
else
  METHOD="$CMD"
  ENDPOINT="${POSITIONAL[1]:-}"
  DATA="${POSITIONAL[2]:-}"
  [ -n "$ENDPOINT" ] || die "missing endpoint for $METHOD"
fi

METHOD="$(printf '%s' "$METHOD" | tr '[:lower:]' '[:upper:]')"
ENDPOINT="${ENDPOINT#/}"

# DELETE defaults to trash (recoverable). --force permanently deletes.
if [ "$METHOD" = "DELETE" ] && [ "$FORCE" -eq 1 ]; then
  if [ -n "$QUERY" ]; then QUERY="$QUERY&force=true"; else QUERY="force=true"; fi
fi

# --- Dry run: show what WOULD be sent. Never sources .env, never shows creds. ---
if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN — no request sent"
  echo "METHOD:   $METHOD"
  echo "ENDPOINT: wp/v2/${ENDPOINT}${QUERY:+?$QUERY}"
  echo "BASE URL: (from $ENV_FILE — not shown)"
  [ -n "$DATA" ] && echo "PAYLOAD:  $DATA"
  exit 0
fi

# --- Load credentials (this process only) ---
[ -f "$ENV_FILE" ] || die "env file not found at $ENV_FILE (set WP_ENV_FILE or create .env)"
# Source credentials as plain shell vars — NOT exported. curl receives them as
# arguments, so child processes never need them in their environment.
# shellcheck disable=SC1090
source "$ENV_FILE"
set +x   # re-assert: a stray `set -x` inside .env must not leave tracing enabled

for key in WP_SITE_URL WP_USERNAME WP_APP_PASSWORD; do
  [ -n "${!key:-}" ] || die "$key not set in $ENV_FILE"
done

URL="${WP_SITE_URL%/}/wp-json/wp/v2/${ENDPOINT}${QUERY:+?$QUERY}"

# --- The one place the password is referenced. It is never echoed. ---
CURL_ARGS=(-sS -w $'\n%{http_code}' -u "$WP_USERNAME:$WP_APP_PASSWORD" -X "$METHOD")
if [ -n "$DATA" ]; then
  CURL_ARGS+=(-H "Content-Type: application/json" --data "$DATA")
fi

RAW="$(curl "${CURL_ARGS[@]}" "$URL")" || die "request failed (curl error)"

HTTP_CODE="${RAW##*$'\n'}"
BODY="${RAW%$'\n'*}"

print_body() {
  if command -v python3 >/dev/null 2>&1; then
    printf '%s' "$BODY" | python3 -m json.tool 2>/dev/null || printf '%s\n' "$BODY"
  else
    printf '%s\n' "$BODY"
  fi
}

if [ "$HTTP_CODE" -ge 400 ] 2>/dev/null; then
  echo "HTTP $HTTP_CODE" >&2
  print_body >&2
  exit 1
fi

print_body
