#!/usr/bin/env bats

# Test suite for CHANGELOG auto-update functionality
# Tests automatic CHANGELOG.md generation from git and GitHub data

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
    
    # Path to the library
    export LIB_PATH="$ORIG_DIR/scripts/lib/update-documentation-lib.sh"
    
    # Create basic CHANGELOG template
    cat > CHANGELOG.md <<'EOF'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup

## [1.0.0] - 2024-01-01

### Added
- Initial release
EOF
}

teardown() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

# ============================================================================
# Git Commit Analysis Tests
# ============================================================================

@test "analyze_git_commits() detects commit types" {
    source "$LIB_PATH"
    
    # Create test commits of different types
    echo "feature: add user login" > feature.txt
    git add feature.txt
    git commit -m "feat: add user authentication system" >/dev/null 2>&1
    
    echo "bugfix: fix validation" > bugfix.txt  
    git add bugfix.txt
    git commit -m "fix: resolve login validation issue" >/dev/null 2>&1
    
    result=$(analyze_git_commits --since="1 hour ago")
    [ "$?" -eq 0 ]
    [[ "$result" == *"feat:"* ]]
    [[ "$result" == *"fix:"* ]]
}

@test "analyze_git_commits() handles conventional commit format" {
    source "$LIB_PATH"
    
    git commit --allow-empty -m "feat(auth): add OAuth integration

    - Add OAuth provider support
    - Implement token refresh
    - Add user profile sync
    
    Closes #123" >/dev/null 2>&1
    
    result=$(analyze_git_commits --since="1 hour ago" --format="detailed")
    [ "$?" -eq 0 ]
    [[ "$result" == *"feat(auth)"* ]]
    [[ "$result" == *"OAuth integration"* ]]
    [[ "$result" == *"Closes #123"* ]]
}

@test "categorize_commit() sorts commits by type" {
    source "$LIB_PATH"
    
    result=$(categorize_commit "feat: add new feature")
    [[ "$result" == "Added" ]]
    
    result=$(categorize_commit "fix: resolve bug")
    [[ "$result" == "Fixed" ]]
    
    result=$(categorize_commit "docs: update readme")
    [[ "$result" == "Changed" ]]
    
    result=$(categorize_commit "breaking: remove deprecated API")
    [[ "$result" == "Changed" ]]
}

# ============================================================================
# PR Integration Tests  
# ============================================================================

@test "fetch_pr_data() retrieves GitHub PR information" {
    source "$LIB_PATH"
    
    # Mock gh command for testing
    function gh() {
        if [[ "$1" == "pr" && "$2" == "list" ]]; then
            echo '[
                {
                    "number": 123,
                    "title": "Add user authentication", 
                    "mergedAt": "2024-08-28T10:00:00Z",
                    "author": {"login": "testuser"},
                    "body": "Implements OAuth and JWT tokens"
                }
            ]'
        fi
    }
    export -f gh
    
    result=$(fetch_pr_data --merged --limit=5)
    [ "$?" -eq 0 ]
    [[ "$result" == *"123"* ]]
    [[ "$result" == *"Add user authentication"* ]]
}

@test "format_pr_entry() creates changelog entries" {
    source "$LIB_PATH"
    
    local pr_data='{"number": 123, "title": "Add user authentication", "author": {"login": "testuser"}}'
    
    result=$(format_pr_entry "$pr_data" "Added")
    [ "$?" -eq 0 ]
    [[ "$result" == *"- **Add user authentication** (#123)"* ]]
    [[ "$result" == *"@testuser"* ]]
}

# ============================================================================
# CHANGELOG Generation Tests
# ============================================================================

@test "generate_changelog_entries() creates properly formatted entries" {
    source "$LIB_PATH"
    
    # Mock commit and PR data
    export TEST_COMMITS='[
        {"message": "feat: add user login", "date": "2024-08-28", "hash": "abc123"},
        {"message": "fix: resolve validation bug", "date": "2024-08-28", "hash": "def456"}
    ]'
    
    result=$(generate_changelog_entries --since="1 day ago")
    [ "$?" -eq 0 ]
    [[ "$result" == *"### Added"* ]]
    [[ "$result" == *"### Fixed"* ]]
    [[ "$result" == *"- add user login"* ]]
    [[ "$result" == *"- resolve validation bug"* ]]
}

