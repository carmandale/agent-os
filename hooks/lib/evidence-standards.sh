#!/bin/bash

# evidence-standards.sh
# Defines required testing evidence standards for different work types
# Part of Agent OS testing enforcement system

set -e

# Frontend Work Evidence Requirements
get_frontend_evidence_requirements() {
    cat << 'EOF'
**🎨 FRONTEND WORK - Required Testing Evidence:**

**MANDATORY Requirements:**
• **Browser Testing**: Test actual functionality in browser (Chrome/Firefox/Safari)
• **Visual Verification**: Confirm UI appears and behaves correctly
• **User Interaction**: Test clicks, forms, navigation, user workflows
• **Responsive Testing**: Verify layout works on different screen sizes

**Test Evidence Examples:**
✅ "Tested in browser - login form submits correctly"
✅ "Verified on mobile and desktop - responsive design works"
✅ "Clicked through entire user flow - everything functional"

**Playwright/E2E Testing (if available):**
• Run existing Playwright tests: `npm run test:e2e`
• Show test results with pass/fail status
• Include screenshots or video if available

**Unit Testing:**
• Run component tests: `npm test` or `yarn test`
• Show test suite results
• Verify new functionality has tests

**Evidence Format:**
```
Tested the [feature] in browser:
• ✓ Feature works correctly
• ✓ No console errors
• ✓ Responsive design verified
```

**❌ NOT Acceptable:**
• "Will test later"
• "Looks good in code"
• "Should work fine"
• Failed tests without resolution
EOF
}

# Backend Work Evidence Requirements  
get_backend_evidence_requirements() {
    cat << 'EOF'
**🔧 BACKEND WORK - Required Testing Evidence:**

**MANDATORY Requirements:**
• **API Testing**: Test endpoints with actual HTTP requests
• **Data Validation**: Verify database operations and data integrity
• **Error Handling**: Test error scenarios and edge cases
• **Integration Testing**: Verify connections between components

**API Testing Examples:**
✅ `curl -X POST http://localhost:8000/api/users -d '{"name":"test"}'`
✅ `curl -H "Authorization: Bearer token" http://localhost:8000/api/protected`
✅ API returns correct status codes and response format

**Database Testing:**
• Verify data is created/updated/deleted correctly
• Check database constraints and validations
• Test migrations if applicable

**Unit Testing:**
• Run test suite: `pytest`, `npm test`, `go test`
• Show test results with pass/fail status
• Verify new functionality has tests

**Evidence Format:**
```bash
# Tested API endpoint
curl -X POST http://localhost:8000/api/users
{"id": 123, "status": "created", "name": "test"}

# Verified database
SELECT * FROM users WHERE id = 123;
✓ User created successfully
```

**❌ NOT Acceptable:**
• "API should work"
• "Database logic is correct"
• Untested endpoints
• Failed tests without fixes
EOF
}

# Script Work Evidence Requirements
get_script_evidence_requirements() {
    cat << 'EOF'
**⚙️ SCRIPT WORK - Required Testing Evidence:**

**MANDATORY Requirements:**
• **Execution Proof**: Actually run the script and show output
• **Success Verification**: Confirm script completed successfully
• **Error Handling**: Test error scenarios and edge cases
• **Input Validation**: Test with different inputs/parameters

**Script Testing Examples:**
✅ `./backup.sh` - show full execution output
✅ `python migrate.py` - display migration results
✅ `node deploy.js` - confirm deployment success

**Evidence Format:**
```bash
$ ./backup-database.sh
Starting database backup...
✓ Connected to database
✓ Backup completed: backup_2025-07-30.sql
✓ Backup verified: 1.2MB
Script completed successfully
```

**Testing Requirements:**
• Run script with normal parameters
• Test error conditions (invalid input, missing files)
• Verify output files/changes are created
• Test cleanup/rollback if applicable

**Configuration Scripts:**
• Show before/after states
• Verify configuration changes applied
• Test rollback procedures

**❌ NOT Acceptable:**
• "Script looks correct"
• "Should work when run"
• Syntax-only validation
• Untested error handling
EOF
}

