#!/bin/bash
# ------------------------------------------------------------------------------
# find-all-endpoints.sh
#
# This script recursively searches the codebase for endpoints in common code file
# types. It detects both absolute endpoints (starting with "http://" or "https://")
# and relative endpoints (starting with "/"). It then writes a sorted, unique list
# of endpoints into a file whose name includes a timestamp.
#
# For maximum performance the script uses ripgrep (rg) if available. Otherwise, it
# falls back to grep -R.
#
# Usage:
#   chmod +x find-all-endpoints.sh
#   ./find-all-endpoints.sh
# ------------------------------------------------------------------------------
 
# Get current timestamp (format: YYYYMMDD_HHMMSS) and set output file name.
timestamp=$(date +%Y%m%d_%H%M%S)
output_file="endpoints_${timestamp}.txt"

echo "Searching for endpoints in the codebase..."
echo "Results will be saved to: ${output_file}"

# ------------------------------------------------------------------------------
# Define a regex pattern that matches:
#
# 1. Absolute endpoints: "http://" or "https://" followed by any non-whitespace
#    characters (stopping at whitespace, quotes, or angle brackets).
#
# 2. Relative endpoints: a "/" followed by one or more characters that are common
#    in URL paths (letters, digits, underscore, hyphen, question mark, equals, ampersand,
#    period, percent, or colon).
# ------------------------------------------------------------------------------
pattern='(https?:\/\/[^[:space:]"<>]+)|(\/[a-zA-Z0-9/_\-\?=&\.%:]+)'

# ------------------------------------------------------------------------------
# Use ripgrep if available, otherwise fall back to grep.
#
# - When using ripgrep:
#    --no-heading: do not print file names.
#    --color=never: disable color codes.
#    -o: print only matching parts.
#    -g '!node_modules' etc.: exclude common directories.
#    -t js/ts/jsx/tsx/vue/svelte: restrict search to common code file types.
# ------------------------------------------------------------------------------
if command -v rg >/dev/null 2>&1; then
    echo "Using ripgrep (rg) for high-performance search."
    rg --no-heading --color=never -o \
       -g '!node_modules' -g '!.git' -g '!dist' \
       -t js -t ts -t jsx -t tsx -t vue -t svelte \
       "$pattern" . | sort -u > "$output_file"
else
    echo "Ripgrep not found, falling back to grep -R (this may be slower)."
    grep -R --exclude-dir={node_modules,.git,dist} -Eo "$pattern" . \
       | sort -u > "$output_file"
fi

echo "Done! Endpoints have been saved to ${output_file}"