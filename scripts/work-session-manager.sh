#!/bin/bash

# Agent OS Work Session Manager
# Enables batched work mode to reduce commit spam while maintaining quality

set -e

WORK_SESSION_FILE="$HOME/.agent-os/cache/work-session"

show_help() {
    echo "Agent OS Work Session Manager"
    echo "Usage: work-session-manager.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start [description]   Start a work session"
    echo "  status               Show current session status"
    echo "  commit [message]     Create a commit with session context"
    echo "  end                  End session and validate workflow"
    echo "  abort                Abort current session"
    echo ""
    echo "Environment Variables:"
    echo "  AGENT_OS_WORK_SESSION=true   Enable work session mode"
    echo ""
}

start_session() {
    local description="${1:-Work session}"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    mkdir -p "$(dirname "$WORK_SESSION_FILE")"
    
    cat > "$WORK_SESSION_FILE" <<EOF
{
  "active": true,
  "description": "$description",
  "started": "$timestamp",
  "commits": [],
  "files_modified": []
}
EOF
    
    export AGENT_OS_WORK_SESSION=true
    echo "✅ Work session started: $description"
    echo "   Use 'work-session-manager.sh commit' to create logical commits"
    echo "   Use 'work-session-manager.sh end' to finish session"
}

show_status() {
    if [[ ! -f "$WORK_SESSION_FILE" ]]; then
        echo "❌ No active work session"
        return 1
    fi
    
    local description=$(jq -r '.description' "$WORK_SESSION_FILE")
    local started=$(jq -r '.started' "$WORK_SESSION_FILE")
    local commit_count=$(jq '.commits | length' "$WORK_SESSION_FILE")
    
    echo "📋 Active Work Session"
    echo "   Description: $description"
    echo "   Started: $started"
    echo "   Commits made: $commit_count"
    echo "   Session mode: AGENT_OS_WORK_SESSION=${AGENT_OS_WORK_SESSION:-false}"
}

create_commit() {
    local message="$1"
    
    if [[ ! -f "$WORK_SESSION_FILE" ]]; then
        echo "❌ No active work session. Start one with: work-session-manager.sh start"
        return 1
    fi
    
    if [[ -z "$message" ]]; then
        echo "❌ Commit message required"
        return 1
    fi
    
    # Create the commit
    git add -A
    git commit -m "$message

🔧 Work Session Commit

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Record the commit
    local commit_hash=$(git rev-parse HEAD)
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq --arg hash "$commit_hash" --arg msg "$message" --arg time "$timestamp" \
       '.commits += [{"hash": $hash, "message": $msg, "timestamp": $time}]' \
       "$WORK_SESSION_FILE" > "${WORK_SESSION_FILE}.tmp" && \
       mv "${WORK_SESSION_FILE}.tmp" "$WORK_SESSION_FILE"
    
    echo "✅ Session commit created: $message"
}

end_session() {
    if [[ ! -f "$WORK_SESSION_FILE" ]]; then
        echo "❌ No active work session"
        return 1
    fi
    
    local commit_count=$(jq '.commits | length' "$WORK_SESSION_FILE")
    local description=$(jq -r '.description' "$WORK_SESSION_FILE")
    
    # Check if there are uncommitted changes
    if ! git diff --quiet || ! git diff --staged --quiet; then
        echo "⚠️  You have uncommitted changes. Commit them first:"
        echo "   work-session-manager.sh commit 'Final changes'"
        return 1
    fi
    
    # Clean up
    rm "$WORK_SESSION_FILE"
    unset AGENT_OS_WORK_SESSION
    
    echo "✅ Work session ended: $description"
    echo "   Total commits: $commit_count"
    echo "   Session mode disabled"
}

abort_session() {
    if [[ ! -f "$WORK_SESSION_FILE" ]]; then
        echo "❌ No active work session"
        return 1
    fi
    
    rm "$WORK_SESSION_FILE"
    unset AGENT_OS_WORK_SESSION
    
    echo "🚫 Work session aborted"
    echo "   Session mode disabled"
}

# Main command handling
case "${1:-help}" in
    start)
        start_session "${2:-Work session}"
        ;;
    status)
        show_status
        ;;
    commit)
        create_commit "$2"
        ;;
    end)
        end_session
        ;;
    abort)
        abort_session
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        show_help
        exit 1
        ;;
esac