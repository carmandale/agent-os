#!/bin/bash

# Test script for testing-enforcer.sh

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the testing enforcer
source "$HOOKS_DIR/lib/testing-enforcer.sh"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Test function
run_test() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
    fi
}

echo "=== Testing testing-enforcer.sh ==="
echo

# Test completion claim detection
echo "Testing completion claim detection:"

# Should detect completion claims
contains_completion_claim "The feature is complete" && result="true" || result="false"
run_test "Detects 'complete'" "true" "$result"

contains_completion_claim "✅ FINISHED implementing the feature" && result="true" || result="false"
run_test "Detects '✅ FINISHED'" "true" "$result"

contains_completion_claim "The work is done and ready" && result="true" || result="false"
run_test "Detects 'done and ready'" "true" "$result"

# Should not detect non-completion messages
contains_completion_claim "I will implement this feature" && result="true" || result="false"
run_test "No false positive on future tense" "false" "$result"

echo

# Test evidence detection
echo "Testing evidence detection:"

# Should detect testing evidence
contains_testing_evidence "All tests passing ✓" && result="true" || result="false"
run_test "Detects 'tests passing'" "true" "$result"

contains_testing_evidence "Ran npm test and verified" && result="true" || result="false"
run_test "Detects 'npm test'" "true" "$result"

contains_testing_evidence "Tested in browser locally" && result="true" || result="false"
run_test "Detects browser testing" "true" "$result"

# Should not detect non-evidence
contains_testing_evidence "I will test this later" && result="true" || result="false"
run_test "No false positive on future testing" "false" "$result"

echo

# Test work type detection
echo "Testing work type detection:"

work_type=$(detect_work_type "Updated React component")
run_test "Detects frontend work" "frontend" "$work_type"

work_type=$(detect_work_type "Fixed API endpoint")
run_test "Detects backend work" "backend" "$work_type"

work_type=$(detect_work_type "Created bash script")
run_test "Detects script work" "script" "$work_type"

echo

# Test requires_testing_evidence
echo "Testing completion without evidence detection:"

requires_testing_evidence "Feature is complete and working" && result="true" || result="false"
run_test "Flags completion without evidence" "true" "$result"

requires_testing_evidence "Feature is complete. Ran all tests and they pass." && result="true" || result="false"
run_test "Allows completion with evidence" "false" "$result"

requires_testing_evidence "Working on the implementation" && result="true" || result="false"
run_test "Ignores non-completion messages" "false" "$result"

echo
echo "=== Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"

if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
fi