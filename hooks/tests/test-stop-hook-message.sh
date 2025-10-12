#!/bin/bash

# test-stop-hook-message.sh
# Tests for stop-hook message generation with context

set -e

# Get the directory paths
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$TESTS_DIR")"

# Source test utilities
source "$TESTS_DIR/test-utilities.sh"

# Source the modules being tested
source "$HOOKS_DIR/lib/git-utils.sh"
source "$HOOKS_DIR/lib/workflow-detector.sh"

# Mock generate_stop_message with context (we'll implement this in stop-hook.sh later)
generate_stop_message_with_context() {
	local project_root="$1"
	local num_changed="$2"
	local sample_list="$3"
	local current_branch="${4:-}"
	local issue_num="${5:-}"
	local spec_folder="${6:-}"

	# Build context lines conditionally
	local context_lines=""
	if [ -n "$current_branch" ]; then
		context_lines="${context_lines}Branch: $current_branch\n"
	fi
	if [ -n "$issue_num" ]; then
		context_lines="${context_lines}GitHub Issue: #$issue_num\n"
	fi
	if [ -n "$spec_folder" ]; then
		context_lines="${context_lines}Active Spec: $spec_folder\n"
	fi

	# Generate commit suggestion
	local commit_suggestion=""
	if [ -n "$issue_num" ]; then
		commit_suggestion="  git commit -m \"feat: describe changes #${issue_num}\""
	else
		commit_suggestion="  git commit -m \"describe your work\""
	fi

	cat <<EOF
Agent OS: Uncommitted source code detected

Project: $(basename "$project_root")
${context_lines}Detected $num_changed modified source file(s) with no recent commits.

Suggested commit:
$commit_suggestion

Next steps:
  1. Review changes: git status
  2. Commit work with suggested format above
  3. Or stash:      git stash
  4. Suppress temporarily: export AGENT_OS_HOOKS_QUIET=true

Changed files (sample):
$sample_list
EOF
}

