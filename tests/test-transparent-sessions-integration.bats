#!/usr/bin/env bats

# Comprehensive integration tests for transparent work sessions

load test_helper

setup() {
    setup_test_repo
    
    # Create Agent OS structure in test repo
    mkdir -p "$TEST_REPO_DIR/.agent-os/specs/test-feature-#123"
    
    # Create a test spec
    cat > "$TEST_REPO_DIR/.agent-os/specs/test-feature-#123/spec.md" << 'EOF'
# Test Feature Specification

This is a test feature for validating transparent work sessions.

## Requirements
- Test feature implementation
- Automated testing
- Documentation updates
EOF

    cat > "$TEST_REPO_DIR/.agent-os/specs/test-feature-#123/tasks.md" << 'EOF'
# Spec Tasks

- [ ] 1. Implement test feature
  - [ ] 1.1 Create test file
  - [ ] 1.2 Add basic functionality
  - [ ] 1.3 Write unit tests
  
- [ ] 2. Add documentation
  - [ ] 2.1 Update README
  - [ ] 2.2 Add code comments
EOF

    # Copy Agent OS scripts for testing
    mkdir -p "$TEST_REPO_DIR/scripts"
    cp "$BATS_TEST_DIRNAME/../scripts/workflow-validator.sh" "$TEST_REPO_DIR/scripts/"
    cp "$BATS_TEST_DIRNAME/../scripts/work-session-manager.sh" "$TEST_REPO_DIR/scripts/"
    cp "$BATS_TEST_DIRNAME/../scripts/commit-boundary-manager.sh" "$TEST_REPO_DIR/scripts/"
    chmod +x "$TEST_REPO_DIR/scripts"/*.sh
    
    # Set up GitHub issue environment variable
    export GITHUB_ISSUE="123"
    
    # Commit the spec files AND scripts to ensure clean git status
    git -C "$TEST_REPO_DIR" add .agent-os/
    git -C "$TEST_REPO_DIR" add scripts/
    git -C "$TEST_REPO_DIR" commit -m "Add test spec and scripts for transparent sessions"
}

teardown() {
    cleanup_test_repo
    # Clean up session files and environment
    rm -f ~/.agent-os/cache/work-session 2>/dev/null || true
    unset AGENT_OS_WORK_SESSION 2>/dev/null || true
    unset AGENT_OS_FORCE_SESSION 2>/dev/null || true
    unset GITHUB_ISSUE 2>/dev/null || true
}

@test "workflow validator detects ideal conditions for transparent sessions" {
    # Clean git workspace (already clean from setup)
    # Active spec exists (created in setup)
    # GitHub issue reference exists (set in setup)
    
    # Use workflow validator from outside repo to avoid uncommitted changes
    run bash -c "cd '$TEST_REPO_DIR' && bash '$BATS_TEST_DIRNAME/../scripts/workflow-validator.sh' check"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "All conditions met - transparent work session can auto-start" ]]
}

@test "workflow validator provides helpful guidance when conditions not met" {
    # Remove the spec to break conditions
    rm -rf "$TEST_REPO_DIR/.agent-os/specs"
    
    run bash -c "cd '$TEST_REPO_DIR' && ./scripts/workflow-validator.sh check"
    
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Workflow conditions not met" ]]
    [[ "$output" =~ "Create a feature specification" ]]
}

@test "work session manager creates and manages sessions correctly" {
    run bash -c "cd '$TEST_REPO_DIR' && ./scripts/work-session-manager.sh start 'Integration test session'"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Work session started" ]]
    
    # Verify session file exists
    [ -f ~/.agent-os/cache/work-session ]
    
    # Verify session content
    run cat ~/.agent-os/cache/work-session
    [[ "$output" =~ "Integration test session" ]]
    [[ "$output" =~ "\"active\": true" ]]
}

@test "commit boundary manager creates logical commits during sessions" {
    # Start work session
    bash -c "cd '$TEST_REPO_DIR' && ./scripts/work-session-manager.sh start 'Test boundary commits'" > /dev/null
    export AGENT_OS_WORK_SESSION=true
    
    # Create some changes
    echo "Test implementation" > "$TEST_REPO_DIR/feature.js"
    git -C "$TEST_REPO_DIR" add feature.js
    
    # Test boundary commit
    run bash -c "cd '$TEST_REPO_DIR' && ./scripts/commit-boundary-manager.sh commit phase_2_complete 'Feature implementation complete'"
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Automatic commit created" ]]
    
    # Verify commit was created
    run bash -c "cd '$TEST_REPO_DIR' && git log --oneline | wc -l"
    [ "${output}" -eq 2 ]  # Initial + boundary commit
    
    # Verify commit message format
    run bash -c "cd '$TEST_REPO_DIR' && git log -1 --pretty=format:'%s'"
    [[ "$output" =~ "feat: complete task implementation" ]]
}

@test "transparent sessions integrate with workflow validation" {
    # Test the complete flow
    
    # 1. Validate workflow conditions
    run bash -c "cd '$TEST_REPO_DIR' && ./scripts/workflow-validator.sh check-with-override"
    [ "$status" -eq 0 ]
    
    # 2. Start session based on validation
    run bash -c "cd '$TEST_REPO_DIR' && ./scripts/work-session-manager.sh start 'Auto-started workflow'"
    [ "$status" -eq 0 ]
    
    # 3. Verify environment is set for transparent operation
    export AGENT_OS_WORK_SESSION=true
    
    # 4. Create some work
    echo "# Test Feature" > "$TEST_REPO_DIR/README.md"
    echo "console.log('test');" > "$TEST_REPO_DIR/test.js"
    
    # 5. Create boundary commits
    bash -c "cd '$TEST_REPO_DIR' && git add . && ./scripts/commit-boundary-manager.sh commit subtask_complete 'Initial implementation'"
    
    echo "// Added tests" >> "$TEST_REPO_DIR/test.js"
    bash -c "cd '$TEST_REPO_DIR' && git add . && ./scripts/commit-boundary-manager.sh commit quality_complete 'Tests added and passing'"
    
    # 6. Verify logical commit structure
    run bash -c "cd '$TEST_REPO_DIR' && git log --oneline | wc -l"
    [ "${output}" -eq 3 ]  # Initial + 2 boundary commits
    
    # 7. End session
    run bash -c "cd '$TEST_REPO_DIR' && ./scripts/work-session-manager.sh end"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Work session ended" ]]
}

@test "override mechanism works when conditions not met" {
    # Break workflow conditions
    rm -rf "$TEST_REPO_DIR/.agent-os/specs"
    
    # Should fail without override
    run bash -c "cd '$TEST_REPO_DIR' && ./scripts/workflow-validator.sh check"
    [ "$status" -eq 1 ]
    
    # Should succeed with override
    export AGENT_OS_FORCE_SESSION=true
    run bash -c "cd '$TEST_REPO_DIR' && ./scripts/workflow-validator.sh check-with-override"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "AGENT_OS_FORCE_SESSION=true - allowing override" ]]
}

@test "sessions prevent excessive commits compared to manual workflow" {
    export AGENT_OS_WORK_SESSION=true
    mkdir -p ~/.agent-os/cache
    echo '{"active": true, "description": "Commit reduction test"}' > ~/.agent-os/cache/work-session
    
    # Simulate work that would normally create many commits
    # In transparent session, this creates logical boundary commits instead
    
    echo "file1" > "$TEST_REPO_DIR/file1.txt"
    bash -c "cd '$TEST_REPO_DIR' && git add . && ./scripts/commit-boundary-manager.sh commit subtask_complete 'File 1 created'" > /dev/null
    
    echo "file2" > "$TEST_REPO_DIR/file2.txt"
    # No boundary - should not create commit
    bash -c "cd '$TEST_REPO_DIR' && git add . && ./scripts/commit-boundary-manager.sh commit intermediate_work" 2>/dev/null || true
    
    echo "file3" > "$TEST_REPO_DIR/file3.txt"
    bash -c "cd '$TEST_REPO_DIR' && git add . && ./scripts/commit-boundary-manager.sh commit phase_2_complete 'Implementation complete'" > /dev/null
    
    # Should have logical commits, not excessive commits
    run bash -c "cd '$TEST_REPO_DIR' && git log --oneline | wc -l"
    [ "${output}" -eq 3 ]  # Initial + 2 logical boundary commits
    
    # Verify commit quality
    run bash -c "cd '$TEST_REPO_DIR' && git log --pretty=format:'%s' | head -2"
    [[ "$output" =~ "feat: complete task implementation" ]]
    [[ "$output" =~ "implement: complete subtask implementation" ]]
}