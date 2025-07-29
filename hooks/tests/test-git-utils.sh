#!/bin/bash

# test-git-utils.sh
# Tests for git-utils.sh

set -e

# Get the directory paths
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$TESTS_DIR")"

# Source test utilities
source "$TESTS_DIR/test-utilities.sh"

# Source the module being tested
source "$HOOKS_DIR/lib/git-utils.sh"

# Test git repository detection
test_git_repo_detection() {
    start_test_suite "Git Repository Detection"
    
    # Create temporary test repository
    local test_dir="/tmp/agent-os-git-test-$$"
    create_test_repo "$test_dir"
    
    cd "$test_dir"
    
    # Test repo detection in git directory
    assert_equals "Detects git repository" \
        "$(is_git_repo && echo "true" || echo "false")" \
        "true"
    
    # Test clean workspace detection
    assert_equals "Detects clean workspace" \
        "$(is_clean_workspace && echo "true" || echo "false")" \
        "true"
    
    # Test current branch detection
    local branch
    branch=$(get_current_branch)
    assert_contains "Gets current branch" \
        "$branch" \
        "main\|master"
    
    # Test outside git repo
    cd /tmp
    assert_equals "Rejects non-git directory" \
        "$(is_git_repo && echo "true" || echo "false")" \
        "false"
    
    # Cleanup
    cd /
    cleanup_test_files "$test_dir"
    
    finish_test_suite
}

# Test branch detection
test_branch_detection() {
    start_test_suite "Branch Detection"
    
    # Create temporary test repository
    local test_dir="/tmp/agent-os-branch-test-$$"
    create_test_repo "$test_dir"
    
    cd "$test_dir"
    
    # Test main branch detection
    assert_equals "Main branch is not feature branch" \
        "$(is_feature_branch && echo "true" || echo "false")" \
        "false"
    
    # Create and switch to feature branch
    git checkout -q -b "feature-authentication-#123"
    
    assert_equals "Feature branch detected" \
        "$(is_feature_branch && echo "true" || echo "false")" \
        "true"
    
    local branch
    branch=$(get_current_branch)
    assert_equals "Gets feature branch name" \
        "$branch" \
        "feature-authentication-#123"
    
    # Cleanup
    cd /
    cleanup_test_files "$test_dir"
    
    finish_test_suite
}

# Test Agent OS file operations
test_agent_os_file_operations() {
    start_test_suite "Agent OS File Operations"
    
    # Create temporary test repository with Agent OS structure
    local test_dir="/tmp/agent-os-files-test-$$"
    create_test_repo "$test_dir"
    create_agent_os_project "$test_dir"
    
    cd "$test_dir"
    
    # Add and commit Agent OS files initially to have a clean starting point
    git add .agent-os/
    git commit -q -m "Add Agent OS structure"
    
    # Test no uncommitted changes initially after commit
    assert_equals "No initial Agent OS changes" \
        "$(has_uncommitted_agent_os_changes && echo "true" || echo "false")" \
        "false"
    
    # Modify an Agent OS file
    echo "# Modified" >> .agent-os/product/mission.md
    
    # Test uncommitted changes detection
    assert_equals "Detects uncommitted Agent OS changes" \
        "$(has_uncommitted_agent_os_changes && echo "true" || echo "false")" \
        "true"
    
    # Test modified files detection
    local modified_files
    modified_files=$(get_modified_agent_os_files)
    assert_contains "Lists modified Agent OS files" \
        "$modified_files" \
        ".agent-os/product/mission.md"
    
    # Cleanup
    cd /
    cleanup_test_files "$test_dir"
    
    finish_test_suite
}

# Test commit operations
test_commit_operations() {
    start_test_suite "Commit Operations"
    
    # Create temporary test repository with Agent OS structure
    local test_dir="/tmp/agent-os-commit-test-$$"
    create_test_repo "$test_dir"
    create_agent_os_project "$test_dir"
    
    cd "$test_dir"
    
    # Add Agent OS files to tracking
    git add .agent-os/
    git commit -q -m "Add Agent OS structure"
    
    # Modify an Agent OS file
    echo "# Modified for testing" >> .agent-os/product/mission.md
    
    # Test commit function
    run_test "Commits Agent OS changes" \
        "commit_agent_os_changes" \
        0
    
    # Verify commit was made
    local recent_commit
    recent_commit=$(git log --oneline -1)
    assert_contains "Commit has Agent OS documentation message" \
        "$recent_commit" \
        "docs: update Agent OS documentation"
    
    # Cleanup
    cd /
    cleanup_test_files "$test_dir"
    
    finish_test_suite
}

# Test issue extraction
test_issue_extraction() {
    start_test_suite "Issue Extraction"
    
    # Create temporary test repository
    local test_dir="/tmp/agent-os-issue-test-$$"
    create_test_repo "$test_dir"
    
    cd "$test_dir"
    
    # Create branch with issue number
    git checkout -q -b "feature-auth-#456"
    
    # Test issue extraction from branch
    local issue_num
    issue_num=$(extract_github_issue "branch")
    assert_equals "Extracts issue from branch name" \
        "$issue_num" \
        "456"
    
    # Test commit with issue reference
    echo "test" > test.txt
    git add test.txt
    git commit -q -m "feat: add authentication #456"
    
    issue_num=$(extract_github_issue "commits")
    assert_equals "Extracts issue from commit message" \
        "$issue_num" \
        "456"
    
    # Cleanup
    cd /
    cleanup_test_files "$test_dir"
    
    finish_test_suite
}

# Test work-in-progress detection
test_wip_detection() {
    start_test_suite "Work-in-Progress Detection"
    
    # Create temporary test repository
    local test_dir="/tmp/agent-os-wip-test-$$"
    create_test_repo "$test_dir"
    
    cd "$test_dir"
    
    # Test clean main branch (not WIP)
    assert_equals "Clean main branch is not WIP" \
        "$(is_work_in_progress && echo "true" || echo "false")" \
        "false"
    
    # Create feature branch (WIP)
    git checkout -q -b "feature-test"
    
    assert_equals "Feature branch is WIP" \
        "$(is_work_in_progress && echo "true" || echo "false")" \
        "true"
    
    # Add uncommitted changes
    echo "test" > test.txt
    
    assert_equals "Uncommitted changes indicate WIP" \
        "$(is_work_in_progress && echo "true" || echo "false")" \
        "true"
    
    # Cleanup
    cd /
    cleanup_test_files "$test_dir"
    
    finish_test_suite
}

# Main test execution
main() {
    echo "🧪 Testing git-utils.sh"
    echo "======================="
    echo ""
    
    local total_failures=0
    
    test_git_repo_detection || ((total_failures++))
    test_branch_detection || ((total_failures++))
    test_agent_os_file_operations || ((total_failures++))
    test_commit_operations || ((total_failures++))
    test_issue_extraction || ((total_failures++))
    test_wip_detection || ((total_failures++))
    
    echo "🏁 Git Utils Tests Complete"
    echo "==========================="
    
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