# Test message generation with all context present
test_message_with_full_context() {
	start_test_suite "Message Generation - Full Context"

	# Create temporary test repository
	local test_dir="/tmp/agent-os-msg-full-test-$$"
	create_test_repo "$test_dir"
	create_agent_os_project "$test_dir"

	cd "$test_dir"

	# Setup full context
	git checkout -q -b "feature/stop-hook-context-#98"
	mkdir -p ".agent-os/specs/2025-10-12-stop-hook-context-#98"

	# Extract context
	local branch issue spec
	branch=$(get_current_branch)
	issue=$(extract_github_issue "branch")
	spec=$(detect_current_spec)

	# Generate message
	local message
	message=$(generate_stop_message_with_context \
		"$test_dir" \
		"3" \
		"  - file1.sh\n  - file2.sh\n  - file3.sh" \
		"$branch" \
		"$issue" \
		"$spec")

	# Assert message contains all context
	assert_contains "Message includes branch name" \
		"$message" \
		"Branch: feature/stop-hook-context-#98"
	assert_contains "Message includes issue number" \
		"$message" \
		"GitHub Issue: #98"
	assert_contains "Message includes spec folder" \
		"$message" \
		"Active Spec: 2025-10-12-stop-hook-context-#98"
	assert_contains "Message includes commit suggestion with issue" \
		"$message" \
		"feat: describe changes #98"

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Test message generation with partial context (branch only)
test_message_with_branch_only() {
	start_test_suite "Message Generation - Branch Only"

	# Create temporary test repository
	local test_dir="/tmp/agent-os-msg-branch-test-$$"
	create_test_repo "$test_dir"

	cd "$test_dir"

	# Setup branch context only (no issue, no spec)
	git checkout -q -b "refactor-hooks"

	# Extract context
	local branch issue spec
	branch=$(get_current_branch)
	issue=$(extract_github_issue "branch")
	spec=$(detect_current_spec)

	# Generate message
	local message
	message=$(generate_stop_message_with_context \
		"$test_dir" \
		"2" \
		"  - hooks/stop-hook.sh" \
		"$branch" \
		"$issue" \
		"$spec")

	# Assert message contains only branch
	assert_contains "Message includes branch name" \
		"$message" \
		"Branch: refactor-hooks"
	assert_not_contains "Message does not include issue" \
		"$message" \
		"GitHub Issue:"
	assert_not_contains "Message does not include spec" \
		"$message" \
		"Active Spec:"
	assert_contains "Message includes generic commit suggestion" \
		"$message" \
		"describe your work"

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Test message generation with issue but no spec
test_message_with_issue_only() {
	start_test_suite "Message Generation - Issue Only"

	# Create temporary test repository
	local test_dir="/tmp/agent-os-msg-issue-test-$$"
	create_test_repo "$test_dir"

	cd "$test_dir"

	# Setup branch with issue but no spec
	git checkout -q -b "feature-#123-authentication"

	# Extract context
	local branch issue spec
	branch=$(get_current_branch)
	issue=$(extract_github_issue "branch")
	spec=$(detect_current_spec)

	# Generate message
	local message
	message=$(generate_stop_message_with_context \
		"$test_dir" \
		"1" \
		"  - auth.sh" \
		"$branch" \
		"$issue" \
		"$spec")

	# Assert message contains branch and issue
	assert_contains "Message includes branch name" \
		"$message" \
		"Branch: feature-#123-authentication"
	assert_contains "Message includes issue number" \
		"$message" \
		"GitHub Issue: #123"
	assert_not_contains "Message does not include spec" \
		"$message" \
		"Active Spec:"
	assert_contains "Message includes commit suggestion with issue" \
		"$message" \
		"feat: describe changes #123"

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Test message generation with no context (main branch, no spec)
test_message_with_no_context() {
	start_test_suite "Message Generation - No Context"

	# Create temporary test repository
	local test_dir="/tmp/agent-os-msg-nocontext-test-$$"
	create_test_repo "$test_dir"

	cd "$test_dir"

	# Stay on main branch, no spec
	# Extract context
	local branch issue spec
	branch=$(get_current_branch)
	issue=$(extract_github_issue "branch")
	spec=$(detect_current_spec)

	# Generate message
	local message
	message=$(generate_stop_message_with_context \
		"$test_dir" \
		"1" \
		"  - test.sh" \
		"$branch" \
		"$issue" \
		"$spec")

	# Assert message has minimal context
	assert_contains "Message includes branch name" \
		"$message" \
		"Branch:"
	assert_not_contains "Message does not include issue" \
		"$message" \
		"GitHub Issue:"
	assert_not_contains "Message does not include spec" \
		"$message" \
		"Active Spec:"
	assert_contains "Message includes generic commit suggestion" \
		"$message" \
		"describe your work"

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Test message formatting consistency
test_message_formatting() {
	start_test_suite "Message Formatting Consistency"

	# Create temporary test repository
	local test_dir="/tmp/agent-os-msg-format-test-$$"
	create_test_repo "$test_dir"
	create_agent_os_project "$test_dir"

	cd "$test_dir"

	# Setup full context
	git checkout -q -b "feature-#99-formatting"
	mkdir -p ".agent-os/specs/2025-10-12-formatting-#99"

	# Extract context
	local branch issue spec
	branch=$(get_current_branch)
	issue=$(extract_github_issue "branch")
	spec=$(detect_current_spec)

	# Generate message
	local message
	message=$(generate_stop_message_with_context \
		"$test_dir" \
		"5" \
		"  - file1.sh\n  - file2.sh\n  - file3.sh\n  - file4.sh\n  - file5.sh" \
		"$branch" \
		"$issue" \
		"$spec")

	# Assert message structure
	assert_contains "Message has header" \
		"$message" \
		"Agent OS: Uncommitted source code detected"
	assert_contains "Message has project line" \
		"$message" \
		"Project:"
	assert_contains "Message has file count" \
		"$message" \
		"Detected 5 modified source file"
	assert_contains "Message has suggested commit section" \
		"$message" \
		"Suggested commit:"
	assert_contains "Message has next steps section" \
		"$message" \
		"Next steps:"
	assert_contains "Message has changed files section" \
		"$message" \
		"Changed files (sample):"

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Helper function for not_contains assertion
assert_not_contains() {
	local description="$1"
	local actual="$2"
	local expected_missing="$3"

	if echo "$actual" | grep -q "$expected_missing"; then
		echo "  ❌ $description"
		echo "     Expected NOT to contain: $expected_missing"
		echo "     But found it in: $actual"
		return 1
	else
		echo "  ✅ $description"
		return 0
	fi
}

# Main test execution
main() {
	echo "🧪 Testing Stop-Hook Message Generation"
	echo "========================================"
	echo ""

	local total_failures=0

	test_message_with_full_context || ((total_failures++))
	test_message_with_branch_only || ((total_failures++))
	test_message_with_issue_only || ((total_failures++))
	test_message_with_no_context || ((total_failures++))
	test_message_formatting || ((total_failures++))

	echo "🏁 Stop-Hook Message Tests Complete"
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
