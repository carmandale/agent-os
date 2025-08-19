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
    local workflow_state=$(detect_workflow_state)
    log_debug "Workflow state: $workflow_state"
    
    # Only intervene in Agent OS workflows
    if [ "$workflow_state" != "spec_execution" ] && [ "$workflow_state" != "dirty_workspace" ]; then
        log_debug "Not in Agent OS workflow, allowing interaction"
        return 1  # Don't block
    fi
    
    # Check for abandonment patterns in the conversation
    # This would be called by Claude Code with conversation context
    # For now, we'll check the current state for obvious issues
    
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
    local current_spec=$(get_current_spec_folder)
    log_debug "Checking spec abandonment for: $current_spec"
    
    if [ -z "$current_spec" ]; then
        return 1  # No active spec, don't block
    fi
    
    # Check if there are uncommitted changes that should be part of the workflow
    if has_uncommitted_changes; then
        local issue_number=$(get_current_issue_number)
        if [ -n "$issue_number" ]; then
            log_debug "Found uncommitted changes with issue #$issue_number"
            return 0  # Block - should commit changes
        fi
    fi
    
    # Check if tasks are marked complete but not reflected in git
    if [ -f ".agent-os/specs/$current_spec/tasks.md" ]; then
        local completed_tasks=$(grep -c "^- \[x\]" ".agent-os/specs/$current_spec/tasks.md" 2>/dev/null || echo "0")
        local total_tasks=$(grep -c "^- \[" ".agent-os/specs/$current_spec/tasks.md" 2>/dev/null || echo "0")
        
        if [ "$completed_tasks" -gt 0 ] && [ "$total_tasks" -gt 0 ]; then
            log_debug "Found $completed_tasks/$total_tasks completed tasks"
            
            # If we have completed tasks but no recent commits, might be abandonment
            local recent_commits=$(git log --oneline --since="1 hour ago" 2>/dev/null | wc -l)
            if [ "$recent_commits" -eq 0 ] && has_uncommitted_changes; then
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
    
    # If we have uncommitted changes, suggest completing the workflow
    if has_uncommitted_changes; then
        log_debug "Found uncommitted changes in dirty workspace"
        return 0  # Block to suggest cleanup
    fi
    
    return 1  # Don't block
}

# Generate stop message for Claude Code
generate_stop_message() {
    local context=$(build_stop_hook_context)
    
    cat << EOF
🛑 Agent OS Workflow Completion Required

$context

⚠️ WORKFLOW ABANDONMENT DETECTED

The Agent OS workflow system has detected that you may be abandoning an active workflow without proper completion. Professional development requires complete workflows that include:

1. ✅ Implementation completed
2. ✅ Tests passing  
3. ✅ Changes committed with proper issue reference
4. ✅ Pull request created and ready for review
5. ✅ Workspace cleaned and reset

🔄 RECOMMENDED ACTIONS:

$(generate_next_steps)

To continue with the Agent OS workflow, please complete the above steps. To override this check, you can:
- Complete the workflow properly (recommended)
- Use Claude Code settings to disable Agent OS hooks (not recommended)

This message helps ensure your work is properly integrated and doesn't become "zombie code" that exists only in feature branches.
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
    
    # Only run in git repositories
    if ! is_git_repository; then
        log_debug "Not a git repository, exiting"
        exit 0
    fi
    
    # Only run in Agent OS projects
    if ! is_agent_os_project; then
        log_debug "Not an Agent OS project, exiting"
        exit 0
    fi
    
    # Check if we should block
    if should_block_interaction; then
        log_debug "Blocking interaction - generating stop message"
        generate_stop_message
        exit 1  # Block the interaction
    else
        log_debug "Allowing interaction to proceed"
        exit 0  # Allow interaction
    fi
}

# Run main function
main "$@"