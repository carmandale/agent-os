#!/usr/bin/env python3
"""
Agent OS PreTool Handler
=======================
Handles PreToolUse hook - blocks new work until workflow complete.
Focused on single responsibility: validating tool usage before execution.
"""

import os
import re
import subprocess
import sys
from typing import Dict, Any

from .hook_core import BaseHookHandler, IntentAnalyzer, SpecChecker


class BashCommandAnalyzer:
    """Analyzes Bash commands for write operations and safety."""
    
    READONLY_PREFIXES = [
        "cd ", "ls ", "ls", "cat ", "head ", "tail ", "grep ", "rg ", "find ",
        "ps ", "netstat", "lsof ", "echo ", "env", "which ", "pwd",
        "wc ", "sort ", "uniq ", "awk ", "sed "
    ]
    
    WRITE_PREFIXES = [
        "cp ", "mv ", "rm ", "touch ", "chmod ", "chown ", "tee ", "patch ", 
        "git apply ", "npm ", "yarn ", "pnpm ", "pip ", "uv ", "docker "
    ]
    
    @staticmethod
    def is_write_command(command: str) -> bool:
        """Detect if command performs write operations."""
        c = command.strip()
        
        # Obvious write commands
        if any(c.startswith(p) for p in BashCommandAnalyzer.WRITE_PREFIXES):
            return True
        
        # Echo with redirection
        if c.startswith("echo ") and (">" in c or ">>" in c):
            return True
        
        # Redirections or in-place edits
        if ">>" in c or ">" in c or "sed -i" in c or "awk -i" in c:
            return True
        
        return False
    
    @staticmethod
    def is_readonly_command(command: str) -> bool:
        """Detect if command is clearly read-only."""
        c = command.strip()
        
        # Check against readonly prefixes and ensure no write operations
        is_readonly = any(c.startswith(p) for p in BashCommandAnalyzer.READONLY_PREFIXES)
        has_write = BashCommandAnalyzer.is_write_command(c)
        
        return is_readonly and not has_write
    
    @staticmethod
    def is_docs_only_command(command: str) -> bool:
        """Detect if command only targets documentation files."""
        lowered = command.lower()
        return (".md" in lowered or ".mdc" in lowered or 
                "docs/" in lowered or "claude.md" in lowered)
    
    @staticmethod
    def is_git_gh_command(command: str) -> bool:
        """Detect git or gh commands (usually allowed for workflow cleanup)."""
        return command.strip().startswith(("git ", "gh "))


class DocumentationChecker:
    """Handles documentation status validation for PR operations."""
    
    @staticmethod
    def check_docs_before_pr(command: str, workspace_root: str) -> None:
        """Check if docs are up-to-date before PR creation/merge."""
        # Match PR creation/merge commands
        if not re.match(r"\s*(gh\s+pr\s+(create|merge)\b)", command):
            return
        
        try:
            result = subprocess.run([
                os.path.expanduser("~/.agent-os/scripts/update-documentation.sh"),
                "--deep", "--dry-run"
            ], capture_output=True, text=True, timeout=30, cwd=workspace_root)
            
            if result.returncode == 2:
                raise SystemExit(
                    "Documentation updates required before PR. "
                    "Run /update-documentation --deep --dry-run and include updates in PR."
                )
        except subprocess.TimeoutExpired:
            raise SystemExit("Documentation check timed out")
        except Exception as e:
            raise SystemExit(f"Documentation check failed: {e}")


class PreToolHandler(BaseHookHandler):
    """Handles PreToolUse hook with focused responsibility."""
    
    # Tools that indicate starting new work
    NEW_WORK_TOOLS = ["Write", "Edit", "MultiEdit", "Update", "Task"]
    
    def handle(self) -> None:
        """Main PreTool handler logic."""
        tool_name = self.get_tool_name()
        tool_input = self.get_tool_input()
        
        self.log_debug(f"PreToolUse called for tool: {tool_name}")
        
        # Handle Bash commands with special logic
        if tool_name == "Bash":
            self._handle_bash_command(tool_input.get("command", "").strip())
            return
        
        # Only check non-bash tools that indicate new work
        if tool_name not in self.NEW_WORK_TOOLS:
            self.exit_allow(f"Tool {tool_name} not subject to workflow checks")
        
        # Handle other tools
        self._handle_other_tools(tool_input)
    
    def _handle_bash_command(self, command: str) -> None:
        """Handle Bash command validation."""
        # PR creation/merge guard: require docs up-to-date
        DocumentationChecker.check_docs_before_pr(command, self.workspace_root)
        
        # Always allow git/gh operations (to resolve hygiene issues)
        if BashCommandAnalyzer.is_git_gh_command(command):
            self.exit_allow(f"Git/gh command allowed: {command}")
        
        # Allow clearly read-only commands
        if BashCommandAnalyzer.is_readonly_command(command):
            self.exit_allow(f"Read-only command allowed: {command}")
        
        # Handle write commands based on intent and context
        self._handle_write_command(command)
    
    def _handle_write_command(self, command: str) -> None:
        """Handle write command validation based on intent."""
        is_write = BashCommandAnalyzer.is_write_command(command)
        
        # Allow docs-only writes regardless of intent
        if is_write and BashCommandAnalyzer.is_docs_only_command(command):
            self.exit_allow(f"Docs-only write allowed: {command}")
        
        # Get user intent
        intent = IntentAnalyzer.get_intent()
        
        # For write operations, check intent and enforce workflow
        if is_write:
            # Allow maintenance writes
            if intent == "MAINTENANCE":
                self.exit_allow(f"Maintenance write allowed: {command}")
            
            # For NEW or AMBIGUOUS intent, enforce spec and hygiene
            self._enforce_workflow_requirements(command)
        
        # Non-write commands are generally allowed
        self.exit_allow(f"Non-write command allowed: {command}")
    
    def _handle_other_tools(self, tool_input: Dict[str, Any]) -> None:
        """Handle non-Bash tools."""
        # Docs-only exception for file editing tools
        file_path = tool_input.get("file_path", "") or tool_input.get("path", "")
        if file_path:
            lower = file_path.lower()
            if (lower.endswith((".md", ".mdc")) or 
                lower.startswith("docs/") or 
                os.path.basename(lower) == "claude.md"):
                self.exit_allow(f"Docs file editing allowed: {file_path}")
        
        # Check intent
        intent = IntentAnalyzer.get_intent(tool_input.get("description", ""))
        
        # Allow maintenance work
        if intent == "MAINTENANCE":
            self.exit_allow("Maintenance work allowed")
        
        # Enforce workflow for new work
        self._enforce_workflow_requirements("tool operation")
    
    def _enforce_workflow_requirements(self, operation: str) -> None:
        """Enforce spec and hygiene requirements for new work."""
        # Check for active spec
        if not SpecChecker.has_active_spec(self.workspace_root):
            self.exit_block("No active spec detected (.agent-os/specs). Run /create-spec first.")
        
        # Check workflow status
        issues = self.check_workflow_status()
        if issues:
            reason = "; ".join(issues)
            self.exit_block(reason)
        
        # All checks passed
        self.exit_allow(f"Workflow requirements satisfied for: {operation}")
