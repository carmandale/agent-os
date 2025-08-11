#!/bin/bash

# run-tests.sh
# Test runner for Agent OS hooks system

set -e

# Get the directory paths
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$TESTS_DIR")"

# Source test utilities for colors
source "$TESTS_DIR/test-utilities.sh"

# Configuration
VERBOSE=false
CLEANUP=true
SPECIFIC_TEST=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --no-cleanup)
            CLEANUP=false
            shift
            ;;
        -t|--test)
            SPECIFIC_TEST="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose     Enable verbose output"
            echo "  --no-cleanup      Don't cleanup test files"
            echo "  -t, --test NAME   Run specific test suite"
            echo "  -h, --help        Show this help message"
            echo ""
            echo "Available test suites:"
            echo "  workflow-detector - Test workflow detection utilities"
            echo "  git-utils         - Test git operation utilities"
            echo "  hook-integration  - Test complete hook integration"
            echo "  bash-hooks        - Test Bash observation hooks"
            echo "  all               - Run all tests (default)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to run a test suite
run_test_suite() {
    local test_name="$1"
    local test_script="$2"
    
    if [ ! -f "$test_script" ]; then
        echo -e "${RED}❌ Test script not found: $test_script${NC}"
        return 1
    fi
    
    if [ ! -x "$test_script" ]; then
        chmod +x "$test_script"
    fi
    
    echo -e "${YELLOW}🚀 Running $test_name${NC}"
    echo "----------------------------------------"
    
    if [ "$VERBOSE" = true ]; then
        "$test_script"
    else
        "$test_script" 2>/dev/null
    fi
    
    local result=$?
    
    if [ $result -eq 0 ]; then
        echo -e "${GREEN}✅ $test_name completed successfully${NC}"
    else
        echo -e "${RED}❌ $test_name failed${NC}"
    fi
    
    echo ""
    return $result
}

# Function to setup test environment
setup_test_environment() {
    echo -e "${YELLOW}🔧 Setting up test environment${NC}"
    echo "======================================"
    
    # Make all test scripts executable
    chmod +x "$TESTS_DIR"/*.sh
    
    # Create log directory for testing
    mkdir -p "$HOME/.agent-os/logs"
    
    # Verify hook scripts are executable
    chmod +x "$HOOKS_DIR"/*.sh
    chmod +x "$HOOKS_DIR/lib"/*.sh
    
    echo "✅ Test environment ready"
    echo ""
}

# Function to cleanup test environment
cleanup_test_environment() {
    if [ "$CLEANUP" = false ]; then
        return 0
    fi
    
    echo -e "${YELLOW}🧹 Cleaning up test environment${NC}"
    echo "=================================="
    
    # Remove any test repositories that might be left over
    find /tmp -maxdepth 1 -name "agent-os-*-test-*" -type d 2>/dev/null | while read -r dir; do
        if [ -d "$dir" ]; then
            echo "  Removing $dir"
            rm -rf "$dir"
        fi
    done
    
    echo "✅ Cleanup completed"
    echo ""
}

# Function to display test summary
display_summary() {
    local total_suites="$1"
    local failed_suites="$2"
    local passed_suites=$((total_suites - failed_suites))
    
    echo "🏁 TEST SUMMARY"
    echo "==============="
    echo ""
    echo -e "Total test suites: $total_suites"
    echo -e "${GREEN}Passed: $passed_suites${NC}"
    echo -e "${RED}Failed: $failed_suites${NC}"
    echo ""
    
    if [ "$failed_suites" -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed! The hooks system is working correctly.${NC}"
        echo ""
        echo "Next steps:"
        echo "• Install hooks with: $HOOKS_DIR/install-hooks.sh"
        echo "• Verify installation with Claude Code"
        echo "• Test in an Agent OS project"
    else
        echo -e "${RED}❌ Some tests failed. Please review the output above.${NC}"
        echo ""
        echo "Troubleshooting:"
        echo "• Run with -v flag for verbose output"
        echo "• Check individual test suites with -t flag"
        echo "• Verify hook scripts are properly executable"
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}🧪 Agent OS Hooks Test Suite${NC}"
    echo "============================="
    echo ""
    
    # Setup
    setup_test_environment
    
    # Test suites to run
    local test_suites=()
    local failed_count=0
    
    case "${SPECIFIC_TEST:-all}" in
        "workflow-detector")
            test_suites=("workflow-detector:$TESTS_DIR/test-workflow-detector.sh")
            ;;
        "git-utils")
            test_suites=("git-utils:$TESTS_DIR/test-git-utils.sh")
            ;;
        "hook-integration")
            test_suites=("hook-integration:$TESTS_DIR/test-hook-integration.sh")
            ;;
        "all"|*)
            test_suites=(
                "workflow-detector:$TESTS_DIR/test-workflow-detector.sh"
                "git-utils:$TESTS_DIR/test-git-utils.sh"
                "hook-integration:$TESTS_DIR/test-hook-integration.sh"
            )
            ;;
    esac
    
    # Run test suites
    for suite in "${test_suites[@]}"; do
        local name="${suite%%:*}"
        local script="${suite##*:}"
        
        if run_test_suite "$name" "$script"; then
            echo -e "${GREEN}✓${NC} $name passed"
        else
            echo -e "${RED}✗${NC} $name failed"
            ((failed_count++))
        fi
        echo ""
    done
    
    # Cleanup
    cleanup_test_environment
    
    # Display summary
    display_summary "${#test_suites[@]}" "$failed_count"
    
    # Exit with failure if any tests failed
    if [ "$failed_count" -gt 0 ]; then
        exit 1
    fi
    
    exit 0
}

# Run main function
main "$@"