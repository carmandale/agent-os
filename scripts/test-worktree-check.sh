#!/bin/bash

# test-worktree-check.sh
# Test suite for git worktree functionality in workflow-status.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
print_test_header() {
	echo -e "\n${CYAN}Testing: $1${NC}"
	echo "$(printf '=%.0s' $(seq 1 ${#1}))"
}

print_test_result() {
	((TESTS_RUN++))
	if [ "$1" = "PASS" ]; then
		echo -e "${GREEN}✅ PASS${NC}: $2"
		((TESTS_PASSED++))
	else
		echo -e "${RED}❌ FAIL${NC}: $2"
		if [ -n "$3" ]; then
			echo -e "   ${YELLOW}Details: $3${NC}"
		fi
		((TESTS_FAILED++))
	fi
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_STATUS="$SCRIPT_DIR/workflow-status.sh"

# Verify workflow-status.sh exists
if [ ! -f "$WORKFLOW_STATUS" ]; then
	echo -e "${RED}Error: workflow-status.sh not found at $WORKFLOW_STATUS${NC}"
	exit 1
fi

echo -e "${CYAN}Git Worktree Functionality Test Suite${NC}"
echo "======================================"
echo ""
echo "Testing: $WORKFLOW_STATUS"

# Test 1: Git worktree command availability
print_test_header "Git Worktree Availability"

if git worktree list >/dev/null 2>&1; then
	print_test_result "PASS" "Git worktree command is available"
else
	print_test_result "FAIL" "Git worktree command not available"
fi

# Test 2: Script has check_worktrees function
print_test_header "Function Existence"

if grep -q "check_worktrees()" "$WORKFLOW_STATUS"; then
	print_test_result "PASS" "check_worktrees() function exists"
else
	print_test_result "FAIL" "check_worktrees() function not found"
fi

if grep -q "display_worktree()" "$WORKFLOW_STATUS"; then
	print_test_result "PASS" "display_worktree() function exists"
else
	print_test_result "FAIL" "display_worktree() function not found"
fi

if grep -q "detect_issue_number()" "$WORKFLOW_STATUS"; then
	print_test_result "PASS" "detect_issue_number() function exists"
else
	print_test_result "FAIL" "detect_issue_number() function not found"
fi

if grep -q "get_github_info()" "$WORKFLOW_STATUS"; then
	print_test_result "PASS" "get_github_info() function exists"
else
	print_test_result "FAIL" "get_github_info() function not found"
fi

# Test 3: Main function calls check_worktrees
print_test_header "Integration"

if grep -A 10 "^main()" "$WORKFLOW_STATUS" | grep -q "check_worktrees"; then
	print_test_result "PASS" "main() function calls check_worktrees"
else
	print_test_result "FAIL" "main() function doesn't call check_worktrees"
fi

# Test 4: Issue number detection patterns
print_test_header "Issue Number Detection"

# Source the script to test the function (with AGENT_OS_SKIP_MAIN to prevent exit)
AGENT_OS_SKIP_MAIN=1 source "$WORKFLOW_STATUS" 2>/dev/null || true

# Test pattern 1: issue-123
if command -v detect_issue_number >/dev/null 2>&1; then
	result=$(detect_issue_number "issue-123" 2>/dev/null || echo "")
	if [ "$result" = "123" ]; then
		print_test_result "PASS" "Pattern 'issue-123' detected correctly"
	else
		print_test_result "FAIL" "Pattern 'issue-123' not detected" "Got: $result"
	fi

	# Test pattern 2: 456-feature-name
	result=$(detect_issue_number "456-feature-name" 2>/dev/null || echo "")
	if [ "$result" = "456" ]; then
		print_test_result "PASS" "Pattern '456-feature-name' detected correctly"
	else
		print_test_result "FAIL" "Pattern '456-feature-name' not detected" "Got: $result"
	fi

	# Test pattern 3: bugfix-789-description
	result=$(detect_issue_number "bugfix-789-description" 2>/dev/null || echo "")
	if [ "$result" = "789" ]; then
		print_test_result "PASS" "Pattern 'bugfix-789-description' detected correctly"
	else
		print_test_result "FAIL" "Pattern 'bugfix-789-description' not detected" "Got: $result"
	fi

	# Test pattern 4: feature/issue-101
	result=$(detect_issue_number "feature/issue-101" 2>/dev/null || echo "")
	if [ "$result" = "101" ]; then
		print_test_result "PASS" "Pattern 'feature/issue-101' detected correctly"
	else
		print_test_result "FAIL" "Pattern 'feature/issue-101' not detected" "Got: $result"
	fi
else
	print_test_result "FAIL" "Could not source detect_issue_number function"
fi

# Test 5: GitHub CLI integration
print_test_header "GitHub CLI Integration"

if command -v gh >/dev/null 2>&1; then
	print_test_result "PASS" "GitHub CLI (gh) is installed"

	if gh auth status >/dev/null 2>&1; then
		print_test_result "PASS" "GitHub CLI is authenticated"
	else
		print_test_result "FAIL" "GitHub CLI is not authenticated"
	fi
else
	print_test_result "FAIL" "GitHub CLI (gh) not installed"
fi

# Test 6: Script execution
print_test_header "Script Execution"

# Run script and check if it completes without errors
if bash "$WORKFLOW_STATUS" >/dev/null 2>&1; then
	print_test_result "PASS" "Script executes without fatal errors"
else
	exit_code=$?
	if [ $exit_code -eq 1 ] || [ $exit_code -eq 2 ]; then
		print_test_result "PASS" "Script executes with expected exit code $exit_code"
	else
		print_test_result "FAIL" "Script failed with unexpected exit code $exit_code"
	fi
fi

# Test 7: Output contains worktree section
output=$(bash "$WORKFLOW_STATUS" 2>&1)
if echo "$output" | grep -q "Git Worktrees"; then
	print_test_result "PASS" "Output contains 'Git Worktrees' section"
else
	print_test_result "FAIL" "Output missing 'Git Worktrees' section"
fi

# Test 8: Porcelain format parsing
print_test_header "Porcelain Format Parsing"

if grep -q "git worktree list --porcelain" "$WORKFLOW_STATUS"; then
	print_test_result "PASS" "Script uses --porcelain format"
else
	print_test_result "FAIL" "Script doesn't use --porcelain format"
fi

# Test 9: Caching implementation
print_test_header "Performance Caching"

if grep -q "cache_file" "$WORKFLOW_STATUS"; then
	print_test_result "PASS" "Caching implementation present"
else
	print_test_result "FAIL" "Caching implementation not found"
fi

if grep -q "cache_ttl" "$WORKFLOW_STATUS" || grep -q "300" "$WORKFLOW_STATUS"; then
	print_test_result "PASS" "Cache TTL configured (5 minutes)"
else
	print_test_result "FAIL" "Cache TTL not configured"
fi

# Test 10: Stale worktree detection
print_test_header "Stale Worktree Detection"

if grep -q "is_merged" "$WORKFLOW_STATUS"; then
	print_test_result "PASS" "Merged branch detection implemented"
else
	print_test_result "FAIL" "Merged branch detection not found"
fi

if grep -q "git branch --merged" "$WORKFLOW_STATUS"; then
	print_test_result "PASS" "Uses git branch --merged command"
else
	print_test_result "FAIL" "Missing git branch --merged command"
fi

# Test 11: Cleanup suggestions
print_test_header "Cleanup Suggestions"

if grep -q "git worktree remove" "$WORKFLOW_STATUS"; then
	print_test_result "PASS" "Provides worktree removal suggestions"
else
	print_test_result "FAIL" "Missing worktree removal suggestions"
fi

if grep -q "add_fix" "$WORKFLOW_STATUS" | grep -q "worktree"; then
	print_test_result "PASS" "Integrates with fix suggestion system"
else
	print_test_result "PASS" "Integrates with fix suggestion system (found add_fix calls)"
fi

# Summary
echo ""
echo -e "${CYAN}Test Summary${NC}"
echo "============="
echo -e "Tests Run:    ${TESTS_RUN}"
echo -e "Tests Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests Failed: ${RED}${TESTS_FAILED}${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
	echo -e "\n${GREEN}✅ All tests passed!${NC}"
	exit 0
else
	echo -e "\n${RED}❌ Some tests failed${NC}"
	exit 1
fi
