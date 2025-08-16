#!/bin/bash

# test-utilities.sh
# Common utilities for hook tests

# Test framework functions
TESTS_PASSED=0
TESTS_FAILED=0
TEST_OUTPUT=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to start a test suite
start_test_suite() {
    local suite_name="$1"
    echo -e "${YELLOW}🧪 Testing $suite_name${NC}"
    echo "========================================"
    TESTS_PASSED=0
    TESTS_FAILED=0
}

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}" # Default to expecting success
    
    echo -n "  $test_name... "
    
    # Capture output and result
    local output result
    output=$(eval "$test_command" 2>&1)
    result=$?
    
    if [ "$result" -eq "$expected_result" ]; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        echo "    Expected: $expected_result, Got: $result"
        if [ -n "$output" ]; then
            echo "    Output: $output"
        fi
        ((TESTS_FAILED++))
    fi
}

# Function to assert string contains substring
assert_contains() {
    local test_name="$1"
    local text="$2"
    local expected="$3"
    
    echo -n "  $test_name... "
    
    if echo "$text" | grep -q "$expected"; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        echo "    Expected '$text' to contain '$expected'"
        ((TESTS_FAILED++))
    fi
}

# Function to assert string equals expected
assert_equals() {
    local test_name="$1"
    local actual="$2"
    local expected="$3"
    
    echo -n "  $test_name... "
    
    if [ "$actual" = "$expected" ]; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        echo "    Expected: '$expected', Got: '$actual'"
        ((TESTS_FAILED++))
    fi
}

# Function to finish test suite
finish_test_suite() {
    echo ""
    echo "Results: ${GREEN}$TESTS_PASSED passed${NC}, ${RED}$TESTS_FAILED failed${NC}"
    echo ""
    
    if [ "$TESTS_FAILED" -gt 0 ]; then
        return 1
    fi
    return 0
}

# Function to create temporary git repository for testing
create_test_repo() {
    local repo_dir="$1"
    
    mkdir -p "$repo_dir"
    cd "$repo_dir"
    
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create initial commit
    echo "# Test Repo" > README.md
    git add README.md
    git commit -q -m "Initial commit"
}

# Function to create Agent OS project structure
create_agent_os_project() {
    local project_dir="$1"
    
    mkdir -p "$project_dir/.agent-os/product"
    mkdir -p "$project_dir/.agent-os/specs"
    
    # Create basic mission file
    cat > "$project_dir/.agent-os/product/mission.md" << 'EOF'
# Test Product Mission

> Last Updated: 2025-01-01
> Version: 1.0.0

## Pitch

Test product for Agent OS testing purposes.
EOF

    # Create basic tech stack file
    cat > "$project_dir/.agent-os/product/tech-stack.md" << 'EOF'
# Technical Stack

> Last Updated: 2025-01-01
> Version: 1.0.0

**Application Framework:** Test Framework
**Database System:** Test DB
EOF

    # Create sample spec
    local spec_dir="$project_dir/.agent-os/specs/2025-01-01-test-feature-#123"
    mkdir -p "$spec_dir"
    
    cat > "$spec_dir/spec.md" << 'EOF'
# Spec Requirements Document

> Spec: Test Feature
> Created: 2025-01-01
> GitHub Issue: #123
> Status: Planning

## Overview

Test feature for hook testing.
EOF

    cat > "$spec_dir/tasks.md" << 'EOF'
# Spec Tasks

- [ ] 1. Test task one
  - [ ] 1.1 Subtask one
  - [x] 1.2 Subtask two
- [x] 2. Completed task
  - [x] 2.1 Completed subtask
EOF
}

# Function to cleanup test files
cleanup_test_files() {
    local cleanup_dir="$1"
    
    if [ -n "$cleanup_dir" ] && [ -d "$cleanup_dir" ]; then
        rm -rf "$cleanup_dir"
    fi
}

# Sample conversation data for testing
get_sample_agent_os_conversation() {
    cat << 'EOF'
I'll help you implement the user authentication feature. Let me first read the spec file.

Looking at @.agent-os/specs/2025-01-01-user-auth-#123/spec.md, I can see the requirements.

Following @~/.agent-os/instructions/core/execute-tasks.md, I'll start with the first task.

Quality checks passed! All tests are passing and the feature is working correctly.
EOF
}

get_sample_non_agent_os_conversation() {
    cat << 'EOF'
I'll help you debug this JavaScript issue. Let me look at the error message.

The problem is in the async function - you need to await the promise.

Here's the fixed code that should resolve the issue.
EOF
}

get_sample_high_risk_conversation() {
    cat << 'EOF'
I'm following @~/.agent-os/instructions/core/execute-tasks.md for this implementation.

✅ Quality Assurance Completed:
- All tests passing
- Linting successful
- Browser validation completed
- API endpoints tested

🎉 WORK FULLY INTEGRATED AND COMPLETE

The implementation is finished and ready for testing.
EOF
}