#!/usr/bin/env python3
"""
Agent OS UserPrompt Handler
===========================
Handles UserPromptSubmit hook - adds context for proceed attempts.
Focused on single responsibility: user intent validation and context injection.
"""

import json
import re
import sys
from .hook_core_optimized import BaseHookHandler, IntentAnalyzer


class UserPromptHandler(BaseHookHandler):
    """Handles UserPromptSubmit hook with focused responsibility."""
    
    # Patterns that indicate user wants to proceed with new work
    PROCEED_PATTERNS = [
        r"\b(proceed|continue|next|what'?s next|task \d+|move on|start|begin)\b",
        r"ready for .*task",
        r"let'?s (do|start|work on)",
    ]
    
    def handle(self) -> None:
        """Main UserPrompt handler logic."""
        prompt = self.input_data.get("prompt", "").lower()
        
        self.log_debug(f"UserPromptSubmit called with prompt: {prompt[:100]}...")
        
        # Check if user is trying to proceed with new work
        if not self._is_proceed_attempt(prompt):
            self.exit_allow("Not a proceed attempt")
        
        # Handle proceed attempts with workflow validation
        self._handle_proceed_attempt(prompt)
    
    def _is_proceed_attempt(self, prompt: str) -> bool:
        """Check if prompt indicates user wants to proceed with work."""
        return any(re.search(pattern, prompt) for pattern in self.PROCEED_PATTERNS)
    
    def _handle_proceed_attempt(self, prompt: str) -> None:
        """Handle user attempts to proceed with new work."""
        # Get user intent from the prompt
        intent = IntentAnalyzer.get_intent(prompt)
        
        # Allow maintenance work without hygiene checks
        if intent == "MAINTENANCE":
            self.exit_allow("Maintenance work proceed allowed")
        
        # Check workflow status for new work attempts
        issues = self.check_workflow_status()
        if issues:
            message = "⚠️ Cannot proceed: workflow issues detected.\n\n" + \
                     "\n".join(f"• {issue}" for issue in issues)
            
            # Return structured JSON for UserPromptSubmit hook
            output = {
                "decision": "block",
                "hookSpecificOutput": {"additionalContext": message}
            }
            print(json.dumps(output))
            self.exit_allow("Proceed blocked due to workflow issues")
        
        # All checks passed
        self.exit_allow("Proceed allowed")
