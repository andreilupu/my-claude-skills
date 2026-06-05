#!/usr/bin/env bash
#
# wp-connect.sh — obtain a WordPress Application Password via the authorize flow
# and save it to .env, WITHOUT ever printing the password.
#
# Two steps (run in order; share the same --port):
#   1) wp-connect.sh url <site-url> [--port N]
#        Confirms the site supports Application Passwords and prints a
#        ready-to-click authorize URL. Open it (logged into the site), approve.
#   2) wp-connect.sh listen [--port N] [--env-file PATH] [--force]
#        Runs a one-shot 127.0.0.1 catcher. On the WordPress redirect it writes
#        WP_SITE_URL / WP_USERNAME / WP_APP_PASSWORD to .env and prints only a
#        non-secret confirmation. The password flows browser -> catcher -> .env.
#
# The credential never passes through this script's stdout/stderr.

set +x                       # never trace; credentials must not leak into output
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_PORT=9789
APP_NAME="Claude Code (wp-push-content-to-live)"

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
  cat >&2 <<'EOF'
Usage:
  wp-connect.sh url <site-url> [--port N]
  wp-connect.sh listen [--port N] [--env-file PATH] [--force]
EOF
  exit 2
}

command -v python3 >/dev/null 2>&1 || die "python3 is required"

CMD="${1:-}"; shift || true
[ -n "$CMD" ] || usage

PORT="$DEFAULT_PORT"
ENV_FILE="${WP_ENV_FILE:-$SCRIPT_DIR/.env}"
FORCE=0
SITE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --port)     [ $# -ge 2 ] || die "--port needs a value"; PORT="$2"; shift 2 ;;
    --env-file) [ $# -ge 2 ] || die "--env-file needs a value"; ENV_FILE="$2"; shift 2 ;;
    --force)    FORCE=1; shift ;;
    -h|--help)  usage ;;
    *)          SITE="$1"; shift ;;
  esac
done

CALLBACK="http://127.0.0.1:$PORT/callback"

case "$CMD" in
  url)
    [ -n "$SITE" ] || die "missing site URL. Usage: wp-connect.sh url <site-url>"
    command -v curl >/dev/null 2>&1 || die "curl is required"
    SITE="${SITE%/}"
    INDEX="$(curl -s "$SITE/wp-json/")" || die "could not reach $SITE/wp-json/"
    AUTHZ="$(printf '%s' "$INDEX" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    print(""); sys.exit(0)
ap = (d.get("authentication") or {}).get("application-passwords") or {}
print((ap.get("endpoints") or {}).get("authorization", ""))
')"
    [ -n "$AUTHZ" ] || die "site does not advertise Application Passwords — confirm it is served over HTTPS and the feature is enabled: $SITE"
    AUTHORIZE="$(python3 -c '
import sys, urllib.parse
base, app, cb = sys.argv[1], sys.argv[2], sys.argv[3]
q = urllib.parse.urlencode({"app_name": app, "success_url": cb})
print(base + ("&" if "?" in base else "?") + q)
' "$AUTHZ" "$APP_NAME" "$CALLBACK")"
    echo "Application Passwords supported. Open this URL (logged into $SITE) and approve:"
    echo
    echo "  $AUTHORIZE"
    echo
    echo "Then run:  bash wp-connect.sh listen --port $PORT"
    ;;

  listen)
    if [ -f "$ENV_FILE" ] && grep -q '^WP_APP_PASSWORD=' "$ENV_FILE" 2>/dev/null && [ "$FORCE" -ne 1 ]; then
      die "$ENV_FILE already has a credential. Re-run with --force to overwrite."
    fi
    echo "Waiting for the WordPress redirect on $CALLBACK (up to 5 min)…"
    ENV_FILE="$ENV_FILE" python3 - "$PORT" <<'PY'
import sys, os, time
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs

port = int(sys.argv[1])
env_file = os.environ["ENV_FILE"]
state = {"done": False, "error": None}

class H(BaseHTTPRequestHandler):
    def log_message(self, *a):   # silence default logs — the request path carries the password
        pass
    def do_GET(self):
        q = parse_qs(urlparse(self.path).query)
        pw   = (q.get("password")   or [""])[0]
        user = (q.get("user_login") or [""])[0]
        site = (q.get("site_url")   or [""])[0]
        if not pw:
            self.send_response(400); self.end_headers()
            self.wfile.write(b"Missing password parameter.")
            return
        try:
            # 0600 perms; the password is written straight to the file, never printed
            fd = os.open(env_file, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
            with os.fdopen(fd, "w") as f:
                f.write("WP_SITE_URL=%s\n" % site)
                f.write("WP_USERNAME=%s\n" % user)
                f.write('WP_APP_PASSWORD="%s"\n' % pw)
        except OSError as e:
            self.send_response(500); self.end_headers()
            self.wfile.write(b"Failed to write env file.")
            state["error"] = "could not write %s: %s" % (env_file, e.strerror)  # no password
            state["done"] = True
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"<h2>Saved. You can close this tab.</h2>")
        print("Saved credentials for '%s' at %s" % (user, site))  # no password
        state["done"] = True

srv = HTTPServer(("127.0.0.1", port), H)
srv.timeout = 5
start = time.time()
while not state["done"]:
    srv.handle_request()
    if time.time() - start > 300:
        sys.stderr.write("ERROR: timed out waiting for authorization\n")
        sys.exit(1)
if state["error"]:
    sys.stderr.write("ERROR: %s\n" % state["error"])
    sys.exit(1)
PY
    echo "Done. Verify with: bash wp-api.sh whoami"
    ;;

  -h|--help) usage ;;
  *) die "unknown command '$CMD' (use 'url' or 'listen')" ;;
esac
