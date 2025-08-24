#!/usr/bin/env bats

# Tests for transparent work session workflow validation logic
# Tests the auto-start detection system for proper Agent OS workflow conditions

load test_helper

setup() {
    # Create test environment
    export TEST_AGENT_OS_DIR=$(mktemp -d)
    export TEST_PROJECT_DIR=$(mktemp -d)
    cd "$TEST_PROJECT_DIR"
    
    # Initialize git repo
    git init -q
    git config user.email "test@example.com"  
    git config user.name "Test User"
    
    # Create basic Agent OS structure
    mkdir -p .agent-os/specs
}

teardown() {
    # Cleanup
    rm -rf "$TEST_AGENT_OS_DIR" "$TEST_PROJECT_DIR" 2>/dev/null || true
    unset TEST_AGENT_OS_DIR TEST_PROJECT_DIR
}

@test "detect clean git status" {
    # Clean repo should pass validation
    run bash -c 'git status --porcelain'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "detect dirty git status" {
    # Create uncommitted file
    echo "test" > test_file.txt
    
    run bash -c 'git status --porcelain'
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [[ "$output" =~ "test_file.txt" ]]
}

@test "detect active spec existence" {
    # Create spec structure
    mkdir -p .agent-os/specs/2025-08-24-test-spec-#123
    echo "# Test Spec" > .agent-os/specs/2025-08-24-test-spec-#123/spec.md
    echo "# Test Tasks" > .agent-os/specs/2025-08-24-test-spec-#123/tasks.md
    
    # Should find active spec
    run bash -c 'find .agent-os/specs -name "*.md" -type f | wc -l'
    [ "$status" -eq 0 ]
    [ "$output" -gt 0 ]
}

@test "detect missing spec" {
    # Empty specs directory should fail validation
    run bash -c 'find .agent-os/specs -name "tasks.md" -type f | wc -l'
    [ "$status" -eq 0 ]
    [ "$output" -eq 0 ]
}

@test "validate workflow conditions all met" {
    # Setup proper workflow conditions:
    # 1. Clean git
    git add . && git commit -q -m "initial commit" --allow-empty
    
    # 2. Active spec
    mkdir -p .agent-os/specs/2025-08-24-test-spec-#123
    echo "# Test Spec" > .agent-os/specs/2025-08-24-test-spec-#123/spec.md
    echo "# Test Tasks" > .agent-os/specs/2025-08-24-test-spec-#123/tasks.md
    git add .agent-os && git commit -q -m "add spec"
    
    # 3. GitHub issue (mock check)
    export MOCK_GITHUB_ISSUE="123"
    
    # All conditions should be met
    run bash -c '[[ -z "$(git status --porcelain)" ]] && [[ -f .agent-os/specs/*/tasks.md ]] && [[ -n "$MOCK_GITHUB_ISSUE" ]]'
    [ "$status" -eq 0 ]
}

@test "validate workflow conditions missing spec" {
    # Clean git but no spec
    git add . && git commit -q -m "initial commit" --allow-empty
    export MOCK_GITHUB_ISSUE="123"
    
    # Should fail due to missing spec
    run bash -c '[[ -z "$(git status --porcelain)" ]] && [[ -f .agent-os/specs/*/tasks.md ]] && [[ -n "$MOCK_GITHUB_ISSUE" ]]'
    [ "$status" -eq 1 ]
}

@test "validate workflow conditions dirty git" {
    # Dirty git with spec and issue
    mkdir -p .agent-os/specs/2025-08-24-test-spec-#123
    echo "# Test Spec" > .agent-os/specs/2025-08-24-test-spec-#123/spec.md
    echo "# Test Tasks" > .agent-os/specs/2025-08-24-test-spec-#123/tasks.md
    echo "uncommitted" > dirty_file.txt
    export MOCK_GITHUB_ISSUE="123"
    
    # Should fail due to dirty git
    run bash -c '[[ -z "$(git status --porcelain)" ]] && [[ -f .agent-os/specs/*/tasks.md ]] && [[ -n "$MOCK_GITHUB_ISSUE" ]]'
    [ "$status" -eq 1 ]
}