#!/usr/bin/env python3
"""
Agent OS Context-Aware Workflow Hook
====================================
Intelligent wrapper for workflow enforcement hooks that distinguishes between
maintenance work and new development work based on user intent analysis.

This hook integrates the Intent Analysis Engine with the existing workflow
enforcement system to provide context-aware behavior:
- Maintenance work: Allowed even with dirty workspace/open PRs
- New work: Requires clean workspace following standard Agent OS workflow
- Ambiguous work: Interactive prompts for user clarification

Usage:
    python3 context-aware-hook.py [hook-type]
    Hook types: pretool, pretool-task, userprompt, posttool
    
Environment Variables:
    AGENT_OS_WORK_TYPE: Override intent detection ('maintenance' or 'new_work')
    AGENT_OS_DEBUG: Enable detailed debugging output
"""

import json
import os
import subprocess
import sys
import time
from datetime import datetime
from typing import Dict, Any, Optional

# Import the intent analyzer
from intent_analyzer import IntentAnalyzer, IntentType, WorkIntentResult


# Tools that indicate starting new work (inherited from original hook)
NEW_WORK_TOOLS = ["Write", "Edit", "MultiEdit"]

# Tools that are always allowed for investigation
ALWAYS_ALLOWED_TOOLS = ["Read", "Glob", "Grep", "LS"]


def log_debug(message: str) -> None:
    """Write debug logs if debugging enabled."""
    if os.environ.get("AGENT_OS_DEBUG", "").lower() == "true":
        log_path = os.path.expanduser("~/.agent-os/logs/context-aware-hook-debug.log")
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "a") as f:
            f.write(f"[{datetime.now().isoformat()}] {message}\n")


