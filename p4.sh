#!/usr/bin/env bash
# p3.sh — Finds, resolves, and prints all ondo.finance / ondo.foundation API base URLs
#
# This script recursively searches for references to ondo.finance or ondo.foundation
# in files under SEARCH_DIR, extracts endpoints (absolute or relative),
# normalizes them using a default base URL (https://ondo.finance),
# follows redirects with curl concurrently, and prints a timestamp + final URL.
#
# Results are printed to the terminal and saved in a timestamped output file.
#
# Usage:
#   chmod +x p3.sh
#   ./p3.sh
#
# Configuration
set -o errexit
set -o pipefail
set -o nounset

SEARCH_DIR="."         # Directory to search recursively
BASE_1="https://ondo.finance"
BASE_2="https://ondo.foundation"
THREADS=10             # Number of parallel processes for curl calls
TIMEOUT=10             # Timeout (seconds) for curl

# Create a timestamped output file name
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"  # e.g. 20250209_123045
OUTPUT="p3_results_${TIMESTAMP}.txt"

# Clear (or create) the output file
> "$OUTPUT"

# choose_base selects the default base URL for relative endpoints.
choose_base() {
  # Defaulting to ondo.finance; adjust logic if needed.
  echo "$BASE_1"
}

# process_url normalizes the endpoint, follows redirects via curl,
# and appends the timestamp and final URL to the output.
process_url() {
  local raw="$1"
  local line
  line="$(echo "$raw" | xargs)"  # Trim whitespace
  [[ -z "$line" ]] && return

  local url final_url

  # Determine if the endpoint is absolute or relative.
  if [[ "$line" =~ ^https?:// ]]; then
    url="$line"
  elif [[ "$line" =~ ^/ ]]; then
    url="$(choose_base)${line}"
  elif [[ "$line" =~ ^\./ ]]; then
    url="$(choose_base)/${line#./}"
  else
    url="$(choose_base)/$line"
  fi

  # Follow redirects and obtain the effective URL.
  final_url="$(curl -s -m "$TIMEOUT" -L -o /dev/null -w '%{url_effective}' "$url")"
  [[ -z "$final_url" ]] && final_url="$url"

  local ts
  ts="$(date +%Y-%m-%dT%H:%M:%S)"
  echo "$ts $final_url"
  echo "$ts $final_url" >> "$OUTPUT"
}

export -f process_url
export TIMEOUT OUTPUT BASE_1

# Search all files under SEARCH_DIR for references to ondo.finance or ondo.foundation.
# The grep command extracts any URL or URL fragment containing the domains,
# sed removes extra quotes and spaces,
# sort -u ensures uniqueness,
# and xargs processes each candidate URL in parallel.
grep -rEioh "(https?://[^ \"')]+ondo\.finance[^ \"')]*|https?://[^ \"')]+ondo\.foundation[^ \"')]*|[ '/\"]/?[^ \"')]+ondo\.finance[^ \"')]*|[ '/\"]/?[^ \"')]+ondo\.foundation[^ \"')]*" "$SEARCH_DIR" 2>/dev/null \
| sed "s/[\"' ]//g" \
| sort -u \
| xargs -n1 -P "$THREADS" -I {} bash -c 'process_url "$@"' _ {}

echo "Done! Results are in $OUTPUT"
