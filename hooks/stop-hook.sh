#!/bin/bash

# stop-hook.sh  
# Agent OS Stop Hook - Prevents workflow abandonment

set -e

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.agent-os/logs/stop-hook.log"

# Source utilities
source "$HOOKS_DIR/lib/workflow-detector.sh"
source "$HOOKS_DIR/lib/git-utils.sh"
source "$HOOKS_DIR/lib/context-builder.sh"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log_hook() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] STOP: $*" >> "$LOG_FILE"
}

# Main hook execution
main() {
    local conversation="$1"
    
    log_hook "Stop hook triggered"
    
    # Check if this is an Agent OS workflow
    if ! is_agent_os_workflow "$conversation"; then
        log_hook "Not an Agent OS workflow, skipping"
        return 0
    fi
    
    log_hook "Agent OS workflow detected"
    
    # Assess abandonment risk
    local risk
    risk=$(detect_abandonment_risk "$conversation")
    log_hook "Abandonment risk: $risk"
    
    # Only intervene on high risk scenarios
    if [ "$risk" != "high" ]; then
        log_hook "Risk level acceptable, no intervention needed"
        return 0
    fi
    
    log_hook "High abandonment risk detected, building intervention context"
    
    # Build stop context
    local stop_context
    stop_context=$(build_stop_context "$conversation")
    
    # Auto-commit documentation if needed
    if needs_documentation_commit; then
        log_hook "Uncommitted Agent OS documentation detected"
        if commit_agent_os_changes; then
            log_hook "Agent OS documentation auto-committed successfully"
            stop_context+="\n✅ **Auto-committed Agent OS documentation changes**\n\n"
        else
            log_hook "Failed to auto-commit Agent OS documentation"
            stop_context+="\n⚠️ **Failed to auto-commit documentation changes**\n\n"
        fi
    fi
    
    # Output intervention message if we have context
    if [ -n "$stop_context" ]; then
        echo -e "$stop_context"
        log_hook "Intervention message displayed"
    fi
    
    log_hook "Stop hook completed"
    return 0
}

# Execute main function if called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi