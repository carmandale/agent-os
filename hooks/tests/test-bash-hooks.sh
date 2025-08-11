#!/bin/bash

# test-bash-hooks.sh
# Unit tests for Bash observation hooks

set -e

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")"
TEST_TEMP="/tmp/aos-test-$$"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source test utilities
source "$SCRIPT_DIR/test-utilities.sh"

# Setup test environment
setup() {
    mkdir -p "$TEST_TEMP"
    export CLAUDE_PROJECT_DIR="$TEST_TEMP"
    mkdir -p "$TEST_TEMP/.agent-os"
}

# Teardown test environment
teardown() {
    rm -rf "$TEST_TEMP"
    unset CLAUDE_PROJECT_DIR
}

# Test pre-bash-hook.sh
test_pre_bash_hook() {
    test_start "pre-bash-hook.sh"
    
    # Test server command classification
    local json_input='{"hookMetadata":{"toolName":"Bash"},"tool_input":{"command":"npm run dev"}}'
    echo "$json_input" | "$HOOKS_DIR/pre-bash-hook.sh" > "$TEST_TEMP/output.txt" 2>&1
    
    # Check that it doesn't block (exit code 0)
    if [ $? -eq 0 ]; then
        test_pass "Pre-bash hook doesn't block"
    else
        test_fail "Pre-bash hook blocked execution"
    fi
    
    # Check that log file was created
    if [ -f "$TEST_TEMP/.agent-os/observed-bash.jsonl" ]; then
        test_pass "Log file created"
    else
        test_fail "Log file not created"
    fi
    
    # Check log content
    if grep -q '"intent":"server"' "$TEST_TEMP/.agent-os/observed-bash.jsonl"; then
        test_pass "Server intent classified correctly"
    else
        test_fail "Server intent not classified"
    fi
    
    # Test test command classification
    setup
    json_input='{"hookMetadata":{"toolName":"Bash"},"tool_input":{"command":"pytest tests/"}}'
    echo "$json_input" | "$HOOKS_DIR/pre-bash-hook.sh" > "$TEST_TEMP/output.txt" 2>&1
    
    if grep -q '"intent":"test"' "$TEST_TEMP/.agent-os/observed-bash.jsonl"; then
        test_pass "Test intent classified correctly"
    else
        test_fail "Test intent not classified"
    fi
    
    # Test build command classification
    setup
    json_input='{"hookMetadata":{"toolName":"Bash"},"tool_input":{"command":"npm run build"}}'
    echo "$json_input" | "$HOOKS_DIR/pre-bash-hook.sh" > "$TEST_TEMP/output.txt" 2>&1
    
    if grep -q '"intent":"build"' "$TEST_TEMP/.agent-os/observed-bash.jsonl"; then
        test_pass "Build intent classified correctly"
    else
        test_fail "Build intent not classified"
    fi
}

# Test post-bash-hook.sh
test_post_bash_hook() {
    test_start "post-bash-hook.sh"
    
    # Test successful command
    local json_input='{"hookMetadata":{"toolName":"Bash"},"tool_input":{"command":"ls -la"},"tool_response":{"exit_code":"0"}}'
    echo "$json_input" | "$HOOKS_DIR/post-bash-hook.sh" > "$TEST_TEMP/output.txt" 2>&1
    
    # Check exit code
    if [ $? -eq 0 ]; then
        test_pass "Post-bash hook doesn't block"
    else
        test_fail "Post-bash hook blocked execution"
    fi
    
    # Check output contains summary
    if grep -q "Status:" "$TEST_TEMP/output.txt"; then
        test_pass "Status summary generated"
    else
        test_fail "No status summary"
    fi
    
    # Test failed command
    setup
    json_input='{"hookMetadata":{"toolName":"Bash"},"tool_input":{"command":"npm test"},"tool_response":{"exit_code":"1"}}'
    echo "$json_input" | "$HOOKS_DIR/post-bash-hook.sh" > "$TEST_TEMP/output.txt" 2>&1
    
    if grep -q "Failed with exit code: 1" "$TEST_TEMP/output.txt"; then
        test_pass "Failure reported correctly"
    else
        test_fail "Failure not reported"
    fi
    
    # Check log contains exit code
    if grep -q '"exit":"1"' "$TEST_TEMP/.agent-os/observed-bash.jsonl"; then
        test_pass "Exit code logged"
    else
        test_fail "Exit code not logged"
    fi
}

