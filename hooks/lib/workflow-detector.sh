#!/bin/bash

# workflow-detector.sh
# Detects current Agent OS workflow state and context

set -e

# Source required utilities
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HOOKS_DIR/lib/git-utils.sh"

# Function to detect if we're in Agent OS workflow
is_agent_os_workflow() {
    local conversation="$1"
    
    # Check for Agent OS workflow indicators in conversation
    if echo "$conversation" | grep -qE "(execute-tasks\.md|create-spec\.md|plan-product\.md|analyze-product\.md)"; then
        return 0
    fi
    
    # Check for Agent OS command usage
    if echo "$conversation" | grep -qE "(/plan-product|/create-spec|/execute-tasks|/analyze-product|/hygiene-check)"; then
        return 0
    fi
    
    # Check for Agent OS file references
    if echo "$conversation" | grep -qE "(@\.agent-os/|@~/\.agent-os/)"; then
        return 0
    fi
    
    return 1
}

# Function to detect current workflow phase
detect_workflow_phase() {
    local conversation="$1"
    
    # Check for spec creation workflow
    if echo "$conversation" | grep -qE "(create-spec\.md|/create-spec)"; then
        echo "spec-creation"
        return
    fi
    
    # Check for task execution workflow
    if echo "$conversation" | grep -qE "(execute-tasks\.md|/execute-tasks)"; then
        echo "task-execution"
        return
    fi
    
    # Check for product planning workflow
    if echo "$conversation" | grep -qE "(plan-product\.md|/plan-product)"; then
        echo "product-planning"
        return
    fi
    
    # Check for product analysis workflow
    if echo "$conversation" | grep -qE "(analyze-product\.md|/analyze-product)"; then
        echo "product-analysis"
        return
    fi
    
    echo "unknown"
}

# Function to detect workflow abandonment risk
detect_abandonment_risk() {
    local conversation="$1"
    
    # High-risk patterns that typically lead to workflow abandonment
    local high_risk_patterns=(
        "Quality checks passed"
        "All tests passing"
        "Implementation complete"
        "Ready for testing"
        "Feature working"
        "Browser validation"
        "API testing completed"
        "Functionality validated"
        "WORKFLOW COMPLETE"
        "merge approval required"
        "Next steps:"
        "Work is complete"
        "Implementation successful"
        "Task.*COMPLETE"
        "fully integrated and complete"
        "development work finished"
    )
    
    for pattern in "${high_risk_patterns[@]}"; do
        if echo "$conversation" | grep -qiE "$pattern"; then
            echo "high"
            return
        fi
    done
    
    # Medium-risk patterns
    local medium_risk_patterns=(
        "Tests are passing"
        "Linting passed"
        "Quality assurance"
        "Validation complete"
        "Feature implemented"
        "Code changes made"
    )
    
    for pattern in "${medium_risk_patterns[@]}"; do
        if echo "$conversation" | grep -qiE "$pattern"; then
            echo "medium"
            return
        fi
    done
    
    echo "low"
}

# Function to check if current state requires workflow completion
requires_workflow_completion() {
    local conversation="$1"
    
    # Check if we're in a completion-required state
    if echo "$conversation" | grep -qE "(Step [89]|Quality checks|WORKFLOW COMPLETE|merge approval)"; then
        # But not already in git workflow
        if ! echo "$conversation" | grep -qE "(Step 1[0-4]|git commit|PR created|merged)"; then
            return 0
        fi
    fi
    
    return 1
}

# Function to detect if Step 13 blocking is needed
needs_step_13_blocking() {
    local conversation="$1"
    
    # Check if quality checks passed but not yet at Step 13
    if echo "$conversation" | grep -qiE "(Quality checks passed|All tests passing|Task.*COMPLETE)"; then
        # Check if git workflow started
        if echo "$conversation" | grep -qE "(git commit|PR created|Pull request)"; then
            # Check if NOT already at Step 13 blocking message
            if ! echo "$conversation" | grep -qE "(READY TO MERGE|Type.*merge.*to complete|Autonomous.*[Pp]reparation)"; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# Function to detect current spec context
detect_current_spec() {
    # Look for active spec directory
    if [ -d ".agent-os/specs" ]; then
        # Find most recent spec directory
        local latest_spec=$(find .agent-os/specs -maxdepth 1 -type d -name "20*" | sort -r | head -1)
        if [ -n "$latest_spec" ]; then
            basename "$latest_spec"
            return
        fi
    fi
    
    echo ""
}

# Function to detect if documentation needs committing
needs_documentation_commit() {
    local git_status
    git_status=$(git status --porcelain 2>/dev/null || echo "")
    
    # Check for modified Agent OS documentation files
    if echo "$git_status" | grep -qE "^\s*M\s+\.agent-os/"; then
        return 0
    fi
    
    # Check for modified spec files
    if echo "$git_status" | grep -qE "^\s*M\s+.*tasks\.md$"; then
        return 0
    fi
    
    return 1
}

# Function to get workflow suggestions based on current state
get_workflow_suggestions() {
    local conversation="$1"
    local phase
    phase=$(detect_workflow_phase "$conversation")
    
    case "$phase" in
        "spec-creation")
            echo "Consider proceeding to task execution with /execute-tasks"
            ;;
        "task-execution")
            if requires_workflow_completion "$conversation"; then
                echo "Complete the workflow by proceeding through git integration steps"
            else
                echo "Continue with current task implementation"
            fi
            ;;
        "product-planning")
            echo "Consider creating your first feature spec with /create-spec"
            ;;
        "product-analysis")
            echo "Consider planning your next feature with /create-spec"
            ;;
        *)
            echo "Continue with your current workflow"
            ;;
    esac
}

# Main execution when called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-}" in
        "is_workflow")
            is_agent_os_workflow "${2:-}" && echo "true" || echo "false"
            ;;
        "phase")
            detect_workflow_phase "${2:-}"
            ;;
        "abandonment_risk")
            detect_abandonment_risk "${2:-}"
            ;;
        "needs_completion")
            requires_workflow_completion "${2:-}" && echo "true" || echo "false"
            ;;
        "needs_step_13")
            needs_step_13_blocking "${2:-}" && echo "true" || echo "false"
            ;;
        "current_spec")
            detect_current_spec
            ;;
        "needs_commit")
            needs_documentation_commit && echo "true" || echo "false"
            ;;
        "suggestions")
            get_workflow_suggestions "${2:-}"
            ;;
        *)
            echo "Usage: $0 {is_workflow|phase|abandonment_risk|needs_completion|needs_step_13|current_spec|needs_commit|suggestions} [conversation]"
            exit 1
            ;;
    esac
fi