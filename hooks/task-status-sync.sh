#!/bin/bash

# task-status-sync.sh
# Agent OS Task Status Synchronizer
# Automatically updates tasks.md files when work is completed
# Fixes Issue #6: Task status synchronization gap

# Source utilities
HOOKS_DIR="$(dirname "$0")"
source "$HOOKS_DIR/lib/workflow-detector.sh" 2>/dev/null || true
source "$HOOKS_DIR/lib/git-utils.sh" 2>/dev/null || true

# Log function for debugging
log_debug() {
    if [ "${AGENT_OS_DEBUG:-false}" = "true" ]; then
        echo "[TASK-SYNC DEBUG] $*" >&2
    fi
}

# Find current active spec
get_current_spec_path() {
    if [ -d ".agent-os/specs" ]; then
        local current_spec=$(find .agent-os/specs -maxdepth 1 -type d -name "20*" 2>/dev/null | sort -r | head -1)
        if [ -n "$current_spec" ] && [ -f "$current_spec/tasks.md" ]; then
            echo "$current_spec/tasks.md"
            return 0
        fi
    fi
    return 1
}

# Analyze recent commits for completion indicators
analyze_recent_commits() {
    local spec_file="$1"
    local issue_number=$(basename "$(dirname "$spec_file")" | grep -oE '#[0-9]+' | sed 's/#//')

    log_debug "Analyzing commits for issue #$issue_number"

    # Look for commits in the last hour that reference the issue
    local recent_commits
    if [ -n "$issue_number" ]; then
        recent_commits=$(git log --oneline --since="1 hour ago" --grep="#$issue_number" 2>/dev/null || echo "")
    else
        recent_commits=$(git log --oneline --since="1 hour ago" | head -3)
    fi

    if [ -z "$recent_commits" ]; then
        log_debug "No recent commits found"
        return 1
    fi

    log_debug "Found recent commits: $recent_commits"

    # Look for completion indicators in commit messages
    echo "$recent_commits" | grep -qi -E "(complete|finish|done|implement|add|fix|create)" && return 0 || return 1
}

# Update task status based on commit analysis
update_task_status() {
    local spec_file="$1"

    if [ ! -f "$spec_file" ]; then
        log_debug "Tasks file not found: $spec_file"
        return 1
    fi

    # Check if we have recent implementation commits
    if ! analyze_recent_commits "$spec_file"; then
        log_debug "No completion indicators in recent commits"
        return 1
    fi

    log_debug "Processing task updates for: $spec_file"

    # Get current task status
    local completed_tasks=$(grep -c "^- \[x\]" "$spec_file" 2>/dev/null || echo "0")
    local uncompleted_main_tasks=$(grep -c "^- \[ \]" "$spec_file" 2>/dev/null || echo "0")
    local total_tasks=$(grep -c "^- \[" "$spec_file" 2>/dev/null || echo "0")

    log_debug "Task status: $completed_tasks completed, $uncompleted_main_tasks uncompleted main tasks, $total_tasks total"

    # If we have recent completion commits and uncompleted main tasks, mark them complete
    if [ "$uncompleted_main_tasks" -gt 0 ]; then
        # Create a backup
        cp "$spec_file" "$spec_file.backup"

        # Mark first uncompleted main task as complete
        sed -i.tmp '0,/^- \[ \]/{s/^- \[ \]/- [x]/}' "$spec_file"
        rm "$spec_file.tmp" 2>/dev/null || true

        log_debug "Updated task status in $spec_file"

        # Show what was updated
        local new_completed=$(grep -c "^- \[x\]" "$spec_file" 2>/dev/null || echo "0")
        if [ "$new_completed" -gt "$completed_tasks" ]; then
            echo "✅ Updated task status: $completed_tasks → $new_completed completed tasks"
            return 0
        fi
    fi

    return 1
}

# Validate task status consistency
validate_task_consistency() {
    local spec_file="$1"

    if [ ! -f "$spec_file" ]; then
        return 1
    fi

    # Check for inconsistent patterns (main task unchecked but all subtasks checked)
    local inconsistent_blocks=0
    local current_main_unchecked=false
    local subtask_count=0
    local subtask_checked=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^-\ \[\ \] ]]; then
            # New unchecked main task
            if $current_main_unchecked && [ "$subtask_count" -gt 0 ] && [ "$subtask_checked" -eq "$subtask_count" ]; then
                ((inconsistent_blocks++))
            fi
            current_main_unchecked=true
            subtask_count=0
            subtask_checked=0
        elif [[ "$line" =~ ^-\ \[x\] ]]; then
            # Checked main task
            current_main_unchecked=false
            subtask_count=0
            subtask_checked=0
        elif [[ "$line" =~ ^\ \ -\ \[x\] ]]; then
            # Checked subtask
            if $current_main_unchecked; then
                ((subtask_count++))
                ((subtask_checked++))
            fi
        elif [[ "$line" =~ ^\ \ -\ \[\ \] ]]; then
            # Unchecked subtask
            if $current_main_unchecked; then
                ((subtask_count++))
            fi
        fi
    done < "$spec_file"

    # Check the last block
    if $current_main_unchecked && [ "$subtask_count" -gt 0 ] && [ "$subtask_checked" -eq "$subtask_count" ]; then
        ((inconsistent_blocks++))
    fi

    if [ "$inconsistent_blocks" -gt 0 ]; then
        echo "⚠️ Found $inconsistent_blocks inconsistent task block(s) - main tasks unchecked but all subtasks complete"
        return 1
    fi

    return 0
}

# Auto-commit task status updates
commit_task_updates() {
    local spec_file="$1"

    # Check if the file was actually modified
    if git diff --quiet "$spec_file" 2>/dev/null; then
        log_debug "No changes to commit"
        return 0
    fi

    local issue_number=$(basename "$(dirname "$spec_file")" | grep -oE '#[0-9]+' | sed 's/#//')
    local commit_msg="docs: update task status"

    if [ -n "$issue_number" ]; then
        commit_msg="docs: update task status #$issue_number

Automatically updated task completion status based on recent commits.

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    fi

    git add "$spec_file"
    git commit -m "$commit_msg" >/dev/null 2>&1 && {
        echo "📝 Committed task status update"
        return 0
    }

    return 1
}

# Main execution
main() {
    log_debug "Task status sync triggered"

    # Only run in Agent OS projects
    if [ ! -d ".agent-os" ]; then
        log_debug "Not an Agent OS project, exiting"
        exit 0
    fi

    # Only run in git repositories
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log_debug "Not a git repository, exiting"
        exit 0
    fi

    # Find current spec
    local spec_file
    spec_file=$(get_current_spec_path)

    if [ $? -ne 0 ]; then
        log_debug "No active spec found, exiting"
        exit 0
    fi

    log_debug "Found active spec: $spec_file"

    # Update task status based on recent commits
    if update_task_status "$spec_file"; then
        # Validate consistency after updates
        validate_task_consistency "$spec_file" || {
            echo "⚠️ Task inconsistencies remain after update"
        }

        # Auto-commit the changes
        commit_task_updates "$spec_file"
    else
        # Just validate existing status
        validate_task_consistency "$spec_file" || {
            echo "⚠️ Task status inconsistencies detected - recommend manual review"
            exit 1
        }
    fi

    log_debug "Task status sync complete"
    exit 0
}

# Run main function
main "$@"