# Test notify-hook.sh
test_notify_hook() {
    test_start "notify-hook.sh"
    
    # Create mock log with recent server start
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    echo "{\"ts\":\"$timestamp\",\"event\":\"pre\",\"cmd\":\"npm run dev\",\"exit\":null,\"intent\":\"server\",\"project\":\"/test\",\"cwd\":\"/test\"}" > "$TEST_TEMP/.agent-os/observed-bash.jsonl"
    
    # Run notify hook
    "$HOOKS_DIR/notify-hook.sh" > "$TEST_TEMP/output.txt" 2>&1
    
    # Check exit code (should always be 0)
    if [ $? -eq 0 ]; then
        test_pass "Notify hook doesn't block"
    else
        test_fail "Notify hook blocked"
    fi
    
    # Check for server notification (may not trigger depending on time)
    # This is optional since it depends on the 5-minute window
    if grep -q "Development server" "$TEST_TEMP/output.txt"; then
        test_pass "Server notification generated (optional)"
    else
        test_info "No server notification (time-dependent)"
    fi
}

# Test JSON parsing with missing jq
test_hooks_without_jq() {
    test_start "Hooks without jq"
    
    # Temporarily rename jq if it exists
    local jq_path=$(which jq 2>/dev/null || echo "")
    if [ -n "$jq_path" ]; then
        # Create a fake environment without jq
        PATH_WITHOUT_JQ=$(echo "$PATH" | sed "s|$(dirname "$jq_path"):||g")
        
        # Test pre-bash-hook without jq
        local json_input='{"hookMetadata":{"toolName":"Bash"},"tool_input":{"command":"echo test"}}'
        PATH="$PATH_WITHOUT_JQ" echo "$json_input" | "$HOOKS_DIR/pre-bash-hook.sh" > "$TEST_TEMP/output.txt" 2>&1
        
        if [ $? -eq 0 ]; then
            test_pass "Pre-bash hook handles missing jq gracefully"
        else
            test_fail "Pre-bash hook failed without jq"
        fi
        
        # Test post-bash-hook without jq
        PATH="$PATH_WITHOUT_JQ" echo "$json_input" | "$HOOKS_DIR/post-bash-hook.sh" > "$TEST_TEMP/output.txt" 2>&1
        
        if [ $? -eq 0 ]; then
            test_pass "Post-bash hook handles missing jq gracefully"
        else
            test_fail "Post-bash hook failed without jq"
        fi
    else
        test_info "jq not installed - skipping fallback test"
    fi
}

# Test non-Bash tool handling
test_non_bash_tool() {
    test_start "Non-Bash tool handling"
    
    # Send a non-Bash tool event
    local json_input='{"hookMetadata":{"toolName":"Write"},"tool_input":{"file_path":"test.txt","content":"hello"}}'
    echo "$json_input" | "$HOOKS_DIR/pre-bash-hook.sh" > "$TEST_TEMP/output.txt" 2>&1
    
    # Should exit cleanly without creating logs
    if [ $? -eq 0 ]; then
        test_pass "Pre-bash hook ignores non-Bash tools"
    else
        test_fail "Pre-bash hook failed on non-Bash tool"
    fi
    
    # Check that no log was created
    if [ ! -f "$TEST_TEMP/.agent-os/observed-bash.jsonl" ]; then
        test_pass "No log created for non-Bash tool"
    else
        test_fail "Log created for non-Bash tool"
    fi
}

# Main test execution
main() {
    echo "🧪 Testing Agent OS Bash Observation Hooks"
    echo "=========================================="
    echo ""
    
    # Run tests
    setup
    test_pre_bash_hook
    teardown
    
    setup
    test_post_bash_hook
    teardown
    
    setup
    test_notify_hook
    teardown
    
    setup
    test_hooks_without_jq
    teardown
    
    setup
    test_non_bash_tool
    teardown
    
    # Print summary
    echo ""
    echo "=========================================="
    echo "Test Summary:"
    echo "  Tests run: $TESTS_RUN"
    echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
        exit 1
    else
        echo ""
        echo -e "${GREEN}✅ All tests passed!${NC}"
        exit 0
    fi
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi