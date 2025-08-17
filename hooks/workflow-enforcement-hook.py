#!/usr/bin/env python3
"""
Agent OS Workflow Enforcement Hook
==================================
Unified hook handler for Agent OS workflow enforcement in Claude Code.

Usage: python3 workflow-enforcement-hook.py [hook-type]
Hook types: pretool, pretool-task, userprompt, posttool
"""

import json
import os
import re
import subprocess
import sys
from datetime import datetime


# Patterns that indicate user wants to proceed
PROCEED_PATTERNS = [
    r"\b(proceed|continue|next|what'?s next|task \d+|move on|start|begin)\b",
    r"ready for .*task",
    r"let'?s (do|start|work on)",
]

# Tools that indicate starting new work
NEW_WORK_TOOLS = ["Write", "Edit", "MultiEdit"]


def log_debug(message):
    """Write debug logs if debugging enabled."""
    if os.environ.get("AGENT_OS_DEBUG", "").lower() == "true":
        log_path = os.path.expanduser("~/.agent-os/logs/hooks-debug.log")
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "a") as f:
            f.write(f"[{datetime.now().isoformat()}] {message}\n")


def check_git_status():
    """Check if there are uncommitted changes."""
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain"],
            capture_output=True,
            text=True,
            timeout=5,
            cwd=os.getcwd()
        )
        return bool(result.stdout.strip())
    except Exception as e:
        log_debug(f"Git status check failed: {e}")
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
        if result.returncode == 0:
            prs = json.loads(result.stdout)
            return len(prs) > 0
        return False
    except Exception as e:
        log_debug(f"PR check failed: {e}")
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


def handle_pretool(input_data):
    """Handle PreToolUse hook - block new work until workflow complete."""
    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    
    log_debug(f"PreToolUse hook called for tool: {tool_name}")
    
    # Special handling for Bash commands
    if tool_name == "Bash":
        command = tool_input.get("command", "").strip()
        
        # Allow workflow and investigation commands
        allowed_commands = [
            "git ", "gh ", "cd ",  # Workflow commands
            "ls ", "ls", "cat ", "head ", "tail ", "grep ", "find ",  # File investigation
            "ps ", "netstat", "lsof ", "echo ", "env", "which ", "pwd",  # System investigation
            "wc ", "sort ", "uniq ", "awk ", "sed ",  # Text processing (read-only usage)
            "chmod ", "mv ", "rm ", "cp ", "touch "  # File operations often needed with git
        ]
        
        # Check if command contains git operations (even in compound commands)
        is_git_command = "git " in command or "gh " in command
        is_allowed_command = any(command.startswith(cmd) for cmd in allowed_commands) or is_git_command
        
        if is_allowed_command:
            log_debug(f"Allowing command: {command}")
            sys.exit(0)
        
        # Check workflow status for non-git bash commands
        issues = check_workflow_status()
        
        # If there are uncommitted changes but the command includes git operations,
        # allow it (they're trying to fix the issue)
        if issues and "Uncommitted changes" in str(issues) and is_git_command:
            log_debug(f"Allowing git command to resolve uncommitted changes: {command}")
            sys.exit(0)
        
        if issues:
            message = "⚠️ Agent OS workflow guidance needed:\n\n"
            
            # Show current issues
            for issue in issues:
                message += f"• {issue}\n"
            
            # Add workflow reminder
            message += "\n🔄 **AGENT OS WORKFLOW - FOLLOW EXACTLY:**\n"
            message += "1. CHECK: git status (must be clean)\n"
            message += "2. ISSUE: Create or reference GitHub issue\n"
            message += "3. BRANCH: git checkout -b feature-name-#123\n"
            message += "4. WORK: Make changes, test them IN BROWSER/REALITY\n"
            message += "5. COMMIT: git add . && git commit -m 'type: message #123'\n"
            message += "6. PR: gh pr create\n\n"
            
            # Provide specific guidance based on the issue
            if "Open pull requests" in str(issues):
                message += "📋 **NEXT STEP**: Review and merge your open PR:\n"
                message += "• gh pr view [number]\n"
                message += "• Ask user for merge approval\n"
                message += "• gh pr merge [number]\n"
                message += "• git checkout main && git pull"
            elif "Uncommitted changes" in str(issues):
                message += "\n📋 **NEXT STEP**: You have uncommitted changes\n"
                message += "• git status - See what changed\n"
                message += "• git diff - Review changes\n"
                message += "• TEST your changes in browser/reality\n"
                message += "• git add . && git commit -m 'type: description #NUM'\n\n"
                message += "⚠️ NEVER claim work is complete without testing!"
            else:
                message += "\nComplete git integration workflow first:\n"
                message += "1. git add & commit with issue reference\n"
                message += "2. git push & create PR\n"
                message += "3. Complete merge process\n"
                message += "4. Update issue status"
            
            print(message, file=sys.stderr)
            sys.exit(2)
    
    # Only check for tools that indicate new work
    elif tool_name not in NEW_WORK_TOOLS:
        sys.exit(0)
    
    # Check workflow status for other tools
    else:
        issues = check_workflow_status()
        
        if issues:
            # Block tool usage with feedback
            message = "⚠️ Agent OS workflow guidance needed:\n\n"
            
            # Show current issues
            for issue in issues:
                message += f"• {issue}\n"
            
            # Add workflow reminder
            message += "\n🔄 **AGENT OS WORKFLOW - FOLLOW EXACTLY:**\n"
            message += "1. CHECK: git status (must be clean)\n"
            message += "2. ISSUE: Create or reference GitHub issue\n"
            message += "3. BRANCH: git checkout -b feature-name-#123\n"
            message += "4. WORK: Make changes, test them IN BROWSER/REALITY\n"
            message += "5. COMMIT: git add . && git commit -m 'type: message #123'\n"
            message += "6. PR: gh pr create\n\n"
            
            # Provide specific guidance based on the issue
            if "Open pull requests" in str(issues):
                message += "📋 **NEXT STEP**: Review and merge your open PR:\n"
                message += "• gh pr view [number]\n"
                message += "• Ask user for merge approval\n"
                message += "• gh pr merge [number]\n"
                message += "• git checkout main && git pull"
            elif "Uncommitted changes" in str(issues):
                message += "\n📋 **NEXT STEP**: You have uncommitted changes\n"
                message += "• git status - See what changed\n"
                message += "• git diff - Review changes\n"
                message += "• TEST your changes in browser/reality\n"
                message += "• git add . && git commit -m 'type: description #NUM'\n\n"
                message += "⚠️ NEVER claim work is complete without testing!"
            else:
                message += "\nComplete git integration workflow first:\n"
                message += "1. git add & commit with issue reference\n"
                message += "2. git push & create PR\n"
                message += "3. Complete merge process\n"
                message += "4. Update issue status"
            
            print(message, file=sys.stderr)
            sys.exit(2)  # Block with feedback to Claude
    
    sys.exit(0)


def handle_pretool_task(input_data):
    """Handle Task tool - enforce subagent usage for complex work."""
    tool_input = input_data.get("tool_input", {})
    description = tool_input.get("description", "").lower()
    
    log_debug(f"Task tool called with description: {description}")
    
    # Check if this is a review/validation task that should use subagents
    review_keywords = ["review", "validate", "check", "verify", "test", "analyze"]
    needs_subagent = any(keyword in description for keyword in review_keywords)
    
    if needs_subagent:
        message = ("⚠️ Use specialized subagents for quality assurance:\n\n"
                  "• senior-software-engineer - For architecture and design review\n"
                  "• qa-test-engineer - For comprehensive test validation\n"
                  "• code-analyzer-debugger - For debugging complex issues\n\n"
                  "Example: 'Use senior-software-engineer to review the implementation'")
        
        print(message, file=sys.stderr)
        sys.exit(2)  # Block with subagent recommendation
    
    sys.exit(0)


def handle_userprompt(input_data):
    """Handle UserPromptSubmit - add context for proceed attempts."""
    prompt = input_data.get("prompt", "").lower()
    
    log_debug(f"UserPromptSubmit called with prompt: {prompt[:100]}...")
    
    # Check if user is trying to proceed
    is_proceed_attempt = any(re.search(pattern, prompt) for pattern in PROCEED_PATTERNS)
    
    if not is_proceed_attempt:
        sys.exit(0)
    
    # Check workflow status
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
            "decision": "allow",
            "hookSpecificOutput": {
                "additionalContext": context
            }
        }
        print(json.dumps(output))
    
    sys.exit(0)


def handle_posttool(input_data):
    """Handle PostToolUse - auto-commit Agent OS documentation changes."""
    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    
    log_debug(f"PostToolUse called for tool: {tool_name}")
    
    # If PR-completion flows detected, ensure docs are current
    try:
        # Run updater in dry-run to detect pending docs (exit 2 means proposals exist)
        result = subprocess.run([
            os.path.expanduser("~/.agent-os/scripts/update-documentation.sh"),
            "--dry-run",
            "--deep"
        ], capture_output=True, text=True, timeout=10)
        if result.returncode == 2:
            msg = (
                "⚠️ Documentation updates required.\n\n"
                "Please run `/update-documentation --dry-run` to review proposals.\n"
                "Include updates in your PR under 'Documentation Updates'."
            )
            print(msg, file=sys.stderr)
            sys.exit(2)
    except Exception as e:
        log_debug(f"Doc updater check failed: {e}")
    
    sys.exit(0)


def main():
    """Main entry point - route to appropriate handler."""
    if len(sys.argv) < 2:
        print("Error: Hook type not specified", file=sys.stderr)
        sys.exit(1)
    
    hook_type = sys.argv[1]
    
    try:
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)
        log_debug(f"Hook {hook_type} called with data: {json.dumps(input_data)[:200]}...")
    except Exception as e:
        log_debug(f"Failed to parse JSON input: {e}")
        sys.exit(0)  # Don't block on parse errors
    
    # Route to appropriate handler
    handlers = {
        "pretool": handle_pretool,
        "pretool-task": handle_pretool_task,
        "userprompt": handle_userprompt,
        "posttool": handle_posttool
    }
    
    handler = handlers.get(hook_type)
    if handler:
        handler(input_data)
    else:
        log_debug(f"Unknown hook type: {hook_type}")
        sys.exit(1)


if __name__ == "__main__":
    main()