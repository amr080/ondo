#!/bin/bash

echo "Finding API endpoints..."
echo "----------------------"

# Search for direct API routes
find . -type f -exec grep -H "\/api\/" {} \; | grep -v "node_modules" > api_endpoints.txt

# Search for route definitions
find . -type f -name "*.js" -o -name "*.ts" | xargs grep -l "router\." >> api_endpoints.txt

# Search for IP compliance specific endpoints
find . -type f -exec grep -H "ipcomply" {} \; >> api_endpoints.txt

# Format and display unique endpoints
sort api_endpoints.txt | uniq | grep -oE '\/api\/[a-zA-Z0-9\/_-]+' | sort -u

echo "----------------------"
echo "Results saved to api_endpoints.txt"
