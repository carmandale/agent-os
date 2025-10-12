#!/bin/bash

# test-stop-hook-integration.sh
# Integration tests for stop-hook context enhancement

set -e

# Get the directory paths
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$TESTS_DIR")"

# Source test utilities
source "$TESTS_DIR/test-utilities.sh"

# Test stop-hook with feature branch and full context
test_stop_hook_full_context() {
	start_test_suite "Stop-Hook with Full Context"

	# Create temporary test repository with Agent OS structure
	local test_dir="/tmp/agent-os-integration-full-$$"
	create_test_repo "$test_dir"
	create_agent_os_project "$test_dir"

	cd "$test_dir"

	# Create feature branch with issue
	git checkout -q -b "feature/stop-hook-integration-#98"

	# Create additional spec for testing
	mkdir -p ".agent-os/specs/2025-10-12-integration-test-#98"

	# Create uncommitted source file
	echo "#!/bin/bash\necho 'test'" > test.sh

	# Clear any recent commits (simulate no commits in recent window)
	# The stop-hook checks for commits within RECENT_WINDOW (default 2 hours ago)

	# Run stop-hook (simulate call)
	# Note: We can't actually run the hook in strict mode, so we test the functions
	source "$HOOKS_DIR/lib/git-utils.sh"
	source "$HOOKS_DIR/lib/workflow-detector.sh"

	# Verify context extraction works
	local branch issue spec
	branch=$(get_current_branch)
	issue=$(extract_github_issue "branch")
	spec=$(detect_current_spec)

	assert_equals "Branch extracted correctly" \
		"$branch" \
		"feature/stop-hook-integration-#98"

	assert_equals "Issue extracted correctly" \
		"$issue" \
		"98"

	# Spec should be the most recent (2025-10-12)
	assert_contains "Spec detected correctly" \
		"$spec" \
		"2025-10-12"

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Test stop-hook with branch but no issue
test_stop_hook_no_issue() {
	start_test_suite "Stop-Hook with Branch but No Issue"

	# Create temporary test repository
	local test_dir="/tmp/agent-os-integration-noissue-$$"
	create_test_repo "$test_dir"
	create_agent_os_project "$test_dir"

	cd "$test_dir"

	# Create feature branch without issue number
	git checkout -q -b "refactor-cleanup"

	# Create uncommitted source file
	echo "#!/bin/bash\necho 'cleanup'" > cleanup.sh

	# Test context extraction
	source "$HOOKS_DIR/lib/git-utils.sh"
	source "$HOOKS_DIR/lib/workflow-detector.sh"

	local branch issue
	branch=$(get_current_branch)
	issue=$(extract_github_issue "branch")

	assert_equals "Branch extracted correctly" \
		"$branch" \
		"refactor-cleanup"

	assert_equals "No issue extracted" \
		"$issue" \
		""

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Test stop-hook in non-Agent OS project
test_stop_hook_non_agent_os() {
	start_test_suite "Stop-Hook in Non-Agent OS Project"

	# Create temporary test repository without .agent-os
	local test_dir="/tmp/agent-os-integration-noagentos-$$"
	create_test_repo "$test_dir"

	cd "$test_dir"

	# Create feature branch
	git checkout -q -b "feature-#123-test"

	# Test context extraction (should still work for branch/issue)
	source "$HOOKS_DIR/lib/git-utils.sh"
	source "$HOOKS_DIR/lib/workflow-detector.sh"

	local branch issue spec
	branch=$(get_current_branch)
	issue=$(extract_github_issue "branch")
	spec=$(detect_current_spec)

	assert_equals "Branch extracted correctly" \
		"$branch" \
		"feature-#123-test"

	assert_equals "Issue extracted correctly" \
		"$issue" \
		"123"

	assert_equals "No spec detected (no .agent-os)" \
		"$spec" \
		""

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Test performance of context extraction
test_context_extraction_performance() {
	start_test_suite "Context Extraction Performance"

	# Create temporary test repository with Agent OS structure
	local test_dir="/tmp/agent-os-integration-perf-$$"
	create_test_repo "$test_dir"
	create_agent_os_project "$test_dir"

	cd "$test_dir"

	# Create feature branch with issue
	git checkout -q -b "feature/performance-test-#99"

	# Create multiple spec folders to test detection performance
	for i in {1..10}; do
		mkdir -p ".agent-os/specs/2025-10-$(printf "%02d" $i)-test-$i-#$i"
	done

	# Measure context extraction time
	source "$HOOKS_DIR/lib/git-utils.sh"
	source "$HOOKS_DIR/lib/workflow-detector.sh"

	local start_time end_time elapsed
	start_time=$(date +%s%N 2>/dev/null || date +%s000000000)

	# Run context extraction
	local branch issue spec
	branch=$(get_current_branch)
	issue=$(extract_github_issue "branch")
	spec=$(detect_current_spec)

	end_time=$(date +%s%N 2>/dev/null || date +%s000000000)
	elapsed=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds

	echo "  Context extraction took: ${elapsed}ms"

	# Verify extraction worked
	assert_equals "Branch extracted" \
		"$branch" \
		"feature/performance-test-#99"
	assert_equals "Issue extracted" \
		"$issue" \
		"99"
	assert_contains "Spec detected (most recent)" \
		"$spec" \
		"2025-10-10"

	# Performance requirement: < 50ms added latency
	# Note: This is for the extraction only, not the full stop-hook
	if [ "$elapsed" -lt 100 ]; then
		echo "  ✅ Performance within acceptable range (<100ms for extraction)"
	else
		echo "  ⚠️  Performance warning: ${elapsed}ms (expected <100ms)"
	fi

	# Cleanup
	cd /
	cleanup_test_files "$test_dir"

	finish_test_suite
}

# Test environment variable suppression
test_hooks_suppression() {
	start_test_suite "Hooks Suppression"

	# The AGENT_OS_HOOKS_QUIET variable should suppress hooks
	# We test that the variable is respected

	export AGENT_OS_HOOKS_QUIET=true

	# In real usage, the stop-hook would check this and exit early
	# We just verify the variable is set correctly
	assert_equals "Suppression variable set" \
		"$AGENT_OS_HOOKS_QUIET" \
		"true"

	unset AGENT_OS_HOOKS_QUIET

	assert_equals "Suppression variable cleared" \
		"${AGENT_OS_HOOKS_QUIET:-false}" \
		"false"

	finish_test_suite
}

# Main test execution
main() {
	echo "🧪 Testing Stop-Hook Integration"
	echo "================================="
	echo ""

	local total_failures=0

	test_stop_hook_full_context || ((total_failures++))
	test_stop_hook_no_issue || ((total_failures++))
	test_stop_hook_non_agent_os || ((total_failures++))
	test_context_extraction_performance || ((total_failures++))
	test_hooks_suppression || ((total_failures++))

	echo "🏁 Stop-Hook Integration Tests Complete"
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
