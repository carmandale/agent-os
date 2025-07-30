#!/bin/bash

# Test script for evidence validation logic in testing-enforcer.sh

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the testing enforcer
source "$HOOKS_DIR/lib/testing-enforcer.sh"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Test function
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

echo "=== Testing Evidence Validation Logic ==="
echo

# Test frontend evidence detection
echo -e "${YELLOW}Frontend Testing Evidence:${NC}"

# Should detect browser testing evidence
message="I tested the component in the browser and everything works correctly"
contains_testing_evidence "$message" && result="true" || result="false"
run_test "Detects browser testing evidence" "true" "$result"

# Should detect Playwright evidence
message="Ran Playwright tests and all scenarios passed:
\`\`\`
Running 5 tests using 1 worker
✓ Login flow works correctly
✓ User can navigate dashboard
✓ Form submission successful
✓ Error handling displays properly
✓ Responsive design works
\`\`\`"
contains_testing_evidence "$message" && result="true" || result="false"
run_test "Detects Playwright test output" "true" "$result"

# Should detect npm test evidence
message="Ran npm test to verify the changes:
\`\`\`
PASS src/components/Button.test.tsx
PASS src/utils/validation.test.ts
Test Suites: 2 passed, 2 total
\`\`\`"
contains_testing_evidence "$message" && result="true" || result="false"
run_test "Detects npm test evidence" "true" "$result"

echo

# Test backend evidence detection
echo -e "${YELLOW}Backend Testing Evidence:${NC}"

# Should detect API testing evidence
message="Tested the API endpoint with curl:
\`\`\`
curl -X POST http://localhost:8000/api/users
{\"id\": 123, \"status\": \"created\"}
\`\`\`"
contains_testing_evidence "$message" && result="true" || result="false"
run_test "Detects curl API testing" "true" "$result"

# Should detect pytest evidence
message="Ran pytest and all tests pass:
\`\`\`
================================= test session starts =================================
collected 15 items
test_models.py .......... [66%]
test_views.py ..... [100%]
================================= 15 passed in 2.34s =================================
\`\`\`"
contains_testing_evidence "$message" && result="true" || result="false"
run_test "Detects pytest evidence" "true" "$result"

echo

# Test script evidence detection
echo -e "${YELLOW}Script Testing Evidence:${NC}"

# Should detect script execution output
message="Executed the script and it works correctly:
\`\`\`bash
./backup-database.sh
Starting database backup...
✓ Connected to database
✓ Backup completed: backup_2025-07-30.sql
\`\`\`"
contains_testing_evidence "$message" && result="true" || result="false"
run_test "Detects script execution evidence" "true" "$result"

# Should detect command output evidence
message="Tested the command and got expected output:
\`\`\`
$ node migrate.js
Migration started...
✓ Table users created
✓ Table posts created  
✓ Migration completed successfully
\`\`\`"
contains_testing_evidence "$message" && result="true" || result="false"
run_test "Detects command execution evidence" "true" "$result"

echo

# Test negative cases (should NOT detect as evidence)
echo -e "${YELLOW}False Positive Prevention:${NC}"

# Should not detect future testing plans
message="I will test this in the browser later"
contains_testing_evidence "$message" && result="true" || result="false"
run_test "Ignores future testing plans" "false" "$result"

# Should not detect testing mentions without execution
message="This feature needs comprehensive testing"
contains_testing_evidence "$message" && result="true" || result="false"
run_test "Ignores testing mentions without execution" "false" "$result"

# Should not detect broken/failed tests as evidence
message="Ran the tests but they failed:
\`\`\`
FAIL src/components/Button.test.tsx
Expected behavior not working
\`\`\`"
contains_testing_evidence "$message" && result="true" || result="false"
run_test "Does not accept failed tests as evidence" "true" "$result"

echo

# Test edge cases
echo -e "${YELLOW}Edge Cases:${NC}"

# Should handle mixed content
message="Implemented the feature and tested locally. The tests are all passing:
\`\`\`
✓ All 25 tests passed
\`\`\`
Also verified in browser that the UI works correctly."
contains_testing_evidence "$message" && result="true" || result="false"
run_test "Handles mixed testing evidence" "true" "$result"

# Should detect testing in code blocks
message="Here's the implementation:
\`\`\`javascript
function validate() { return true; }
\`\`\`
Tested with:
\`\`\`
npm test -- --coverage
All tests passed with 100% coverage
\`\`\`"
contains_testing_evidence "$message" && result="true" || result="false"
run_test "Detects evidence in separate code blocks" "true" "$result"

echo
echo "=== Test Summary ==="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"

if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
    echo -e "${GREEN}All evidence validation tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some evidence validation tests failed${NC}"
    exit 1
fi