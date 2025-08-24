#!/usr/bin/env bats

# Test commit boundary error handling and rollback scenarios

load test_helper

setup() {
    setup_test_repo
    
    # Copy the commit boundary manager to test repo
    cp "$BATS_TEST_DIRNAME/../scripts/commit-boundary-manager.sh" "$TEST_REPO_DIR/"
    chmod +x "$TEST_REPO_DIR/commit-boundary-manager.sh"
}

teardown() {
    cleanup_test_repo
    # Clean up session files
    rm -f ~/.agent-os/cache/work-session 2>/dev/null || true
    unset AGENT_OS_WORK_SESSION 2>/dev/null || true
}

@test "handles missing work session gracefully" {
    unset AGENT_OS_WORK_SESSION 2>/dev/null || true
    rm -f ~/.agent-os/cache/work-session 2>/dev/null || true
    
    # Create some changes
    echo "test content" > "$TEST_REPO_DIR/test-file.txt"
    
    run bash -c "cd '$TEST_REPO_DIR' && ./commit-boundary-manager.sh commit phase_2_complete"
    
    # Should not create commit without work session
    [ "$status" -eq 0 ]
    # Verify no new commits were created beyond the initial one
    run bash -c "cd '$TEST_REPO_DIR' && git rev-list --count HEAD 2>/dev/null || echo 1"
    [ "${output}" -eq 1 ]  # Only initial commit
}

@test "handles no changes to commit gracefully" {
    export AGENT_OS_WORK_SESSION=true
    mkdir -p ~/.agent-os/cache
    echo '{"active": true, "description": "test session"}' > ~/.agent-os/cache/work-session
    
    # No changes in working directory
    run bash -c "cd '$TEST_REPO_DIR' && ./commit-boundary-manager.sh commit phase_2_complete"
    
    # Should handle gracefully
    [ "$status" -eq 0 ]
}

@test "handles invalid boundary context gracefully" {
    export AGENT_OS_WORK_SESSION=true
    
    # Create some changes
    echo "test content" > "$TEST_REPO_DIR/test-file.txt"
    
    run bash -c "cd '$TEST_REPO_DIR' && ./commit-boundary-manager.sh commit invalid_context"
    
    # Should not create commit for invalid context
    [ "$status" -eq 1 ]
}

@test "handles git commit failure gracefully" {
    export AGENT_OS_WORK_SESSION=true
    mkdir -p ~/.agent-os/cache
    echo '{"active": true, "description": "test session"}' > ~/.agent-os/cache/work-session
    
    # Create changes
    echo "test content" > "$TEST_REPO_DIR/test-file.txt"
    
    # Make git commit fail by corrupting the git directory
    rm -rf "$TEST_REPO_DIR/.git/refs"
    
    run bash -c "cd '$TEST_REPO_DIR' && ./commit-boundary-manager.sh commit phase_2_complete"
    
    # Should handle git failure and return error status
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Failed to create automatic commit" ]]
}

@test "generates appropriate error message for invalid generate-message context" {
    run bash -c "cd '$TEST_REPO_DIR' && ./commit-boundary-manager.sh generate-message invalid_context"
    
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Error: No boundary detected" ]]
}

@test "shows usage help for invalid command" {
    run bash -c "cd '$TEST_REPO_DIR' && ./commit-boundary-manager.sh invalid_command"
    
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Commands:" ]]
    [[ "$output" =~ "Boundary contexts:" ]]
}