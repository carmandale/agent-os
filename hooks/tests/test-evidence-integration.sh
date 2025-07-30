#!/bin/bash

# Test script for complete evidence integration system
# Tests the integration between testing-enforcer.sh and evidence-standards.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source both systems
source "$HOOKS_DIR/lib/testing-enforcer.sh"
source "$HOOKS_DIR/lib/evidence-standards.sh"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

echo "=== Testing Complete Evidence Integration System ==="
echo

# Test evidence extraction and validation integration
echo -e "${YELLOW}Evidence Extraction and Validation Integration:${NC}"

# Test frontend evidence extraction with good evidence
frontend_good="I implemented the login form and tested it thoroughly in the browser. Clicked through all user interactions and verified responsive design works on mobile and desktop."
validation_result=$(extract_and_validate_evidence "frontend" "$frontend_good")
if echo "$validation_result" | grep -q "✅ Evidence meets requirements"; then
    result="passes"
else
    result="fails"
fi
run_test "Frontend evidence extraction validates complete evidence" "passes" "$result"

# Test backend evidence extraction with good evidence
backend_good="I implemented the user API and tested it:
curl -X POST http://localhost:8000/api/users
{\"id\": 123, \"status\": \"created\"}
Also verified the user was correctly saved to the database."
validation_result=$(extract_and_validate_evidence "backend" "$backend_good")
if echo "$validation_result" | grep -q "✅ Evidence meets requirements"; then
    result="passes"
else
    result="fails"
fi
run_test "Backend evidence extraction validates complete evidence" "passes" "$result"

# Test script evidence extraction with good evidence
script_good="Executed the backup script:
\$ ./backup.sh
✓ Database connected
✓ Backup completed successfully
The script ran without errors."
validation_result=$(extract_and_validate_evidence "script" "$script_good")
if echo "$validation_result" | grep -q "✅ Evidence meets requirements"; then
    result="passes"
else
    result="fails"
fi
run_test "Script evidence extraction validates complete evidence" "passes" "$result"

# Test evidence extraction with incomplete evidence
incomplete_evidence="I implemented the feature and it should work correctly."
validation_result=$(extract_and_validate_evidence "frontend" "$incomplete_evidence")
if echo "$validation_result" | grep -q "❌ Missing"; then
    result="detects_missing"
else
    result="does_not_detect"
fi
run_test "Evidence extraction detects missing evidence" "detects_missing" "$result"

echo

# Test testing requirements integration
echo -e "${YELLOW}Testing Requirements Integration:${NC}"

# Test that requirements are retrieved from evidence standards
frontend_reqs=$(get_testing_requirements "frontend")
if echo "$frontend_reqs" | grep -q "FRONTEND WORK"; then
    result="uses_standards"
else
    result="uses_fallback"
fi
run_test "Testing requirements uses evidence standards" "uses_standards" "$result"

backend_reqs=$(get_testing_requirements "backend")
if echo "$backend_reqs" | grep -q "BACKEND WORK"; then
    result="uses_standards"
else
    result="uses_fallback"
fi
run_test "Backend requirements uses evidence standards" "uses_standards" "$result"

echo

# Test enhanced testing reminders with templates
echo -e "${YELLOW}Enhanced Testing Reminders:${NC}"

# Test that reminders include evidence templates
frontend_reminder=$(build_testing_reminder "frontend")
if echo "$frontend_reminder" | grep -q "Evidence Template"; then
    result="includes_template"
else
    result="missing_template"
fi
run_test "Frontend reminder includes evidence template" "includes_template" "$result"

backend_reminder=$(build_testing_reminder "backend")
if echo "$backend_reminder" | grep -q "Evidence Template"; then
    result="includes_template"
else
    result="missing_template"
fi
run_test "Backend reminder includes evidence template" "includes_template" "$result"

script_reminder=$(build_testing_reminder "script")
if echo "$script_reminder" | grep -q "Evidence Template"; then
    result="includes_template"
else
    result="missing_template"
fi
run_test "Script reminder includes evidence template" "includes_template" "$result"

echo

# Test complete workflow integration
echo -e "${YELLOW}Complete Workflow Integration:${NC}"

# Test that the system correctly identifies work requiring evidence
work_needing_evidence="Using @.agent-os/specs/test/tasks.md workflow. The feature is complete and ready for testing."
if requires_testing_evidence "$work_needing_evidence"; then
    result="requires_evidence"
else
    result="no_evidence_needed"
fi
run_test "System correctly identifies work needing evidence" "requires_evidence" "$result"

# Test that the system allows work with evidence
work_with_evidence="Using @.agent-os/specs/test/tasks.md workflow. The feature is complete. I tested it in the browser and all functionality works correctly."
if requires_testing_evidence "$work_with_evidence"; then
    result="requires_evidence"
else
    result="no_evidence_needed"
fi
run_test "System allows work with testing evidence" "no_evidence_needed" "$result"

echo

# Test all original tests still pass
echo -e "${YELLOW}Regression Testing:${NC}"

# Run original testing enforcer tests
if bash "$HOOKS_DIR/tests/test-testing-enforcer.sh" >/dev/null 2>&1; then
    original_test_result="pass"
else
    original_test_result="fail"
fi
run_test "Original testing enforcer tests still pass" "pass" "$original_test_result"

# Run evidence standards tests
if bash "$HOOKS_DIR/tests/test-evidence-standards.sh" >/dev/null 2>&1; then
    evidence_test_result="pass"
else
    evidence_test_result="fail"
fi
run_test "Evidence standards tests still pass" "pass" "$evidence_test_result"

# Run evidence validation tests
if bash "$HOOKS_DIR/tests/test-evidence-validation.sh" >/dev/null 2>&1; then
    validation_test_result="pass"
else
    validation_test_result="fail"
fi
run_test "Evidence validation tests still pass" "pass" "$validation_test_result"

echo
echo "=== Integration Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"

if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
    echo -e "${GREEN}All evidence integration tests passed!${NC}"
    echo -e "${GREEN}✅ Task 2: Build Testing Evidence Standards - COMPLETE${NC}"
    exit 0
else
    echo -e "${RED}Some evidence integration tests failed${NC}"
    exit 1
fi