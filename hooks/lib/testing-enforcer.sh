#!/bin/bash

# testing-enforcer.sh
# Detects completion claims without testing evidence
# Part of Agent OS testing enforcement system

set -e

# Source evidence standards for validation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/evidence-standards.sh" ]; then
    source "$SCRIPT_DIR/evidence-standards.sh"
fi

# Patterns that indicate completion claims
COMPLETION_PATTERNS=(
    " complete"
    " finished"
    " done"
    " ready"
    " resolved"
    " working"
    "successful"
    "implemented"
    " fixed"
    "✓"
    "✅"
    "🎉"
)

# Patterns that indicate testing was performed
TESTING_EVIDENCE_PATTERNS=(
    "test.*pass"
    "all.*tests.*passing"
    "playwright.*test"
    "npm.*test"
    "yarn.*test"
    "pytest"
    "curl.*http"
    "api.*call"
    "browser.*test"
    "verified.*in.*browser"
    "tested.*in.*browser"
    "tested.*locally"
    "ran.*test"
    "execution.*output"
    "command.*output"
    "executed.*script"
    "script.*works"
    "backup.*completed"
    "migration.*completed"
)

# Function to check if message contains completion claims
contains_completion_claim() {
    local message="$1"
    local lower_message=$(echo "$message" | tr '[:upper:]' '[:lower:]')
    
    for pattern in "${COMPLETION_PATTERNS[@]}"; do
        if [[ "$lower_message" == *"$pattern"* ]]; then
            return 0
        fi
    done
    
    return 1
}

# Function to check if message contains testing evidence
contains_testing_evidence() {
    local message="$1"
    local lower_message=$(echo "$message" | tr '[:upper:]' '[:lower:]')
    
    for pattern in "${TESTING_EVIDENCE_PATTERNS[@]}"; do
        if echo "$lower_message" | grep -qE "$pattern"; then
            return 0
        fi
    done
    
    # Check for code blocks with test output
    if echo "$message" | grep -qE '```[^`]*test[^`]*```'; then
        return 0
    fi
    
    # Check for code blocks with execution evidence
    if echo "$message" | grep -qE '```[^`]*(✓|passed|completed|successful)[^`]*```'; then
        return 0
    fi
    
    # Check for bash script execution blocks
    if echo "$message" | grep -qE '```bash[^`]*```'; then
        return 0
    fi
    
    # Check for specific test commands
    if echo "$message" | grep -qE 'bash.*test|python.*test|node.*test'; then
        return 0
    fi
    
    return 1
}

# Function to analyze work type from message
detect_work_type() {
    local message="$1"
    local lower_message=$(echo "$message" | tr '[:upper:]' '[:lower:]')
    
    if echo "$lower_message" | grep -qE 'frontend|react|vue|angular|ui|browser|component'; then
        echo "frontend"
    elif echo "$lower_message" | grep -qE 'backend|api|server|endpoint|database|model'; then
        echo "backend"
    elif echo "$lower_message" | grep -qE 'script|bash|shell|command|cli'; then
        echo "script"
    else
        echo "general"
    fi
}

# Function to build testing reminder based on work type
build_testing_reminder() {
    local work_type="$1"
    local reminder=""
    
    case "$work_type" in
        "frontend")
            reminder="**🧪 TESTING REQUIRED for Frontend Work:**\n"
            reminder+="• Test in actual browser (Chrome/Firefox/Safari)\n"
            reminder+="• Verify user interactions (clicks, forms, navigation)\n"
            reminder+="• Check responsive design on different screen sizes\n"
            reminder+="• Run component tests: \`npm test\` or \`yarn test\`\n"
            reminder+="• Run E2E tests if available: \`npm run test:e2e\`\n\n"
            reminder+="**Evidence Template:**\n"
            reminder+="\`\`\`\n"
            reminder+="Tested the [feature] in browser:\n"
            reminder+="• ✓ Feature works correctly\n"
            reminder+="• ✓ No console errors\n"
            reminder+="• ✓ Responsive design verified\n"
            reminder+="• ✓ User interactions functional\n"
            reminder+="\`\`\`"
            ;;
        "backend")
            reminder="**🧪 TESTING REQUIRED for Backend Work:**\n"
            reminder+="• Test API endpoints with actual HTTP requests\n"
            reminder+="• Verify database operations and data integrity\n"
            reminder+="• Run unit tests: \`pytest\`, \`npm test\`, etc.\n"
            reminder+="• Test error scenarios and edge cases\n\n"
            reminder+="**Evidence Template:**\n"
            reminder+="\`\`\`bash\n"
            reminder+="# Tested API endpoint\n"
            reminder+="curl -X POST http://localhost:8000/api/endpoint\n"
            reminder+="{\"result\": \"success\", \"data\": {...}}\n\n"
            reminder+="# Verified database\n"
            reminder+="✓ Data created/updated correctly\n"
            reminder+="✓ All tests passing: 15/15\n"
            reminder+="\`\`\`"
            ;;
        "script")
            reminder="**🧪 TESTING REQUIRED for Scripts:**\n"
            reminder+="• Execute the script and show full output\n"
            reminder+="• Test with different inputs/parameters\n"
            reminder+="• Verify error handling and edge cases\n"
            reminder+="• Confirm successful completion\n\n"
            reminder+="**Evidence Template:**\n"
            reminder+="\`\`\`bash\n"
            reminder+="\$ ./your-script.sh\n"
            reminder+="Starting script execution...\n"
            reminder+="✓ Step 1 completed\n"
            reminder+="✓ Step 2 completed\n"
            reminder+="✓ Script completed successfully\n"
            reminder+="\`\`\`"
            ;;
        *)
            reminder="**🧪 TESTING REQUIRED:**\n"
            reminder+="• Run relevant tests for your changes\n"
            reminder+="• Show actual execution output\n"
            reminder+="• Verify functionality works as expected\n"
            reminder+="• Provide evidence of testing completion\n\n"
            reminder+="**Evidence Template:**\n"
            reminder+="\`\`\`\n"
            reminder+="Testing Results:\n"
            reminder+="✓ [Test type]: [Result]\n"
            reminder+="✓ Manual verification completed\n"
            reminder+="✓ No errors detected\n"
            reminder+="\`\`\`"
            ;;
    esac
    
    echo -e "$reminder"
}

# Function to check if testing is required
requires_testing_evidence() {
    local message="$1"
    
    # Check if this is a completion claim
    if contains_completion_claim "$message"; then
        # Check if testing evidence is provided
        if ! contains_testing_evidence "$message"; then
            return 0  # Testing required but not provided
        fi
    fi
    
    return 1  # Either not a completion claim or has evidence
}

# Export functions
export -f contains_completion_claim
export -f contains_testing_evidence
export -f detect_work_type
export -f build_testing_reminder
export -f requires_testing_evidence