#!/bin/bash

# test-hook-integration.sh
# Integration tests for all hooks

set -e

# Get the directory paths
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$TESTS_DIR")"

# Source test utilities
source "$TESTS_DIR/test-utilities.sh"

# Test stop hook integration
test_stop_hook() {
    start_test_suite "Stop Hook Integration"
    
    # Create temporary test environment
    local test_dir="/tmp/agent-os-stop-test-$$"
    create_test_repo "$test_dir"
    create_agent_os_project "$test_dir"
    
    cd "$test_dir"
    
    # Add and commit Agent OS files
    git add .agent-os/
    git commit -q -m "Add Agent OS structure"
    
    # Test stop hook with high-risk conversation
    local high_risk_conv
    high_risk_conv=$(get_sample_high_risk_conversation)
    
    # Run stop hook
    local stop_output
    stop_output=$("$HOOKS_DIR/stop-hook.sh" "$high_risk_conv" 2>&1)
    
    assert_contains "Stop hook detects high risk" \
        "$stop_output" \
        "Workflow Abandonment Prevention"
    
    # Test stop hook with low-risk conversation
    local low_risk_conv="I'm working on the authentication feature."
    
    stop_output=$("$HOOKS_DIR/stop-hook.sh" "$low_risk_conv" 2>&1)
    
    # Should produce no output for low risk
    assert_equals "Stop hook silent for low risk" \
        "${#stop_output}" \
        "0"
    
    # Cleanup
    cd /
    cleanup_test_files "$test_dir"
    
    finish_test_suite
}

# Test post-tool-use hook integration
test_post_tool_use_hook() {
    start_test_suite "Post Tool Use Hook Integration"
    
    # Create temporary test environment
    local test_dir="/tmp/agent-os-post-tool-test-$$"
    create_test_repo "$test_dir"
    create_agent_os_project "$test_dir"
    
    cd "$test_dir"
    
    # Add and commit Agent OS files initially
    git add .agent-os/
    git commit -q -m "Add Agent OS structure"
    
    # Modify an Agent OS file to simulate tool use
    echo "# Modified by tool" >> .agent-os/product/mission.md
    
    # Test post-tool-use hook with Agent OS tool use
    local tool_input='{"file_path": ".agent-os/product/mission.md", "content": "test"}'
    local agent_os_conv
    agent_os_conv=$(get_sample_agent_os_conversation)
    
    local hook_output
    hook_output=$("$HOOKS_DIR/post-tool-use-hook.sh" "Edit" "$tool_input" "$agent_os_conv" 2>&1)
    
    # Should auto-commit the changes
    assert_contains "Post-tool-use hook commits changes" \
        "$hook_output" \
        "Auto-Committed"
    
    # Verify commit was made
    local recent_commit
    recent_commit=$(git log --oneline -1)
    assert_contains "Commit has documentation message" \
        "$recent_commit" \
        "docs: update Agent OS documentation"
    
    # Cleanup
    cd /
    cleanup_test_files "$test_dir"
    
    finish_test_suite
}

# Test user-prompt-submit hook integration
test_user_prompt_submit_hook() {
    start_test_suite "User Prompt Submit Hook Integration"
    
    # Create temporary test environment
    local test_dir="/tmp/agent-os-prompt-test-$$"
    create_test_repo "$test_dir"
    create_agent_os_project "$test_dir"
    
    cd "$test_dir"
    
    # Test user prompt submit hook with Agent OS context
    local user_message="I want to implement authentication"
    local agent_os_conv
    agent_os_conv=$(get_sample_agent_os_conversation)
    
    local hook_output
    hook_output=$("$HOOKS_DIR/user-prompt-submit-hook.sh" "$user_message" "$agent_os_conv" 2>&1)
    
    assert_contains "User prompt hook injects context" \
        "$hook_output" \
        "Agent OS Context Injection"
    
    assert_contains "Context includes project info" \
        "$hook_output" \
        "Project Context"
    
    # Test with non-Agent OS conversation
    local non_agent_os_conv
    non_agent_os_conv=$(get_sample_non_agent_os_conversation)
    
    # Should still inject context if in Agent OS project directory
    hook_output=$("$HOOKS_DIR/user-prompt-submit-hook.sh" "$user_message" "$non_agent_os_conv" 2>&1)
    
    assert_contains "Context injected for Agent OS project" \
        "$hook_output" \
        "Agent OS Context Injection"
    
    # Cleanup
    cd /
    cleanup_test_files "$test_dir"
    
    finish_test_suite
}

