#!/bin/bash

# Test script for workflow module integration with testing enforcement
# Tests the complete workflow behavior with testing requirements

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the testing systems
source "$HOOKS_DIR/lib/testing-enforcer.sh"
source "$HOOKS_DIR/lib/evidence-standards.sh"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

run_test() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
    fi
}

echo "=== Testing Workflow Integration with Testing Enforcement ==="
echo

# Test workflow detection and enforcement
echo -e "${YELLOW}Workflow Detection and Enforcement:${NC}"

# Test that workflow completion claims are properly blocked
completion_without_evidence="I'm working on @.agent-os/specs/feature-#123/tasks.md. The implementation is complete and ready for review."
if requires_testing_evidence "$completion_without_evidence"; then
    result="blocks"
else
    result="allows"
fi
run_test "Workflow blocks completion claims without testing evidence" "blocks" "$result"

# Test that workflow allows completion with proper evidence
completion_with_evidence="I'm working on @.agent-os/specs/feature-#123/tasks.md. The implementation is complete. I tested it thoroughly in the browser and all functionality works correctly. Also ran npm test and all 15 tests pass."
if requires_testing_evidence "$completion_with_evidence"; then
    result="blocks"
else
    result="allows"
fi
run_test "Workflow allows completion with proper testing evidence" "allows" "$result"

echo

# Test work type detection for workflow guidance
echo -e "${YELLOW}Work Type Detection for Workflow Guidance:${NC}"

# Test frontend work detection
frontend_work="I'm implementing a React component for the user dashboard. Updated the UI and added responsive design."
work_type=$(detect_work_type "$frontend_work")
run_test "Detects frontend work in workflow context" "frontend" "$work_type"

# Test backend work detection
backend_work="I'm creating an API endpoint for user authentication. Added the database model and controller logic."
work_type=$(detect_work_type "$backend_work")
run_test "Detects backend work in workflow context" "backend" "$work_type"

# Test script work detection  
script_work="I wrote a bash script to automate the deployment process. Added error handling and logging."
work_type=$(detect_work_type "$script_work")
run_test "Detects script work in workflow context" "script" "$work_type"

echo

# Test workflow-specific testing requirements
echo -e "${YELLOW}Workflow-Specific Testing Requirements:${NC}"

# Test that workflow provides appropriate testing guidance for frontend
frontend_reqs=$(get_testing_requirements "frontend")
if echo "$frontend_reqs" | grep -q "browser"; then
    result="includes_browser_testing"
else
    result="missing_browser_testing"
fi
run_test "Workflow provides browser testing requirements for frontend" "includes_browser_testing" "$result"

# Test that workflow provides appropriate testing guidance for backend
backend_reqs=$(get_testing_requirements "backend")
if echo "$backend_reqs" | grep -q "API"; then
    result="includes_api_testing"
else
    result="missing_api_testing"
fi
run_test "Workflow provides API testing requirements for backend" "includes_api_testing" "$result"

# Test that workflow provides appropriate testing guidance for scripts
script_reqs=$(get_testing_requirements "script")
if echo "$script_reqs" | grep -q "execution"; then
    result="includes_execution_testing"
else
    result="missing_execution_testing"
fi
run_test "Workflow provides execution testing requirements for scripts" "includes_execution_testing" "$result"

echo

# Test workflow evidence validation
echo -e "${YELLOW}Workflow Evidence Validation:${NC}"

# Test frontend evidence validation in workflow context
frontend_evidence="Working on the login component. Tested it in Chrome and Firefox, verified all form interactions work correctly, and confirmed responsive design on mobile devices."
validation_result=$(extract_and_validate_evidence "frontend" "$frontend_evidence")
if echo "$validation_result" | grep -q "✅ Evidence meets requirements"; then
    result="validates"
else
    result="rejects"
fi
run_test "Workflow validates complete frontend evidence" "validates" "$result"

# Test backend evidence validation in workflow context
backend_evidence="Implemented the user registration API. Tested with curl commands, verified database operations, and ran all unit tests successfully."
validation_result=$(extract_and_validate_evidence "backend" "$backend_evidence")
if echo "$validation_result" | grep -q "✅ Evidence meets requirements"; then
    result="validates"
else
    result="rejects"
fi
run_test "Workflow validates complete backend evidence" "validates" "$result"

# Test script evidence validation in workflow context
script_evidence="Created the backup script. Executed it successfully with different parameters, verified output files are created, and tested error handling scenarios."
validation_result=$(extract_and_validate_evidence "script" "$script_evidence")
if echo "$validation_result" | grep -q "✅ Evidence meets requirements"; then
    result="validates"
else
    result="rejects"
fi
run_test "Workflow validates complete script evidence" "validates" "$result"

echo

# Test workflow testing reminders with templates
echo -e "${YELLOW}Workflow Testing Reminders and Templates:${NC}"

# Test that workflow provides actionable testing reminders
frontend_reminder=$(build_testing_reminder "frontend")
if echo "$frontend_reminder" | grep -q "Evidence Template"; then
    result="includes_template"
else
    result="missing_template"
fi
run_test "Workflow provides evidence templates for frontend work" "includes_template" "$result"

backend_reminder=$(build_testing_reminder "backend")
if echo "$backend_reminder" | grep -q "curl"; then
    result="includes_examples"
else
    result="missing_examples"
fi
run_test "Workflow provides practical examples for backend testing" "includes_examples" "$result"

script_reminder=$(build_testing_reminder "script")
if echo "$script_reminder" | grep -q "\$"; then
    result="includes_commands"
else
    result="missing_commands"
fi
run_test "Workflow provides command examples for script testing" "includes_commands" "$result"

echo

# Test workflow enforcement scenarios
echo -e "${YELLOW}Workflow Enforcement Scenarios:${NC}"

# Test mixed work type enforcement
mixed_work="I implemented both the React frontend component and the Express.js API endpoint. The feature is complete and working."
if requires_testing_evidence "$mixed_work"; then
    result="requires_evidence"
else
    result="allows_without_evidence"
fi
run_test "Workflow requires evidence for mixed work types" "requires_evidence" "$result"

# Test workflow with partial evidence
partial_evidence="I implemented the user dashboard. Tested the API endpoints and they return correct data."
if requires_testing_evidence "$partial_evidence"; then
    result="requires_more_evidence"
else
    result="accepts_partial_evidence"
fi
run_test "Workflow requires comprehensive evidence (not just partial)" "requires_more_evidence" "$result"

echo
echo "=== Workflow Integration Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"

if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
    echo -e "${GREEN}All workflow integration tests passed!${NC}"
    echo -e "${BLUE}✅ Workflow modules are ready for testing enforcement integration${NC}"
    exit 0
else
    echo -e "${RED}Some workflow integration tests failed${NC}"
    echo -e "${RED}❌ Workflow integration needs fixes before proceeding${NC}"
    exit 1
fi