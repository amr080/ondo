#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Enhanced API Endpoint Finder${NC}"
echo "================================"

# Create results directory
mkdir -p ./api_analysis

# Function to search for endpoints
find_endpoints() {
    local pattern="$1"
    local description="$2"
    
    echo -e "\n${GREEN}Searching for $description...${NC}"
    
    # Search and save results
    find . -type f \( -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \) \
        ! -path "./node_modules/*" \
        -exec grep -l "$pattern" {} \; | \
        while read -r file; do
            echo "Found in: $file"
            grep -h "$pattern" "$file" | \
            grep -oE "$pattern[a-zA-Z0-9\/_\-\?=&]+" >> "./api_analysis/$description.txt"
        done
    
    # Show unique endpoints
    if [ -f "./api_analysis/$description.txt" ]; then
        echo -e "\n${BLUE}Unique $description endpoints:${NC}"
        sort -u "./api_analysis/$description.txt"
    fi
}

# Search for different types of endpoints
find_endpoints "/api/" "General API endpoints"
find_endpoints "/api/ipcomply" "IP Compliance endpoints"
find_endpoints "/api/auth" "Auth endpoints"
find_endpoints "restriction_type=" "Restriction endpoints"
find_endpoints "fetch\(" "Fetch calls"
find_endpoints "axios\." "Axios calls"

# Search for test tokens
echo -e "\n${GREEN}Searching for test tokens...${NC}"
grep -r "test" . --include="*.js" --include="*.ts" | grep -i "token" > "./api_analysis/test_tokens.txt"

# Generate summary
echo -e "\n${BLUE}Analysis Summary${NC}"
echo "================="
echo "Results saved in ./api_analysis/"
ls -l ./api_analysis/

# Create markdown report
cat > ./api_analysis/API_ENDPOINTS.md << 'MDEOF'
# API Endpoint Analysis

## Overview
This document contains automatically detected API endpoints and related information.

## Endpoints Found
$(cat ./api_analysis/*.txt)

## Test Tokens
$(cat ./api_analysis/test_tokens.txt)

## Notes
- Some endpoints may require authentication
- Check implementation files for full context
- Verify endpoints manually before use

Generated on: $(date)
MDEOF

echo -e "\n${GREEN}Analysis complete! Check ./api_analysis/API_ENDPOINTS.md for full report${NC}"
