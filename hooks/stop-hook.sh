#!/bin/bash

# stop-hook.sh
# Claude Code stop hook for Agent OS workflow abandonment prevention
# This hook prevents users from abandoning Agent OS workflows after quality checks

# Source required utilities
HOOKS_DIR="$(dirname "$0")"
source "$HOOKS_DIR/lib/workflow-detector.sh"
source "$HOOKS_DIR/lib/git-utils.sh"
source "$HOOKS_DIR/lib/context-builder.sh"

# Log function for debugging
log_debug() {
    if [ "${AGENT_OS_DEBUG:-false}" = "true" ]; then
        echo "[STOP-HOOK DEBUG] $*" >&2
    fi
}

# Check if we should block the current interaction
should_block_interaction() {
    # Use basic workflow detection since detect_workflow_state might not exist
    local workflow_state="unknown"

    # Simple checks for Agent OS workflow states
    if [ -d ".agent-os/specs" ] && [ -n "$(find .agent-os/specs -name "*.md" 2>/dev/null)" ]; then
        workflow_state="spec_execution"
    elif ! git diff --quiet HEAD 2>/dev/null; then
        workflow_state="dirty_workspace"
    fi

    log_debug "Workflow state: $workflow_state"

    # Only intervene in Agent OS workflows
    if [ "$workflow_state" != "spec_execution" ] && [ "$workflow_state" != "dirty_workspace" ]; then
        log_debug "Not in Agent OS workflow, allowing interaction"
        return 1  # Don't block
    fi

    # Check for abandonment patterns
    if [ "$workflow_state" = "spec_execution" ]; then
        check_spec_abandonment
        return $?
    elif [ "$workflow_state" = "dirty_workspace" ]; then
        check_workspace_abandonment
        return $?
    fi

    return 1  # Don't block by default
}

# Check for spec execution abandonment
check_spec_abandonment() {
    # Find current spec using simple file operations
    local current_spec=""
    if [ -d ".agent-os/specs" ]; then
        current_spec=$(find .agent-os/specs -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -1)
        current_spec=$(basename "$current_spec" 2>/dev/null)
    fi

    log_debug "Checking spec abandonment for: $current_spec"

    if [ -z "$current_spec" ]; then
        return 1  # No active spec, don't block
    fi

    # Extract issue number from spec name and check if it's closed
    local issue_number=$(echo "$current_spec" | grep -oE '#[0-9]+' | sed 's/#//' | head -1)
    if [ -n "$issue_number" ]; then
        # Check if GitHub CLI is available and issue is closed
        if command -v gh >/dev/null 2>&1; then
            local issue_state=$(gh issue view "$issue_number" --json state -q '.state' 2>/dev/null || echo "")
            if [ "$issue_state" = "CLOSED" ]; then
                log_debug "Issue #$issue_number is closed, not blocking"
                return 1  # Don't block - issue is complete
            fi
        fi
    fi

    # Check if there are uncommitted changes (excluding local config files)
    local uncommitted_files
    uncommitted_files=$(git diff --name-only HEAD 2>/dev/null | grep -v -E "\.(local|temp)\.json$|\.env\.local$|\.DS_Store$" || echo "")

    if [ -n "$uncommitted_files" ]; then
        log_debug "Found uncommitted changes - possible abandonment: $uncommitted_files"
        return 0  # Block - should commit changes
    fi

    # Check if tasks are marked complete but not reflected in git
    if [ -f ".agent-os/specs/$current_spec/tasks.md" ]; then
        local completed_tasks=$(grep -c "^- \[x\]" ".agent-os/specs/$current_spec/tasks.md" 2>/dev/null || echo "0")
        local total_tasks=$(grep -c "^- \[" ".agent-os/specs/$current_spec/tasks.md" 2>/dev/null || echo "0")

        if [ "$completed_tasks" -gt 0 ] && [ "$total_tasks" -gt 0 ]; then
            log_debug "Found $completed_tasks/$total_tasks completed tasks"

            # If we have completed tasks but no recent commits, might be abandonment
            local recent_commits=$(git log --oneline --since="1 hour ago" 2>/dev/null | wc -l)
            if [ "$recent_commits" -eq 0 ] && ! git diff --quiet HEAD 2>/dev/null; then
                log_debug "Completed tasks but no recent commits - possible abandonment"
                return 0  # Block
            fi
        fi
    fi

    return 1  # Don't block
}