@test "update_changelog_file() preserves existing content" {
    source "$LIB_PATH"
    
    # Backup original changelog
    cp CHANGELOG.md CHANGELOG.md.backup
    
    local new_entries="### Added
- New authentication system (#123)

### Fixed  
- Login validation issue (#124)"
    
    update_changelog_file "$new_entries"
    [ "$?" -eq 0 ]
    
    # Check that new entries were added under [Unreleased]
    grep -A 10 "## \[Unreleased\]" CHANGELOG.md | grep -q "New authentication system"
    
    # Check that existing content is preserved
    grep -q "Initial release" CHANGELOG.md
}

@test "update_changelog_file() handles empty changelog" {
    source "$LIB_PATH"
    
    # Create empty changelog
    echo "# Changelog" > CHANGELOG.md
    
    local new_entries="### Added
- First feature (#100)"
    
    update_changelog_file "$new_entries"
    [ "$?" -eq 0 ]
    
    grep -q "First feature" CHANGELOG.md
    grep -q "Unreleased" CHANGELOG.md
}

# ============================================================================
# Date and Version Tests
# ============================================================================

@test "detect_version_changes() identifies version bumps" {
    source "$LIB_PATH"
    
    # Create version file changes
    echo "1.0.0" > VERSION
    git add VERSION
    git commit -m "release: version 1.0.0" >/dev/null 2>&1
    
    echo "1.1.0" > VERSION
    git add VERSION
    git commit -m "release: version 1.1.0" >/dev/null 2>&1
    
    result=$(detect_version_changes)
    [ "$?" -eq 0 ]
    [[ "$result" == *"1.1.0"* ]]
}

@test "format_changelog_date() uses consistent date format" {
    source "$LIB_PATH"
    
    result=$(format_changelog_date "2024-08-28T14:30:00Z")
    [ "$?" -eq 0 ]
    [[ "$result" == "2024-08-28" ]]
    
    result=$(format_changelog_date "now")
    [ "$?" -eq 0 ]
    [[ "$result" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

# ============================================================================
# Content Preservation Tests
# ============================================================================

@test "preserve_manual_entries() keeps user-written content" {
    source "$LIB_PATH"
    
    # Add manual entry to changelog
    sed -i '' '/## \[Unreleased\]/a\
### Added\
- Manual feature addition by user\
- Another user-written entry\
' CHANGELOG.md
    
    local new_entries="### Added
- Automated feature from git (#200)"
    
    result=$(preserve_manual_entries "$new_entries")
    [ "$?" -eq 0 ]
    
    # Should contain both manual and automated entries
    [[ "$result" == *"Manual feature addition by user"* ]]
    [[ "$result" == *"Automated feature from git"* ]]
}

@test "merge_changelog_sections() combines entries properly" {
    source "$LIB_PATH"
    
    local existing="### Added
- Existing feature
### Fixed
- Existing fix"
    
    local new="### Added  
- New feature
### Changed
- Updated component"
    
    result=$(merge_changelog_sections "$existing" "$new")
    [ "$?" -eq 0 ]
    [[ "$result" == *"Existing feature"* ]]
    [[ "$result" == *"New feature"* ]]
    [[ "$result" == *"Updated component"* ]]
}

# ============================================================================
# Backup and Safety Tests
# ============================================================================

@test "backup_changelog() creates safety backup" {
    source "$LIB_PATH"
    
    backup_changelog
    [ "$?" -eq 0 ]
    [ -f "CHANGELOG.md.backup" ]
    
    # Backup should be identical to original
    diff CHANGELOG.md CHANGELOG.md.backup
}

@test "validate_changelog_format() checks structure" {
    source "$LIB_PATH"
    
    validate_changelog_format CHANGELOG.md
    [ "$?" -eq 0 ]
    
    # Create malformed changelog
    echo "Bad changelog" > bad_changelog.md
    
    validate_changelog_format bad_changelog.md
    [ "$?" -ne 0 ]
}

# ============================================================================
# Integration Tests
# ============================================================================

@test "full_changelog_update() integrates all components" {
    skip "Integration not yet implemented - Task 2.3"
    source "$LIB_PATH"
    
    # Create test commits
    echo "new feature" > feature.txt
    git add feature.txt
    git commit -m "feat: add new feature" >/dev/null 2>&1
    
    echo "bug fix" > fix.txt
    git add fix.txt  
    git commit -m "fix: resolve issue" >/dev/null 2>&1
    
    # Mock PR data
    function gh() {
        echo '[{"number": 100, "title": "Feature PR", "mergedAt": "'$(date -Iseconds)'"}]'
    }
    export -f gh
    
    result=$(full_changelog_update --since="1 hour ago")
    [ "$?" -eq 0 ]
    
    # Verify changelog was updated
    grep -q "add new feature" CHANGELOG.md
    grep -q "resolve issue" CHANGELOG.md
    
    # Verify structure is maintained  
    grep -q "## \[Unreleased\]" CHANGELOG.md
    grep -q "### Added" CHANGELOG.md
    grep -q "### Fixed" CHANGELOG.md
}