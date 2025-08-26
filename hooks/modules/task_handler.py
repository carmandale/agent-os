#!/usr/bin/env python3
"""
Agent OS Task Handler
====================
Handles Task tool validation - enforces subagent usage for complex work.
Focused on single responsibility: Task tool quality assurance.
"""

import sys
from .hook_core import BaseHookHandler


class TaskHandler(BaseHookHandler):
    """Handles Task tool validation with focused responsibility."""
    
    # Keywords that indicate review/validation work needing subagents
    REVIEW_KEYWORDS = [
        "review", "validate", "check", "verify", "test", "analyze", 
        "debug", "troubleshoot", "investigate", "audit"
    ]
    
    def handle(self) -> None:
        """Main Task handler logic."""
        tool_input = self.get_tool_input()
        description = tool_input.get("description", "").lower()
        
        self.log_debug(f"Task tool called with description: {description}")
        
        # Check if this task should use specialized subagents
        if self._needs_subagent(description):
            self._recommend_subagent()
        
        self.exit_allow("Task tool allowed")
    
    def _needs_subagent(self, description: str) -> bool:
        """Check if task description indicates need for specialized subagents."""
        return any(keyword in description for keyword in self.REVIEW_KEYWORDS)
    
    def _recommend_subagent(self) -> None:
        """Block task and recommend appropriate subagent."""
        message = (
            "⚠️ Use specialized subagents for quality assurance:\n\n"
            "• senior-software-engineer - For architecture and design review\n"
            "• qa-test-engineer - For comprehensive test validation\n"
            "• code-analyzer-debugger - For debugging complex issues\n\n"
            "Example: 'Use senior-software-engineer to review the implementation'"
        )
        
        self.exit_block(message)
