#!/bin/bash

# context-builder.sh
# Builds contextual information for Agent OS workflows

set -e

# Source required utilities
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HOOKS_DIR/lib/git-utils.sh"
source "$HOOKS_DIR/lib/workflow-detector.sh"
source "$HOOKS_DIR/lib/project-config-injector.sh"

# Function to build Agent OS project context
build_project_context() {
    local context=""
    
    # Check if we're in an Agent OS project
    if [ -d ".agent-os" ]; then
        context+="🏗️ **Agent OS Project Context:**\n"
        
        # Add mission context
        if [ -f ".agent-os/product/mission.md" ]; then
            local mission_title
            mission_title=$(head -1 ".agent-os/product/mission.md" | sed 's/^# //')
            context+="- **Product:** $mission_title\n"
        fi
        
        # Add tech stack context
        if [ -f ".agent-os/product/tech-stack.md" ]; then
            local tech_info
            tech_info=$(grep -E "^\*\*.*:\*\*" ".agent-os/product/tech-stack.md" | head -3 | sed 's/^\*\*\(.*\):\*\* \(.*\)/- \1: \2/' | tr '\n' ' ')
            if [ -n "$tech_info" ]; then
                context+="- **Tech Stack:** $tech_info\n"
            fi
        fi
        
        # Add current spec context
        local current_spec
        current_spec=$(detect_current_spec)
        if [ -n "$current_spec" ]; then
            context+="- **Active Spec:** $current_spec\n"
            
            # Add spec details if available
            if [ -f ".agent-os/specs/$current_spec/spec.md" ]; then
                local spec_title
                spec_title=$(grep -E "^> Spec:" ".agent-os/specs/$current_spec/spec.md" | sed 's/> Spec: //')
                if [ -n "$spec_title" ]; then
                    context+="- **Current Feature:** $spec_title\n"
                fi
            fi
        fi
        
        context+="\n"
    fi
    
    echo -e "$context"
}

# Function to build git context
build_git_context() {
    local context=""
    
    if is_git_repo; then
        context+="📋 **Repository Context:**\n"
        
        local branch
        branch=$(get_current_branch)
        context+="- **Branch:** $branch\n"
        
        local issue_num
        issue_num=$(extract_github_issue "branch")
        if [ -n "$issue_num" ]; then
            context+="- **GitHub Issue:** #$issue_num\n"
        fi
        
        if ! is_clean_workspace; then
            local modified untracked
            modified=$(git status --porcelain | grep -E "^\s*M" | wc -l | tr -d ' ')
            untracked=$(git status --porcelain | grep -E "^\s*\?\?" | wc -l | tr -d ' ')
            context+="- **Workspace:** $modified modified, $untracked untracked files\n"
        else
            context+="- **Workspace:** Clean\n"
        fi
        
        context+="\n"
    fi
    
    echo -e "$context"
}

# Function to build workflow context
build_workflow_context() {
    local conversation="$1"
    local context=""
    
    if is_agent_os_workflow "$conversation"; then
        context+="⚙️ **Workflow Context:**\n"
        
        local phase
        phase=$(detect_workflow_phase "$conversation")
        context+="- **Current Phase:** $phase\n"
        
        local risk
        risk=$(detect_abandonment_risk "$conversation")
        context+="- **Abandonment Risk:** $risk\n"
        
        if requires_workflow_completion "$conversation"; then
            context+="- **Status:** ⚠️ Workflow completion required\n"
        fi
        
        local suggestions
        suggestions=$(get_workflow_suggestions "$conversation")
        if [ -n "$suggestions" ]; then
            context+="- **Suggestion:** $suggestions\n"
        fi
        
        context+="\n"
    fi
    
    echo -e "$context"
}

# Function to build standards context
build_standards_context() {
    local context=""
    
    # Check for global standards
    if [ -d "$HOME/.agent-os/standards" ]; then
        context+="📋 **Development Standards:**\n"
        context+="- **Global Standards:** Available at ~/.agent-os/standards/\n"
        
        # Check for project-specific overrides
        if [ -f ".agent-os/product/tech-stack.md" ]; then
            context+="- **Project Tech Stack:** Defined in .agent-os/product/tech-stack.md\n"
        fi
        
        if [ -f ".agent-os/product/code-style.md" ]; then
            context+="- **Project Code Style:** Defined in .agent-os/product/code-style.md\n"
        fi
        
        context+="\n"
    fi
    
    echo -e "$context"
}

