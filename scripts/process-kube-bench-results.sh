#!/bin/bash

#
# Kube-bench Results Processor
# Processes kube-bench CIS benchmark results and generates human-readable reports
#
# Usage: ./process-kube-bench-results.sh [input_file] [output_dir]
#
# Author: Security Team
# Version: 1.0
#

set -euo pipefail

# Default values
INPUT_FILE="${1:-kube-bench-raw-output.txt}"
OUTPUT_DIR="${2:-.}"
SUMMARY_FILE="$OUTPUT_DIR/kube-bench-summary.txt"
REPORT_FILE="$OUTPUT_DIR/kube-bench-report.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${CYAN}$1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

print_info() {
    echo -e "${BLUE}$1${NC}"
}

# Function to validate input
validate_input() {
    if [ ! -f "$INPUT_FILE" ]; then
        print_error "❌ Error: Input file '$INPUT_FILE' not found"
        print_info "Usage: $0 [input_file] [output_dir]"
        print_info "Example: $0 kube-bench-raw-output.txt ./reports"
        exit 1
    fi

    if [ ! -s "$INPUT_FILE" ]; then
        print_error "❌ Error: Input file '$INPUT_FILE' is empty"
        exit 1
    fi

    # Create output directory if it doesn't exist
    mkdir -p "$OUTPUT_DIR"
    
    print_success "✅ Input file validated: $INPUT_FILE"
    print_info "📁 Output directory: $OUTPUT_DIR"
}

# Function to extract metrics from kube-bench output
extract_metrics() {
    print_info "📊 Extracting metrics from kube-bench results..."
    
    # Extract summary totals (from the "Summary total" section)
    PASS=$(grep "checks PASS" "$INPUT_FILE" | tail -1 | grep -o '[0-9]\+' | head -1 || echo "0")
    FAIL=$(grep "checks FAIL" "$INPUT_FILE" | tail -1 | grep -o '[0-9]\+' | head -1 || echo "0")
    WARN=$(grep "checks WARN" "$INPUT_FILE" | tail -1 | grep -o '[0-9]\+' | head -1 || echo "0")
    INFO=$(grep "checks INFO" "$INPUT_FILE" | tail -1 | grep -o '[0-9]\+' | head -1 || echo "0")
    
    # Calculate totals
    TOTAL=$((PASS + FAIL + WARN + INFO))
    
    if [ $TOTAL -eq 0 ]; then
        print_error "❌ Error: No valid metrics found in input file"
        print_info "Please ensure the input file contains valid kube-bench output"
        exit 1
    fi
    
    # Calculate pass rate
    PASS_RATE=$(echo "scale=1; $PASS * 100 / $TOTAL" | bc -l 2>/dev/null || echo "0")
    
    print_success "✅ Metrics extracted successfully"
    print_info "   PASS: $PASS, FAIL: $FAIL, WARN: $WARN, INFO: $INFO"
    print_info "   Total: $TOTAL, Pass Rate: ${PASS_RATE}%"
}

# Function to extract category breakdown
extract_categories() {
    print_info "📋 Extracting category breakdown..."
    
    # Count by major categories
    CONTROL_PLANE_PASS=$(grep "^\[PASS\] 1\." "$INPUT_FILE" | wc -l || echo "0")
    CONTROL_PLANE_FAIL=$(grep "^\[FAIL\] 1\." "$INPUT_FILE" | wc -l || echo "0")
    CONTROL_PLANE_WARN=$(grep "^\[WARN\] 1\." "$INPUT_FILE" | wc -l || echo "0")
    
    ETCD_PASS=$(grep "^\[PASS\] 2\." "$INPUT_FILE" | wc -l || echo "0")
    ETCD_FAIL=$(grep "^\[FAIL\] 2\." "$INPUT_FILE" | wc -l || echo "0")
    ETCD_WARN=$(grep "^\[WARN\] 2\." "$INPUT_FILE" | wc -l || echo "0")
    
    WORKER_PASS=$(grep "^\[PASS\] 3\." "$INPUT_FILE" | wc -l || echo "0")
    WORKER_FAIL=$(grep "^\[FAIL\] 3\." "$INPUT_FILE" | wc -l || echo "0")
    WORKER_WARN=$(grep "^\[WARN\] 3\." "$INPUT_FILE" | wc -l || echo "0")
    
    POLICIES_PASS=$(grep "^\[PASS\] 5\." "$INPUT_FILE" | wc -l || echo "0")
    POLICIES_FAIL=$(grep "^\[FAIL\] 5\." "$INPUT_FILE" | wc -l || echo "0")
    POLICIES_WARN=$(grep "^\[WARN\] 5\." "$INPUT_FILE" | wc -l || echo "0")
    
    print_success "✅ Category breakdown extracted"
}

