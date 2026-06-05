#!/usr/bin/env bash
# Tests for wp-connect.sh. No real WordPress: a mock serves /wp-json/, and the
# WordPress redirect is simulated by curling the local catcher directly.
# Core guarantee: the captured password lands in .env but NEVER in script output.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONNECT="$HERE/../wp-connect.sh"

PASS=0
fail() { echo "FAIL: $1"; exit 1; }
ok()   { echo "PASS: $1"; PASS=$((PASS + 1)); }

free_port() { python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()'; }

# start_mock <port> <supported|unsupported> — serves a fake REST index at /wp-json/
start_mock() {
  python3 - "$1" "$2" >/dev/null 2>&1 <<'PY' &
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
port = int(sys.argv[1]); kind = sys.argv[2]
if kind == "supported":
    INDEX = '{"authentication":{"application-passwords":{"endpoints":{"authorization":"https://mock.example/wp-admin/authorize-application.php"}}}}'
else:
    INDEX = '{"authentication":{}}'
class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_GET(self):
        if self.path.rstrip("/") == "/wp-json":
            b = INDEX.encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b)
        else:
            self.send_response(404); self.end_headers()
HTTPServer(("127.0.0.1", port), H).serve_forever()
PY
  MOCK_PID=$!
}

wait_up() { for i in $(seq 1 40); do curl -s "$1" >/dev/null 2>&1 && return 0; sleep 0.1; done; return 1; }

# 1: `url` with no site → usage/error, nonzero
out="$(bash "$CONNECT" url 2>&1)"; rc=$?
[ "$rc" -ne 0 ] || fail "url without a site should exit nonzero"
ok "url requires a site URL"

# 2: `url` against a supported mock → prints the authorize link
MP="$(free_port)"
start_mock "$MP" supported
wait_up "http://127.0.0.1:$MP/wp-json/" || fail "mock (supported) did not start"
out="$(bash "$CONNECT" url "http://127.0.0.1:$MP" --port 9999 2>&1)"; rc=$?
kill "$MOCK_PID" 2>/dev/null; wait "$MOCK_PID" 2>/dev/null
[ "$rc" -eq 0 ] || fail "url against supported site should succeed: $out"
echo "$out" | grep -qF "authorize-application.php" || fail "should print the authorize endpoint"
echo "$out" | grep -qF "app_name=" || fail "should include app_name"
echo "$out" | grep -qF "success_url=" || fail "should include success_url"
echo "$out" | grep -qF "9999" || fail "success_url should carry the callback port"
ok "url builds the authorize link from the REST index"

# 3: `url` against an unsupported mock → clear failure
MP="$(free_port)"
start_mock "$MP" unsupported
wait_up "http://127.0.0.1:$MP/wp-json/" || fail "mock (unsupported) did not start"
out="$(bash "$CONNECT" url "http://127.0.0.1:$MP" 2>&1)"; rc=$?
kill "$MOCK_PID" 2>/dev/null; wait "$MOCK_PID" 2>/dev/null
[ "$rc" -ne 0 ] || fail "unsupported site should exit nonzero"
echo "$out" | grep -qF "does not advertise" || fail "should explain lack of support"
ok "url rejects sites without Application Passwords"

# 4: CORE — `listen` saves the redirect to .env without leaking the password
LP="$(free_port)"
ENVF="$(mktemp -u)"
OUTF="$(mktemp)"
FAKE_PW="CONNECT-PW-DO-NOT-LEAK-9999"
bash "$CONNECT" listen --port "$LP" --env-file "$ENVF" --force >"$OUTF" 2>&1 &
LISTEN_PID=$!
CB="http://127.0.0.1:$LP/callback?site_url=https://x.example&user_login=bob&password=$FAKE_PW"
up=0
for i in $(seq 1 50); do curl -s "$CB" >/dev/null 2>&1 && { up=1; break; }; sleep 0.2; done
wait "$LISTEN_PID" 2>/dev/null
[ "$up" -eq 1 ] || fail "catcher never came up"
grep -qF 'WP_APP_PASSWORD="'"$FAKE_PW"'"' "$ENVF" || fail ".env missing password"
grep -qF 'WP_USERNAME=bob' "$ENVF" || fail ".env missing user_login"
grep -qF 'WP_SITE_URL=https://x.example' "$ENVF" || fail ".env missing site_url"
if grep -qF "$FAKE_PW" "$OUTF"; then fail "LEAK: password appeared in script output"; fi
ok "listen saves .env without leaking the password"

# 5: .env written with 0600 perms
perms="$(stat -f '%Lp' "$ENVF" 2>/dev/null || stat -c '%a' "$ENVF" 2>/dev/null)"
[ "$perms" = "600" ] || fail ".env should be chmod 600 (got '$perms')"
ok ".env written with 0600 perms"
rm -f "$ENVF" "$OUTF"

# 6: a write failure must error WITHOUT leaking the password (no hang, no traceback w/ secret)
LP2="$(free_port)"
OUTF2="$(mktemp)"
bash "$CONNECT" listen --port "$LP2" --env-file "/no-such-dir-xyz/.env" --force >"$OUTF2" 2>&1 &
LISTEN_PID=$!
CB2="http://127.0.0.1:$LP2/callback?site_url=https://x.example&user_login=bob&password=$FAKE_PW"
for i in $(seq 1 50); do curl -s "$CB2" >/dev/null 2>&1 && break; sleep 0.2; done
wait "$LISTEN_PID" 2>/dev/null
if grep -qF "$FAKE_PW" "$OUTF2"; then fail "LEAK: password appeared in error output"; fi
ok "write failure errors without leaking the password"
rm -f "$OUTF2"

echo ""
echo "ALL TESTS PASSED ($PASS)"
