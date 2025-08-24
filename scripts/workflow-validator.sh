#!/bin/bash

# Agent OS Workflow Validator
# Validates conditions for transparent work session auto-start

set -e

# Default values
VALIDATION_MODE="${1:-check}"  # check, check-with-override
FORCE_SESSION="${AGENT_OS_FORCE_SESSION:-false}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local level="$1"
    local message="$2"
    case "$level" in
        "error")   echo -e "${RED}❌${NC} $message" ;;
        "success") echo -e "${GREEN}✅${NC} $message" ;;
        "warning") echo -e "${YELLOW}⚠️${NC}  $message" ;;
        "info")    echo -e "${BLUE}ℹ️${NC}  $message" ;;
    esac
}

check_git_status() {
    if [[ -z "$(git status --porcelain 2>/dev/null)" ]]; then
        return 0  # Clean
    else
        return 1  # Dirty
    fi
}

check_active_spec() {
    if find .agent-os/specs -name "tasks.md" -type f 2>/dev/null | grep -q .; then
        return 0  # Found spec
    else
        return 1  # No spec
    fi
}

check_github_issue() {
    # Check if we can find issue reference in spec folders or environment
    if [[ -n "${GITHUB_ISSUE:-}" ]] || find .agent-os/specs -name "*#*" -type d 2>/dev/null | grep -q .; then
        return 0  # Issue found
    else
        return 1  # No issue
    fi
}

validate_workflow_conditions() {
    local git_clean=false
    local spec_exists=false
    local issue_exists=false
    local conditions_met=true

    print_status "info" "Checking workflow conditions for transparent work session auto-start..."
    echo

    # Check git status
    if check_git_status; then
        print_status "success" "Git workspace is clean"
        git_clean=true
    else
        print_status "error" "Git workspace has uncommitted changes"
        git_clean=false
        conditions_met=false
    fi

    # Check for active spec
    if check_active_spec; then
        local spec_path=$(find .agent-os/specs -name "tasks.md" -type f | head -1)
        local spec_dir=$(dirname "$spec_path")
        print_status "success" "Active spec found: $(basename "$spec_dir")"
        spec_exists=true
    else
        print_status "error" "No active spec found in .agent-os/specs/"
        spec_exists=false
        conditions_met=false
    fi

    # Check for GitHub issue
    if check_github_issue; then
        print_status "success" "GitHub issue reference found"
        issue_exists=true
    else
        print_status "error" "No GitHub issue reference found"
        issue_exists=false
        conditions_met=false
    fi

    echo
    
    # Summary and guidance
    if [[ "$conditions_met" == "true" ]]; then
        print_status "success" "All conditions met - transparent work session can auto-start"
        return 0
    else
        print_status "warning" "Workflow conditions not met for auto-start"
        echo
        print_status "info" "To enable transparent work sessions, please:"
        
        if [[ "$git_clean" == "false" ]]; then
            echo "  1. Commit or stash uncommitted changes: git add . && git commit -m 'message'"
        fi
        
        if [[ "$spec_exists" == "false" ]]; then
            echo "  2. Create a feature specification: /create-spec"
        fi
        
        if [[ "$issue_exists" == "false" ]]; then
            echo "  3. Create or reference a GitHub issue for this work"
        fi
        
        echo
        if [[ "$FORCE_SESSION" == "true" ]]; then
            print_status "warning" "AGENT_OS_FORCE_SESSION=true - allowing override"
            return 0
        else
            print_status "info" "Override with: export AGENT_OS_FORCE_SESSION=true"
            return 1
        fi
    fi
}

# Main execution
case "$VALIDATION_MODE" in
    "check")
        validate_workflow_conditions
        ;;
    "check-with-override")
        validate_workflow_conditions || {
            if [[ "$FORCE_SESSION" == "true" ]]; then
                exit 0
            else
                exit 1
            fi
        }
        ;;
    *)
        echo "Usage: $0 [check|check-with-override]"
        echo "Environment: AGENT_OS_FORCE_SESSION=true to override failed conditions"
        exit 1
        ;;
esac
