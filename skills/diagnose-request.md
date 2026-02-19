---
name: diagnose-request
description: "Diagnose slow HTTP requests by breaking down timing (DNS, TLS, TTFB, transfer) and identifying bottlenecks"
argument-hint: "<URL> [Bearer <token>] [Body: <json>]"
---

# Diagnose HTTP Request Performance

Investigate slow HTTP requests by measuring each phase of the request lifecycle and identifying the bottleneck.

## Step 1: Parse the Request

Extract from `$ARGUMENTS`:
- **URL** (required) — the full URL to test
- **Bearer token** (optional) — if `Bearer <token>` is present, add Authorization header
- **Request body** (optional) — if `Body: <json>` is present, use POST with JSON body
- **Method** — default GET, use POST if body is provided

If `$ARGUMENTS` is empty, ask the user for the URL.

## Step 2: Run Timing Request

Execute the request with full timing breakdown:

```bash
curl -w "\n\n--- Timing Breakdown ---\nDNS Lookup:      %{time_namelookup}s\nTCP Connect:     %{time_connect}s\nTLS Handshake:   %{time_appconnect}s\nTime to First Byte (TTFB): %{time_starttransfer}s\nTotal Time:      %{time_total}s\n\n--- Transfer ---\nResponse Size:   %{size_download} bytes\nHTTP Status:     %{http_code}\nRedirects:       %{num_redirects}\n" \
  -s -o /tmp/diagnose-response.json \
  --max-time 60 \
  {method_flag} "{url}" \
  {headers} \
  {body_flag}
```

## Step 3: Check for DNS Issues

If DNS lookup > 1s:
- Run `nslookup {hostname}` to check network DNS
- Run `dscacheutil -q host -a name {hostname}` to check local cache (macOS)
- Check `/etc/hosts` for the hostname with `grep -i {hostname} /etc/hosts`
- Flag `.local` TLD as known-slow on macOS (mDNS timeout issue)

## Step 4: Check for TLS Issues

If TLS handshake > 0.5s:
- Note whether the URL is HTTP or HTTPS
- Check if certificate validation is slow
- Suggest `--resolve` flag to bypass DNS for TLS re-testing

## Step 5: Check for Server Processing Issues

Calculate server processing time: `TTFB - TLS Handshake` (or `TTFB - TCP Connect` for HTTP).

If server processing > 2s:
- Show the response body from `/tmp/diagnose-response.json`
- Look for processing time hints in the response (e.g., `processing_time_ms`, `cache_hits`)
- Suggest checking server logs

## Step 6: Check for Transfer Issues

Calculate transfer time: `Total - TTFB`.

If transfer time > 1s:
- Report the response size
- Suggest compression if response is large and uncompressed

## Step 7: Run Comparison (Optional)

If DNS was the bottleneck:
- Re-run with `--resolve {hostname}:{port}:127.0.0.1` to bypass DNS and confirm

If TLS was the bottleneck:
- Re-run with HTTP (if possible) to isolate TLS overhead

## Step 8: Present Diagnosis

### Format the Results as a Table

| Phase | Time | Status |
|-------|------|--------|
| DNS Lookup | {time}s | {ok/slow/bottleneck} |
| TCP Connect | {time}s | {ok/slow/bottleneck} |
| TLS Handshake | {time}s | {ok/slow/n/a} |
| Server Processing | {time}s | {ok/slow/bottleneck} |
| Data Transfer | {time}s | {ok/slow/bottleneck} |
| **Total** | **{time}s** | |

### Thresholds

| Phase | OK | Slow | Bottleneck |
|-------|-----|------|------------|
| DNS | < 0.1s | 0.1-1s | > 1s |
| TCP Connect | < 0.1s | 0.1-0.5s | > 0.5s |
| TLS | < 0.3s | 0.3-1s | > 1s |
| Server Processing | < 1s | 1-3s | > 3s |
| Transfer | < 0.5s | 0.5-2s | > 2s |

### Identify Root Cause

Clearly state:
1. **What** is slow (the specific phase)
2. **Why** it's likely slow (common causes for that phase)
3. **How** to fix it (actionable suggestions)

### Common Causes Reference

| Bottleneck | Common Causes | Fixes |
|------------|---------------|-------|
| DNS > 5s on `.local` | macOS mDNS timeout | Switch to `.test` TLD, or add `/etc/resolver/local` |
| DNS > 1s | Slow upstream DNS | Add to `/etc/hosts`, use faster DNS (1.1.1.1, 8.8.8.8) |
| TLS slow | Certificate chain, OCSP stapling | Check cert chain, enable OCSP stapling |
| TTFB slow | Server processing, cold start, DB queries | Check server logs, add caching |
| Transfer slow | Large uncompressed response | Enable gzip/brotli, reduce payload |
| CORS preflight | Browser adds OPTIONS request | Note this doubles the time in browsers vs curl |

### Browser vs curl Note

Always remind the user: **Browsers may be slower than curl** because:
- CORS preflight (OPTIONS request before POST) doubles the round trip
- HTTP/2 multiplexing behavior differs
- Browser DNS cache behaves differently from system DNS

If the diagnosis shows a fast curl time but the user reports slow browser performance, suggest checking the Network tab for preflight requests.