# General Evidence Requirements
get_general_evidence_requirements() {
    cat << 'EOF'
**🔍 GENERAL WORK - Required Testing Evidence:**

**MANDATORY Requirements:**
• **Functional Verification**: Prove the feature/fix works as intended
• **Edge Case Testing**: Test boundary conditions and error scenarios
• **Integration Testing**: Verify compatibility with existing system
• **Documentation Verification**: Ensure docs match implementation

**Evidence Examples:**
✅ "Ran full test suite - all 47 tests passing"
✅ "Manually verified feature works in development environment"
✅ "Tested edge cases: empty input, large files, network errors"

**Test Commands:**
• Run relevant test suites
• Execute manual testing procedures
• Verify system integration
• Check logs for errors

**Evidence Format:**
```
Testing Results:
✓ Unit tests: 25/25 passing
✓ Integration tests: 12/12 passing  
✓ Manual verification completed
✓ No errors in logs
```

**❌ NOT Acceptable:**
• "Code review looks good"
• "Implementation is correct"
• "No obvious issues"
• Incomplete testing
EOF
}

# Function to get evidence requirements by work type
get_evidence_requirements() {
    local work_type="$1"
    
    case "$work_type" in
        "frontend")
            get_frontend_evidence_requirements
            ;;
        "backend") 
            get_backend_evidence_requirements
            ;;
        "script")
            get_script_evidence_requirements
            ;;
        *)
            get_general_evidence_requirements
            ;;
    esac
}

# Function to validate evidence against requirements
validate_evidence_completeness() {
    local work_type="$1"
    local evidence="$2"
    local validation_result=""
    
    case "$work_type" in
        "frontend")
            # Check for browser testing evidence
            if ! echo "$evidence" | grep -qiE "(browser|tested.*ui|visual|responsive)"; then
                validation_result+="❌ Missing browser testing evidence\n"
            fi
            
            # Check for user interaction testing
            if ! echo "$evidence" | grep -qiE "(click|form|interaction|workflow|user)"; then
                validation_result+="❌ Missing user interaction testing\n"
            fi
            ;;
            
        "backend")
            # Check for API testing evidence
            if ! echo "$evidence" | grep -qiE "(curl|api|endpoint|http|request)"; then
                validation_result+="❌ Missing API testing evidence\n"
            fi
            
            # Check for data validation
            if ! echo "$evidence" | grep -qiE "(database|data|query|model)"; then
                validation_result+="❌ Missing database/data validation\n"
            fi
            ;;
            
        "script")
            # Check for execution evidence
            if ! echo "$evidence" | grep -qiE "(executed|ran.*script|\$\.|bash|python.*|node)"; then
                validation_result+="❌ Missing script execution evidence\n"
            fi
            
            # Check for output verification
            if ! echo "$evidence" | grep -qiE "(output|result|completed|success)"; then
                validation_result+="❌ Missing execution output verification\n"
            fi
            ;;
    esac
    
    # Check for general test execution (all work types) - this is a warning, not an error
    local warnings=""
    if ! echo "$evidence" | grep -qiE "(test.*pass|npm test|pytest|test.*result)"; then
        warnings+="⚠️ Consider adding automated test execution\n"
    fi
    
    # Return success if no errors (warnings are okay)
    if [ -z "$validation_result" ]; then
        if [ -z "$warnings" ]; then
            echo "✅ Evidence meets requirements for $work_type work"
        else
            echo -e "✅ Evidence meets requirements for $work_type work\n$warnings"
        fi
    else
        if [ -n "$warnings" ]; then
            echo -e "Evidence validation for $work_type work:\n$validation_result$warnings"
        else
            echo -e "Evidence validation for $work_type work:\n$validation_result"
        fi
    fi
}

# Export functions for use in other scripts
export -f get_evidence_requirements
export -f validate_evidence_completeness
export -f get_frontend_evidence_requirements
export -f get_backend_evidence_requirements
export -f get_script_evidence_requirements
export -f get_general_evidence_requirements