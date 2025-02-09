#!/bin/bash
# Follow Endpoints to Their Source File
# This script reads a combined endpoints file (default: the most recent api_endpoints_*.txt)
# and for each endpoint (starting with "/api/") it searches for matching source files in the
# ./api folder. The results are written to a timestamped report.
#
# Usage:
#   ./follow-endpoints.sh [endpoints_file]
# If no endpoints file is provided, the script will use the most recent api_endpoints_*.txt.

set -e

# ------------------------------------------------------------------------------
# Determine endpoints file to use
# ------------------------------------------------------------------------------
if [ -n "$1" ]; then
    ENDPOINTS_FILE="$1"
elif ls api_endpoints_*.txt 1> /dev/null 2>&1; then
    # pick the most recent one
    ENDPOINTS_FILE=$(ls -t api_endpoints_*.txt | head -n 1)
else
    echo "No endpoints file provided or found."
    exit 1
fi

echo "Using endpoints file: $ENDPOINTS_FILE"

# ------------------------------------------------------------------------------
# Build a list of API source files in the ./api directory
# ------------------------------------------------------------------------------
API_DIR="./api"
if [ ! -d "$API_DIR" ]; then
    echo "No ./api directory found, cannot follow endpoints to source."
    exit 1
fi

echo "Building list of API source files in $API_DIR ..."
mapfile -t api_files < <(find "$API_DIR" -type f)

# ------------------------------------------------------------------------------
# Output file for followed endpoints
# ------------------------------------------------------------------------------
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FOLLOW_FILE="followed_endpoints_${TIMESTAMP}.txt"
{
  echo "Followed Endpoints Report - Generated on $(date)"
  echo "------------------------------------------------------------"
} > "$FOLLOW_FILE"

# ------------------------------------------------------------------------------
# Helper function: escape regex special characters
# ------------------------------------------------------------------------------
escape_regex() {
    sed -e 's/[]\/$*.^|[]/\\&/g' <<< "$1"
}

# ------------------------------------------------------------------------------
# Process each endpoint from the endpoints file
# ------------------------------------------------------------------------------
while IFS= read -r endpoint; do
    # Skip empty lines
    [ -z "$endpoint" ] && continue

    echo "Endpoint: $endpoint" >> "$FOLLOW_FILE"
    # Only process endpoints starting with "/api/"
    if [[ $endpoint != /api/* ]]; then
        echo "  Not an API endpoint. Skipping." >> "$FOLLOW_FILE"
        echo "" >> "$FOLLOW_FILE"
        continue
    fi

    # Remove leading "/api/" to get the relative path
    subpath="${endpoint#/api/}"
    # Escape subpath for regex usage
    esc_subpath=$(escape_regex "$subpath")
    # Build a regex to match file paths in the API directory that start with this subpath.
    # For example, endpoint "/api/auth" → regex "^./api/auth($|/)"
    regex="^${API_DIR}/$esc_subpath(\$|/)"

    found=false
    for file in "${api_files[@]}"; do
        if [[ $file =~ $regex ]]; then
            echo "  Source: $file" >> "$FOLLOW_FILE"
            found=true
        fi
    done

    if ! $found; then
        echo "  Source not found." >> "$FOLLOW_FILE"
    fi

    echo "" >> "$FOLLOW_FILE"
done < "$ENDPOINTS_FILE"

echo "Followed endpoints report generated: $FOLLOW_FILE"