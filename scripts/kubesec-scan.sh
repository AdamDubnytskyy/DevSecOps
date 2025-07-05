#!/bin/bash

# kubesec-scan.sh - Scan Kubernetes manifests for critical security issues
# Usage: ./kubesec-scan.sh [directory]

set -euo pipefail

SCAN_DIR="${1:-.}"
CRITICAL_FOUND=false
TEMP_REPORT=$(mktemp)
EXIT_CODE=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Starting kubesec scan in directory: $SCAN_DIR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if kubesec is installed
if ! command -v kubesec &> /dev/null; then
    echo -e "${RED}❌ Error: kubesec is not installed or not in PATH${NC}"
    echo "Please install kubesec: https://github.com/controlplaneio/kubesec"
    exit 1
fi

# Check if directory exists
if [[ ! -d "$SCAN_DIR" ]]; then
    echo -e "${RED}❌ Error: Directory '$SCAN_DIR' does not exist${NC}"
    exit 1
fi

# Find all YAML files
YAML_FILES=$(find "$SCAN_DIR" -name "*.yml" -o -name "*.yaml" 2>/dev/null)

if [[ -z "$YAML_FILES" ]]; then
    echo -e "${YELLOW}⚠️  No YAML files found in $SCAN_DIR${NC}"
    exit 0
fi

echo "Found $(echo "$YAML_FILES" | wc -l) YAML file(s) to scan"
echo

# Process each YAML file
while IFS= read -r file; do
    echo "📄 Scanning: $file"
    
    # Run kubesec scan and capture output
    if kubesec scan "$file" > "$TEMP_REPORT" 2>/dev/null; then
        # Check if the report contains critical items
        CRITICAL_COUNT=$(jq -r '.[].scoring.critical // [] | length' "$TEMP_REPORT" 2>/dev/null || echo "0")
        
        if [[ "$CRITICAL_COUNT" -gt 0 ]]; then
            CRITICAL_FOUND=true
            echo -e "${RED}❌ CRITICAL ISSUES FOUND: $CRITICAL_COUNT${NC}"
            
            # Display critical issues
            echo "   Critical issues:"
            jq -r '.[].scoring.critical[]? | "   • \(.id): \(.reason) (Points: \(.points))"' "$TEMP_REPORT" 2>/dev/null || echo "   • Failed to parse critical issues"
            
            # Show overall score
            SCORE=$(jq -r '.[].score // "unknown"' "$TEMP_REPORT" 2>/dev/null)
            echo -e "   Score: ${RED}$SCORE${NC}"
            
        else
            echo -e "${GREEN}✅ No critical issues found${NC}"
            SCORE=$(jq -r '.[].score // "unknown"' "$TEMP_REPORT" 2>/dev/null)
            echo "   Score: $SCORE"
        fi
    else
        echo -e "${RED}❌ Failed to scan $file${NC}"
        EXIT_CODE=1
    fi
    
    echo
done <<< "$YAML_FILES"

# Cleanup
rm -f "$TEMP_REPORT"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Final summary
if [[ "$CRITICAL_FOUND" == true ]]; then
    echo -e "${RED}🚨 SCAN FAILED: Critical security issues found!${NC}"
    echo "Please review and fix the critical issues above."
    exit 1
else
    echo -e "${GREEN}✅ SCAN PASSED: No critical security issues found${NC}"
    exit $EXIT_CODE
fi