#!/usr/bin/env python3
"""
Agent OS Workflow Enforcement Hook v2.0 - Production Ready
==========================================================
Modular architecture optimized for P95 < 500ms with smart fallbacks.
Maintains zero breaking changes while achieving performance targets.

Usage: python3 workflow-enforcement-hook-v2-final.py [hook-type]
Hook types: pretool, pretool-task, userprompt, posttool
"""

import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any, List, Tuple

# Add parent directory to path for project root resolver
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
try:
    from scripts.project_root_resolver import ProjectRootResolver
except ImportError:
    ProjectRootResolver = None

# === PERFORMANCE OPTIMIZATION LAYER ===

# Simple in-memory cache with timestamps
_cache = {}
_cache_times = {}

def cached_subprocess(cmd: List[str], cwd: str = None, timeout: float = 1.5, 
                     cache_ttl: int = 10) -> Tuple[int, str, str]:
    """Ultra-fast subprocess with aggressive caching and timeouts."""
    cache_key = f"{':'.join(cmd)}:{cwd or 'none'}"
    now = time.time()
    
    # Check cache
    if cache_key in _cache and (now - _cache_times[cache_key]) < cache_ttl:
        return _cache[cache_key]
    
    # Execute with strict timeout
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, 
                              cwd=cwd, timeout=timeout)
        output = (result.returncode, result.stdout or "", result.stderr or "")
        _cache[cache_key] = output
        _cache_times[cache_key] = now
        return output
    except (subprocess.TimeoutExpired, Exception):
        # Cache failures too (avoid repeated slow calls)
        output = (1, "", "timeout or error")
        _cache[cache_key] = output
        _cache_times[cache_key] = now
        return output


def log_debug(message):
    """Minimal logging."""
    if os.environ.get("AGENT_OS_DEBUG", "").lower() == "true":
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        print(f"[{timestamp}] {message}", file=sys.stderr)


def resolve_workspace_root(input_data: dict) -> str:
    """Fast workspace resolution with fallbacks."""
    if ProjectRootResolver:
        try:
            resolver = ProjectRootResolver()
            tool_input = input_data.get("tool_input", {}) or {}
            file_path = tool_input.get("file_path") or tool_input.get("path")
            return resolver.resolve(file_path=file_path, hook_payload=input_data)
        except Exception:
            pass
    return os.getcwd()


# === OPTIMIZED CHECKERS ===

def fast_git_check(cwd: str) -> bool:
    """Ultra-fast git status check."""
    returncode, stdout, _ = cached_subprocess(
        ["git", "status", "--porcelain"], cwd=cwd, timeout=1.5, cache_ttl=10
    )
    return returncode == 0 and bool(stdout.strip())


def fast_pr_check(cwd: str) -> bool:
    """Ultra-fast PR check with fallback."""
    returncode, stdout, _ = cached_subprocess(
        ["gh", "pr", "list", "--state", "open", "--json", "number"], 
        cwd=cwd, timeout=0.3, cache_ttl=30
    )
    if returncode == 0:
        try:
            prs = json.loads(stdout or "[]")
            return len(prs) > 0
        except json.JSONDecodeError:
            pass
    return False


def fast_intent_check(prompt: str = "") -> str:
    """Ultra-fast intent analysis with smart fallbacks."""
    # Environment override (fastest)
    env_intent = os.environ.get("AGENT_OS_INTENT", "").strip().upper()
    if env_intent in {"MAINTENANCE", "NEW", "AMBIGUOUS"}:
        return env_intent
    
    text = prompt or os.environ.get("CLAUDE_USER_PROMPT", "")
    if not text.strip():
        return "AMBIGUOUS"
    
    # Quick heuristic analysis (faster than external script)
    lower_text = text.lower()
    
    # Maintenance keywords
    maintenance_words = ["fix", "bug", "error", "broken", "debug", "repair", "correct"]
    if any(word in lower_text for word in maintenance_words):
        return "MAINTENANCE"
    
    # New work keywords  
    new_words = ["add", "create", "implement", "build", "feature", "new", "start"]
    if any(word in lower_text for word in new_words):
        return "NEW"
    
    # Fallback to external analyzer with timeout
    try:
        returncode, stdout, _ = cached_subprocess([
            os.path.expanduser("~/.agent-os/scripts/intent-analyzer.sh"), "--text", text
        ], timeout=0.2, cache_ttl=60)
        
        if returncode == 0:
            val = (stdout or "").strip().upper()
            if val in {"MAINTENANCE", "NEW", "AMBIGUOUS"}:
                return val
    except Exception:
        pass
    
    return "AMBIGUOUS"