# Function to build task context
build_task_context() {
    local context=""
    
    # Look for active tasks
    local current_spec
    current_spec=$(detect_current_spec)
    
    if [ -n "$current_spec" ] && [ -f ".agent-os/specs/$current_spec/tasks.md" ]; then
        context+="📝 **Current Tasks:**\n"
        
        # Count completed vs remaining tasks
        local total_tasks completed_tasks
        total_tasks=$(grep -c "^- \[" ".agent-os/specs/$current_spec/tasks.md" 2>/dev/null || echo "0")
        completed_tasks=$(grep -c "^- \[x\]" ".agent-os/specs/$current_spec/tasks.md" 2>/dev/null || echo "0")
        
        context+="- **Progress:** $completed_tasks/$total_tasks tasks completed\n"
        
        # Show next incomplete task
        local next_task
        next_task=$(grep -m 1 "^- \[ \]" ".agent-os/specs/$current_spec/tasks.md" 2>/dev/null | sed 's/^- \[ \] //' || echo "")
        if [ -n "$next_task" ]; then
            context+="- **Next Task:** $next_task\n"
        fi
        
        context+="\n"
    fi
    
    echo -e "$context"
}

# Function to build complete context
build_complete_context() {
    local conversation="$1"
    local context=""
    
    # Always include workflow reminder first
    if command -v build_workflow_reminder >/dev/null 2>&1; then
        context+=$(build_workflow_reminder "$conversation")
        context+="\n"
    fi
    
    # Include project config reminder to prevent amnesia
    if command -v build_config_reminder >/dev/null 2>&1; then
        context+=$(build_config_reminder)
    fi
    
    context+=$(build_project_context)
    context+=$(build_git_context)
    context+=$(build_workflow_context "$conversation")
    context+=$(build_standards_context)
    context+=$(build_task_context)
    
    if [ -n "$context" ]; then
        echo -e "---\n\n**🤖 Agent OS Context Injection**\n\n$context---\n"
    fi
}

# Function to build stop hook context
build_stop_context() {
    local conversation="$1"
    local context=""
    
    if is_agent_os_workflow "$conversation"; then
        local risk
        risk=$(detect_abandonment_risk "$conversation")
        
        if [ "$risk" = "high" ]; then
            # Check if Step 13 blocking is needed
            if needs_step_13_blocking "$conversation"; then
                context+="🚨🛑 **WORKFLOW COMPLETE - MERGE APPROVAL REQUIRED** 🛑🚨\n\n"
                context+="✅ Code implemented and validated\n"
                context+="✅ Subagent expert review completed\n"
                context+="✅ All tests passing\n"
                context+="✅ PR optimized and conflict-free\n\n"
                context+="Type \"merge\" to complete workflow\n\n"
                context+="⚠️ **DO NOT abandon the workflow here!** The Agent OS workflow requires Steps 13-14 to be completed.\n"
            else
                context+="⚠️ **Workflow Abandonment Prevention Active**\n\n"
                context+="This appears to be a completion summary that may lead to workflow abandonment. "
                context+="Remember that Agent OS workflows require full integration (commit → PR → merge) to be considered complete.\n\n"
                
                if requires_workflow_completion "$conversation"; then
                    context+="**Required Next Steps:**\n"
                    context+="1. Commit changes with proper issue reference\n"
                    context+="2. Create pull request\n"
                    context+="3. Complete integration workflow\n\n"
                fi
            fi
        fi
    fi
    
    echo -e "$context"
}

# Main execution when called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    case "${1:-}" in
        "project")
            build_project_context
            ;;
        "git")
            build_git_context
            ;;
        "workflow")
            build_workflow_context "${2:-}"
            ;;
        "standards")
            build_standards_context
            ;;
        "tasks")
            build_task_context
            ;;
        "complete")
            build_complete_context "${2:-}"
            ;;
        "stop")
            build_stop_context "${2:-}"
            ;;
        *)
            echo "Usage: $0 {project|git|workflow|standards|tasks|complete|stop} [conversation]"
            exit 1
            ;;
    esac
fi