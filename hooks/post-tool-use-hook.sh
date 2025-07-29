#!/bin/bash

# post-tool-use-hook.sh
# Agent OS Post Tool Use Hook - Auto-commits documentation changes

set -e

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.agent-os/logs/post-tool-use-hook.log"

# Source utilities
source "$HOOKS_DIR/lib/workflow-detector.sh"
source "$HOOKS_DIR/lib/git-utils.sh"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log_hook() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] POST-TOOL: $*" >> "$LOG_FILE"
}

# Function to determine if tool use was Agent OS-related
is_agent_os_tool_use() {
    local tool_name="$1"
    local tool_input="$2"
    
    # Check for Agent OS file operations
    case "$tool_name" in
        "Edit"|"Write"|"MultiEdit")
            # Check if editing Agent OS files
            if echo "$tool_input" | grep -qE "\.agent-os/|tasks\.md|spec\.md"; then
                return 0
            fi
            ;;
        "Read")
            # Reading Agent OS files doesn't require commits, but indicates workflow
            if echo "$tool_input" | grep -qE "\.agent-os/"; then
                return 0
            fi
            ;;
    esac
    
    return 1
}

# Function to handle Agent OS documentation commits
handle_documentation_commit() {
    log_hook "Checking for Agent OS documentation changes to commit"
    
    # Give git a moment to register file changes
    sleep 0.5
    
    if has_uncommitted_agent_os_changes; then
        log_hook "Found uncommitted Agent OS documentation changes"
        
        # List the files that will be committed
        local modified_files untracked_files
        modified_files=$(get_modified_agent_os_files)
        untracked_files=$(get_untracked_agent_os_files)
        
        if [ -n "$modified_files" ]; then
            log_hook "Modified files: $modified_files"
        fi
        
        if [ -n "$untracked_files" ]; then
            log_hook "Untracked files: $untracked_files"
        fi
        
        # Attempt to commit
        if commit_agent_os_changes; then
            log_hook "Successfully auto-committed Agent OS documentation"
            echo ""
            echo "✅ **Agent OS Documentation Auto-Committed**"
            echo ""
            echo "Changes to Agent OS documentation files have been automatically committed to maintain consistency."
            echo ""
            return 0
        else
            log_hook "Failed to auto-commit Agent OS documentation"
            echo ""
            echo "⚠️ **Failed to Auto-Commit Agent OS Documentation**"
            echo ""
            echo "Please commit Agent OS documentation changes manually when ready."
            echo ""
            return 1
        fi
    else
        log_hook "No Agent OS documentation changes to commit"
    fi
    
    return 0
}

# Main hook execution
main() {
    local tool_name="$1"
    local tool_input="$2"
    local conversation="$3"
    
    log_hook "Post-tool-use hook triggered for tool: $tool_name"
    
    # Check if we're in an Agent OS workflow
    if ! is_agent_os_workflow "$conversation"; then
        log_hook "Not in Agent OS workflow, skipping"
        return 0
    fi
    
    log_hook "Agent OS workflow detected"
    
    # Check if this was Agent OS-related tool use
    if is_agent_os_tool_use "$tool_name" "$tool_input"; then
        log_hook "Agent OS-related tool use detected"
        
        # Only handle commits if we're in a git repository
        if is_git_repo; then
            handle_documentation_commit
        else
            log_hook "Not in git repository, skipping documentation commit"
        fi
    else
        log_hook "Tool use not Agent OS-related, skipping"
    fi
    
    log_hook "Post-tool-use hook completed"
    return 0
}

# Execute main function if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi