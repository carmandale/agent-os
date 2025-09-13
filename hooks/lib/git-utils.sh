#!/bin/bash

# git-utils.sh
# Git utilities for Agent OS workflows

# Function to check if we're in a git repository
is_git_repo() {
    git rev-parse --git-dir >/dev/null 2>&1
}

# Function to check if workspace is clean
is_clean_workspace() {
    if ! is_git_repo; then
        return 1
    fi
    
    local status
    status=$(git status --porcelain 2>/dev/null)
    [ -z "$status" ]
}

# Function to get current branch name
get_current_branch() {
    if ! is_git_repo; then
        echo "not-a-git-repo"
        return 1
    fi
    
    git branch --show-current 2>/dev/null || echo "unknown"
}

# Function to check if current branch is a feature branch
is_feature_branch() {
    local current_branch
    current_branch=$(get_current_branch)
    
    # Consider it a feature branch if it's not main, master, develop, or staging
    case "$current_branch" in
        "main"|"master"|"develop"|"staging"|"not-a-git-repo"|"unknown")
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# Function to get modified Agent OS files
get_modified_agent_os_files() {
    if ! is_git_repo; then
        return 1
    fi
    
    git status --porcelain 2>/dev/null | grep -E "^\s*M\s+\.agent-os/" | awk '{print $2}' || true
}

# Function to get untracked Agent OS files
get_untracked_agent_os_files() {
    if ! is_git_repo; then
        return 1
    fi
    
    git status --porcelain 2>/dev/null | grep -E "^\s*\?\?\s+\.agent-os/" | awk '{print $2}' || true
}

# Function to check if there are uncommitted Agent OS documentation changes
has_uncommitted_agent_os_changes() {
    if ! is_git_repo; then
        return 1
    fi
    
    local modified_files untracked_files
    modified_files=$(get_modified_agent_os_files)
    untracked_files=$(get_untracked_agent_os_files)
    
    [ -n "$modified_files" ] || [ -n "$untracked_files" ]
}

# Function to commit Agent OS documentation changes
commit_agent_os_changes() {
    if ! is_git_repo; then
        echo "Error: Not in a git repository"
        return 1
    fi
    
    local modified_files untracked_files
    modified_files=$(get_modified_agent_os_files)
    untracked_files=$(get_untracked_agent_os_files)
    
    if [ -z "$modified_files" ] && [ -z "$untracked_files" ]; then
        return 0  # Nothing to commit
    fi
    
    # Stage Agent OS files
    if [ -n "$modified_files" ]; then
        echo "$modified_files" | xargs -r git add 2>/dev/null || {
            echo "Warning: Failed to stage modified Agent OS files"
            return 1
        }
    fi

    if [ -n "$untracked_files" ]; then
        echo "$untracked_files" | xargs -r git add 2>/dev/null || {
            echo "Warning: Failed to stage untracked Agent OS files"
            return 1
        }
    fi
    
    # Create commit message
    local commit_message="docs: update Agent OS documentation

🤖 Auto-committed by Agent OS hooks to maintain documentation consistency

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Commit the changes
    git commit -m "$commit_message" 2>/dev/null || {
        echo "Warning: Failed to commit Agent OS documentation changes"
        return 1
    }
    
    echo "✅ Agent OS documentation changes committed automatically"
    return 0
}

# Function to get current repository remote URL
get_repo_remote_url() {
    if ! is_git_repo; then
        return 1
    fi
    
    git remote get-url origin 2>/dev/null || echo "no-remote"
}

# Function to extract GitHub issue number from branch name or commit messages
extract_github_issue() {
    local source="${1:-branch}"
    
    case "$source" in
        "branch")
            local branch_name
            branch_name=$(get_current_branch)
            echo "$branch_name" | grep -oE '#[0-9]+' | head -1 | sed 's/#//' || echo ""
            ;;
        "commits")
            git log --oneline -n 10 2>/dev/null | grep -oE '#[0-9]+' | head -1 | sed 's/#//' || echo ""
            ;;
        *)
            echo ""
            ;;
    esac
}

# Function to check if there are open PRs for current branch
has_open_pr() {
    # This would require GitHub CLI (gh) to be installed
    # For now, we'll just return false
    return 1
}

# Function to get recent commit messages
get_recent_commits() {
    local count="${1:-5}"
    
    if ! is_git_repo; then
        return 1
    fi
    
    git log --oneline -n "$count" 2>/dev/null || echo "No commits found"
}

# Function to check if current state suggests work in progress
is_work_in_progress() {
    if ! is_git_repo; then
        return 1
    fi
    
    # Check for uncommitted changes
    if ! is_clean_workspace; then
        return 0
    fi
    
    # Check if we're on a feature branch
    if is_feature_branch; then
        return 0
    fi
    
    # Check recent commits for WIP patterns
    if get_recent_commits 3 | grep -qiE "(wip|work in progress|tmp|temp|debug)"; then
        return 0
    fi
    
    return 1
}

# Function to generate git status summary for hooks
get_git_status_summary() {
    if ! is_git_repo; then
        echo "Not a git repository"
        return 1
    fi
    
    local branch modified untracked
    branch=$(get_current_branch)
    modified=$(git status --porcelain 2>/dev/null | grep -E "^\s*M" | wc -l | tr -d ' ')
    untracked=$(git status --porcelain 2>/dev/null | grep -E "^\s*\?\?" | wc -l | tr -d ' ')
    
    echo "Branch: $branch, Modified: $modified, Untracked: $untracked"
}

# Main execution when called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-}" in
        "status")
            get_git_status_summary
            ;;
        "clean")
            is_clean_workspace && echo "true" || echo "false"
            ;;
        "branch")
            get_current_branch
            ;;
        "feature_branch")
            is_feature_branch && echo "true" || echo "false"
            ;;
        "commit_docs")
            commit_agent_os_changes
            ;;
        "needs_commit")
            has_uncommitted_agent_os_changes && echo "true" || echo "false"
            ;;
        "wip")
            is_work_in_progress && echo "true" || echo "false"
            ;;
        "issue")
            extract_github_issue "${2:-branch}"
            ;;
        "commits")
            get_recent_commits "${2:-5}"
            ;;
        *)
            echo "Usage: $0 {status|clean|branch|feature_branch|commit_docs|needs_commit|wip|issue|commits} [args]"
            exit 1
            ;;
    esac
fi