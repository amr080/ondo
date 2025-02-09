#!/usr/bin/env bash
# This script reads an endpoints file, “resolves” each endpoint into a full API URL
# by prepending the base URL (https://ondo.finance) for relative endpoints,
# then uses curl to follow redirects and print the effective (final) URL.
# Results are printed to stdout and saved to full_api_endpoints.txt.

# Configuration
BASE="https://ondo.finance"
INPUT="endpoints_20250209_061422.txt"
OUTPUT="full_api_endpoints.txt"
THREADS=10
TIMEOUT=10

# Empty or create the output file
: > "$OUTPUT"

process_endpoint() {
  local line="$1"
  # Trim whitespace
  line=$(echo "$line" | xargs)
  [ -z "$line" ] && return

  local url=""
  if [[ "$line" =~ ^https?:// ]]; then
    url="$line"
  elif [[ "$line" =~ ^/ ]]; then
    url="${BASE}${line}"
  elif [[ "$line" =~ ^\./ ]]; then
    url="${BASE}/${line#./}"
  else
    url="${BASE}/${line}"
  fi

  # Use curl to follow redirects and get the effective URL
  effective_url=$(curl -Ls -m "$TIMEOUT" -o /dev/null -w '%{url_effective}' "$url" 2>/dev/null)
  [ -z "$effective_url" ] && effective_url="$url"

  echo "$effective_url"
  echo "$effective_url" >> "$OUTPUT"
}

export BASE TIMEOUT OUTPUT
export -f process_endpoint

# Process the endpoints file in parallel.
# Remove empty lines, sort uniquely, and process each line.
grep -v '^[[:space:]]*$' "$INPUT" | sort -u |
xargs -n1 -P "$THREADS" -I {} bash -c 'process_endpoint "{}"'

echo "Resolved API endpoints written to $OUTPUT"
