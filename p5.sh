#!/usr/bin/env bash
# find_urls.sh — High-performance URL extractor from an external request
# This script fetches content from a given URL (default: https://ondo.finance),
# extracts all unique URLs from the response using ripgrep (if installed) or grep,
# and writes the results (with a timestamp) to both the terminal and a timestamped file.
#
# Usage:
#   chmod +x find_urls.sh
#   ./find_urls.sh [external_url]
#
# Example:
#   ./find_urls.sh https://ondo.finance

set -euo pipefail

# Use the provided URL or default to https://ondo.finance
EXTERNAL_URL="${1:-https://ondo.finance}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT="extracted_urls_${TIMESTAMP}.txt"

echo "Fetching content from: $EXTERNAL_URL"

# Fetch content and extract URLs using ripgrep for performance if available,
# otherwise fallback to grep.
if command -v rg >/dev/null 2>&1; then
    curl -s "$EXTERNAL_URL" | rg -o '(https?://[^"'\'' >]+)' | sort -u | tee "$OUTPUT"
else
    curl -s "$EXTERNAL_URL" | grep -Eo '(https?://[^"'\'' >]+)' | sort -u | tee "$OUTPUT"
fi

echo "Extracted URLs saved to $OUTPUT"