# Check for workspace abandonment
check_workspace_abandonment() {
    log_debug "Checking workspace abandonment"

    # If we have uncommitted changes (excluding local config files), suggest completing the workflow
    local uncommitted_files
    uncommitted_files=$(git diff --name-only HEAD 2>/dev/null | grep -v -E "\.(local|temp)\.json$|\.env\.local$|\.DS_Store$" || echo "")

    if [ -n "$uncommitted_files" ]; then
        log_debug "Found uncommitted changes in dirty workspace: $uncommitted_files"
        return 0  # Block to suggest cleanup
    fi

    return 1  # Don't block
}

# Generate stop message for Claude Code
generate_stop_message() {
    cat << 'EOF'
Agent OS: Incomplete workflow detected

Current status:
EOF

    # Show current state
    if [ -d ".agent-os/specs" ]; then
        local current_spec=$(find .agent-os/specs -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -1)
        if [ -n "$current_spec" ]; then
            echo "  - Active spec: $(basename "$current_spec")" >&2
        fi
    fi

    if ! git diff --quiet HEAD 2>/dev/null; then
        echo "  - Uncommitted changes found" >&2
    fi

    cat << 'EOF' >&2

Next steps:
  1. Review changes: git status
  2. Commit work: git commit -m "description #issue"
  3. Create PR if ready: gh pr create
  4. Or suppress this check: export AGENT_OS_HOOKS_QUIET=true

EOF
}

# Generate specific next steps based on current state
generate_next_steps() {
    local workflow_state=$(detect_workflow_state)
    
    if [ "$workflow_state" = "spec_execution" ]; then
        local current_spec=$(get_current_spec_folder)
        local issue_number=$(get_current_issue_number)
        
        echo "SPEC EXECUTION WORKFLOW COMPLETION:"
        echo "1. Commit changes: git commit -m \"<description> #$issue_number\""
        echo "2. Push changes: git push origin <branch-name>"
        echo "3. Create PR: gh pr create --title \"<title>\" --body \"Fixes #$issue_number\""
        echo "4. Mark tasks complete in: .agent-os/specs/$current_spec/tasks.md"
        echo "5. Return to main branch: git checkout main"
        
    elif [ "$workflow_state" = "dirty_workspace" ]; then
        echo "WORKSPACE CLEANUP REQUIRED:"
        echo "1. Review uncommitted changes: git status"
        echo "2. Either commit work: git add . && git commit -m \"<description>\""
        echo "3. Or stash changes: git stash"
        echo "4. Or discard changes: git checkout ."
        echo "5. Ensure clean workspace: git status"
    fi
}

# Main execution
main() {
    log_debug "Stop hook triggered"

    # Allow users to suppress Agent OS hooks
    if [ "${AGENT_OS_HOOKS_QUIET:-false}" = "true" ]; then
        log_debug "Agent OS hooks suppressed via AGENT_OS_HOOKS_QUIET"
        exit 0
    fi

    # Only run in git repositories
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_debug "Not a git repository, exiting"
        exit 0
    fi

    # Only run in Agent OS projects
    if [ ! -d ".agent-os" ]; then
        log_debug "Not an Agent OS project, exiting"
        exit 0
    fi

    # Check if we should block
    if should_block_interaction; then
        log_debug "Blocking interaction - generating stop message"
        # Write clear message to stderr for Claude Code
        generate_stop_message
        exit 1  # Block the interaction
    else
        log_debug "Allowing interaction to proceed"
        exit 0  # Allow interaction
    fi
}

# Run main function
main "$@"