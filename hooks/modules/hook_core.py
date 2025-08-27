#!/usr/bin/env python3
"""
Agent OS Hook Core Module
========================
Shared utilities and base classes for Agent OS hooks.
Provides common functionality for workspace resolution, logging, and subprocess management.
"""

import json
import os
import subprocess
import sys
from datetime import datetime
from typing import Optional, Dict, Any, List
from pathlib import Path

# Add parent directory to path for project root resolver
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
try:
    from scripts.project_root_resolver import ProjectRootResolver
except ImportError:
    ProjectRootResolver = None


class HookError(Exception):
    """Base exception for hook-related errors."""
    pass


class HookLogger:
    """Centralized logging for hook operations."""
    
    @staticmethod
    def debug(message: str) -> None:
        """Write debug logs if debugging enabled."""
        if os.environ.get("AGENT_OS_DEBUG", "").lower() == "true":
            log_path = Path.home() / ".agent-os" / "logs" / "hooks-debug.log"
            log_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(log_path, "a") as f:
                timestamp = datetime.now().isoformat()
                f.write(f"[{timestamp}] {message}\n")


class WorkspaceResolver:
    """Handles workspace root resolution with fallback strategies."""
    
    @staticmethod
    def resolve(input_data: Optional[Dict[str, Any]] = None) -> str:
        """Best-effort resolution of the target project directory."""
        # Use ProjectRootResolver if available
        if ProjectRootResolver:
            try:
                resolver = ProjectRootResolver()
                
                # Extract file path if present
                file_path = None
                if input_data:
                    tool_input = input_data.get("tool_input", {}) or {}
                    for key in ["file_path", "path"]:
                        p = tool_input.get(key)
                        if isinstance(p, str) and p.strip():
                            file_path = p
                            break
                
                return resolver.resolve(file_path=file_path, hook_payload=input_data)
            except Exception as e:
                HookLogger.debug(f"ProjectRootResolver failed: {e}, falling back to legacy resolution")
        
        # Legacy fallback resolution
        try:
            if input_data:
                # Check common workspace fields
                for key in ["cwd", "workspaceDir", "workspace", "projectRoot", "rootDir"]:
                    val = input_data.get(key)
                    if isinstance(val, str) and val.strip():
                        return val
                
                # Check tool input fields
                tool_input = input_data.get("tool_input", {}) or {}
                for key in ["cwd", "workspaceDir", "projectRoot", "rootDir"]:
                    val = tool_input.get(key)
                    if isinstance(val, str) and val.strip():
                        return val
                
                # Derive from file path if present
                for key in ["file_path", "path"]:
                    p = tool_input.get(key)
                    if isinstance(p, str) and p.strip():
                        return os.path.dirname(p)
        except Exception as e:
            HookLogger.debug(f"Legacy workspace resolution failed: {e}")
        
        # Environment hint fallback
        env_dir = os.environ.get("CLAUDE_PROJECT_DIR", "").strip()
        if env_dir:
            return env_dir
        
        # Last resort: current working directory
        return os.getcwd()


class GitChecker:
    """Handles git-related status checks."""
    
    @staticmethod
    def has_uncommitted_changes(cwd: str) -> bool:
        """Check if there are uncommitted changes in workspace."""
        try:
            result = subprocess.run(
                ["git", "status", "--porcelain"],
                capture_output=True,
                text=True,
                timeout=5,
                cwd=cwd
            )
            return bool(result.stdout.strip())
        except Exception as e:
            HookLogger.debug(f"Git status check failed: {e}")
            return False
    
    @staticmethod
    def has_open_prs(cwd: str) -> bool:
        """Check for open PRs in the repository."""
        try:
            result = subprocess.run(
                ["gh", "pr", "list", "--state", "open", "--json", "number"],
                capture_output=True,
                text=True,
                timeout=5,
                cwd=cwd
            )
            if result.returncode == 0:
                prs = json.loads(result.stdout or "[]")
                return len(prs) > 0
            return False
        except Exception as e:
            HookLogger.debug(f"PR check failed: {e}")
            return False