# Function to get security rating
get_security_rating() {
    if (( $(echo "$PASS_RATE >= 90" | bc -l) )); then
        RATING="🟢 EXCELLENT"
        RATING_DESC="Outstanding security posture"
    elif (( $(echo "$PASS_RATE >= 75" | bc -l) )); then
        RATING="🟡 GOOD"
        RATING_DESC="Strong security with minor improvements needed"
    elif (( $(echo "$PASS_RATE >= 50" | bc -l) )); then
        RATING="🟠 MODERATE"
        RATING_DESC="Significant security improvements required"
    else
        RATING="🔴 CRITICAL"
        RATING_DESC="Immediate security action required"
    fi
}

# Function to generate visual progress bar
generate_progress_bar() {
    local percentage=$1
    local width=20
    local filled=$(echo "scale=0; $percentage / 5" | bc -l 2>/dev/null || echo "0")
    
    printf "["
    for i in $(seq 1 $width); do
        if [ $i -le $filled ]; then
            printf "█"
        else
            printf "░"
        fi
    done
    printf "] ${percentage}%%"
}

# Function to display console report
display_console_report() {
    print_header "🏛️ =================================================================="
    print_header "🏛️                    KUBE-BENCH CIS SECURITY REPORT                "
    print_header "🏛️ =================================================================="
    echo
    
    print_header "📊 EXECUTIVE SUMMARY"
    echo "┌─────────────────────────────────────────────────────────────────────┐"
    echo "│                          SECURITY OVERVIEW                         │"
    echo "├─────────────────────────────────────────────────────────────────────┤"
    echo "│                                                                     │"
    printf "│  ✅ PASSED: %-3d    ❌ FAILED: %-3d    ⚠️  WARNINGS: %-3d    ℹ️  INFO: %-3d │\n" $PASS $FAIL $WARN $INFO
    echo "│                                                                     │"
    printf "│  🎯 SECURITY SCORE: %-4s%%    📊 TOTAL CHECKS: %-3d                    │\n" $PASS_RATE $TOTAL
    echo "│                                                                     │"
    echo "└─────────────────────────────────────────────────────────────────────┘"
    
    # Security rating
    echo
    print_header "🏆 SECURITY RATING"
    echo "━━━━━━━━━━━━━━━━━━━━"
    echo "$RATING (${PASS_RATE}%) - $RATING_DESC"
    
    echo
    print_header "🚨 CRITICAL SECURITY ISSUES ($FAIL Failed Checks)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Extract and display failed checks
    if [ $FAIL -gt 0 ]; then
        grep "\[FAIL\]" "$INPUT_FILE" | head -10 | while read -r line; do
            CHECK_ID=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
            CHECK_DESC=$(echo "$line" | sed 's/.*\] [0-9]\+\.[0-9]\+\.[0-9]\+ //')
            print_error "❌ $CHECK_ID: $CHECK_DESC"
        done
    else
        print_success "🎉 No critical failures found!"
    fi
    
    echo
    print_header "⚠️  SECURITY WARNINGS ($WARN Warning Checks)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Extract and display warning checks (show first 5)
    if [ $WARN -gt 0 ]; then
        grep "\[WARN\]" "$INPUT_FILE" | head -5 | while read -r line; do
            CHECK_ID=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
            CHECK_DESC=$(echo "$line" | sed 's/.*\] [0-9]\+\.[0-9]\+\.[0-9]\+ //')
            print_warning "⚠️  $CHECK_ID: $CHECK_DESC"
        done
        
        if [ $WARN -gt 5 ]; then
            print_info "... and $((WARN - 5)) more warnings (see full report)"
        fi
    else
        print_success "🎉 No warnings found!"
    fi
    
    echo
    print_header "📋 CATEGORY BREAKDOWN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━"
    
    echo "┌─────────────────────────┬──────┬──────┬──────┬───────┐"
    echo "│        Category         │ Pass │ Fail │ Warn │ Total │"
    echo "├─────────────────────────┼──────┼──────┼──────┼───────┤"
    printf "│ 🏛️  Control Plane        │ %4d │ %4d │ %4d │ %5d │\n" $CONTROL_PLANE_PASS $CONTROL_PLANE_FAIL $CONTROL_PLANE_WARN $((CONTROL_PLANE_PASS + CONTROL_PLANE_FAIL + CONTROL_PLANE_WARN))
    printf "│ 💾 etcd                  │ %4d │ %4d │ %4d │ %5d │\n" $ETCD_PASS $ETCD_FAIL $ETCD_WARN $((ETCD_PASS + ETCD_FAIL + ETCD_WARN))
    printf "│ 👷 Worker Nodes          │ %4d │ %4d │ %4d │ %5d │\n" $WORKER_PASS $WORKER_FAIL $WORKER_WARN $((WORKER_PASS + WORKER_FAIL + WORKER_WARN))
    printf "│ 📋 Policies              │ %4d │ %4d │ %4d │ %5d │\n" $POLICIES_PASS $POLICIES_FAIL $POLICIES_WARN $((POLICIES_PASS + POLICIES_FAIL + POLICIES_WARN))
    echo "└─────────────────────────┴──────┴──────┴──────┴───────┘"
    
    echo
    print_header "🎯 PRIORITY ACTION PLAN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "┌─────┬─────────────────────────────────────────────────────────────────┐"
    echo "│ Pri │                            Action                              │"
    echo "├─────┼─────────────────────────────────────────────────────────────────┤"
    echo "│ 🔴 1│ FIX $FAIL CRITICAL FAILURES - Security gaps requiring immediate │"
    echo "│     │ attention (API server, etcd, controller manager configuration)  │"
    echo "├─────┼─────────────────────────────────────────────────────────────────┤"
    echo "│ 🟡 2│ REVIEW $WARN WARNINGS - Implement based on security requirements │"
    echo "│     │ (Network policies, admission plugins, encryption)              │"
    echo "├─────┼─────────────────────────────────────────────────────────────────┤"
    echo "│ 🔵 3│ IMPLEMENT comprehensive security policies and monitoring        │"
    echo "├─────┼─────────────────────────────────────────────────────────────────┤"
    echo "│ 🟢 4│ ESTABLISH regular security scanning and compliance reviews      │"
    echo "└─────┴─────────────────────────────────────────────────────────────────┘"
    
    echo
    print_header "📈 PROGRESS TRACKING"
    echo "━━━━━━━━━━━━━━━━━━━━━━"
    
    # Visual progress bar
    printf "Security Progress: "
    generate_progress_bar $PASS_RATE
    echo
    
    echo
    print_header "🔗 NEXT STEPS"
    echo "━━━━━━━━━━━━━━━"
    echo "1. 📋 Review detailed remediation guide in full report"
    echo "2. 🔧 Implement critical fixes (priority 1 items)"
    echo "3. 📊 Re-run kube-bench to verify improvements"
    echo "4. 🔄 Integrate kube-bench into CI/CD pipeline"
    echo "5. 📈 Monitor security posture continuously"
    
    echo
    print_header "🏛️ =================================================================="
    print_info "📄 Reports generated:"
    print_info "   - Console output (above)"
    print_info "   - Summary file: $SUMMARY_FILE"
    print_info "   - Detailed report: $REPORT_FILE"
    print_header "🏛️ =================================================================="
}

