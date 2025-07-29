#!/bin/bash

# Agent OS Workspace Hygiene Check Script
# Performs git status, branch validation, and workspace cleanliness verification
# Part of slash command refactoring to reduce execute-tasks.md size

set -e

echo "🧹 **Workspace Status Check**"
echo ""

# Check git status
git_status=$(git status --porcelain 2>&1 || echo "ERROR")
if [[ "$git_status" == "ERROR" ]]; then
    echo "❌ Not in a git repository"
    exit 1
fi

# Determine cleanliness
if [[ -z "$git_status" ]]; then
    workspace_status="CLEAN"
    echo "- Git status: ✅ CLEAN"
else
    workspace_status="DIRTY"
    echo "- Git status: ⚠️ DIRTY"
fi

# Check current branch
current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
echo "- Current branch: $current_branch"

# Check for open PRs (if gh is available)
if command -v gh &> /dev/null; then
    open_prs=$(gh pr list --json number,title 2>/dev/null | jq length 2>/dev/null || echo "0")
    if [[ "$open_prs" -gt 0 ]]; then
        echo "- Open PRs: $open_prs (consider merging)"
    else
        echo "- Open PRs: NONE"
    fi
else
    echo "- Open PRs: Cannot check (gh CLI not available)"
fi

# Check for open issues that might be completed
if command -v gh &> /dev/null; then
    open_issues=$(gh issue list --json number,title 2>/dev/null | jq length 2>/dev/null || echo "unknown")
    echo "- Open issues: $open_issues"
else
    echo "- Open issues: Cannot check (gh CLI not available)"
fi

echo ""

# Return status for orchestrator
if [[ "$workspace_status" == "CLEAN" ]]; then
    echo "✅ **Workspace is clean and ready for work!**"
    exit 0
else
    echo "📋 **Workspace contains uncommitted changes - requires cleanup**"
    exit 1
fi