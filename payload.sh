#!/usr/bin/env bash
# payload.sh

# Set substitution defaults for endpoints with variables
export e="test" t="test" d="test" n="test" o="test" p="test" y="1"

# Define the base URL for relative endpoints
BASE_URL="https://summit.ondo.finance"

# Function to test a single endpoint with various HTTP methods
test_endpoint() {
  local raw="$1"
  # If line contains a colon, take text after the colon
  if [[ "$raw" == *":"* ]]; then
    endpoint="${raw#*:}"
  else
    endpoint="$raw"
  fi
  # Substitute environment variables (e.g. ${e}, ${t})
  endpoint=$(echo "$endpoint" | envsubst)
  # Prepend BASE_URL if endpoint starts with '/'
  if [[ "$endpoint" =~ ^/ ]]; then
    url="${BASE_URL}${endpoint}"
  else
    url="$endpoint"
  fi

  echo "Testing: $url"

  # GET
  curl -s -m 10 -o /dev/null -w "GET  %{http_code} $url\n" "$url"
  # HEAD
  curl -s -m 10 -I -o /dev/null -w "HEAD %{http_code} $url\n" "$url"
  # OPTIONS
  curl -s -m 10 -X OPTIONS -o /dev/null -w "OPTS %{http_code} $url\n" "$url"
  # POST with JSON payload
  curl -s -m 10 -X POST -H "Content-Type: application/json" \
       -d '{"payload":"test"}' -o /dev/null \
       -w "POST %{http_code} $url\n" "$url"
}

export -f test_endpoint
export BASE_URL

# Combine endpoints from both files, remove blank lines and duplicates
cat endpoints_20250209_061422.txt endpoints_20250209_060512.txt \
  | grep -v '^$' | sort -u \
  | xargs -n1 -P 10 -I {} bash -c 'test_endpoint "$@"' _ {}