def fast_spec_check(cwd: str) -> bool:
    """Ultra-fast spec detection with filesystem check."""
    # Direct filesystem check (faster than subprocess)
    specs_dir = os.path.join(cwd, ".agent-os", "specs")
    try:
        if os.path.isdir(specs_dir):
            return len(os.listdir(specs_dir)) > 0
    except Exception:
        pass
    return False


def fast_work_session_check() -> bool:
    """Ultra-fast work session detection."""
    if os.environ.get("AGENT_OS_WORK_SESSION", "").lower() == "true":
        return True
    session_file = os.path.expanduser("~/.agent-os/cache/work-session")
    return os.path.exists(session_file)


def check_workflow_issues(cwd: str) -> List[str]:
    """Fast workflow status check with early returns."""
    if fast_work_session_check():
        log_debug("Work session active - skipping hygiene")
        return []
    
    issues = []
    
    # Quick git check
    if fast_git_check(cwd):
        issues.append("Uncommitted changes detected")
    
    # Skip PR check if git check already failed (common case)
    if not issues and fast_pr_check(cwd):
        issues.append("Open pull requests need review/merge")
    
    return issues


# === COMMAND ANALYSIS ===

def is_write_command(command: str) -> bool:
    """Fast write detection with optimized checks."""
    c = command.strip()
    
    # Most common write patterns first
    if c.startswith(("cp ", "mv ", "rm ", "touch ")):
        return True
    
    if c.startswith("echo ") and (">" in c):
        return True
    
    # Package managers and tools
    if c.startswith(("npm ", "yarn ", "pip ", "uv ")):
        return True
    
    # In-place edits
    if "sed -i" in c or "awk -i" in c or ">>" in c:
        return True
    
    return False


def is_readonly_command(command: str) -> bool:
    """Fast readonly detection."""
    c = command.strip()
    readonly_starts = ["ls", "cat ", "head ", "tail ", "grep ", "find ", "ps ", "pwd", "which "]
    return any(c.startswith(p) for p in readonly_starts) and not is_write_command(c)


def is_docs_operation(text: str) -> bool:
    """Fast docs detection."""
    lower = text.lower()
    return any(pattern in lower for pattern in [".md", "docs/", "claude.md", "readme"])


# === HANDLER IMPLEMENTATIONS ===

def handle_pretool(input_data):
    """PreTool handler optimized for speed."""
    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    
    log_debug(f"PreTool: {tool_name}")
    
    if tool_name == "Bash":
        command = tool_input.get("command", "").strip()
        
        # Fast-path: git/gh commands always allowed
        if command.startswith(("git ", "gh ")):
            log_debug("Git command allowed")
            sys.exit(0)
        
        # Fast-path: readonly commands
        if is_readonly_command(command):
            log_debug("Readonly command allowed")
            sys.exit(0)
        
        # Handle write commands
        if is_write_command(command):
            # Docs exception
            if is_docs_operation(command):
                log_debug("Docs write allowed")
                sys.exit(0)
            
            # Intent check with fast fallback
            intent = fast_intent_check()
            if intent == "MAINTENANCE":
                log_debug("Maintenance write allowed")
                sys.exit(0)
            
            # NEW/AMBIGUOUS: check requirements
            root = resolve_workspace_root(input_data)
            
            if not fast_spec_check(root):
                print("No active spec detected (.agent-os/specs). Run /create-spec first.", file=sys.stderr)
                sys.exit(2)
            
            issues = check_workflow_issues(root)
            if issues:
                print("; ".join(issues), file=sys.stderr)
                sys.exit(2)
        
        log_debug("Bash command allowed")
        sys.exit(0)
    
    # Handle other tools
    elif tool_name in ["Write", "Edit", "MultiEdit", "Update", "Task"]:
        # Docs fast-path
        file_path = tool_input.get("file_path", "") or tool_input.get("path", "")
        if file_path and is_docs_operation(file_path):
            log_debug("Docs edit allowed")
            sys.exit(0)
        
        # Intent check
        intent = fast_intent_check(tool_input.get("description", ""))
        if intent == "MAINTENANCE":
            log_debug("Maintenance tool allowed")
            sys.exit(0)
        
        # NEW work: check requirements
        root = resolve_workspace_root(input_data)
        
        if not fast_spec_check(root):
            print("No active spec detected (.agent-os/specs). Run /create-spec first.", file=sys.stderr)
            sys.exit(2)
        
        issues = check_workflow_issues(root)
        if issues:
            print("; ".join(issues), file=sys.stderr)
            sys.exit(2)
    
    log_debug("Tool allowed")
    sys.exit(0)


