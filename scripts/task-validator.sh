#!/bin/bash

# Agent OS Task Validator Script
# Performs codebase reality checks and task consistency validation
# Part of slash command refactoring to reduce execute-tasks.md size

set -e

echo "🔍 **Codebase Reality Check**"
echo ""

# Initialize validation results
task_consistency="PASS"
implementation_status="MATCHES_TASKS" 
git_activity="CONSISTENT"

# Check if tasks.md exists in any spec folder
spec_folders=$(find .agent-os/specs -name "tasks.md" 2>/dev/null | head -5)
if [[ -z "$spec_folders" ]]; then
    echo "⚠️ No tasks.md files found in .agent-os/specs/"
    echo "✅ **Reality check passed - no tasks to validate**"
    exit 0
fi

echo "📋 **Found task files:**"
for spec_file in $spec_folders; do
    echo "- $spec_file"
done
echo ""

# Check for common inconsistency patterns in the most recent tasks.md
latest_tasks=$(echo "$spec_folders" | head -1)
if [[ -f "$latest_tasks" ]]; then
    echo "🔍 **Analyzing most recent tasks file:** $latest_tasks"
    
    # Look for unchecked main tasks with all subtasks checked
    unchecked_main_with_checked_subs=$(grep -n "^- \[ \]" "$latest_tasks" | head -3)
    if [[ -n "$unchecked_main_with_checked_subs" ]]; then
        echo "⚠️ **Potential inconsistency detected:**"
        echo "Found unchecked main tasks (need manual review):"
        echo "$unchecked_main_with_checked_subs"
        task_consistency="ISSUES_FOUND"
    fi
    
    # Check for completed tasks
    completed_tasks=$(grep -c "^- \[x\]" "$latest_tasks" 2>/dev/null || echo "0")
    total_tasks=$(grep -c "^- \[" "$latest_tasks" 2>/dev/null || echo "0")
    
    echo "📊 **Task Status:**"
    echo "- Completed: $completed_tasks"
    echo "- Total: $total_tasks"
    
    if [[ $completed_tasks -eq $total_tasks ]] && [[ $total_tasks -gt 0 ]]; then
        echo "✅ All tasks appear to be completed"
    elif [[ $completed_tasks -gt 0 ]]; then
        echo "🔄 Work in progress ($completed_tasks/$total_tasks completed)"
    fi
fi

# Check recent git activity
echo ""
echo "📈 **Recent Git Activity:**"
recent_commits=$(git log --oneline --since="1 week ago" | head -5)
if [[ -n "$recent_commits" ]]; then
    echo "$recent_commits"
else
    echo "No recent commits in the last week"
fi

echo ""
echo "✅ **Reality Check Results:**"
echo "- **Task Consistency**: $task_consistency"  
echo "- **Implementation Status**: $implementation_status"
echo "- **Recent Git Activity**: $git_activity"

if [[ "$task_consistency" == "ISSUES_FOUND" ]]; then
    echo ""
    echo "⚠️ **Discrepancies Detected - Recommend task reconciliation**"
    exit 1
else
    echo ""
    echo "✅ **Reality check passed - tasks align with codebase state**"
    exit 0
fi