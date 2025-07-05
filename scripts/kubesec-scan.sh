#!/bin/bash

# kubesec-scan.sh - Scan Kubernetes manifests for critical security issues
# Usage: .scripts/kubesec-scan.sh [directory]

set -e

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

# Scan each YAML file
while IFS= read -r file; do
    echo "📄 Scanning: $file"
    
    CRITICAL_ISSUES=$(kubesec scan "$file" 2>/dev/null | jq -e '.[0].scoring.critical')
    if kubesec scan "$file" | jq -e '.[0].scoring.critical | length > 0'; then
        echo -e "${RED} ❌ $file has critical issues. Please fix listed issues below."
        echo "$CRITICAL_ISSUES" | jq -r '.[] | "• \(.id): \(.reason) (Points: \(.points))"'
        exit 1
    else
        # Check if the report is valid and contains scannable content
        echo [[ -s "$TEMP_REPORT" ]]
        echo jq -e '.[0].valid' "$TEMP_REPORT"
        if [[ -s "$TEMP_REPORT" ]] && jq -e '.[0].valid' "$TEMP_REPORT" >/dev/null 2>&1; then
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
            echo -e "${YELLOW}⚠️  Skipped: Not a supported resource type for scanning${NC}"
        fi
    fi
    
done <<< "$YAML_FILES"

# Cleanup
rm -f "$TEMP_REPORT"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "${GREEN}✅ SCAN PASSED: No critical security issues found${NC}"
exit $EXIT_CODE