class ContextAwareWorkflowHook:
    """
    Context-aware wrapper for Agent OS workflow enforcement hooks.
    
    This class integrates intent analysis with workspace state checking to provide
    intelligent workflow enforcement that distinguishes between maintenance and new work.
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize the context-aware hook wrapper.
        
        Args:
            config_path: Optional path to configuration file
        """
        self.intent_analyzer = IntentAnalyzer(config_path=config_path)
        log_debug("ContextAwareWorkflowHook initialized with intent analyzer")
    
    def check_workspace_state(self) -> Dict[str, Any]:
        """
        Check the current workspace state including git status and open PRs.
        
        Returns:
            Dictionary with workspace state information
        """
        workspace_state = {
            'has_uncommitted_changes': False,
            'has_open_prs': False,
            'is_clean': True
        }
        
        try:
            # Check git status for uncommitted changes
            git_result = subprocess.run(
                ["git", "status", "--porcelain"],
                capture_output=True,
                text=True,
                timeout=5,
                cwd=os.getcwd()
            )
            
            if git_result.returncode == 0:
                has_changes = bool(git_result.stdout.strip())
                workspace_state['has_uncommitted_changes'] = has_changes
                log_debug(f"Git status check: has_changes={has_changes}")
            else:
                log_debug(f"Git status check failed with return code: {git_result.returncode}")
                
        except Exception as e:
            log_debug(f"Git status check failed: {e}")
        
        try:
            # Check for open PRs
            pr_result = subprocess.run(
                ["gh", "pr", "list", "--state", "open", "--json", "number"],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if pr_result.returncode == 0:
                prs = json.loads(pr_result.stdout)
                has_prs = len(prs) > 0
                workspace_state['has_open_prs'] = has_prs
                log_debug(f"PR check: has_open_prs={has_prs}")
            else:
                log_debug(f"PR check failed with return code: {pr_result.returncode}")
                
        except Exception as e:
            log_debug(f"PR check failed: {e}")
        
        # Update is_clean based on both factors
        workspace_state['is_clean'] = not (
            workspace_state['has_uncommitted_changes'] or 
            workspace_state['has_open_prs']
        )
        
        log_debug(f"Workspace state: {workspace_state}")
        return workspace_state
    
    def should_allow_work(self, user_message: str, workspace_state: Dict[str, Any]) -> bool:
        """
        Determine whether work should be allowed based on intent and workspace state.
        
        Args:
            user_message: The user's message describing their intent
            workspace_state: Current workspace state information
            
        Returns:
            True if work should be allowed, False otherwise
        """
        log_debug(f"Evaluating work allowance for message: '{user_message[:100]}{'...' if len(user_message) > 100 else ''}'")
        
        # Check for manual override first
        manual_override = os.environ.get("AGENT_OS_WORK_TYPE", "").lower()
        if manual_override:
            log_debug(f"Manual override detected: {manual_override}")
            
            if manual_override == "maintenance":
                log_debug("Manual override: allowing work as maintenance")
                return True
            elif manual_override == "new_work":
                # Still require clean workspace for new work
                log_debug(f"Manual override: treating as new work, workspace clean: {workspace_state['is_clean']}")
                return workspace_state['is_clean']
        
        # Analyze intent using the intent analyzer
        intent_result = self.intent_analyzer.analyze_intent(user_message)
        log_debug(f"Intent analysis result: {intent_result}")
        
        if intent_result.intent_type == IntentType.MAINTENANCE:
            log_debug("Allowing maintenance work regardless of workspace state")
            return True
        
        elif intent_result.intent_type == IntentType.NEW_WORK:
            log_debug(f"New work detected, requiring clean workspace: {workspace_state['is_clean']}")
            return workspace_state['is_clean']
        
        else:  # IntentType.AMBIGUOUS
            log_debug("Ambiguous intent detected, prompting user")
            return self._handle_ambiguous_intent(user_message, workspace_state, intent_result)
    
    def _handle_ambiguous_intent(self, user_message: str, workspace_state: Dict[str, Any], 
                                intent_result: WorkIntentResult) -> bool:
        """
        Handle ambiguous intent by prompting the user for clarification.
        
        Args:
            user_message: Original user message
            workspace_state: Current workspace state
            intent_result: The ambiguous intent result
            
        Returns:
            True if work should be allowed, False otherwise
        """
        try:
            # Display intent analysis information
            print("\n⚠️ **Agent OS Intent Analysis - Clarification Needed**\n", file=sys.stderr)
            print(f"Message: {user_message}\n", file=sys.stderr)
            print(f"Analysis: {intent_result.reasoning}\n", file=sys.stderr)
            
            # Show workspace state
            if not workspace_state['is_clean']:
                print("⚠️ **Workspace Status:**", file=sys.stderr)
                if workspace_state['has_uncommitted_changes']:
                    print("• Uncommitted changes detected", file=sys.stderr)
                if workspace_state['has_open_prs']:
                    print("• Open pull requests need review", file=sys.stderr)
                print("", file=sys.stderr)
            
            # Prompt user for intent
            print("Is this maintenance work (fixing/debugging existing code) or new development work?", file=sys.stderr)
            print("", file=sys.stderr)
            print("🔧 **maintenance** - Bug fixes, debugging, CI fixes, conflict resolution", file=sys.stderr)
            print("   (Allowed even with dirty workspace/open PRs)", file=sys.stderr)
            print("", file=sys.stderr)
            print("🚀 **new_work** - New features, components, functionality", file=sys.stderr)
            print("   (Requires clean workspace following Agent OS workflow)", file=sys.stderr)
            print("", file=sys.stderr)
            
            response = input("Enter 'maintenance' or 'new_work': ").strip().lower()
            log_debug(f"User selected work type: '{response}'")
            
            if response == "maintenance":
                log_debug("User classified as maintenance work, allowing")
                return True
            elif response == "new_work":
                log_debug(f"User classified as new work, workspace clean: {workspace_state['is_clean']}")
                return workspace_state['is_clean']
            else:
                print(f"Invalid response '{response}', defaulting to new work behavior", file=sys.stderr)
                log_debug(f"Invalid user response '{response}', defaulting to new work")
                return workspace_state['is_clean']
                
        except (KeyboardInterrupt, EOFError):
            log_debug("User interrupted prompt, defaulting to new work behavior")
            print("\nUser interrupted, defaulting to new work behavior", file=sys.stderr)
            return workspace_state['is_clean']
    
    def _should_allow_tool_unconditionally(self, tool_name: str, tool_input: Dict[str, Any]) -> bool:
        """
        Check if a tool should be allowed unconditionally regardless of workflow state.
        
        Args:
            tool_name: Name of the tool being used
            tool_input: Input parameters for the tool
            
        Returns:
            True if tool should always be allowed
        """
        # Always allow investigation tools
        if tool_name in ALWAYS_ALLOWED_TOOLS:
            log_debug(f"Allowing investigation tool: {tool_name}")
            return True
        
        # Allow workflow and git commands in Bash tool
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
                log_debug(f"Allowing bash command: {command}")
                return True
        
        return False
    
    def _generate_workflow_guidance(self, workspace_state: Dict[str, Any]) -> str:
        """
        Generate workflow guidance message based on current workspace state.
        
        Args:
            workspace_state: Current workspace state
            
        Returns:
            Formatted guidance message
        """
        message = "⚠️ Agent OS context-aware workflow guidance:\n\n"
        
        # Show current issues
        if workspace_state['has_uncommitted_changes']:
            message += "• Uncommitted changes detected\n"
        if workspace_state['has_open_prs']:
            message += "• Open pull requests need review/merge\n"
        
        # Add workflow reminder
        message += "\n🔄 **AGENT OS WORKFLOW - FOLLOW EXACTLY:**\n"
        message += "1. CHECK: git status (must be clean for new work)\n"
        message += "2. ISSUE: Create or reference GitHub issue\n"
        message += "3. BRANCH: git checkout -b feature-name-#123\n"
        message += "4. WORK: Make changes, test them IN BROWSER/REALITY\n"
        message += "5. COMMIT: git add . && git commit -m 'type: message #123'\n"
        message += "6. PR: gh pr create\n\n"
        
        # Provide specific guidance based on the issue
        if workspace_state['has_open_prs']:
            message += "📋 **NEXT STEP**: Review and merge your open PR:\n"
            message += "• gh pr view [number]\n"
            message += "• Ask user for merge approval\n"
            message += "• gh pr merge [number]\n"
            message += "• git checkout main && git pull"
        elif workspace_state['has_uncommitted_changes']:
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
        
        return message
    
    def process_hook(self, hook_type: str, input_data: Dict[str, Any]) -> int:
        """
        Process a hook call with context-aware behavior.
        
        Args:
            hook_type: Type of hook being processed
            input_data: Hook input data
            
        Returns:
            Exit code: 0 = allow, 2 = block with feedback
        """
        log_debug(f"Processing {hook_type} hook with context-aware behavior")
        
        if hook_type == "pretool":
            return self._handle_pretool(input_data)
        elif hook_type == "pretool-task":
            return self._handle_pretool_task(input_data)
        elif hook_type == "userprompt":
            return self._handle_userprompt(input_data)
        elif hook_type == "posttool":
            return self._handle_posttool(input_data)
        else:
            log_debug(f"Unknown hook type: {hook_type}")
            return 0  # Allow unknown hooks
    
    def _handle_pretool(self, input_data: Dict[str, Any]) -> int:
        """Handle PreToolUse hook with context-aware behavior."""
        tool_name = input_data.get("tool_name", "")
        tool_input = input_data.get("tool_input", {})
        user_message = input_data.get("user_message", "")
        
        log_debug(f"PreToolUse hook: tool={tool_name}, user_message='{user_message[:100]}{'...' if len(user_message) > 100 else ''}'")
        
        # Check if tool should be allowed unconditionally
        if self._should_allow_tool_unconditionally(tool_name, tool_input):
            return 0
        
        # Only apply context-aware logic to work-related tools
        if tool_name not in NEW_WORK_TOOLS:
            log_debug(f"Tool {tool_name} not in NEW_WORK_TOOLS, allowing")
            return 0
        
        # Check workspace state and user intent
        workspace_state = self.check_workspace_state()
        
        # If no user message provided, fall back to original behavior
        if not user_message:
            log_debug("No user message provided, falling back to workspace state check")
            if not workspace_state['is_clean']:
                print(self._generate_workflow_guidance(workspace_state), file=sys.stderr)
                return 2
            return 0
        
        # Apply context-aware decision logic
        should_allow = self.should_allow_work(user_message, workspace_state)
        
        if should_allow:
            log_debug("Context-aware analysis: allowing work")
            return 0
        else:
            log_debug("Context-aware analysis: blocking work")
            print(self._generate_workflow_guidance(workspace_state), file=sys.stderr)
            return 2
    
    def _handle_pretool_task(self, input_data: Dict[str, Any]) -> int:
        """Handle Task tool - maintain original subagent enforcement behavior."""
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
            return 2  # Block with subagent recommendation
        
        return 0
    
    def _handle_userprompt(self, input_data: Dict[str, Any]) -> int:
        """Handle UserPromptSubmit - provide context for proceed attempts."""
        prompt = input_data.get("prompt", "").lower()
        
        log_debug(f"UserPromptSubmit called with prompt: {prompt[:100]}...")
        
        # Patterns that indicate user wants to proceed
        proceed_patterns = [
            r"\b(proceed|continue|next|what'?s next|task \d+|move on|start|begin)\b",
            r"ready for .*task",
            r"let'?s (do|start|work on)",
        ]
        
        import re
        is_proceed_attempt = any(re.search(pattern, prompt) for pattern in proceed_patterns)
        
        if not is_proceed_attempt:
            return 0
        
        # Check workspace state
        workspace_state = self.check_workspace_state()
        
        if not workspace_state['is_clean']:
            # Add context about incomplete workflow
            context = "\n⚠️ **Agent OS Context-Aware Workflow Status Check**\n\n"
            context += "Before proceeding to new work:\n"
            if workspace_state['has_uncommitted_changes']:
                context += "• Uncommitted changes detected\n"
            if workspace_state['has_open_prs']:
                context += "• Open pull requests need review/merge\n"
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
        
        return 0
    
    def _handle_posttool(self, input_data: Dict[str, Any]) -> int:
        """Handle PostToolUse - maintain original auto-commit behavior."""
        tool_name = input_data.get("tool_name", "")
        tool_input = input_data.get("tool_input", {})
        
        log_debug(f"PostToolUse called for tool: {tool_name}")
        
        # Check if Agent OS files were modified
        if tool_name in ["Write", "Edit", "MultiEdit"]:
            file_path = tool_input.get("file_path", "")
            if ".agent-os/" in file_path or "CLAUDE.md" in file_path:
                log_debug(f"Agent OS file modified: {file_path}")
                # Could auto-commit here if needed
        
        return 0


def main():
    """Main entry point for the context-aware hook."""
    if len(sys.argv) < 2:
        print("Error: Hook type not specified", file=sys.stderr)
        sys.exit(1)
    
    hook_type = sys.argv[1]
    
    try:
        # Read JSON input from stdin
        input_data = json.load(sys.stdin)
        log_debug(f"Context-aware hook {hook_type} called with data: {json.dumps(input_data)[:200]}...")
    except Exception as e:
        log_debug(f"Failed to parse JSON input: {e}")
        sys.exit(0)  # Don't block on parse errors
    
    # Initialize context-aware hook wrapper
    hook = ContextAwareWorkflowHook()
    
    # Process the hook and exit with appropriate code
    exit_code = hook.process_hook(hook_type, input_data)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()