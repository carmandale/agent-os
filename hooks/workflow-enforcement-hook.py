#!/usr/bin/env python3
"""
Agent OS Workflow Enforcement Hook
==================================
This hook runs as both UserPromptSubmit and PreToolUse to enforce Agent OS workflows.

UserPromptSubmit: Adds workflow status context when users try to proceed
PreToolUse: Blocks tool usage until git workflow is complete

Configuration in ~/.claude/settings.json:
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 /Users/dalecarman/.agent-os/hooks/workflow-enforcement-hook.py"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "python3 /Users/dalecarman/.agent-os/hooks/workflow-enforcement-hook.py"
          }
        ]
      }
    ]
  }
}
"""

import json
import os
import re
import subprocess
import sys

# Patterns that indicate user wants to proceed
PROCEED_PATTERNS = [
    r"\b(proceed|continue|next|what'?s next|task \d+|move on|start|begin)\b",
    r"ready for .*task",
    r"let'?s (do|start|work on)",
]

# Patterns that indicate workflow completion claims
COMPLETION_PATTERNS = [
    r"task.*complete",
    r"quality checks? passed",
    r"all tests? pass",
    r"implementation complete",
    r"ready for.*task",
    r"work is complete",
    r"fully integrated",
]

# Tools that indicate starting new work
NEW_WORK_TOOLS = ["Write", "Edit", "MultiEdit", "Task"]


def check_git_status():
    """Check if there are uncommitted changes."""
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain"],
            capture_output=True,
            text=True,
            timeout=5
        )
        return bool(result.stdout.strip())
    except:
        return False


def check_open_prs():
    """Check for open PRs in the current repo."""
    try:
        result = subprocess.run(
            ["gh", "pr", "list", "--state", "open", "--json", "number"],
            capture_output=True,
            text=True,
            timeout=5
        )
        prs = json.loads(result.stdout)
        return len(prs) > 0
    except:
        return False


def check_workflow_status():
    """Analyze workflow status and return issues."""
    issues = []
    
    # Check for uncommitted changes
    if check_git_status():
        issues.append("Uncommitted changes detected")
    
    # Check for open PRs
    if check_open_prs():
        issues.append("Open pull requests need review/merge")
    
    return issues


def handle_user_prompt_submit_with_data(input_data):
    """Handle UserPromptSubmit hook - add context for proceed attempts."""
    prompt = input_data.get("prompt", "").lower()
    
    # Note: conversation history may not be available in the input
    # We'll check git status and PR status directly
    
    # Check if user is trying to proceed
    is_proceed_attempt = any(re.search(pattern, prompt) for pattern in PROCEED_PATTERNS)
    
    if not is_proceed_attempt:
        sys.exit(0)
    
    # Check workflow status (without conversation context)
    issues = check_workflow_status()
    
    if issues:
        # Add context about incomplete workflow
        context = "\n⚠️ **Agent OS Workflow Status Check**\n\n"
        context += "Before proceeding to new work:\n"
        for issue in issues:
            context += f"• {issue}\n"
        context += "\n**Required Actions:**\n"
        context += "1. Commit all changes with issue reference\n"
        context += "2. Create/update pull request\n"
        context += "3. Complete merge workflow\n"
        context += "4. Close related GitHub issues\n"
        context += "\nComplete these steps before starting new tasks.\n"
        
        # Return JSON to add context
        output = {
            "decision": "continue",
            "hookSpecificOutput": {
                "additionalContext": context
            }
        }
        print(json.dumps(output))
    
    sys.exit(0)


def handle_pre_tool_use_with_data(input_data):
    """Handle PreToolUse hook - block new work until workflow complete."""
    tool_name = input_data.get("tool_name", "")
    
    # Only check for tools that indicate new work
    if tool_name not in NEW_WORK_TOOLS:
        sys.exit(0)
    
    # Check workflow status (without conversation context)
    issues = check_workflow_status()
    
    if issues:
        # Block tool usage with feedback
        message = "⚠️ Cannot start new work - Agent OS workflow incomplete:\n\n"
        for issue in issues:
            message += f"• {issue}\n"
        message += "\nComplete git integration workflow first:\n"
        message += "1. git add & commit with issue reference\n"
        message += "2. git push & create PR\n"
        message += "3. Complete merge process\n"
        message += "4. Update issue status"
        
        print(message, file=sys.stderr)
        sys.exit(2)  # Block with feedback to Claude


# Legacy handlers for backward compatibility
def handle_user_prompt_submit():
    """Legacy handler - reads from stdin."""
    try:
        input_data = json.load(sys.stdin)
        handle_user_prompt_submit_with_data(input_data)
    except:
        sys.exit(0)


def handle_pre_tool_use():
    """Legacy handler - reads from stdin."""
    try:
        input_data = json.load(sys.stdin)
        handle_pre_tool_use_with_data(input_data)
    except:
        sys.exit(0)


def main():
    """Route to appropriate handler based on hook event."""
    try:
        # Read input once
        input_data = json.load(sys.stdin)
        
        # Determine hook type based on hook_event_name or available fields
        hook_event = input_data.get("hook_event_name", "")
        
        if hook_event == "UserPromptSubmit" or "prompt" in input_data:
            handle_user_prompt_submit_with_data(input_data)
        elif hook_event == "PreToolUse" or "tool_name" in input_data:
            handle_pre_tool_use_with_data(input_data)
        else:
            sys.exit(0)
    except Exception as e:
        # Log error for debugging
        print(f"Hook error: {e}", file=sys.stderr)
        sys.exit(0)


if __name__ == "__main__":
    main()