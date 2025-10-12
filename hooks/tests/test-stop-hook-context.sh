#!/bin/bash

# test-stop-hook-context.sh
# Tests for stop-hook context extraction enhancement

set -e

# Get the directory paths
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$TESTS_DIR")"

# Source test utilities
source "$TESTS_DIR/test-utilities.sh"

# Source the modules being tested
source "$HOOKS_DIR/lib/git-utils.sh"
source "$HOOKS_DIR/lib/workflow-detector.sh"

# Test get_current_branch() in various scenarios
test_current_branch_extraction() {
	start_test_suite "Current Branch Extraction"

	# Create temporary test repository
	local test_dir="/tmp/agent-os-branch-context-test-$$"
	create_test_repo "$test_dir"

	cd "$test_dir"

	# Test on main branch
	local branch
	branch=$(get_current_branch)
	assert_contains "Gets main/master branch" \
		"$branch" \
		"main\|master"

	# Test on feature branch with issue number
	git checkout -q -b "feature/stop-hook-context-#98"
	branch=$(get_current_branch)
	assert_equals "Gets feature branch with issue" \
		"$branch" \
		"feature/stop-hook-context-#98"

	# Test on feature branch without issue
	git checkout -q -b "feature-no-issue"
	branch=$(get_current_branch)
	assert_equals "Gets feature branch without issue" \
		"$branch" \
		"feature-no-issue"

	# Test outside git repo
	cd /tmp
	branch=$(get_current_branch)
	assert_equals "Returns 'not-a-git-repo' outside git repo" \
		"$branch" \
		"not-a-git-repo"

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Test extract_github_issue() with various branch naming patterns
test_issue_number_extraction() {
	start_test_suite "Issue Number Extraction from Branch"

	# Create temporary test repository
	local test_dir="/tmp/agent-os-issue-extract-test-$$"
	create_test_repo "$test_dir"

	cd "$test_dir"

	# Pattern: feature-#123-description
	git checkout -q -b "feature-#123-authentication"
	local issue_num
	issue_num=$(extract_github_issue "branch")
	assert_equals "Extracts issue from feature-#123-desc pattern" \
		"$issue_num" \
		"123"

	# Pattern: #123-feature-name
	git checkout -q -b "#456-add-login"
	issue_num=$(extract_github_issue "branch")
	assert_equals "Extracts issue from #456-feature pattern" \
		"$issue_num" \
		"456"

	# Pattern: 789-feature-name (without #)
	git checkout -q -b "789-implement-api"
	issue_num=$(extract_github_issue "branch")
	assert_equals "Does not extract issue without # symbol" \
		"$issue_num" \
		""

	# Pattern: feature-name (no issue)
	git checkout -q -b "feature-no-issue"
	issue_num=$(extract_github_issue "branch")
	assert_equals "Returns empty string when no issue found" \
		"$issue_num" \
		""

	# Main branch (no issue)
	git checkout -q main
	issue_num=$(extract_github_issue "branch")
	assert_equals "Returns empty string on main branch" \
		"$issue_num" \
		""

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Test detect_current_spec() in various scenarios
test_spec_folder_detection() {
	start_test_suite "Spec Folder Detection"

	# Create temporary test repository with Agent OS structure
	local test_dir="/tmp/agent-os-spec-detect-test-$$"
	create_test_repo "$test_dir"

	cd "$test_dir"

	# Test with no .agent-os directory
	local spec_folder
	spec_folder=$(detect_current_spec)
	assert_equals "Returns empty string when .agent-os doesn't exist" \
		"$spec_folder" \
		""

	# Create Agent OS project structure (creates a default spec)
	create_agent_os_project "$test_dir"

	# Remove default spec to test empty state
	rm -rf ".agent-os/specs/2025-01-01-test-feature-#123"
	spec_folder=$(detect_current_spec)
	assert_equals "Returns empty string when no specs exist" \
		"$spec_folder" \
		""

	# Create spec folder with date prefix
	mkdir -p ".agent-os/specs/2025-10-12-feature-one-#98"
	spec_folder=$(detect_current_spec)
	assert_equals "Detects single spec folder" \
		"$spec_folder" \
		"2025-10-12-feature-one-#98"

	# Create older spec folder
	mkdir -p ".agent-os/specs/2025-09-01-older-feature-#50"
	spec_folder=$(detect_current_spec)
	assert_equals "Returns most recent spec when multiple exist" \
		"$spec_folder" \
		"2025-10-12-feature-one-#98"

	# Create newer spec folder
	mkdir -p ".agent-os/specs/2025-11-15-newer-feature-#100"
	spec_folder=$(detect_current_spec)
	assert_equals "Returns newest spec folder" \
		"$spec_folder" \
		"2025-11-15-newer-feature-#100"

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Test context extraction with multiple patterns
test_context_extraction_patterns() {
	start_test_suite "Context Extraction Patterns"

	# Create temporary test repository with Agent OS structure
	local test_dir="/tmp/agent-os-context-patterns-test-$$"
	create_test_repo "$test_dir"
	create_agent_os_project "$test_dir"

	cd "$test_dir"

	# Scenario 1: Feature branch with issue and spec
	git checkout -q -b "feature/stop-hook-enhancement-#98"
	mkdir -p ".agent-os/specs/2025-10-12-stop-hook-context-#98"

	local branch issue spec
	branch=$(get_current_branch)
	issue=$(extract_github_issue "branch")
	spec=$(detect_current_spec)

	assert_equals "Branch extracted correctly" \
		"$branch" \
		"feature/stop-hook-enhancement-#98"
	assert_equals "Issue extracted correctly" \
		"$issue" \
		"98"
	assert_equals "Spec detected correctly" \
		"$spec" \
		"2025-10-12-stop-hook-context-#98"

	# Scenario 2: Feature branch without issue
	git checkout -q -b "refactor-hooks"
	issue=$(extract_github_issue "branch")

	assert_equals "No issue extracted from branch without issue" \
		"$issue" \
		""

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Test graceful fallback when context is unavailable
test_graceful_fallback() {
	start_test_suite "Graceful Fallback"

	# Create temporary test repository
	local test_dir="/tmp/agent-os-fallback-test-$$"
	create_test_repo "$test_dir"

	cd "$test_dir"

	# Test all functions return safe values
	local branch issue spec
	branch=$(get_current_branch)
	issue=$(extract_github_issue "branch")
	spec=$(detect_current_spec)

	assert_contains "Branch returns valid value" \
		"$branch" \
		"main\|master"
	assert_equals "Issue returns empty string" \
		"$issue" \
		""
	assert_equals "Spec returns empty string" \
		"$spec" \
		""

	# Test outside git repo
	cd /tmp
	branch=$(get_current_branch)
	issue=$(extract_github_issue "branch")
	spec=$(detect_current_spec)

	assert_equals "Branch returns error state" \
		"$branch" \
		"not-a-git-repo"
	assert_equals "Issue returns empty string outside git" \
		"$issue" \
		""
	assert_equals "Spec returns empty string outside git" \
		"$spec" \
		""

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Main test execution
main() {
	echo "🧪 Testing Stop-Hook Context Extraction"
	echo "========================================"
	echo ""

	local total_failures=0

	test_current_branch_extraction || ((total_failures++))
	test_issue_number_extraction || ((total_failures++))
	test_spec_folder_detection || ((total_failures++))
	test_context_extraction_patterns || ((total_failures++))
	test_graceful_fallback || ((total_failures++))

	echo "🏁 Stop-Hook Context Tests Complete"
	echo "===================================="

	if [ "$total_failures" -eq 0 ]; then
		echo -e "${GREEN}✅ All test suites passed!${NC}"
		exit 0
	else
		echo -e "${RED}❌ $total_failures test suite(s) failed${NC}"
		exit 1
	fi
}

# Run tests if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
	main "$@"
fi
