#!/usr/bin/env bash

# post-bash-hook.sh
# Agent OS PostToolUse Hook for Bash commands
# Observes Bash command execution results and provides suggestions

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${HOME}/.agent-os/logs"
PROJECT_LOG=""

# Determine storage location based on CLAUDE_PROJECT_DIR
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}/.agent-os" ]; then
    PROJECT_LOG="${CLAUDE_PROJECT_DIR}/.agent-os/observed-bash.jsonl"
    mkdir -p "$(dirname "$PROJECT_LOG")"
else
    PROJECT_LOG="${LOG_DIR}/observed-bash.jsonl"
    mkdir -p "$LOG_DIR"
fi

# Read stdin JSON payload
payload="$(cat)"

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found; skipping post-bash observation" >&2
    exit 0
fi

# Parse JSON fields
tool_name="$(jq -r '.hookMetadata.toolName // empty' <<<"$payload")"
cmd="$(jq -r '.tool_input.command // empty' <<<"$payload")"
exit_code="$(jq -r '.tool_response.exit_code // empty' <<<"$payload")"
output="$(jq -r '.tool_response.output // empty' <<<"$payload" | head -100)"  # Limit output length

# If not a Bash command, exit early
if [ "$tool_name" != "Bash" ] || [ -z "$cmd" ]; then
    exit 0
fi

# Function to classify command intent (same as pre-hook)
classify_intent() {
    local command="$1"
    
    # Server-related patterns
    if echo "$command" | grep -qE "(npm|yarn|pnpm|bun|node|python|uvicorn|django|flask|rails|cargo) (run|start|serve|dev|server)|python.*manage\.py runserver|./start\.sh|serve|dev\.py"; then
        echo "server"
    # Test-related patterns  
    elif echo "$command" | grep -qE "(npm|yarn|pnpm|bun) test|pytest|jest|mocha|vitest|playwright|cypress|rspec|cargo test|go test|make test|./test|test\.sh"; then
        echo "test"
    # Build-related patterns
    elif echo "$command" | grep -qE "(npm|yarn|pnpm|bun) (build|compile)|webpack|rollup|vite build|make( |$)|cargo build|go build|gradle|mvn|tsc|swc"; then
        echo "build"
    # Default
    else
        echo "other"
    fi
}

# Classify the intent
intent=$(classify_intent "$cmd")

# Get current timestamp and project info
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
project="${CLAUDE_PROJECT_DIR:-$PWD}"
cwd="$PWD"

# Determine exit status
exit_status="${exit_code:-unknown}"

# Create JSON record
json_record=$(jq -n \
    --arg ts "$timestamp" \
    --arg event "post" \
    --arg cmd "$cmd" \
    --arg exit "$exit_status" \
    --arg intent "$intent" \
    --arg project "$project" \
    --arg cwd "$cwd" \
    '{ts: $ts, event: $event, cmd: $cmd, exit: $exit, intent: $intent, project: $project, cwd: $cwd}')

# Append to log file
echo "$json_record" >> "$PROJECT_LOG"

# Generate concise summary for transcript (1-3 lines max)
if [ "$exit_status" = "0" ]; then
    status_msg="✅ Completed successfully"
else
    status_msg="❌ Failed with exit code: $exit_status"
fi

# Provide intent-specific suggestions
suggestion=""
case "$intent" in
    "server")
        if [ "$exit_status" = "0" ] || [ "$exit_status" = "unknown" ]; then
            suggestion="Say 'aos dashboard' to view running processes or 'tail server logs' to monitor output."
        fi
        ;;
    "test")
        if [ "$exit_status" = "0" ]; then
            suggestion="All tests passed! Say 'aos dashboard' to see test history."
        else
            suggestion="Tests failed. Say 'grep error' to find failures or 'aos dashboard' for test history."
        fi
        ;;
    "build")
        if [ "$exit_status" = "0" ]; then
            suggestion="Build successful! Check output or run 'aos dashboard' for build history."
        else
            suggestion="Build failed. Review errors above or check 'aos dashboard' for details."
        fi
        ;;
    *)
        if [ "$exit_status" = "0" ]; then
            suggestion="Command completed. Use 'aos dashboard' to view command history."
        fi
        ;;
esac

# Output concise summary (max 3 lines)
echo "📊 Bash command: ${cmd:0:60}$([ ${#cmd} -gt 60 ] && echo "...")"
echo "   Status: $status_msg"
[ -n "$suggestion" ] && echo "   💡 $suggestion"

# Always exit 0 for Bash - never block
exit 0