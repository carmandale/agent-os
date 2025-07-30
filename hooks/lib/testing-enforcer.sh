#!/bin/bash

# testing-enforcer.sh
# Detects completion claims without testing evidence
# Part of Agent OS testing enforcement system

set -e

# Patterns that indicate completion claims
COMPLETION_PATTERNS=(
    "complete"
    "finished"
    "done"
    "ready"
    "resolved"
    "working"
    "successful"
    "implemented"
    "fixed"
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
    "tested.*locally"
    "ran.*test"
    "execution.*output"
    "command.*output"
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
            reminder+="• Run Playwright tests: \`npm test\` or \`yarn test\`\n"
            reminder+="• Test in actual browser with user interactions\n"
            reminder+="• Capture screenshots or test output\n"
            reminder+="• Verify all UI components work as expected"
            ;;
        "backend")
            reminder="**🧪 TESTING REQUIRED for Backend Work:**\n"
            reminder+="• Run unit tests: \`pytest\` or test framework\n"
            reminder+="• Test API endpoints: \`curl\` or API client\n"
            reminder+="• Verify database operations if applicable\n"
            reminder+="• Show actual response data"
            ;;
        "script")
            reminder="**🧪 TESTING REQUIRED for Scripts:**\n"
            reminder+="• Execute the script and show output\n"
            reminder+="• Test with different inputs/scenarios\n"
            reminder+="• Verify error handling works\n"
            reminder+="• Demonstrate successful execution"
            ;;
        *)
            reminder="**🧪 TESTING REQUIRED:**\n"
            reminder+="• Run relevant tests for your changes\n"
            reminder+="• Show actual execution output\n"
            reminder+="• Verify functionality works as expected\n"
            reminder+="• No completion claims without evidence"
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