# Function to generate summary file
generate_summary_file() {
    print_info "📝 Generating summary file..."
    
    cat > "$SUMMARY_FILE" << EOF
KUBE-BENCH SECURITY SUMMARY
===========================
Generated: $(date)
Input File: $INPUT_FILE

SECURITY SCORE: ${PASS_RATE}%
TOTAL CHECKS: $TOTAL

RESULTS BREAKDOWN:
- ✅ PASS: $PASS
- ❌ FAIL: $FAIL (Critical Issues)
- ⚠️  WARN: $WARN (Recommendations)
- ℹ️  INFO: $INFO

SECURITY RATING: $RATING_DESC

CATEGORY BREAKDOWN:
- Control Plane: $CONTROL_PLANE_PASS pass, $CONTROL_PLANE_FAIL fail, $CONTROL_PLANE_WARN warn
- etcd: $ETCD_PASS pass, $ETCD_FAIL fail, $ETCD_WARN warn
- Worker Nodes: $WORKER_PASS pass, $WORKER_FAIL fail, $WORKER_WARN warn
- Policies: $POLICIES_PASS pass, $POLICIES_FAIL fail, $POLICIES_WARN warn

IMMEDIATE ACTIONS REQUIRED:
1. Fix $FAIL critical security failures
2. Review $WARN security warnings
3. Implement comprehensive security policies
4. Establish regular security scanning

NEXT STEPS:
- Review detailed report: $REPORT_FILE
- Implement priority 1 fixes immediately
- Schedule security policy review
- Set up continuous monitoring
EOF
    
    print_success "✅ Summary file generated: $SUMMARY_FILE"
}