# Test hooks configuration
test_hooks_configuration() {
    start_test_suite "Hooks Configuration"
    
    # Test configuration file exists and is valid JSON
    run_test "Configuration file exists" \
        "test -f '$HOOKS_DIR/claude-code-hooks.json'" \
        0
    
    # Test JSON validity
    if command -v jq >/dev/null 2>&1; then
        run_test "Configuration is valid JSON" \
            "jq . '$HOOKS_DIR/claude-code-hooks.json' >/dev/null" \
            0
        
        # Test required fields
        local hook_count
        hook_count=$(jq '.hooks | length' "$HOOKS_DIR/claude-code-hooks.json")
        assert_equals "Configuration has three hooks" \
            "$hook_count" \
            "3"
    else
        echo "  ⚠️ jq not available, skipping JSON validation tests"
    fi
    
    finish_test_suite
}

# Test installation script
test_installation_script() {
    start_test_suite "Installation Script"
    
    # Test installation script exists and is executable
    run_test "Installation script exists" \
        "test -f '$HOOKS_DIR/install-hooks.sh'" \
        0
    
    run_test "Installation script is executable" \
        "test -x '$HOOKS_DIR/install-hooks.sh'" \
        0
    
    # Test uninstallation script
    run_test "Uninstallation script exists" \
        "test -f '$HOOKS_DIR/uninstall-hooks.sh'" \
        0
    
    run_test "Uninstallation script is executable" \
        "test -x '$HOOKS_DIR/uninstall-hooks.sh'" \
        0
    
    finish_test_suite
}

# Test all utility scripts are executable
test_utility_scripts() {
    start_test_suite "Utility Scripts"
    
    local utilities=("workflow-detector.sh" "git-utils.sh" "context-builder.sh")
    
    for util in "${utilities[@]}"; do
        run_test "$util exists and is executable" \
            "test -x '$HOOKS_DIR/lib/$util'" \
            0
    done
    
    finish_test_suite
}

# Test logging functionality
test_logging() {
    start_test_suite "Logging Functionality"
    
    # Create temporary test environment
    local test_dir="/tmp/agent-os-log-test-$$"
    create_test_repo "$test_dir"
    
    cd "$test_dir"
    
    # Run a hook to generate logs
    local test_conv="Test conversation with @.agent-os/ reference"
    "$HOOKS_DIR/stop-hook.sh" "$test_conv" >/dev/null 2>&1
    
    # Check if log file was created
    run_test "Stop hook creates log file" \
        "test -f '$HOME/.agent-os/logs/stop-hook.log'" \
        0
    
    # Check log content
    if [ -f "$HOME/.agent-os/logs/stop-hook.log" ]; then
        local log_content
        log_content=$(tail -5 "$HOME/.agent-os/logs/stop-hook.log")
        
        assert_contains "Log contains hook execution" \
            "$log_content" \
            "Stop hook triggered"
    fi
    
    # Cleanup
    cd /
    cleanup_test_files "$test_dir"
    
    finish_test_suite
}

# Main test execution
main() {
    echo "🧪 Testing Hook Integration"
    echo "==========================="
    echo ""
    
    local total_failures=0
    
    test_stop_hook || ((total_failures++))
    test_post_tool_use_hook || ((total_failures++))
    test_user_prompt_submit_hook || ((total_failures++))
    test_hooks_configuration || ((total_failures++))
    test_installation_script || ((total_failures++))
    test_utility_scripts || ((total_failures++))
    test_logging || ((total_failures++))
    
    echo "🏁 Hook Integration Tests Complete"
    echo "=================================="
    
    if [ "$total_failures" -eq 0 ]; then
        echo -e "${GREEN}✅ All integration tests passed!${NC}"
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