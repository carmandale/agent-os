#!/bin/bash

# Test script for evidence standards system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the evidence standards
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

echo "=== Testing Evidence Standards System ==="
echo

# Test evidence requirements retrieval
echo -e "${YELLOW}Evidence Requirements Retrieval:${NC}"

# Test frontend requirements
frontend_reqs=$(get_evidence_requirements "frontend")
if echo "$frontend_reqs" | grep -q "FRONTEND WORK"; then
    result="contains_frontend_content"
else
    result="missing_frontend_content"
fi
run_test "Frontend requirements contain expected content" "contains_frontend_content" "$result"

# Test backend requirements
backend_reqs=$(get_evidence_requirements "backend")
if echo "$backend_reqs" | grep -q "BACKEND WORK"; then
    result="contains_backend_content"
else
    result="missing_backend_content"
fi
run_test "Backend requirements contain expected content" "contains_backend_content" "$result"

# Test script requirements
script_reqs=$(get_evidence_requirements "script")
if echo "$script_reqs" | grep -q "SCRIPT WORK"; then
    result="contains_script_content"
else
    result="missing_script_content"
fi
run_test "Script requirements contain expected content" "contains_script_content" "$result"

# Test general requirements fallback
general_reqs=$(get_evidence_requirements "unknown")
if echo "$general_reqs" | grep -q "GENERAL WORK"; then
    result="contains_general_content"
else
    result="missing_general_content"
fi
run_test "General requirements used for unknown work type" "contains_general_content" "$result"

echo

# Test evidence validation
echo -e "${YELLOW}Evidence Validation:${NC}"

# Test frontend validation - complete evidence
frontend_evidence="I tested the login form in the browser. Clicked through the entire user workflow and verified it works on both desktop and mobile. All form interactions are working correctly."
validation_result=$(validate_evidence_completeness "frontend" "$frontend_evidence")
if echo "$validation_result" | grep -q "✅ Evidence meets requirements"; then
    result="passes"
else
    result="fails"
fi
run_test "Frontend evidence with browser + interaction testing passes" "passes" "$result"

# Test frontend validation - missing evidence
frontend_evidence_incomplete="I implemented the login form component."
validation_result=$(validate_evidence_completeness "frontend" "$frontend_evidence_incomplete")
if echo "$validation_result" | grep -q "❌ Missing browser testing evidence"; then
    result="detects_missing"
else
    result="does_not_detect"
fi
run_test "Frontend validation detects missing browser testing" "detects_missing" "$result"

# Test backend validation - complete evidence
backend_evidence="Tested the API endpoint with curl:
curl -X POST http://localhost:8000/api/users
{\"id\": 123, \"status\": \"created\"}
Also verified the data was correctly saved to the database."
validation_result=$(validate_evidence_completeness "backend" "$backend_evidence")
if echo "$validation_result" | grep -q "✅ Evidence meets requirements"; then
    result="passes"
else
    result="fails"
fi
run_test "Backend evidence with API + database testing passes" "passes" "$result"

# Test backend validation - missing API testing
backend_evidence_incomplete="I implemented the user creation logic and it looks correct."
validation_result=$(validate_evidence_completeness "backend" "$backend_evidence_incomplete")
if echo "$validation_result" | grep -q "❌ Missing API testing evidence"; then
    result="detects_missing"
else
    result="does_not_detect"
fi
run_test "Backend validation detects missing API testing" "detects_missing" "$result"

# Test script validation - complete evidence
script_evidence="Executed the backup script:
\$ ./backup-database.sh
Starting database backup...
✓ Connected to database
✓ Backup completed: backup_2025-07-30.sql
Script executed successfully with no errors."
validation_result=$(validate_evidence_completeness "script" "$script_evidence")
if echo "$validation_result" | grep -q "✅ Evidence meets requirements"; then
    result="passes"
else
    result="fails"
fi
run_test "Script evidence with execution + output passes" "passes" "$result"

# Test script validation - missing execution
script_evidence_incomplete="I wrote a backup script that should work correctly."
validation_result=$(validate_evidence_completeness "script" "$script_evidence_incomplete")
if echo "$validation_result" | grep -q "❌ Missing script execution evidence"; then
    result="detects_missing"
else
    result="does_not_detect"
fi
run_test "Script validation detects missing execution evidence" "detects_missing" "$result"

echo

# Test requirements content specificity
echo -e "${YELLOW}Requirements Content Validation:${NC}"

# Check frontend requirements mention browser testing
if echo "$frontend_reqs" | grep -qi "browser.*testing"; then
    result="mentions_browser"
else
    result="missing_browser"
fi
run_test "Frontend requirements mention browser testing" "mentions_browser" "$result"

# Check backend requirements mention API testing
if echo "$backend_reqs" | grep -qi "api.*testing"; then
    result="mentions_api"
else
    result="missing_api"
fi
run_test "Backend requirements mention API testing" "mentions_api" "$result"

# Check script requirements mention execution
if echo "$script_reqs" | grep -qi "execution.*proof"; then
    result="mentions_execution"
else
    result="missing_execution"
fi
run_test "Script requirements mention execution proof" "mentions_execution" "$result"

echo
echo "=== Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"

if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
    echo -e "${GREEN}All evidence standards tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some evidence standards tests failed${NC}"
    exit 1
fi