def handle_pretool_task(input_data):
    """Task handler optimized for speed."""
    tool_input = input_data.get("tool_input", {})
    description = tool_input.get("description", "").lower()
    
    log_debug(f"Task check: {description[:30]}")
    
    # Fast keyword check
    if any(word in description for word in ["review", "validate", "verify", "test", "analyze"]):
        message = ("⚠️ Use specialized subagents for quality assurance:\n"
                  "• senior-software-engineer - For architecture review\n"
                  "• qa-test-engineer - For test validation\n"
                  "• code-analyzer-debugger - For debugging")
        print(message, file=sys.stderr)
        sys.exit(2)
    
    sys.exit(0)


def handle_userprompt(input_data):
    """UserPrompt handler optimized for speed."""
    prompt = input_data.get("prompt", "").lower()
    
    log_debug(f"UserPrompt check: {prompt[:30]}")
    
    # Fast proceed detection
    proceed_words = ["proceed", "continue", "next", "start", "begin"]
    if not any(word in prompt for word in proceed_words):
        sys.exit(0)
    
    # Proceed attempt: check intent and status
    intent = fast_intent_check(prompt)
    if intent == "MAINTENANCE":
        log_debug("Maintenance proceed allowed")
        sys.exit(0)
    
    root = resolve_workspace_root(input_data)
    issues = check_workflow_issues(root)
    if issues:
        message = "⚠️ Cannot proceed: workflow issues detected.\n" + \
                 "\n".join(f"• {issue}" for issue in issues)
        output = {"decision": "block", "hookSpecificOutput": {"additionalContext": message}}
        print(json.dumps(output))
    
    sys.exit(0)


def handle_posttool(input_data):
    """PostTool handler optimized for speed."""
    log_debug("PostTool check")
    
    # Skip expensive doc checks in most cases
    tool_name = input_data.get("tool_name", "")
    if tool_name not in ["Write", "Edit", "MultiEdit"]:
        sys.exit(0)
    
    # Quick doc status check with timeout
    try:
        root = resolve_workspace_root(input_data)
        returncode, _, _ = cached_subprocess([
            os.path.expanduser("~/.agent-os/scripts/update-documentation.sh"),
            "--dry-run"
        ], cwd=root, timeout=0.3, cache_ttl=10)
        
        if returncode == 2:
            message = ("⚠️ Documentation updates may be required.\n"
                      "Consider running /update-documentation --dry-run")
            print(message, file=sys.stderr)
            # Don't block - just warn
    except Exception:
        pass
    
    sys.exit(0)


# === MAIN DISPATCHER ===

def main():
    """High-performance main dispatcher."""
    if len(sys.argv) < 2:
        sys.exit(1)
    
    hook_type = sys.argv[1]
    
    # Fast JSON parsing
    try:
        input_data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    
    log_debug(f"Dispatch: {hook_type}")
    
    # Direct dispatch for maximum speed
    if hook_type == "pretool":
        handle_pretool(input_data)
    elif hook_type == "pretool-task":
        handle_pretool_task(input_data)
    elif hook_type == "userprompt":
        handle_userprompt(input_data)
    elif hook_type == "posttool":
        handle_posttool(input_data)
    else:
        log_debug(f"Unknown hook: {hook_type}")
        sys.exit(1)


if __name__ == "__main__":
    main()
