#!/usr/bin/env python3
"""
Agent OS Workflow Enforcement Hook - Optimized Modular Architecture
===================================================================
Single-file modular implementation optimized for P95 < 500ms performance.
Maintains single responsibility principles while eliminating import overhead.

Usage: python3 workflow-enforcement-hook-optimized.py [hook-type]
Hook types: pretool, pretool-task, userprompt, posttool
"""

import json
import os
import re
import subprocess
import sys
import threading
import time
from datetime import datetime
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeoutError
from typing import Optional, Dict, Any, List, Tuple

# Add parent directory to path for project root resolver
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
try:
    from scripts.project_root_resolver import ProjectRootResolver
except ImportError:
    ProjectRootResolver = None


# === PERFORMANCE OPTIMIZATION LAYER ===

class TTLCache:
    """Thread-safe TTL cache for subprocess results."""
    
    def __init__(self, default_ttl=30):
        self._cache = {}
        self._timestamps = {}
        self._lock = threading.Lock()
        self.default_ttl = default_ttl
    
    def get(self, key: str, ttl: int = None) -> Optional[Any]:
        with self._lock:
            if key not in self._cache:
                return None
            age = time.time() - self._timestamps[key]
            if age > (ttl or self.default_ttl):
                del self._cache[key]
                del self._timestamps[key]
                return None
            return self._cache[key]
    
    def set(self, key: str, value: Any) -> None:
        with self._lock:
            self._cache[key] = value
            self._timestamps[key] = time.time()

# Global cache instance
_cache = TTLCache()

class OptimizedSubprocess:
    """High-performance subprocess execution with caching."""
    
    @staticmethod
    def run_cached(cmd: List[str], cwd: str = None, timeout: float = 2.0, 
                   cache_ttl: int = 10) -> Tuple[int, str, str]:
        cache_key = f"{':'.join(cmd)}:{cwd or 'none'}"
        cached = _cache.get(cache_key, cache_ttl)
        if cached is not None:
            return cached
        
        with ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(subprocess.run, cmd, 
                                   capture_output=True, text=True, 
                                   cwd=cwd, timeout=timeout)
            try:
                result = future.result(timeout=timeout + 0.5)
                output = (result.returncode, result.stdout or "", result.stderr or "")
                _cache.set(cache_key, output)
                return output
            except (FuturesTimeoutError, subprocess.TimeoutExpired):
                return (124, "", "Command timed out")
            except Exception as e:
                return (1, "", str(e))


# === SHARED UTILITIES ===

def log_debug(message):
    """Minimal debug logging."""
    if os.environ.get("AGENT_OS_DEBUG", "").lower() == "true":
        timestamp = datetime.now().isoformat()
        log_path = Path.home() / ".agent-os" / "logs" / "hooks-debug.log"
        log_path.parent.mkdir(parents=True, exist_ok=True)
        try:
            with open(log_path, "a") as f:
                f.write(f"[{timestamp}] {message}\n")
        except Exception:
            pass


def resolve_workspace_root(input_data: dict) -> str:
    """Fast workspace resolution."""
    if ProjectRootResolver:
        try:
            resolver = ProjectRootResolver()
            file_path = None
            tool_input = input_data.get("tool_input", {}) or {}
            for key in ["file_path", "path"]:
                p = tool_input.get(key)
                if isinstance(p, str) and p.strip():
                    file_path = p
                    break
            return resolver.resolve(file_path=file_path, hook_payload=input_data)
        except Exception:
            pass
    return os.getcwd()


def check_git_status(cwd: str) -> bool:
    """Fast git status check with caching."""
    try:
        returncode, stdout, _ = OptimizedSubprocess.run_cached(
            ["git", "status", "--porcelain"], cwd=cwd, timeout=3.0, cache_ttl=5
        )
        return returncode == 0 and bool(stdout.strip())
    except Exception:
        return False


def check_open_prs(cwd: str) -> bool:
    """Fast PR check with caching."""
    try:
        returncode, stdout, _ = OptimizedSubprocess.run_cached(
            ["gh", "pr", "list", "--state", "open", "--json", "number"], 
            cwd=cwd, timeout=3.0, cache_ttl=15
        )
        if returncode == 0:
            try:
                prs = json.loads(stdout or "[]")
                return len(prs) > 0
            except json.JSONDecodeError:
                return False
        return False
    except Exception:
        return False


