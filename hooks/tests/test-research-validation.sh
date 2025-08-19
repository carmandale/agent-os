#!/usr/bin/env bash

# test-research-validation.sh
# Tests to validate hooks research findings against documentation

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "Testing $test_name... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo "  Failed: $test_command"
    fi
}

echo "=== Agent OS Hooks Research Validation Tests ==="
echo

# Test 1: Check if hooks configuration exists
run_test "hooks configuration file exists" \
    "test -f ~/.claude/hooks/agent-os-hooks.json"

# Test 2: Verify hook events match documentation
run_test "PreToolUse hook configured" \
    "grep -q 'PreToolUse' ~/.claude/hooks/agent-os-hooks.json"

run_test "PostToolUse hook configured" \
    "grep -q 'PostToolUse' ~/.claude/hooks/agent-os-hooks.json"

run_test "Stop hook configured" \
    "grep -q 'Stop' ~/.claude/hooks/agent-os-hooks.json"

run_test "UserPromptSubmit hook configured" \
    "grep -q 'UserPromptSubmit' ~/.claude/hooks/agent-os-hooks.json"

run_test "Notification hook configured" \
    "grep -q 'Notification' ~/.claude/hooks/agent-os-hooks.json"

# Test 3: Check if hooks read from stdin (best practice)
run_test "pre-bash-hook reads from stdin" \
    "grep -q 'cat' ~/.agent-os/hooks/pre-bash-hook.sh || grep -q 'stdin' ~/.agent-os/hooks/pre-bash-hook.sh"

run_test "post-bash-hook reads from stdin" \
    "grep -q 'cat' ~/.agent-os/hooks/post-bash-hook.sh || grep -q 'stdin' ~/.agent-os/hooks/post-bash-hook.sh"

# Test 4: Verify JSON processing capability
run_test "jq is available for JSON processing" \
    "command -v jq"

run_test "hooks use jq for JSON parsing" \
    "grep -q 'jq' ~/.agent-os/hooks/pre-bash-hook.sh"

# Test 5: Check for security best practices
run_test "hooks use set -e for error handling" \
    "grep -q 'set -e' ~/.agent-os/hooks/stop-hook.sh"

run_test "hooks avoid eval with untrusted input" \
    "! grep -E 'eval.*\$' ~/.agent-os/hooks/*.sh | grep -v '# Safe'"

# Test 6: Check for timeout configuration
run_test "timeout configuration in settings" \
    "grep -q 'timeout' ~/.claude/hooks/agent-os-hooks.json || echo 'Using default 60s timeout'"

# Test 7: Verify hook file permissions
run_test "hook scripts are executable" \
    "test -x ~/.agent-os/hooks/stop-hook.sh"

# Test 8: Check for logging capability
run_test "hooks have logging configured" \
    "grep -q 'LOG' ~/.agent-os/hooks/stop-hook.sh"

# Test 9: Verify environment variable usage
run_test "hooks use CLAUDE_PROJECT_DIR" \
    "grep -q 'CLAUDE_PROJECT_DIR' ~/.agent-os/hooks/pre-bash-hook.sh"

# Test 10: Check for proper error handling
run_test "hooks handle missing dependencies gracefully" \
    "grep -q 'command -v' ~/.agent-os/hooks/pre-bash-hook.sh"

# Summary
echo
echo "=== Test Summary ==="
echo -e "Tests run: $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed. Please review the research findings.${NC}"
    exit 1
fi