#!/usr/bin/env bash
FILE="endpoints_20250209_061422.txt"
THREADS=10
TIMEOUT=10

# Extract unique literal URLs (lines starting with http/https)
grep -E '^https?://' "$FILE" | sort -u |
xargs -n1 -P "$THREADS" -I {} bash -c '
  url="{}"
  echo "Testing: $url"
  curl -s -m '"$TIMEOUT"' -o /dev/null -w "GET  %{http_code} $url\n" "$url"
  curl -s -m '"$TIMEOUT"' -I -o /dev/null -w "HEAD %{http_code} $url\n" "$url"
  curl -s -m '"$TIMEOUT"' -X OPTIONS -o /dev/null -w "OPTS %{http_code} $url\n" "$url"
  curl -s -m '"$TIMEOUT"' -X POST -H "Content-Type: application/json" -d "{\"payload\":\"test\"}" -o /dev/null -w "POST %{http_code} $url\n" "$url"
'