def get_user_intent(prompt_text: str = "") -> str:
    """Fast intent analysis with caching."""
    env_intent = os.environ.get("AGENT_OS_INTENT", "").strip().upper()
    if env_intent in {"MAINTENANCE", "NEW", "AMBIGUOUS"}:
        return env_intent
    
    text = prompt_text or os.environ.get("CLAUDE_USER_PROMPT", "")
    if not text.strip():
        return "AMBIGUOUS"
    
    try:
        returncode, stdout, _ = OptimizedSubprocess.run_cached(
            [os.path.expanduser("~/.agent-os/scripts/intent-analyzer.sh"), "--text", text],
            timeout=2.0, cache_ttl=30
        )
        val = (stdout or "").strip().upper()
        return val if val in {"MAINTENANCE", "NEW", "AMBIGUOUS"} else "AMBIGUOUS"
    except Exception:
        return "AMBIGUOUS"


def has_active_spec(cwd: str) -> bool:
    """Fast spec detection with caching."""
    try:
        returncode, stdout, _ = OptimizedSubprocess.run_cached(
            ["bash", "-lc", "ls -1 .agent-os/specs 2>/dev/null | wc -l"],
            cwd=cwd, timeout=2.0, cache_ttl=10
        )
        count = int((stdout or "0").strip())
        return returncode == 0 and count > 0
    except (ValueError, Exception):
        return False


def check_workflow_status(cwd: str) -> List[str]:
    """Fast workflow status check."""
    issues = []
    
    # Quick work session check
    work_session_active = os.environ.get("AGENT_OS_WORK_SESSION", "").lower() == "true"
    session_file = os.path.expanduser("~/.agent-os/cache/work-session")
    if work_session_active or os.path.exists(session_file):
        log_debug("Work session mode active - skipping hygiene checks")
        return issues
    
    # Parallel git checks with timeout
    with ThreadPoolExecutor(max_workers=2) as executor:
        git_future = executor.submit(check_git_status, cwd)
        pr_future = executor.submit(check_open_prs, cwd)
        
        try:
            if git_future.result(timeout=3.0):
                issues.append("Uncommitted changes detected")
        except Exception:
            pass
        
        try:
            if pr_future.result(timeout=3.0):
                issues.append("Open pull requests need review/merge")
        except Exception:
            pass
    
    return issues


# === BASH COMMAND ANALYSIS ===

def is_write_bash(command: str) -> bool:
    """Fast write detection."""
    c = command.strip()
    write_prefixes = ["cp ", "mv ", "rm ", "touch ", "chmod ", "chown ", "tee ", "patch ", 
                      "git apply ", "npm ", "yarn ", "pnpm ", "pip ", "uv ", "docker "]
    
    if any(c.startswith(p) for p in write_prefixes):
        return True
    
    if c.startswith("echo ") and (">" in c or ">>" in c):
        return True
    
    return ">>" in c or ">" in c or "sed -i" in c or "awk -i" in c


def is_readonly_bash(command: str) -> bool:
    """Fast readonly detection."""
    c = command.strip()
    readonly_prefixes = ["cd ", "ls ", "ls", "cat ", "head ", "tail ", "grep ", "rg ", "find ",
                         "ps ", "netstat", "lsof ", "echo ", "env", "which ", "pwd", 
                         "wc ", "sort ", "uniq ", "awk ", "sed "]
    
    return any(c.startswith(p) for p in readonly_prefixes) and not is_write_bash(c)


def is_docs_only(command_or_path: str) -> bool:
    """Fast docs detection."""
    lower = command_or_path.lower()
    return (".md" in lower or ".mdc" in lower or "docs/" in lower or "claude.md" in lower)


# === HANDLER IMPLEMENTATIONS ===

