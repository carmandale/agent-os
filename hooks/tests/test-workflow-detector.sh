#!/bin/bash

# test-workflow-detector.sh
# Tests for workflow-detector.sh

set -e

# Get the directory paths
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$TESTS_DIR")"

# Source test utilities
source "$TESTS_DIR/test-utilities.sh"

# Source the module being tested
source "$HOOKS_DIR/lib/workflow-detector.sh"

# Test workflow detection
test_workflow_detection() {
    start_test_suite "Workflow Detection"
    
    # Test Agent OS workflow detection
    local agent_os_conv
    agent_os_conv=$(get_sample_agent_os_conversation)
    
    assert_equals "Detects Agent OS workflow" \
        "$(is_agent_os_workflow "$agent_os_conv" && echo "true" || echo "false")" \
        "true"
    
    # Test non-Agent OS conversation
    local non_agent_os_conv
    non_agent_os_conv=$(get_sample_non_agent_os_conversation)
    
    assert_equals "Rejects non-Agent OS workflow" \
        "$(is_agent_os_workflow "$non_agent_os_conv" && echo "true" || echo "false")" \
        "false"
    
    # Test phase detection
    assert_equals "Detects task execution phase" \
        "$(detect_workflow_phase "$agent_os_conv")" \
        "task-execution"
    
    assert_equals "Returns unknown for non-Agent OS" \
        "$(detect_workflow_phase "$non_agent_os_conv")" \
        "unknown"
    
    finish_test_suite
}

# Test abandonment risk detection
test_abandonment_risk_detection() {
    start_test_suite "Abandonment Risk Detection"
    
    # Test high risk detection
    local high_risk_conv
    high_risk_conv=$(get_sample_high_risk_conversation)
    
    assert_equals "Detects high abandonment risk" \
        "$(detect_abandonment_risk "$high_risk_conv")" \
        "high"
    
    # Test low risk detection
    local low_risk_conv="I'm starting to work on the authentication feature."
    
    assert_equals "Detects low abandonment risk" \
        "$(detect_abandonment_risk "$low_risk_conv")" \
        "low"
    
    finish_test_suite
}

# Test workflow completion detection
test_workflow_completion_detection() {
    start_test_suite "Workflow Completion Detection"
    
    # Test completion requirement detection
    local completion_conv="Step 8: Quality checks passed. All tests are running successfully."
    
    assert_equals "Detects completion requirement" \
        "$(requires_workflow_completion "$completion_conv" && echo "true" || echo "false")" \
        "true"
    
    # Test no completion requirement
    local no_completion_conv="Step 3: Implementation in progress."
    
    assert_equals "No completion requirement for early steps" \
        "$(requires_workflow_completion "$no_completion_conv" && echo "true" || echo "false")" \
        "false"
    
    finish_test_suite
}

# Test spec context detection
test_spec_context_detection() {
    start_test_suite "Spec Context Detection"
    
    # Create temporary test environment
    local test_dir="/tmp/agent-os-test-$$"
    create_test_repo "$test_dir"
    create_agent_os_project "$test_dir"
    
    cd "$test_dir"
    
    # Test current spec detection
    local current_spec
    current_spec=$(detect_current_spec)
    
    assert_contains "Detects current spec" \
        "$current_spec" \
        "2025-01-01-test-feature-#123"
    
    # Cleanup
    cd /
    cleanup_test_files "$test_dir"
    
    finish_test_suite
}

# Test workflow suggestions
test_workflow_suggestions() {
    start_test_suite "Workflow Suggestions"
    
    # Test spec creation suggestions
    local spec_conv="Following @~/.agent-os/instructions/core/create-spec.md"
    local suggestion
    suggestion=$(get_workflow_suggestions "$spec_conv")
    
    assert_contains "Suggests task execution after spec creation" \
        "$suggestion" \
        "execute-tasks"
    
    # Test task execution suggestions
    local task_conv="Following @~/.agent-os/instructions/core/execute-tasks.md"
    suggestion=$(get_workflow_suggestions "$task_conv")
    
    assert_contains "Provides task execution guidance" \
        "$suggestion" \
        "Continue"
    
    finish_test_suite
}

# Main test execution
main() {
    echo "🧪 Testing workflow-detector.sh"
    echo "==============================="
    echo ""
    
    local total_failures=0
    
    test_workflow_detection || ((total_failures++))
    test_abandonment_risk_detection || ((total_failures++))
    test_workflow_completion_detection || ((total_failures++))
    test_spec_context_detection || ((total_failures++))
    test_workflow_suggestions || ((total_failures++))
    
    echo "🏁 Workflow Detector Tests Complete"
    echo "==================================="
    
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