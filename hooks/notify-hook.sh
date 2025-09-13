#!/usr/bin/env bash

# notify-hook.sh
# Agent OS Notification Hook
# Provides gentle reminders based on recent observed Bash activity

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${HOME}/.agent-os/logs"
PROJECT_LOG=""

# Determine log location
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "${CLAUDE_PROJECT_DIR}/.agent-os/observed-bash.jsonl" ]; then
    PROJECT_LOG="${CLAUDE_PROJECT_DIR}/.agent-os/observed-bash.jsonl"
elif [ -f "${LOG_DIR}/observed-bash.jsonl" ]; then
    PROJECT_LOG="${LOG_DIR}/observed-bash.jsonl"
else
    # No log file yet, nothing to notify about
    exit 0
fi

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

# Function to check for recent server starts
check_recent_servers() {
    # Look for server starts in the last 5 minutes
    local five_min_ago=$(date -u -v-5M +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -d '5 minutes ago' +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || echo "")
    
    if [ -z "$five_min_ago" ]; then
        return 1
    fi
    
    # Find recent server starts
    local recent_servers=$(tail -100 "$PROJECT_LOG" 2>/dev/null | \
        jq -r --arg since "$five_min_ago" \
        'select(.event == "pre" and .intent == "server" and .ts >= $since) | .cmd' | \
        head -3)
    
    if [ -n "$recent_servers" ]; then
        echo "$recent_servers"
        return 0
    fi
    
    return 1
}

# Function to check for recent test failures
check_recent_test_failures() {
    # Look for test failures in the last 10 minutes
    local ten_min_ago=$(date -u -v-10M +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -d '10 minutes ago' +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || echo "")
    
    if [ -z "$ten_min_ago" ]; then
        return 1
    fi
    
    # Find recent test failures
    local failed_tests=$(tail -100 "$PROJECT_LOG" 2>/dev/null | \
        jq -r --arg since "$ten_min_ago" \
        'select(.event == "post" and .intent == "test" and .exit != "0" and .exit != "unknown" and .ts >= $since) | .cmd' | \
        head -3)
    
    if [ -n "$failed_tests" ]; then
        echo "$failed_tests"
        return 0
    fi
    
    return 1
}

# Function to check for recent build activity
check_recent_builds() {
    # Look for builds in the last 10 minutes
    local ten_min_ago=$(date -u -v-10M +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -d '10 minutes ago' +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || echo "")
    
    if [ -z "$ten_min_ago" ]; then
        return 1
    fi
    
    # Count recent builds
    local build_count=$(tail -100 "$PROJECT_LOG" 2>/dev/null | \
        jq -r --arg since "$ten_min_ago" \
        'select(.event == "post" and .intent == "build" and .ts >= $since) | .exit' | \
        wc -l | tr -d ' ')
    
    if [ "$build_count" -gt 2 ]; then
        echo "$build_count"
        return 0
    fi
    
    return 1
}

# Generate notifications (kept minimal and helpful)
notifications=""

# Check for running servers
if servers=$(check_recent_servers); then
    notifications="${notifications}🚀 Development server appears to be running. "
    notifications="${notifications}You can ask me to check logs or run 'aos dashboard' to monitor.\n"
fi

# Check for test failures
if failed=$(check_recent_test_failures); then
    notifications="${notifications}⚠️ Recent test failures detected. "
    notifications="${notifications}Say 'grep error' to find issues or 'aos dashboard' for history.\n"
fi

# Check for frequent builds
if build_count=$(check_recent_builds); then
    notifications="${notifications}🔨 Multiple builds ($build_count) in last 10 minutes. "
    notifications="${notifications}Consider using watch mode if available.\n"
fi

# Output notifications if any (maximum 3 lines)
if [ -n "$notifications" ]; then
    echo -e "$notifications" | head -3
fi

# Always exit 0 - notifications are optional
exit 0