#!/usr/bin/env bash

# pre-bash-hook.sh
# Agent OS PreToolUse Hook for Bash commands
# Observes and classifies Bash command intent without blocking

set -euo pipefail

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(dirname "$HOOKS_DIR")/scripts"
LOG_DIR="${HOME}/.agent-os/logs"
PROJECT_LOG=""

# Resolve project root using the new standardized resolver
PROJECT_ROOT=""
if [ -f "$SCRIPTS_DIR/project_root_resolver.py" ]; then
    PROJECT_ROOT=$(python3 "$SCRIPTS_DIR/project_root_resolver.py" 2>/dev/null || echo "")
fi

# Fall back to CLAUDE_PROJECT_DIR or current directory if resolver fails
if [ -z "$PROJECT_ROOT" ]; then
    PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
fi

# Determine storage location based on resolved project root
if [ -d "${PROJECT_ROOT}/.agent-os" ]; then
    PROJECT_LOG="${PROJECT_ROOT}/.agent-os/observed-bash.jsonl"
    mkdir -p "$(dirname "$PROJECT_LOG")"
else
    PROJECT_LOG="${LOG_DIR}/observed-bash.jsonl"
    mkdir -p "$LOG_DIR"
fi

# Read stdin JSON payload
payload="$(cat)"

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found; skipping pre-bash observation" >&2
    exit 0
fi

# Parse JSON fields
tool_name="$(jq -r '.hookMetadata.toolName // empty' <<<"$payload")"
cmd="$(jq -r '.tool_input.command // empty' <<<"$payload")"

# If not a Bash command, exit early
if [ "$tool_name" != "Bash" ] || [ -z "$cmd" ]; then
    exit 0
fi

# Function to classify command intent
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

# Create JSON record
json_record=$(jq -n \
    --arg ts "$timestamp" \
    --arg event "pre" \
    --arg cmd "$cmd" \
    --arg intent "$intent" \
    --arg project "$project" \
    --arg cwd "$cwd" \
    '{ts: $ts, event: $event, cmd: $cmd, exit: null, intent: $intent, project: $project, cwd: $cwd}')

# Append to log file
echo "$json_record" >> "$PROJECT_LOG"

# Optional: Output minimal info to transcript (kept very brief)
if [ "$intent" = "server" ]; then
    echo "🚀 Starting development server..."
elif [ "$intent" = "test" ]; then
    echo "🧪 Running tests..."
elif [ "$intent" = "build" ]; then
    echo "🔨 Building project..."
fi

# Always exit 0 - never block
exit 0