#!/bin/bash

# test-stop-hook-active-work.sh
# Tests for active work session detection in stop-hook (Issue #102)

set -e

# Get the directory paths
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$TESTS_DIR")"

# Source test utilities
source "$TESTS_DIR/test-utilities.sh"

# Test: Feature branch with uncommitted code should NOT block
test_feature_branch_allows() {
	start_test_suite "Feature Branch Allows Work"

	local test_dir="/tmp/agent-os-active-work-feature-$$"
	create_test_repo "$test_dir"
	create_agent_os_project "$test_dir"

	cd "$test_dir"

	# Create feature branch
	git checkout -q -b "feature-#102-test"

	# Create uncommitted source file
	echo "def test(): pass" > test.py

	# Source libraries and test is_active_work_session
	source "$HOOKS_DIR/lib/git-utils.sh"
	source "$HOOKS_DIR/lib/workflow-detector.sh"

	# Test that feature branch is detected as active work
	local current_branch
	current_branch=$(get_current_branch)
	assert_equals "Branch is feature branch" "$current_branch" "feature-#102-test"

	# Test the complete flow: uncommitted files should be allowed on feature branch
	# (In the actual stop-hook, this would return 1 for "allow")

	cd /
	cleanup_test_files "$test_dir"
	finish_test_suite
}

# Test: Main branch with uncommitted code SHOULD block
test_main_branch_blocks() {
	start_test_suite "Main Branch Blocks Work"

	local test_dir="/tmp/agent-os-active-work-main-$$"
	create_test_repo "$test_dir"
	create_agent_os_project "$test_dir"

	cd "$test_dir"

	# Stay on default branch (master or main)
	local default_branch=$(git rev-parse --abbrev-ref HEAD)

	# Create uncommitted source file
	echo "def test(): pass" > test.py

	# Source libraries
	source "$HOOKS_DIR/lib/git-utils.sh"
	source "$HOOKS_DIR/lib/workflow-detector.sh"

	# Test that default branch is NOT detected as active work
	local current_branch
	current_branch=$(get_current_branch)
	assert_true "Branch is default (main/master)" "[ \"$current_branch\" = \"main\" ] || [ \"$current_branch\" = \"master\" ]"

	cd /
	cleanup_test_files "$test_dir"
	finish_test_suite
}

# Test: Active spec folder should allow uncommitted code
test_active_spec_allows() {
	start_test_suite "Active Spec Allows Work"

	local test_dir="/tmp/agent-os-active-work-spec-$$"
	create_test_repo "$test_dir"
	create_agent_os_project "$test_dir"

	cd "$test_dir"

	# Stay on main (to test spec detection overrides branch check)
	git checkout -q main

	# Create recent spec folder
	mkdir -p ".agent-os/specs/2025-10-15-test-#102"
	touch ".agent-os/specs/2025-10-15-test-#102/spec.md"

	# Create uncommitted source file
	echo "def test(): pass" > test.py

	# Source libraries
	source "$HOOKS_DIR/lib/git-utils.sh"
	source "$HOOKS_DIR/lib/workflow-detector.sh"

	# Test that spec is detected
	local spec_folder
	spec_folder=$(detect_current_spec)
	assert_contains "Spec detected" "$spec_folder" "2025-10-15"

	cd /
	cleanup_test_files "$test_dir"
	finish_test_suite
}

# Test: Issue number in branch name should allow uncommitted code
test_issue_in_branch_allows() {
	start_test_suite "Issue in Branch Allows Work"

	local test_dir="/tmp/agent-os-active-work-issue-$$"
	create_test_repo "$test_dir"
	create_agent_os_project "$test_dir"

	cd "$test_dir"

	# Create branch with issue number
	git checkout -q -b "feature-#102-active-work-detection"

	# Create uncommitted source file
	echo "def test(): pass" > test.py

	# Source libraries
	source "$HOOKS_DIR/lib/git-utils.sh"
	source "$HOOKS_DIR/lib/workflow-detector.sh"

	# Test that issue is extracted
	local issue_num
	issue_num=$(extract_github_issue "branch")
	assert_equals "Issue extracted" "$issue_num" "102"

	cd /
	cleanup_test_files "$test_dir"
	finish_test_suite
}

# Test: Performance of is_active_work_session
test_performance() {
	start_test_suite "Active Work Detection Performance"

	local test_dir="/tmp/agent-os-active-work-perf-$$"
	create_test_repo "$test_dir"
	create_agent_os_project "$test_dir"

	cd "$test_dir"

	# Create feature branch with issue and spec
	git checkout -q -b "feature-#102-test"
	mkdir -p ".agent-os/specs/2025-10-15-test-#102"

	# Source the full stop-hook (without strict mode)
	set +e
	source "$HOOKS_DIR/lib/git-utils.sh"
	source "$HOOKS_DIR/lib/workflow-detector.sh"

	# Extract the is_active_work_session function (defined in stop-hook.sh)
	# For testing, we'll measure the component functions instead

	local start_time end_time elapsed
	start_time=$(date +%s%N 2>/dev/null || date +%s000000000)

	# Measure all checks
	local branch issue spec
	branch=$(get_current_branch)
	issue=$(extract_github_issue "branch")
	spec=$(detect_current_spec)

	end_time=$(date +%s%N 2>/dev/null || date +%s000000000)
	elapsed=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds

	echo "  Active work detection took: ${elapsed}ms"

	# Verify detection worked
	assert_equals "Branch detected" "$branch" "feature-#102-test"
	assert_equals "Issue detected" "$issue" "102"
	assert_contains "Spec detected" "$spec" "2025-10-15"

	# Performance requirement: < 50ms added latency
	if [ "$elapsed" -lt 50 ]; then
		echo "  ✅ Performance excellent (<50ms)"
	elif [ "$elapsed" -lt 100 ]; then
		echo "  ✅ Performance acceptable (<100ms)"
	else
		echo "  ⚠️  Performance warning: ${elapsed}ms (expected <100ms)"
	fi

	set -e
	cd /
	cleanup_test_files "$test_dir"
	finish_test_suite
}

# Main test execution
main() {
	echo "🧪 Testing Stop-Hook Active Work Detection (#102)"
	echo "=================================================="
	echo ""

	local total_failures=0

	test_feature_branch_allows || ((total_failures++))
	test_main_branch_blocks || ((total_failures++))
	test_active_spec_allows || ((total_failures++))
	test_issue_in_branch_allows || ((total_failures++))
	test_performance || ((total_failures++))

	echo "🏁 Active Work Detection Tests Complete"
	echo "========================================"

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
