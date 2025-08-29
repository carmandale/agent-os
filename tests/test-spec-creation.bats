#!/usr/bin/env bats

# Test suite for spec directory creation functionality
# Tests automatic spec directory generation and template creation

setup() {
    # Create a temporary test directory
    export TEST_DIR="$(mktemp -d)"
    export ORIG_DIR="$(pwd)"
    cd "$TEST_DIR"
    
    # Initialize git repo for testing
    git init >/dev/null 2>&1
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    touch README.md
    git add README.md
    git commit -m "Initial commit" >/dev/null 2>&1
    
    # Create .agent-os directory structure
    mkdir -p .agent-os/specs
    
    # Path to the spec creation library (will be created in Task 3.2)
    export SPEC_LIB_PATH="$ORIG_DIR/scripts/lib/spec-creator.sh"
}

teardown() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

# ============================================================================
# Directory Structure Validation Tests
# ============================================================================

@test "spec directory naming follows date-issue format" {
    source "$SPEC_LIB_PATH"
    
    result=$(generate_spec_directory "fix user authentication" 123)
    [ "$?" -eq 0 ]
    [[ "$result" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-fix-user-authentication-#123$ ]]
}

@test "spec directory creation with proper structure" {
    source "$SPEC_LIB_PATH"
    
    spec_dir=$(generate_spec_directory "implement dashboard" 456)
    setup_spec_structure "$spec_dir"
    create_spec_template "$spec_dir" "implement dashboard" 456
    create_tasks_template "$spec_dir" "implement dashboard"
    
    [ -d ".agent-os/specs/$spec_dir" ]
    [ -f ".agent-os/specs/$spec_dir/spec.md" ]
    [ -f ".agent-os/specs/$spec_dir/tasks.md" ]
    [ -d ".agent-os/specs/$spec_dir/sub-specs" ]
}

@test "spec template generation with proper content" {
    source "$SPEC_LIB_PATH"
    
    spec_dir="2024-08-28-test-feature-#789"
    create_spec_directory "$spec_dir"
    create_spec_template "$spec_dir" "test feature" 789
    
    [ -f ".agent-os/specs/$spec_dir/spec.md" ]
    
    # Check for required content
    grep -q "# Spec Requirements Document" ".agent-os/specs/$spec_dir/spec.md"
    grep -q "Created: $(date +%Y-%m-%d)" ".agent-os/specs/$spec_dir/spec.md"
    grep -q "test feature" ".agent-os/specs/$spec_dir/spec.md"
}

@test "tasks.md template generation with proper structure" {
    source "$SPEC_LIB_PATH"
    
    spec_dir="2024-08-28-test-tasks-#101"
    create_spec_directory "$spec_dir"
    create_tasks_template "$spec_dir" "test tasks feature"
    
    [ -f ".agent-os/specs/$spec_dir/tasks.md" ]
    
    # Check for required task structure
    grep -q "# Implementation Tasks" ".agent-os/specs/$spec_dir/tasks.md"
    grep -q "## Phase 1:" ".agent-os/specs/$spec_dir/tasks.md"
    grep -q "\\- \\[ \\]" ".agent-os/specs/$spec_dir/tasks.md"
}

@test "sub-specs directory structure creation" {
    source "$SPEC_LIB_PATH"
    
    spec_dir="2024-08-28-test-subspecs-#202"
    setup_spec_structure "$spec_dir"
    
    [ -d ".agent-os/specs/$spec_dir/sub-specs" ]
    [ -f ".agent-os/specs/$spec_dir/sub-specs/.gitkeep" ]
}

# ============================================================================
# Naming Convention Tests
# ============================================================================

@test "validate_spec_name() accepts valid names" {
    source "$SPEC_LIB_PATH"
    
    validate_spec_name "implement user authentication"
    [ "$?" -eq 0 ]
    
    validate_spec_name "fix-database-connection"
    [ "$?" -eq 0 ]
    
    validate_spec_name "Add New Dashboard Feature"
    [ "$?" -eq 0 ]
}

@test "validate_spec_name() rejects invalid names" {
    source "$SPEC_LIB_PATH"
    
    ! validate_spec_name ""
    
    ! validate_spec_name "a"
    
    ! validate_spec_name "name with / slash"
    
    ! validate_spec_name "name with . dots"
}

@test "spec name sanitization for directory names" {
    source "$SPEC_LIB_PATH"
    
    result=$(sanitize_spec_name "Fix User Auth & Login Issues")
    [[ "$result" == "fix-user-auth-login-issues" ]]
    
    result=$(sanitize_spec_name "Implement API v2.0 Support")
    [[ "$result" == "implement-api-v2-0-support" ]]
}

# ============================================================================
# Existing Directory Handling Tests
# ============================================================================

@test "handles existing directories without overwriting" {
    source "$SPEC_LIB_PATH"
    
    spec_dir="2024-08-28-existing-test-#303"
    mkdir -p ".agent-os/specs/$spec_dir"
    echo "existing content" > ".agent-os/specs/$spec_dir/spec.md"
    
    create_spec_directory "$spec_dir"
    
    # Should not overwrite existing content
    grep -q "existing content" ".agent-os/specs/$spec_dir/spec.md"
    
    # Should still create missing files
    [ -f ".agent-os/specs/$spec_dir/tasks.md" ]
}

@test "detects spec directory conflicts" {
    source "$SPEC_LIB_PATH"
    
    spec_dir="2024-08-28-conflict-test-#404"
    mkdir -p ".agent-os/specs/$spec_dir"
    
    check_spec_directory_exists "$spec_dir"
    [ "$?" -eq 0 ]
    
    check_spec_directory_exists "nonexistent-spec"
    [ "$?" -ne 0 ]
}

# ============================================================================
# Integration with GitHub Issues Tests
# ============================================================================

@test "generates spec directory from GitHub issue number" {
    skip "Function not yet implemented - Task 3.2"
    source "$SPEC_LIB_PATH"
    
    # Mock gh command for testing
    function gh() {
        if [[ "$1" == "issue" && "$2" == "view" && "$3" == "505" ]]; then
            echo "title: Implement Real-time Notifications"
        fi
    }
    export -f gh
    
    result=$(create_spec_from_issue 505)
    [ "$?" -eq 0 ]
    [[ "$result" =~ implement-real-time-notifications-#505 ]]
}

@test "handles GitHub API failures gracefully" {
    skip "Function not yet implemented - Task 3.2"
    source "$SPEC_LIB_PATH"
    
    # Mock failing gh command
    function gh() {
        return 1
    }
    export -f gh
    
    result=$(create_spec_from_issue 999)
    [ "$?" -ne 0 ]
    [[ "$result" == *"Failed to fetch issue"* ]]
}

# ============================================================================
# Template Content Tests
# ============================================================================

@test "spec template includes all required sections" {
    skip "Function not yet implemented - Task 3.2"
    source "$SPEC_LIB_PATH"
    
    spec_dir="2024-08-28-template-test-#606"
    create_spec_directory "$spec_dir"
    create_spec_template "$spec_dir" "template test feature" 606
    
    spec_file=".agent-os/specs/$spec_dir/spec.md"
    
    # Check all required sections
    grep -q "## Overview" "$spec_file"
    grep -q "## User Stories" "$spec_file"
    grep -q "## Spec Scope" "$spec_file"
    grep -q "## Technical Requirements" "$spec_file"
    grep -q "## Success Criteria" "$spec_file"
}

@test "tasks template includes proper task structure" {
    skip "Function not yet implemented - Task 3.2"
    source "$SPEC_LIB_PATH"
    
    spec_dir="2024-08-28-tasks-template-test-#707"
    create_spec_directory "$spec_dir"
    create_tasks_template "$spec_dir" "tasks template test"
    
    tasks_file=".agent-os/specs/$spec_dir/tasks.md"
    
    # Check task structure
    grep -q "## Phase 1: Planning" "$tasks_file"
    grep -q "## Phase 2: Implementation" "$tasks_file"
    grep -q "## Phase 3: Testing" "$tasks_file"
    grep -q "## Phase 4: Documentation" "$tasks_file"
}