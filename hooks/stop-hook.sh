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
    log_debug "Checking for potential work abandonment"

    # Get all uncommitted files
    local uncommitted_files
    uncommitted_files=$(git diff --name-only HEAD 2>/dev/null || echo "")

    if [ -z "$uncommitted_files" ]; then
        log_debug "No uncommitted changes, allowing interaction"
        return 1  # Don't block - no changes to abandon
    fi

    # Filter out config and generated files - these are never abandonment
    local filtered_files
    filtered_files=$(echo "$uncommitted_files" | grep -v -E "\.DS_Store$|\.env(\..*)?$|\.(local|temp|tmp)\..*$|\.xcodeproj/|\.xcworkspace/|xcuserdata/|\.swiftpm/|Package\.resolved$|package-lock\.json$|yarn\.lock$|Podfile\.lock$|\.gitignore$|\.pbxproj$|node_modules/|\.next/|dist/|build/|out/|\.(log|pid|seed|lock)$|\.vscode/|\.idea/|__pycache__/|\.pyc$|\.gradle/|target/")

    if [ -z "$filtered_files" ]; then
        log_debug "Only config/generated files changed, allowing interaction"
        return 1  # Don't block - only config changes
    fi

    # Check if changes are actual source code files
    local code_files
    code_files=$(echo "$filtered_files" | grep -E '\.(swift|js|jsx|ts|tsx|py|go|rs|java|kt|php|rb|c|cpp|h|hpp|cs|scala|clj|sh)$')

    if [ -z "$code_files" ]; then
        log_debug "No source code files changed, allowing interaction"
        return 1  # Don't block - no code changes
    fi

    log_debug "Found uncommitted source code files: $code_files"

    # Check for signs of active work (recent commits suggest ongoing development)
    local recent_commits
    recent_commits=$(git log --oneline --since="2 hours ago" 2>/dev/null | wc -l)

    if [ "$recent_commits" -gt 0 ]; then
        log_debug "Recent commits found ($recent_commits), suggesting active work - allowing interaction"
        return 1  # Don't block - recent activity suggests active work
    fi

    log_debug "Uncommitted source code with no recent activity - possible abandonment"
    return 0  # Block - might be abandoning code changes
}


# Generate stop message for Claude Code
generate_stop_message() {
    cat << 'EOF'
Agent OS: Uncommitted source code detected

You have uncommitted source code files with no recent commits (within 2 hours).
This might indicate abandoned work that should be committed or stashed.

Next steps:
  1. Review changes: git status
  2. Commit work: git commit -m "description"
  3. Or stash changes: git stash
  4. Or suppress this check: export AGENT_OS_HOOKS_QUIET=true

EOF
}


# Main execution
main() {
    log_debug "Stop hook triggered"

    # Read stdin JSON payload (prevents infinite loops)
    payload="$(cat)"
    if command -v jq >/dev/null 2>&1; then
        stop_active=$(echo "$payload" | jq -r '.stop_hook_active // false' 2>/dev/null)
        if [ "$stop_active" = "true" ]; then
            log_debug "Stop hook already active, preventing loop"
            exit 0
        fi
    fi

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

    # Rate limiting to prevent spam (5 minute cooldown)
    local project_id=$(pwd | md5 2>/dev/null || echo "$PWD" | md5sum 2>/dev/null | cut -d' ' -f1)
    RATE_LIMIT_FILE="/tmp/agent-os-stop-${project_id}"
    if [ -f "$RATE_LIMIT_FILE" ]; then
        local file_age=$(($(date +%s) - $(stat -f %m "$RATE_LIMIT_FILE" 2>/dev/null || stat -c %Y "$RATE_LIMIT_FILE" 2>/dev/null || echo 0)))
        if [ "$file_age" -lt 300 ]; then
            log_debug "Rate limit active, skipping stop hook (${file_age}s < 300s)"
            exit 0
        fi
    fi

    # Check if we should block
    if should_block_interaction; then
        log_debug "Blocking interaction - generating stop message"
        # Update rate limit file
        touch "$RATE_LIMIT_FILE"
        # Write clear message for Claude Code
        generate_stop_message
        exit 1  # Block the interaction
    else
        log_debug "Allowing interaction to proceed"
        exit 0  # Allow interaction
    fi
}

# Run main function
main "$@"