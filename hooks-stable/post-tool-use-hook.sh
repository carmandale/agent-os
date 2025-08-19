#!/bin/bash

# post-tool-use-hook.sh
# Claude Code post-tool-use hook for Agent OS documentation auto-commits
# This hook automatically commits Agent OS documentation changes

# Source required utilities
HOOKS_DIR="$(dirname "$0")"
source "$HOOKS_DIR/lib/workflow-detector.sh"
source "$HOOKS_DIR/lib/git-utils.sh"
source "$HOOKS_DIR/lib/context-builder.sh"

# Log function for debugging
log_debug() {
    if [ "${AGENT_OS_DEBUG:-false}" = "true" ]; then
        echo "[POST-TOOL-USE DEBUG] $*" >&2
    fi
}

# Check if file should be auto-committed
should_auto_commit_file() {
    local file="$1"
    
    # Agent OS documentation patterns
    case "$file" in
        .agent-os/product/*.md)
            return 0 ;;
        .agent-os/specs/*/tasks.md)
            return 0 ;;
        .agent-os/specs/*/spec.md)
            return 0 ;;
        .agent-os/specs/*/sub-specs/*.md)
            return 0 ;;
        *)
            return 1 ;;
    esac
}

# Get modified Agent OS documentation files
get_modified_aos_docs() {
    local modified_files=""
    
    # Check for modified files that match our patterns
    while IFS= read -r file; do
        if [ -n "$file" ] && should_auto_commit_file "$file"; then
            modified_files="$modified_files$file\n"
        fi
    done <<< "$(get_modified_files)"
    
    # Also check staged files
    while IFS= read -r file; do
        if [ -n "$file" ] && should_auto_commit_file "$file"; then
            # Make sure it's not already in our list
            if ! echo -e "$modified_files" | grep -q "^$file$"; then
                modified_files="$modified_files$file\n"
            fi
        fi
    done <<< "$(get_staged_files)"
    
    echo -e "$modified_files" | grep -v "^$"
}

# Create auto-commit message
create_commit_message() {
    local files="$1"
    local file_count=$(echo "$files" | wc -l)
    
    if [ "$file_count" -eq 1 ]; then
        local single_file=$(echo "$files" | head -n1)
        case "$single_file" in
            .agent-os/product/*)
                echo "docs: update Agent OS product documentation"
                ;;
            .agent-os/specs/*/tasks.md)
                echo "docs: update task progress in spec"
                ;;
            .agent-os/specs/*/spec.md)
                echo "docs: update spec requirements"
                ;;
            *)
                echo "docs: update Agent OS documentation"
                ;;
        esac
    else
        echo "docs: update Agent OS documentation ($file_count files)"
    fi
    
    echo ""
    echo "🤖 Auto-committed by Claude Code hooks"
    echo "Co-Authored-By: Claude <noreply@anthropic.com>"
}

# Perform auto-commit
perform_auto_commit() {
    local files="$1"
    
    log_debug "Auto-committing files: $files"
    
    # Stage the Agent OS documentation files
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            git add "$file"
            log_debug "Staged file: $file"
        fi
    done <<< "$files"
    
    # Create commit message
    local commit_message=$(create_commit_message "$files")
    
    # Commit the changes
    if git commit -m "$commit_message" --quiet; then
        log_debug "Auto-commit successful"
        echo "✅ Agent OS documentation auto-committed" >&2
        return 0
    else
        log_debug "Auto-commit failed"
        echo "⚠️  Agent OS documentation auto-commit failed" >&2
        return 1
    fi
}

# Check if we should run auto-commit
should_run_auto_commit() {
    local workflow_state=$(detect_workflow_state)
    
    # Only run in Agent OS projects
    if ! is_agent_os_project; then
        log_debug "Not an Agent OS project"
        return 1
    fi
    
    # Only run if we have uncommitted changes
    if ! has_uncommitted_changes; then
        log_debug "No uncommitted changes"
        return 1
    fi
    
    # Get modified Agent OS docs
    local aos_docs=$(get_modified_aos_docs)
    if [ -z "$aos_docs" ]; then
        log_debug "No modified Agent OS documentation"
        return 1
    fi
    
    log_debug "Found modified Agent OS docs: $aos_docs"
    return 0
}

# Generate status message
generate_status_message() {
    local context=$(build_post_tool_context)
    
    if [ -n "$context" ]; then
        echo "$context"
    fi
}

# Main execution
main() {
    log_debug "Post-tool-use hook triggered"
    
    # Only run in git repositories
    if ! is_git_repository; then
        log_debug "Not a git repository, exiting"
        exit 0
    fi
    
    # Check if we should run auto-commit
    if should_run_auto_commit; then
        local aos_docs=$(get_modified_aos_docs)
        
        # Show what we're about to do
        echo "📝 Agent OS documentation changes detected:" >&2
        while IFS= read -r file; do
            if [ -n "$file" ]; then
                echo "  - $file" >&2
            fi
        done <<< "$aos_docs"
        
        # Perform the auto-commit
        if perform_auto_commit "$aos_docs"; then
            # Generate any additional status info
            local status_msg=$(generate_status_message)
            if [ -n "$status_msg" ]; then
                echo "$status_msg"
            fi
        fi
    else
        log_debug "Auto-commit not needed"
    fi
    
    # Always allow the interaction to continue
    exit 0
}

# Run main function
main "$@"