class IntentAnalyzer:
    """Handles user intent analysis for maintenance vs new work."""
    
    # Patterns that indicate user wants to proceed with new work
    PROCEED_PATTERNS = [
        r"\b(proceed|continue|next|what'?s next|task \d+|move on|start|begin)\b",
        r"ready for .*task",
        r"let'?s (do|start|work on)",
    ]
    
    @staticmethod
    def get_intent(prompt_text: str = "") -> str:
        """Return MAINTENANCE | NEW | AMBIGUOUS using intent analyzer."""
        # Environment override
        env_intent = os.environ.get("AGENT_OS_INTENT", "").strip().upper()
        if env_intent in {"MAINTENANCE", "NEW", "AMBIGUOUS"}:
            return env_intent
        
        # Use provided prompt or environment prompt
        text = prompt_text or os.environ.get("CLAUDE_USER_PROMPT", "")
        
        try:
            result = subprocess.run(
                [os.path.expanduser("~/.agent-os/scripts/intent-analyzer.sh"), "--text", text],
                capture_output=True,
                text=True,
                timeout=3
            )
            val = (result.stdout or "").strip().upper()
            return val if val in {"MAINTENANCE", "NEW", "AMBIGUOUS"} else "AMBIGUOUS"
        except Exception as e:
            HookLogger.debug(f"Intent analyzer failed: {e}")
            return "AMBIGUOUS"


class SpecChecker:
    """Handles spec detection for workflow enforcement."""
    
    @staticmethod
    def has_active_spec(cwd: str) -> bool:
        """Detect if there is a current spec context (.agent-os/specs/*) in workspace."""
        try:
            result = subprocess.run(
                ["bash", "-lc", "ls -1 .agent-os/specs 2>/dev/null | wc -l"],
                capture_output=True,
                text=True,
                timeout=3,
                cwd=cwd
            )
            count = int(result.stdout.strip() or "0")
            return count > 0
        except Exception as e:
            HookLogger.debug(f"Spec detection failed: {e}")
            return False


class BaseHookHandler:
    """Base class for all hook handlers providing common functionality."""
    
    def __init__(self, input_data: Dict[str, Any]):
        self.input_data = input_data
        self.workspace_root = WorkspaceResolver.resolve(input_data)
        
    def log_debug(self, message: str) -> None:
        """Log debug message."""
        HookLogger.debug(f"{self.__class__.__name__}: {message}")
    
    def get_tool_name(self) -> str:
        """Get the tool name from input data."""
        return self.input_data.get("tool_name", "")
    
    def get_tool_input(self) -> Dict[str, Any]:
        """Get the tool input from input data."""
        return self.input_data.get("tool_input", {})
    
    def exit_allow(self, reason: str = "") -> None:
        """Exit with success (allow the operation)."""
        if reason:
            self.log_debug(f"Allowing: {reason}")
        sys.exit(0)
    
    def exit_block(self, reason: str) -> None:
        """Exit with error (block the operation)."""
        self.log_debug(f"Blocking: {reason}")
        print(reason, file=sys.stderr)
        sys.exit(2)
    
    def check_work_session(self) -> bool:
        """Check if work session mode is active."""
        work_session_active = os.environ.get("AGENT_OS_WORK_SESSION", "").lower() == "true"
        session_file = os.path.expanduser("~/.agent-os/cache/work-session")
        session_exists = os.path.exists(session_file)
        return work_session_active or session_exists
    
    def check_workflow_status(self) -> List[str]:
        """Analyze workflow status and return issues."""
        issues = []
        
        # In work session mode, skip uncommitted changes check
        if self.check_work_session():
            self.log_debug("Work session mode active - allowing uncommitted changes")
        else:
            if GitChecker.has_uncommitted_changes(self.workspace_root):
                issues.append("Uncommitted changes detected")
        
        # Check for open PRs
        if GitChecker.has_open_prs(self.workspace_root):
            issues.append("Open pull requests need review/merge")
        
        return issues
    
    def handle(self) -> None:
        """Main handler method to be implemented by subclasses."""
        raise NotImplementedError("Subclasses must implement handle() method")