def handle_pretool(input_data):
    """PreToolUse handler - optimized for performance."""
    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    
    log_debug(f"PreToolUse: {tool_name}")
    
    if tool_name == "Bash":
        command = tool_input.get("command", "").strip()
        root = resolve_workspace_root(input_data)
        
        # PR guard
        if re.match(r"\s*(gh\s+pr\s+(create|merge)\b)", command):
            try:
                returncode, _, _ = OptimizedSubprocess.run_cached([
                    os.path.expanduser("~/.agent-os/scripts/update-documentation.sh"),
                    "--deep", "--dry-run"
                ], cwd=root, timeout=15.0, cache_ttl=5)
                if returncode == 2:
                    print("Documentation updates required before PR. Run /update-documentation --deep --dry-run and include updates in PR.", file=sys.stderr)
                    sys.exit(2)
            except Exception:
                pass
        
        # Always allow git/gh
        if command.startswith(("git ", "gh ")):
            sys.exit(0)
        
        # Allow readonly commands
        if is_readonly_bash(command):
            sys.exit(0)
        
        # Handle writes
        if is_write_bash(command):
            if is_docs_only(command):
                sys.exit(0)
            
            intent = get_user_intent()
            if intent == "MAINTENANCE":
                sys.exit(0)
            
            # NEW/AMBIGUOUS: check requirements
            if not has_active_spec(root):
                print("No active spec detected (.agent-os/specs). Run /create-spec first.", file=sys.stderr)
                sys.exit(2)
            
            issues = check_workflow_status(root)
            if issues:
                print("; ".join(issues), file=sys.stderr)
                sys.exit(2)
        
        sys.exit(0)
    
    # Handle other tools
    elif tool_name in ["Write", "Edit", "MultiEdit", "Update", "Task"]:
        # Docs exception
        file_path = tool_input.get("file_path", "") or tool_input.get("path", "")
        if file_path and is_docs_only(file_path):
            sys.exit(0)
        
        intent = get_user_intent(tool_input.get("description", ""))
        if intent == "MAINTENANCE":
            sys.exit(0)
        
        root = resolve_workspace_root(input_data)
        if not has_active_spec(root):
            print("No active spec detected (.agent-os/specs). Run /create-spec first.", file=sys.stderr)
            sys.exit(2)
        
        issues = check_workflow_status(root)
        if issues:
            print("; ".join(issues), file=sys.stderr)
            sys.exit(2)
    
    sys.exit(0)


def handle_pretool_task(input_data):
    """Task tool handler - optimized."""
    tool_input = input_data.get("tool_input", {})
    description = tool_input.get("description", "").lower()
    
    log_debug(f"Task: {description[:50]}")
    
    review_keywords = ["review", "validate", "check", "verify", "test", "analyze"]
    if any(keyword in description for keyword in review_keywords):
        message = ("⚠️ Use specialized subagents for quality assurance:\n\n"
                  "• senior-software-engineer - For architecture and design review\n"
                  "• qa-test-engineer - For comprehensive test validation\n"
                  "• code-analyzer-debugger - For debugging complex issues\n\n"
                  "Example: 'Use senior-software-engineer to review the implementation'")
        print(message, file=sys.stderr)
        sys.exit(2)
    
    sys.exit(0)


def handle_userprompt(input_data):
    """UserPromptSubmit handler - optimized."""
    prompt = input_data.get("prompt", "").lower()
    
    log_debug(f"UserPrompt: {prompt[:50]}")
    
    # Check for proceed patterns
    proceed_patterns = [
        r"\b(proceed|continue|next|what'?s next|task \d+|move on|start|begin)\b",
        r"ready for .*task",
        r"let'?s (do|start|work on)",
    ]
    
    is_proceed = any(re.search(pattern, prompt) for pattern in proceed_patterns)
    if not is_proceed:
        sys.exit(0)
    
    # Handle proceed attempts
    intent = get_user_intent(prompt)
    if intent == "MAINTENANCE":
        sys.exit(0)
    
    root = resolve_workspace_root(input_data)
    issues = check_workflow_status(root)
    if issues:
        message = "⚠️ Cannot proceed: workflow issues detected.\n\n" + \
                 "\n".join(f"• {issue}" for issue in issues)
        output = {
            "decision": "block",
            "hookSpecificOutput": {"additionalContext": message}
        }
        print(json.dumps(output))
    
    sys.exit(0)


def handle_posttool(input_data):
    """PostToolUse handler - optimized."""
    log_debug(f"PostTool: {input_data.get('tool_name', '')}")
    
    # Check docs status
    try:
        root = resolve_workspace_root(input_data)
        returncode, _, _ = OptimizedSubprocess.run_cached([
            os.path.expanduser("~/.agent-os/scripts/update-documentation.sh"),
            "--dry-run", "--deep"
        ], cwd=root, timeout=15.0, cache_ttl=5)
        
        if returncode == 2:
            message = ("⚠️ Documentation updates required.\n\n"
                      "Please run `/update-documentation --dry-run` to review proposals.\n"
                      "Include updates in your PR under 'Documentation Updates'.")
            print(message, file=sys.stderr)
            sys.exit(2)
    except Exception:
        pass
    
    sys.exit(0)


# === MAIN DISPATCHER ===

def main():
    """Optimized main dispatcher."""
    if len(sys.argv) < 2:
        sys.exit(1)
    
    hook_type = sys.argv[1]
    
    try:
        input_data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    
    log_debug(f"Hook {hook_type} called")
    
    # Fast dispatch
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
