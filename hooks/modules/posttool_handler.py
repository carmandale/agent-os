#!/usr/bin/env python3
"""
Agent OS PostTool Handler
========================
Handles PostToolUse hook - auto-commit Agent OS documentation changes.
Focused on single responsibility: post-tool cleanup and documentation sync.
"""

import os
import subprocess
import sys
from .hook_core import BaseHookHandler


class PostToolHandler(BaseHookHandler):
    """Handles PostToolUse hook with focused responsibility."""
    
    def handle(self) -> None:
        """Main PostTool handler logic."""
        tool_name = self.get_tool_name()
        
        self.log_debug(f"PostToolUse called for tool: {tool_name}")
        
        # Check if documentation updates are required
        self._check_documentation_status()
        
        # Future: Add other post-tool cleanup logic here
        self.exit_allow("PostTool checks completed")
    
    def _check_documentation_status(self) -> None:
        """Check if documentation updates are required after tool use."""
        try:
            # Run documentation updater in dry-run mode
            result = subprocess.run([
                os.path.expanduser("~/.agent-os/scripts/update-documentation.sh"),
                "--dry-run",
                "--deep"
            ], capture_output=True, text=True, timeout=30, cwd=self.workspace_root)
            
            # Exit code 2 means documentation updates are pending
            if result.returncode == 2:
                message = (
                    "⚠️ Documentation updates required.\n\n"
                    "Please run `/update-documentation --dry-run` to review proposals.\n"
                    "Include updates in your PR under 'Documentation Updates'."
                )
                self.exit_block(message)
                
        except subprocess.TimeoutExpired:
            self.log_debug("Documentation check timed out")
        except Exception as e:
            self.log_debug(f"Documentation check failed: {e}")
        
        # Don't block on documentation check failures
