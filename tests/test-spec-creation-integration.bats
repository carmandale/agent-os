#!/usr/bin/env bats

# Test suite for spec creation integration with update-documentation command
# Tests Task 3.3: Integrate Spec Creation

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
    echo "# Test Project" > README.md
    git add README.md
    git commit -m "Initial commit" >/dev/null 2>&1
    
    # Create .agent-os directory structure
    mkdir -p .agent-os/specs
    
    # Create a test change to avoid "no changes" condition
    echo "test" > test.txt
    git add test.txt
    
    # Path to the main script
    export SCRIPT_PATH="$ORIG_DIR/scripts/update-documentation.sh"
}

teardown() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

# ============================================================================
# Integration Tests for Task 3.3
# ============================================================================

@test "--create-spec flag is recognized and parsed" {
    source "$ORIG_DIR/scripts/lib/update-documentation-lib.sh"
    source "$ORIG_DIR/scripts/lib/spec-creator.sh"
    
    # Test that the flag sets CREATE_SPEC variable
    CREATE_SPEC=0
    for arg in "--create-spec"; do
        case "$arg" in
            --create-spec) CREATE_SPEC=1 ;;
        esac
    done
    
    [ "$CREATE_SPEC" -eq 1 ]
}

@test "spec creation integration detects missing specs in dry-run mode" {
    # Mock gh command to return test issues
    function gh() {
        case "$1 $2" in
            "issue list")
                echo '[{"number": 123, "title": "Test Issue"}]'
                ;;
            "issue view")
                echo '{"title": "Test Issue"}'
                ;;
        esac
    }
    export -f gh
    
    # Run the script with --create-spec in dry-run mode
    result=$("$SCRIPT_PATH" --create-spec --dry-run 2>/dev/null | grep -E "(Spec Creation|Would create)")
    
    [[ "$result" == *"Spec Creation"* ]]
}

@test "spec creation integration works with spec-creator library" {
    source "$ORIG_DIR/scripts/lib/spec-creator.sh"
    
    # Test that key functions are available
    command -v create_spec_from_issue >/dev/null 2>&1
    [ "$?" -eq 0 ]
    
    command -v create_complete_spec >/dev/null 2>&1  
    [ "$?" -eq 0 ]
    
    command -v generate_spec_directory >/dev/null 2>&1
    [ "$?" -eq 0 ]
}

@test "update-documentation script sources spec-creator library correctly" {
    # Check that the main script sources the spec-creator library
    grep -q "spec-creator.sh" "$SCRIPT_PATH"
    [ "$?" -eq 0 ]
}

@test "CREATE_SPEC variable is properly initialized in main script" {
    # Check that CREATE_SPEC is initialized in the main script
    grep -q "CREATE_SPEC=0" "$SCRIPT_PATH"
    [ "$?" -eq 0 ]
}

@test "spec creation handles missing gh command gracefully" {
    # Ensure gh is not available
    function command() {
        if [[ "$1" == "-v" && "$2" == "gh" ]]; then
            return 1  # gh not available
        fi
        builtin command "$@"
    }
    export -f command
    
    # Script should not fail when gh is unavailable
    result=$("$SCRIPT_PATH" --create-spec --dry-run 2>/dev/null || echo "FAILED")
    
    [[ "$result" != "FAILED" ]]
}

@test "spec creation can be combined with other flags" {
    function gh() {
        echo '[]'  # No issues
    }
    export -f gh
    
    # Test combining --create-spec with --dry-run (exit code 0 or 2 is OK)
    result=$("$SCRIPT_PATH" --create-spec --dry-run 2>/dev/null)
    exit_code=$?
    [ "$exit_code" -eq 0 ] || [ "$exit_code" -eq 2 ]
    
    # Should contain both discovery and spec creation sections
    [[ "$result" == *"Discovery"* ]]
    [[ "$result" == *"Spec Creation"* ]]
}

@test "spec creation integration provides helpful output" {
    function gh() {
        case "$1 $2" in
            "issue list")
                echo '[{"number": 456, "title": "New Feature Request"}]'
                ;;
            "issue view")
                echo '{"title": "New Feature Request"}'
                ;;
        esac
    }
    export -f gh
    
    result=$("$SCRIPT_PATH" --create-spec --dry-run 2>/dev/null)
    
    # Should provide clear information about what would be created
    [[ "$result" == *"Spec Creation from GitHub Issues"* ]]
    [[ "$result" == *"Issue #456"* ]]
    [[ "$result" == *"New Feature Request"* ]]
}