#!/bin/bash

# workflow-reminder.sh
# Simple, clear workflow reminders for Claude

# Function to get current git state
get_git_state() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "not_in_git_repo"
        return
    fi
    
    if [ -n "$(git status --porcelain)" ]; then
        echo "dirty"
    else
        echo "clean"
    fi
}

# Function to check if on feature branch
on_feature_branch() {
    local branch=$(git branch --show-current 2>/dev/null)
    if [[ "$branch" == "main" ]] || [[ "$branch" == "master" ]]; then
        return 1
    fi
    return 0
}

# Function to extract issue number from branch
get_issue_from_branch() {
    local branch=$(git branch --show-current 2>/dev/null)
    if [[ "$branch" =~ \#([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
}

# Main workflow reminder function
build_workflow_reminder() {
    local context="$1"
    local git_state=$(get_git_state)
    
    local reminder=""
    
    # Always show the workflow
    reminder+="**🔄 AGENT OS WORKFLOW - FOLLOW EXACTLY:**\n\n"
    reminder+="1. **CHECK**: \`git status\` (must be clean)\n"
    reminder+="2. **ISSUE**: Create or reference GitHub issue\n"
    reminder+="3. **BRANCH**: \`git checkout -b feature-name-#123\`\n"
    reminder+="4. **WORK**: Make changes, test them IN BROWSER/REALITY\n"
    reminder+="5. **COMMIT**: \`git add . && git commit -m 'type: message #123'\`\n"
    reminder+="6. **PR**: \`gh pr create\`\n\n"
    
    # Add state-specific guidance
    case "$git_state" in
        "dirty")
            reminder+="**⚠️ CURRENT STATE: Uncommitted changes detected**\n\n"
            
            # Show what's changed
            local changes=$(git status --porcelain | head -5)
            if [ -n "$changes" ]; then
                reminder+="Changed files:\n\`\`\`\n$changes\n\`\`\`\n\n"
            fi
            
            if on_feature_branch; then
                local issue=$(get_issue_from_branch)
                if [ -n "$issue" ]; then
                    reminder+="**NEXT STEP**: You're on a feature branch for issue #$issue\n"
                    reminder+="→ Test your changes in browser/reality\n"
                    reminder+="→ Then: \`git add . && git commit -m 'type: description #$issue'\`\n"
                else
                    reminder+="**NEXT STEP**: Commit your changes\n"
                    reminder+="→ \`git add . && git commit -m 'type: description'\`\n"
                fi
            else
                reminder+="**NEXT STEP**: You're on main branch with uncommitted changes\n"
                reminder+="→ Create an issue first: \`gh issue create --title 'Title' --body 'Description'\`\n"
                reminder+="→ Then create branch: \`git checkout -b feature-name-#NUM\`\n"
            fi
            ;;
            
        "clean")
            if on_feature_branch; then
                local issue=$(get_issue_from_branch)
                reminder+="**✅ CURRENT STATE: Clean workspace on feature branch**\n\n"
                if [ -n "$issue" ]; then
                    reminder+="Working on issue #$issue\n"
                fi
                reminder+="**NEXT STEP**: Continue with step 4 - make changes and TEST them\n"
            else
                reminder+="**✅ CURRENT STATE: Clean workspace on main branch**\n\n"
                reminder+="**NEXT STEP**: Start with step 2 - create a GitHub issue for your work\n"
            fi
            ;;
            
        *)
            reminder+="**❓ CURRENT STATE: Not in a git repository**\n\n"
            reminder+="**NEXT STEP**: Navigate to your project directory first\n"
            ;;
    esac
    
    # Add testing reminder
    reminder+="\n**🧪 REMEMBER**: Never claim work is complete without testing!\n"
    reminder+="- Frontend: Test in actual browser\n"
    reminder+="- Backend: Test with actual API calls\n"
    reminder+="- Scripts: Run them and verify output\n"
    
    echo -e "$reminder"
}

# Export functions
export -f get_git_state
export -f on_feature_branch
export -f get_issue_from_branch
export -f build_workflow_reminder