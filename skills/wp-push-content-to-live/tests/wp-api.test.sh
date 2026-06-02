#!/usr/bin/env bash
# Tests for wp-api.sh. A fake `curl` on PATH means no network is needed.
# Core guarantee under test: the app password never appears in wp-api.sh output,
# while still being passed to curl (so auth genuinely happens).

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="$HERE/../wp-api.sh"
FAKE_PW="SECRET-TOKEN-DO-NOT-LEAK-12345"

PASS=0
fail() { echo "FAIL: $1"; exit 1; }
ok()   { echo "PASS: $1"; PASS=$((PASS + 1)); }

setup() {
  WORK="$(mktemp -d)"
  SHIM_LOG="$WORK/curl.log"
  : > "$SHIM_LOG"
  # Fake curl: record every argument (one per line), then emit canned body + status
  # to mimic real curl invoked with -w $'\n%{http_code}'.
  cat > "$WORK/curl" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$@" >> "$SHIM_LOG"
printf '%s\n%s' '{"id":1,"status":"draft"}' '200'
EOF
  chmod +x "$WORK/curl"
  PATH="$WORK:$PATH"
  ENVF="$WORK/.env"
  cat > "$ENVF" <<EOF
WP_SITE_URL=https://example.com
WP_USERNAME=tester
WP_APP_PASSWORD=$FAKE_PW
EOF
}

teardown() { rm -rf "$WORK"; }

# 1: missing env file → nonzero exit, clear message
setup
out="$(WP_ENV_FILE="$WORK/nope.env" bash "$WRAPPER" whoami 2>&1)"; rc=$?
[ "$rc" -ne 0 ] || fail "missing env should exit nonzero"
echo "$out" | grep -qF "not found" || fail "missing env should say 'not found'"
ok "missing env file errors cleanly"
teardown

# 2: missing key → names the key, nonzero exit
setup
cat > "$ENVF" <<EOF
WP_SITE_URL=https://example.com
WP_USERNAME=tester
EOF
out="$(WP_ENV_FILE="$ENVF" bash "$WRAPPER" whoami 2>&1)"; rc=$?
[ "$rc" -ne 0 ] || fail "missing key should exit nonzero"
echo "$out" | grep -qF "WP_APP_PASSWORD" || fail "should name the missing key"
ok "missing key names the key"
teardown

# 3: CORE — password never in wrapper output; response shown; curl DID get the password
setup
out="$(WP_ENV_FILE="$ENVF" bash "$WRAPPER" POST posts '{"title":"x"}' 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fail "POST should succeed (rc=$rc): $out"
if echo "$out" | grep -qF "$FAKE_PW"; then fail "LEAK: password found in wrapper output"; fi
echo "$out" | grep -qF '"id": 1' || echo "$out" | grep -qF '"id":1' || fail "response not shown"
grep -qF "$FAKE_PW" "$SHIM_LOG" || fail "password should reach curl via -u"
ok "password never leaks to wrapper output"
teardown

# 4: dry-run sends nothing and shows no secret
setup
out="$(WP_ENV_FILE="$ENVF" bash "$WRAPPER" --dry-run POST posts '{"title":"x"}' 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fail "dry-run should exit 0"
[ ! -s "$SHIM_LOG" ] || fail "dry-run must NOT call curl"
echo "$out" | grep -qF "DRY RUN" || fail "dry-run should announce itself"
echo "$out" | grep -qF "POST" || fail "dry-run should show method"
echo "$out" | grep -qF "wp/v2/posts" || fail "dry-run should show endpoint"
if echo "$out" | grep -qF "$FAKE_PW"; then fail "dry-run leaked password"; fi
ok "dry-run previews without sending"
teardown

# 5: whoami → GET users/me
setup
WP_ENV_FILE="$ENVF" bash "$WRAPPER" whoami >/dev/null 2>&1
grep -qF "wp-json/wp/v2/users/me" "$SHIM_LOG" || fail "whoami should hit users/me"
grep -qxF "GET" "$SHIM_LOG" || fail "whoami should use GET"
ok "whoami → GET users/me"
teardown

# 6: --query appended to URL
setup
WP_ENV_FILE="$ENVF" bash "$WRAPPER" GET posts --query "per_page=5" >/dev/null 2>&1
grep -qF "wp-json/wp/v2/posts?per_page=5" "$SHIM_LOG" || fail "query not appended"
ok "--query appended to URL"
teardown

# 7: DELETE trashes by default; --force adds force=true
setup
WP_ENV_FILE="$ENVF" bash "$WRAPPER" DELETE posts/3 >/dev/null 2>&1
if grep -qF "force=true" "$SHIM_LOG"; then fail "default DELETE must not force"; fi
: > "$SHIM_LOG"
WP_ENV_FILE="$ENVF" bash "$WRAPPER" DELETE posts/3 --force >/dev/null 2>&1
grep -qF "force=true" "$SHIM_LOG" || fail "--force should add force=true"
ok "DELETE force semantics"
teardown

echo ""
echo "ALL TESTS PASSED ($PASS)"
