#!/usr/bin/env bats

# Test suite for update-documentation modular refactor
# Tests the modular components extracted from the monolithic script

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
    
    # Path to the modular library (will be created in Task 1.4)
    export LIB_PATH="$ORIG_DIR/scripts/lib/update-documentation-lib.sh"
}

teardown() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

# ============================================================================
# Core Library Loading Tests
# ============================================================================

@test "library exists and can be sourced" {
    [ -f "$LIB_PATH" ]
    source "$LIB_PATH"
}

# ============================================================================
# Flag Parsing Module Tests
# ============================================================================

@test "parse_flags() handles --dry-run flag" {
    source "$LIB_PATH"
    
    result=$(parse_flags --dry-run)
    [ "$?" -eq 0 ]
    [[ "$result" == *"MODE=dry-run"* ]]
}

@test "parse_flags() handles --update flag" {
    source "$LIB_PATH"
    
    result=$(parse_flags --update)
    [ "$?" -eq 0 ]
    [[ "$result" == *"MODE=update"* ]]
}

@test "parse_flags() handles --changelog-only flag" {
    source "$LIB_PATH"
    
    parse_flags --changelog-only
    [ "$?" -eq 0 ]
    [[ "$UPDATE_CHANGELOG" -eq 1 ]]
    [[ "$MODE" == "update" ]]
}

@test "parse_flags() handles --fix-refs flag" {
    source "$LIB_PATH"
    
    parse_flags --fix-refs
    [ "$?" -eq 0 ]
    [[ "$FIX_REFS" -eq 1 ]]
    [[ "$MODE" == "update" ]]
}

@test "parse_flags() handles --sync-roadmap flag" {
    source "$LIB_PATH"
    
    parse_flags --sync-roadmap
    [ "$?" -eq 0 ]
    [[ "$SYNC_ROADMAP" -eq 1 ]]
    [[ "$MODE" == "update" ]]
}

@test "parse_flags() handles --all flag" {
    skip "Function not yet implemented - Task 1.2"
    source "$LIB_PATH"
    
    result=$(parse_flags --all)
    [ "$?" -eq 0 ]
    [[ "$result" == *"UPDATE_ALL=1"* ]]
}

@test "parse_flags() handles multiple flags" {
    skip "Function not yet implemented - Task 1.2"
    source "$LIB_PATH"
    
    result=$(parse_flags --update --fix-refs --sync-roadmap)
    [ "$?" -eq 0 ]
    [[ "$result" == *"MODE=update"* ]]
    [[ "$result" == *"FIX_REFS=1"* ]]
    [[ "$result" == *"SYNC_ROADMAP=1"* ]]
}

# ============================================================================
# Discovery Module Tests
# ============================================================================

@test "discover_changes() detects git changes" {
    skip "Function not yet implemented - Task 1.3"
    source "$LIB_PATH"
    
    echo "# Test" > test.md
    git add test.md
    
    result=$(discover_changes)
    [ "$?" -eq 0 ]
    [[ "$result" == *"test.md"* ]]
}

@test "discover_changes() returns empty for clean workspace" {
    skip "Function not yet implemented - Task 1.3"
    source "$LIB_PATH"
    
    result=$(discover_changes)
    [ "$?" -eq 0 ]
    [ -z "$result" ]
}

# ============================================================================
# Analysis Module Tests
# ============================================================================

@test "analyze_documentation_health() performs basic health check" {
    skip "Function not yet implemented - Task 1.3"
    source "$LIB_PATH"
    
    result=$(analyze_documentation_health)
    [ "$?" -eq 0 ]
    # Should contain sections like "## Issues without specs:"
}

@test "analyze_issues_without_specs() detects missing specs" {
    skip "Function not yet implemented - Task 1.3"
    source "$LIB_PATH"
    
    # Mock gh command for testing
    function gh() {
        if [[ "$1" == "issue" && "$2" == "list" ]]; then
            echo '[{"number": 123, "title": "Test issue"}]'
        fi
    }
    export -f gh
    
    result=$(analyze_issues_without_specs)
    [ "$?" -eq 0 ]
    [[ "$result" == *"Issue #123"* ]]
}

@test "analyze_recent_prs() detects undocumented PRs" {
    skip "Function not yet implemented - Task 1.3"
    source "$LIB_PATH"
    
    # Mock gh command for testing
    function gh() {
        if [[ "$1" == "pr" && "$2" == "list" ]]; then
            echo '[{"number": 456, "title": "Test PR"}]'
        fi
    }
    export -f gh
    
    # Create empty CHANGELOG
    touch CHANGELOG.md
    
    result=$(analyze_recent_prs)
    [ "$?" -eq 0 ]
    [[ "$result" == *"PR #456"* ]]
}

# ============================================================================
# Reporting Module Tests
# ============================================================================

@test "generate_report() creates structured output" {
    skip "Function not yet implemented - Task 1.3"
    source "$LIB_PATH"
    
    result=$(generate_report "Discovery" "test.md" "No issues found")
    [ "$?" -eq 0 ]
    [[ "$result" == *"# Discovery"* ]]
    [[ "$result" == *"test.md"* ]]
}

# ============================================================================
# Validation Module Tests
# ============================================================================

@test "validate_environment() checks required commands" {
    skip "Function not yet implemented - Task 1.3"
    source "$LIB_PATH"
    
    result=$(validate_environment)
    [ "$?" -eq 0 ]
    # Should pass if git, gh, jq are available
}

@test "validate_repository() checks git repository" {
    skip "Function not yet implemented - Task 1.3"
    source "$LIB_PATH"
    
    result=$(validate_repository)
    [ "$?" -eq 0 ]
    # Should pass since we're in a git repo
}

@test "validate_repository() fails outside git repository" {
    skip "Function not yet implemented - Task 1.3"
    source "$LIB_PATH"
    
    cd /tmp
    result=$(validate_repository)
    [ "$?" -ne 0 ]
}

# ============================================================================
# Utility Functions Tests
# ============================================================================

@test "log_info() outputs formatted messages" {
    source "$LIB_PATH"
    
    result=$(log_info "Test message" 2>&1)
    [ "$?" -eq 0 ]
    [[ "$result" == *"Test message"* ]]
}

@test "log_error() outputs error messages" {
    skip "Function not yet implemented - Task 1.3"
    source "$LIB_PATH"
    
    result=$(log_error "Error message")
    [ "$?" -eq 0 ]
    [[ "$result" == *"Error message"* ]]
}

@test "is_dry_run() detects dry run mode" {
    skip "Function not yet implemented - Task 1.3"
    source "$LIB_PATH"
    
    export MODE="dry-run"
    is_dry_run
    [ "$?" -eq 0 ]
    
    export MODE="update"
    is_dry_run
    [ "$?" -ne 0 ]
}

# ============================================================================
# Integration Tests
# ============================================================================

@test "modular components work together" {
    skip "Integration not yet implemented - Task 1.4"
    source "$LIB_PATH"
    
    # Test the full pipeline with modular components
    echo "# Test" > test.md
    git add test.md
    
    export MODE="dry-run"
    result=$(discover_changes | analyze_documentation_health | generate_report "Test" "" "")
    [ "$?" -eq 0 ]
}

@test "backward compatibility maintained" {
    skip "Backward compatibility not yet verified - Task 1.4"
    source "$LIB_PATH"
    
    # Ensure existing functionality still works
    result=$(bash "$ORIG_DIR/scripts/update-documentation.sh" --dry-run)
    [ "$?" -eq 0 ]
    [[ "$result" == *"Discovery"* ]]
}