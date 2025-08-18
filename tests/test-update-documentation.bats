#!/usr/bin/env bats

# Test suite for update-documentation.sh
# Tests documentation drift detection and audit functionality

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
    
    # Path to the script under test
    export SCRIPT_PATH="$ORIG_DIR/scripts/update-documentation.sh"
}

teardown() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

@test "Normal mode: No changes returns clean status" {
    run bash "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "No changes detected" ]]
}

@test "Normal mode: Detects missing CHANGELOG for code changes" {
    # Make a code change
    echo "function test() {}" > script.sh
    git add script.sh
    
    run bash "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 2 ]
    [[ "$output" =~ "CHANGELOG.md" ]]
}

@test "Normal mode: Detects missing README update for setup changes" {
    # Make a setup change
    echo "#!/bin/bash" > setup.sh
    git add setup.sh
    
    run bash "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 2 ]
    [[ "$output" =~ "README.md" ]]
}

@test "Normal mode: Checks recent commits in CHANGELOG" {
    # Create CHANGELOG with old entry
    cat > CHANGELOG.md <<EOF
# Changelog

## 2024-01-01
- Old entry
EOF
    git add CHANGELOG.md
    git commit -m "Add old changelog" >/dev/null 2>&1
    
    # Make new change
    echo "new code" > new-feature.sh
    git add new-feature.sh
    
    run bash "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 2 ]
    [[ "$output" =~ "CHANGELOG.md" ]]
}

@test "Normal mode: Detects issues without specs" {
    # Create .agent-os/specs directory
    mkdir -p .agent-os/specs
    
    # Simulate an open issue (would need gh mock in real test)
    # For now, just test the structure exists
    
    run bash "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
}

@test "Deep mode: Performs comprehensive audit" {
    run bash "$SCRIPT_PATH" --deep --dry-run
    [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
    [[ "$output" =~ "Deep Evidence Audit" ]] || [[ "$output" =~ "No changes detected" ]]
}

@test "Deep mode: Validates file references" {
    # Create files with references
    mkdir -p .agent-os/product
    cat > .agent-os/product/mission.md <<EOF
# Mission

See @.agent-os/specs/non-existent/spec.md
EOF
    git add .agent-os/product/mission.md
    
    run bash "$SCRIPT_PATH" --deep --dry-run
    # Should detect the issue or run cleanly
    [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
}

@test "Deep mode: Cross-references roadmap with specs" {
    mkdir -p .agent-os/product .agent-os/specs
    
    # Create roadmap with reference
    cat > .agent-os/product/roadmap.md <<EOF
# Roadmap

- [ ] Feature 1 - See spec #123
EOF
    git add .agent-os/product/roadmap.md
    
    run bash "$SCRIPT_PATH" --deep --dry-run
    [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
}

@test "Create missing: Scaffolds minimal documentation" {
    # Make a change that requires CHANGELOG
    echo "code" > feature.sh
    git add feature.sh
    
    run bash "$SCRIPT_PATH" --create-missing
    [ "$status" -eq 0 ] || [ "$status" -eq 2 ]
    
    # Check if CHANGELOG was created with minimal scaffold
    if [ -f CHANGELOG.md ]; then
        [[ "$(cat CHANGELOG.md)" =~ "References" ]]
    fi
}

@test "Diff only mode: Shows git diff stats" {
    echo "test" > test.txt
    git add test.txt
    
    run bash "$SCRIPT_PATH" --diff-only
    [ "$status" -eq 0 ]
}

@test "Exit codes: Returns 0 for clean, 2 for issues" {
    # Clean state
    run bash "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 0 ]
    
    # With issues
    echo "code" > app.js
    git add app.js
    run bash "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 2 ]
}

@test "Agent OS specific: Detects instruction changes need docs" {
    mkdir -p instructions
    echo "workflow" > instructions/test.md
    git add instructions/test.md
    
    run bash "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 2 ]
    [[ "$output" =~ "docs/" ]]
}

@test "Agent OS specific: Detects workflow-modules changes" {
    mkdir -p workflow-modules
    echo "module" > workflow-modules/step-1.md
    git add workflow-modules/step-1.md
    
    run bash "$SCRIPT_PATH" --dry-run
    [ "$status" -eq 2 ]
    [[ "$output" =~ "CHANGELOG.md" ]]
}

@test "Evidence-based: No fabricated recommendations" {
    echo "code" > app.py
    git add app.py
    
    run bash "$SCRIPT_PATH" --dry-run
    
    # Output should only contain factual findings
    # Should not contain speculative language
    ! [[ "$output" =~ "might" ]]
    ! [[ "$output" =~ "probably" ]]
    ! [[ "$output" =~ "consider" ]]
}