# Function to generate detailed markdown report
generate_markdown_report() {
    print_info "📝 Generating detailed markdown report..."
    
    cat > "$REPORT_FILE" << EOF
# Kube-bench CIS Security Report

**Generated:** $(date)  
**Input File:** $INPUT_FILE  
**Security Score:** ${PASS_RATE}%  
**Rating:** $RATING_DESC

## Executive Summary

| Metric | Value | Description |
|--------|-------|-------------|
| **Total Checks** | $TOTAL | Complete CIS benchmark coverage |
| **Security Score** | ${PASS_RATE}% | Overall security compliance |
| **Pass Rate** | $PASS/$TOTAL | Successfully implemented controls |
| **Critical Issues** | $FAIL | Immediate attention required |
| **Recommendations** | $WARN | Security improvements suggested |

## Security Rating

**$RATING ($PASS_RATE%)**  
$RATING_DESC

## Results Breakdown

### Summary
- ✅ **PASS**: $PASS checks passed
- ❌ **FAIL**: $FAIL critical security issues
- ⚠️ **WARN**: $WARN security recommendations  
- ℹ️ **INFO**: $INFO informational items

### Category Analysis

| Category | Pass | Fail | Warn | Total | Pass Rate |
|----------|------|------|------|-------|-----------|
| 🏛️ Control Plane | $CONTROL_PLANE_PASS | $CONTROL_PLANE_FAIL | $CONTROL_PLANE_WARN | $((CONTROL_PLANE_PASS + CONTROL_PLANE_FAIL + CONTROL_PLANE_WARN)) | $(echo "scale=1; $CONTROL_PLANE_PASS * 100 / $((CONTROL_PLANE_PASS + CONTROL_PLANE_FAIL + CONTROL_PLANE_WARN + 1))" | bc -l)% |
| 💾 etcd | $ETCD_PASS | $ETCD_FAIL | $ETCD_WARN | $((ETCD_PASS + ETCD_FAIL + ETCD_WARN)) | $(echo "scale=1; $ETCD_PASS * 100 / $((ETCD_PASS + ETCD_FAIL + ETCD_WARN + 1))" | bc -l)% |
| 👷 Worker Nodes | $WORKER_PASS | $WORKER_FAIL | $WORKER_WARN | $((WORKER_PASS + WORKER_FAIL + WORKER_WARN)) | $(echo "scale=1; $WORKER_PASS * 100 / $((WORKER_PASS + WORKER_FAIL + WORKER_WARN + 1))" | bc -l)% |
| 📋 Policies | $POLICIES_PASS | $POLICIES_FAIL | $POLICIES_WARN | $((POLICIES_PASS + POLICIES_FAIL + POLICIES_WARN)) | $(echo "scale=1; $POLICIES_PASS * 100 / $((POLICIES_PASS + POLICIES_FAIL + POLICIES_WARN + 1))" | bc -l)% |

## Critical Security Issues

> **⚠️ URGENT:** $FAIL critical security issues require immediate remediation

EOF

    # Add failed checks to markdown
    if [ $FAIL -gt 0 ]; then
        echo "### Failed Checks" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        grep "\[FAIL\]" "$INPUT_FILE" | while read -r line; do
            CHECK_ID=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
            CHECK_DESC=$(echo "$line" | sed 's/.*\] [0-9]\+\.[0-9]\+\.[0-9]\+ //')
            echo "- **$CHECK_ID**: $CHECK_DESC" >> "$REPORT_FILE"
        done
    else
        echo "🎉 **No critical failures found!**" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << EOF

## Security Recommendations

> **📋 REVIEW:** $WARN security recommendations should be evaluated

EOF

    # Add warning checks to markdown
    if [ $WARN -gt 0 ]; then
        echo "### Warning Checks" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        
        grep "\[WARN\]" "$INPUT_FILE" | head -10 | while read -r line; do
            CHECK_ID=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
            CHECK_DESC=$(echo "$line" | sed 's/.*\] [0-9]\+\.[0-9]\+\.[0-9]\+ //')
            echo "- **$CHECK_ID**: $CHECK_DESC" >> "$REPORT_FILE"
        done
        
        if [ $WARN -gt 10 ]; then
            echo "" >> "$REPORT_FILE"
            echo "_... and $((WARN - 10)) more warnings in full kube-bench output_" >> "$REPORT_FILE"
        fi
    else
        echo "🎉 **No warnings found!**" >> "$REPORT_FILE"
    fi
    
    cat >> "$REPORT_FILE" << EOF

## Action Plan

### Priority 1: Critical Fixes (Immediate)
- [ ] Review and fix all $FAIL critical failures
- [ ] Focus on API server, etcd, and controller manager configurations
- [ ] Implement missing security controls

### Priority 2: Security Improvements (Short-term)
- [ ] Address $WARN security warnings
- [ ] Implement recommended admission plugins
- [ ] Configure audit logging and monitoring

### Priority 3: Comprehensive Security (Medium-term)
- [ ] Implement Pod Security Standards
- [ ] Configure network policies
- [ ] Set up secret management
- [ ] Enable encryption at rest

### Priority 4: Continuous Monitoring (Long-term)
- [ ] Integrate kube-bench into CI/CD pipeline
- [ ] Set up regular security scanning
- [ ] Implement security metrics and alerting
- [ ] Conduct regular security reviews

## Next Steps

1. **Review this report** with your security team
2. **Prioritize fixes** based on your environment
3. **Implement critical fixes** immediately
4. **Re-run kube-bench** to verify improvements
5. **Set up monitoring** for continuous compliance

## Resources

- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Kubernetes Hardening Guide](https://kubernetes.io/docs/concepts/security/hardening-guide/)

---

*Report generated by kube-bench-processor v1.0*
EOF
    
    print_success "✅ Detailed markdown report generated: $REPORT_FILE"
}

# Main function
main() {
    print_header "🚀 Starting Kube-bench Results Processing"
    print_info "📋 Input: $INPUT_FILE"
    print_info "📁 Output: $OUTPUT_DIR"
    echo
    
    # Validate input and setup
    validate_input
    
    # Extract metrics and categories
    extract_metrics
    extract_categories
    
    # Get security rating
    get_security_rating
    
    # Generate outputs
    display_console_report
    generate_summary_file
    generate_markdown_report
    
    print_success "✅ Processing completed successfully!"
    print_info "📊 Generated files:"
    print_info "   - $SUMMARY_FILE (text summary)"
    print_info "   - $REPORT_FILE (detailed markdown report)"
    
    # Return exit code based on critical failures
    if [ $FAIL -gt 0 ]; then
        print_warning "⚠️  Exiting with code 1 due to $FAIL critical security failures"
        exit 1
    else
        print_success "🎉 No critical failures found!"
        exit 0
    fi
}

# Run main function
main "$@"