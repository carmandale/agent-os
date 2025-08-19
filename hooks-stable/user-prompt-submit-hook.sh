#!/bin/bash

# user-prompt-submit-hook.sh  
# Claude Code user-prompt-submit hook for Agent OS context injection
# This hook provides contextual Agent OS information to improve AI assistance

# Source required utilities
HOOKS_DIR="$(dirname "$0")"
source "$HOOKS_DIR/lib/workflow-detector.sh"
source "$HOOKS_DIR/lib/git-utils.sh"
source "$HOOKS_DIR/lib/context-builder.sh"

# Cache file for performance
CONTEXT_CACHE="/tmp/agent-os-context-cache-$$"
CACHE_TTL=60  # seconds

# Log function for debugging
log_debug() {
    if [ "${AGENT_OS_DEBUG:-false}" = "true" ]; then
        echo "[USER-PROMPT-SUBMIT DEBUG] $*" >&2
    fi
}

# Check if cache is valid
is_cache_valid() {
    if [ ! -f "$CONTEXT_CACHE" ]; then
        return 1
    fi
    
    local cache_age=$(( $(date +%s) - $(stat -f "%m" "$CONTEXT_CACHE" 2>/dev/null || stat -c "%Y" "$CONTEXT_CACHE" 2>/dev/null || echo 0) ))
    [ "$cache_age" -lt "$CACHE_TTL" ]
}

# Get cached context or build new
get_context() {
    if is_cache_valid; then
        log_debug "Using cached context"
        cat "$CONTEXT_CACHE"
    else
        log_debug "Building fresh context"
        local context=$(build_context_for_claude)
        echo "$context" > "$CONTEXT_CACHE"
        echo "$context"
    fi
}

# Check if we should inject context
should_inject_context() {
    # Only inject in Agent OS projects
    if ! is_agent_os_project; then
        log_debug "Not an Agent OS project"
        return 1
    fi
    
    # Only inject in git repositories
    if ! is_git_repository; then
        log_debug "Not a git repository"
        return 1
    fi
    
    local workflow_state=$(detect_workflow_state)
    log_debug "Workflow state: $workflow_state"
    
    # Inject context for active workflows
    case "$workflow_state" in
        spec_execution|dirty_workspace|feature_branch)
            return 0
            ;;
        agent_os_project)
            # Even for clean Agent OS projects, provide basic context
            return 0
            ;;
        *)
            # For clean workspaces, provide minimal context
            return 0
            ;;
    esac
}

# Generate context injection message
generate_context_injection() {
    local user_prompt="$1"
    local context=$(get_context)
    
    cat << EOF
<system-reminder>
As you work with this project, you have access to Agent OS context that provides comprehensive information about the current workflow state, project structure, and development status.

Agent OS Context:
$context

This context helps you:
1. Understand the current workflow state and what phase of development we're in
2. Reference relevant Agent OS documentation files using @ syntax
3. Maintain consistency with established patterns and decisions
4. Follow the appropriate Agent OS workflow for the current task

Important: This context is automatically generated and reflects the current state of the project. Use it to provide more informed and contextually appropriate responses.

User's request: $user_prompt
</system-reminder>
EOF
}

# Generate minimal context for non-Agent OS projects
generate_minimal_context() {
    local user_prompt="$1"
    
    if is_git_repository; then
        local branch=$(get_current_branch)
        local repo_status=$(get_repo_status)
        
        cat << EOF
<system-reminder>
Working in git repository:
- Branch: $branch
- Status: $repo_status

User's request: $user_prompt
</system-reminder>
EOF
    else
        # No context injection needed
        echo "$user_prompt"
    fi
}

# Clean up cache on exit
cleanup() {
    if [ -f "$CONTEXT_CACHE" ]; then
        rm -f "$CONTEXT_CACHE"
    fi
}
trap cleanup EXIT

# Main execution
main() {
    local user_prompt="$1"
    
    log_debug "User prompt submit hook triggered"
    log_debug "User prompt length: ${#user_prompt} characters"
    
    # Performance timing
    local start_time=$(date +%s)
    
    if should_inject_context; then
        log_debug "Injecting Agent OS context"
        generate_context_injection "$user_prompt"
    else
        log_debug "Providing minimal context"
        generate_minimal_context "$user_prompt" 
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_debug "Context injection completed in ${duration}s"
    
    # Log performance warning if too slow
    if [ "$duration" -gt 1 ]; then
        echo "⚠️  Agent OS context injection took ${duration}s (target: <1s)" >&2
    fi
}

# Handle the user prompt (passed as argument or stdin)
if [ $# -gt 0 ]; then
    # Prompt passed as argument
    main "$*"
else
    # Prompt passed via stdin
    user_prompt=$(cat)
    main "$user_prompt"
fi