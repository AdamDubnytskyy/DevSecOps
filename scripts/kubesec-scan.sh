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
        echo -e "${GREEN} There are no critical issues."
    fi
    
done <<< "$YAML_FILES"

# Cleanup
rm -f "$TEMP_REPORT"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -e "${GREEN}✅ SCAN PASSED: No critical security issues found${NC}"
exit $EXIT_CODE
