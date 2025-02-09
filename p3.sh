#!/usr/bin/env bash
#
# p3.sh — Finds, resolves, and prints all ondo.finance / ondo.foundation API base URLs
# 1. Recursively searches for references to ondo.finance or ondo.foundation in SEARCH_DIR.
# 2. Extracts endpoints, normalizes them as absolute or relative.
# 3. If endpoint is relative, prepends an ondo base URL.
# 4. Follows redirects with curl (concurrently) to find final destinations.
# 5. Prints a timestamp + final URL to console and to a timestamped result file.

SEARCH_DIR="."
BASE_1="https://ondo.finance"
BASE_2="https://ondo.foundation"
THREADS=10
TIMEOUT=10

# Timestamped output file
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"  # e.g. 20250209_123045
OUTPUT="p3_results_$TIMESTAMP.txt"

# Clear the output file
> "$OUTPUT"

choose_base() {
  # For now, pick https://ondo.finance by default; extend logic if needed
  echo "$BASE_1"
}

process_url() {
  local raw="$1"
  local line
  line="$(echo "$raw" | xargs)"
  [[ -z "$line" ]] && return

  local url final_url
  # Check if line is already an absolute URL
  if [[ "$line" =~ ^https?:// ]]; then
    url="$line"
  elif [[ "$line" =~ ^/ ]]; then
    url="$(choose_base)${line}"
  elif [[ "$line" =~ ^\./ ]]; then
    url="$(choose_base)/${line#./}"
  else
    url="$(choose_base)/$line"
  fi

  final_url="$(curl -s -m "$TIMEOUT" -L -o /dev/null -w '%{url_effective}' "$url")"
  [[ -z "$final_url" ]] && final_url="$url"

  local ts
  ts="$(date +%Y-%m-%dT%H:%M:%S)"
  echo "$ts $final_url"
  echo "$ts $final_url" >> "$OUTPUT"
}

export -f process_url
export TIMEOUT OUTPUT

grep -rEioh "(https?://[^ \"')]+ondo\.finance[^ \"')]*|https?://[^ \"')]+ondo\.foundation[^ \"')]*|[ '/\"]/?[^ \"')]+ondo\.finance[^ \"')]*|[ '/\"]/?[^ \"')]+ondo\.foundation[^ \"')]*" "$SEARCH_DIR" 2>/dev/null \
| sed "s/[\"' ]//g" \
| sort -u \
| xargs -n1 -P "$THREADS" -I {} bash -c 'process_url "$@"' _ {}

echo "Done! Results are in $OUTPUT"