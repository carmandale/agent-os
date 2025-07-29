#!/bin/bash

# user-prompt-submit-hook.sh
# Agent OS User Prompt Submit Hook - Injects contextual information

set -e

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.agent-os/logs/user-prompt-submit-hook.log"

# Source utilities
source "$HOOKS_DIR/lib/workflow-detector.sh"
source "$HOOKS_DIR/lib/git-utils.sh"
source "$HOOKS_DIR/lib/context-builder.sh"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log_hook() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] USER-PROMPT: $*" >> "$LOG_FILE"
}

# Function to determine if context injection is needed
needs_context_injection() {
    local user_message="$1"
    local conversation="$2"
    
    # Always inject context if we're in an Agent OS workflow
    if is_agent_os_workflow "$conversation"; then
        return 0
    fi
    
    # Inject context if user is asking about Agent OS
    if echo "$user_message" | grep -qE "(agent.os|\.agent-os|/plan-product|/create-spec|/execute-tasks|/analyze-product)"; then
        return 0
    fi
    
    # Inject context if in Agent OS project directory
    if [ -d ".agent-os" ]; then
        return 0
    fi
    
    return 1
}

# Function to build context injection message
build_context_injection() {
    local user_message="$1"
    local conversation="$2"
    
    log_hook "Building context injection"
    
    # Build complete context
    local context
    context=$(build_complete_context "$conversation")
    
    if [ -n "$context" ]; then
        log_hook "Context built successfully"
        echo "$context"
    else
        log_hook "No context to inject"
    fi
}

# Main hook execution
main() {
    local user_message="$1"
    local conversation="$2"
    
    log_hook "User prompt submit hook triggered"
    log_hook "User message length: ${#user_message}"
    
    # Check if we need context injection
    if needs_context_injection "$user_message" "$conversation"; then
        log_hook "Context injection needed"
        
        # Build and output context
        local context
        context=$(build_context_injection "$user_message" "$conversation")
        
        if [ -n "$context" ]; then
            echo "$context"
            log_hook "Context injection completed"
        else
            log_hook "No context to inject"
        fi
    else
        log_hook "Context injection not needed"
    fi
    
    log_hook "User prompt submit hook completed"
    return 0
}

# Execute main function if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi