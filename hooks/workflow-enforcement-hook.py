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

# Add parent directory to path to import project root resolver
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
try:
    from scripts.project_root_resolver import ProjectRootResolver
except ImportError:
    # Fallback if resolver not available
    ProjectRootResolver = None


# Patterns that indicate user wants to proceed
PROCEED_PATTERNS = [
    r"\b(proceed|continue|next|what'?s next|task \d+|move on|start|begin)\b",
    r"ready for .*task",
    r"let'?s (do|start|work on)",
]

# Tools that indicate starting new work
NEW_WORK_TOOLS = ["Write", "Edit", "MultiEdit", "Update", "Task"]


def log_debug(message):
    """Write debug logs if debugging enabled."""
    if os.environ.get("AGENT_OS_DEBUG", "").lower() == "true":
        log_path = os.path.expanduser("~/.agent-os/logs/hooks-debug.log")
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "a") as f:
            f.write(f"[{datetime.now().isoformat()}] {message}\n")


def resolve_workspace_root(input_data: dict | None = None) -> str:
    """Best-effort resolution of the target project directory for checks."""
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
            
            # Resolve using the new standardized resolver
            return resolver.resolve(file_path=file_path, hook_payload=input_data)
        except Exception as e:
            log_debug(f"ProjectRootResolver failed: {e}, falling back to legacy resolution")
    
    # Legacy fallback if ProjectRootResolver not available
    try:
        if input_data:
            # Common fields that may be present
            for key in ["cwd", "workspaceDir", "workspace", "projectRoot", "rootDir"]:
                val = input_data.get(key)
                if isinstance(val, str) and val.strip():
                    return val
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
        log_debug(f"resolve_workspace_root payload parse failed: {e}")
    # Fallback to environment hint
    env_dir = os.environ.get("CLAUDE_PROJECT_DIR", "").strip()
    if env_dir:
        return env_dir
    # Last resort: current working directory
    return os.getcwd()


def check_git_status(cwd: str) -> bool:
    """Check if there are uncommitted changes in given workspace."""
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
        log_debug(f"Git status check failed: {e}")
        return False


def check_open_prs(cwd: str) -> bool:
    """Check for open PRs in the given repo."""
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
        log_debug(f"PR check failed: {e}")
        return False


def check_workflow_status(cwd: str) -> list[str]:
    """Analyze workflow status and return issues for given workspace."""
    issues = []
    
    # In work session mode, skip uncommitted changes check to allow batching
    work_session_active = os.environ.get("AGENT_OS_WORK_SESSION", "").lower() == "true"
    session_file = os.path.expanduser("~/.agent-os/cache/work-session")
    session_exists = os.path.exists(session_file)
    
    if work_session_active or session_exists:
        log_debug("Work session mode active - allowing uncommitted changes")
    else:
        # Check for uncommitted changes only when not in work session
        if check_git_status(cwd):
            issues.append("Uncommitted changes detected")
    
    # Check for open PRs
    if check_open_prs(cwd):
        issues.append("Open pull requests need review/merge")
    
    return issues


def get_user_intent(prompt_text: str = "") -> str:
    """Return MAINTENANCE | NEW | AMBIGUOUS using intent analyzer, with env fallback."""
    # Env override
    env_intent = os.environ.get("AGENT_OS_INTENT", "").strip().upper()
    if env_intent in {"MAINTENANCE", "NEW", "AMBIGUOUS"}:
        return env_intent
    # Use prompt if provided
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
        log_debug(f"Intent analyzer failed: {e}")
        return "AMBIGUOUS"


def is_write_bash(command: str) -> bool:
    """Heuristic to detect write-capable bash commands."""
    c = command
    # Obvious write commands
    write_prefixes = ["cp ", "mv ", "rm ", "touch ", "chmod ", "chown ", "tee ", "patch ", "git apply ",
                      "npm ", "yarn ", "pnpm ", "pip ", "uv ", "docker ", "echo "]
    if any(c.startswith(p) for p in write_prefixes):
        return True
    # Redirections / in-place edits
    if ">>" in c or ">" in c or "sed -i" in c or "awk -i" in c:
        return True
    return False


def is_docs_only_command(command: str) -> bool:
    """Rough detection if a bash write targets docs/markdown only."""
    lowered = command.lower()
    return (".md" in lowered or ".mdc" in lowered or "docs/" in lowered or "claude.md" in lowered)


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
        log_debug(f"Spec detection failed: {e}")
        return False


def handle_pretool(input_data):
    """Handle PreToolUse hook - block new work until workflow complete."""
    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    
    log_debug(f"PreToolUse hook called for tool: {tool_name}")
    
    # Special handling for Bash commands
    if tool_name == "Bash":
        command = tool_input.get("command", "").strip()
        root = resolve_workspace_root(input_data)

        # PR creation/merge guard: require docs up-to-date before PR ops
        import re as _re
        if _re.match(r"\s*(gh\s+pr\s+(create|merge)\b)", command):
            try:
                r = __import__("subprocess").run([
                    os.path.expanduser("~/.agent-os/scripts/update-documentation.sh"),
                    "--deep","--dry-run"
                ], capture_output=True, text=True, timeout=30, cwd=root)
                if r.returncode == 2:
                    print("Documentation updates required before PR. Run /update-documentation --deep --dry-run and include updates in PR.", file=sys.stderr)
                    sys.exit(2)
            except Exception as e:
                print(f"Docs check failed: {e}", file=sys.stderr)
                sys.exit(2)

        # Always allow git/gh operations (to resolve hygiene)
        if command.startswith("git ") or command.startswith("gh "):
            log_debug(f"Allowing git/gh command: {command}")
            sys.exit(0)

        # Read-only allowlist (keep minimal to avoid write bypass)
        readonly_prefixes = [
            "cd ", "ls ", "ls", "cat ", "head ", "tail ", "grep ", "rg ", "find ",
            "ps ", "netstat", "lsof ", "echo ", "env", "which ", "pwd",
            "wc ", "sort ", "uniq ", "awk ", "sed "
        ]
        # If clearly read-only, allow
        if any(command.startswith(p) for p in readonly_prefixes) and not is_write_bash(command):
            log_debug(f"Allowing read-only command: {command}")
            sys.exit(0)

        # Classify write and gate based on intent and hygiene
        is_write = is_write_bash(command)
        intent = get_user_intent()
        # Docs-only exception: allow writes to docs/markdown files
        if is_write and is_docs_only_command(command):
            log_debug(f"Allowing docs-only write: {command}")
            sys.exit(0)

        # For maintenance intent, allow writes (to fix), else enforce hygiene/spec
        if is_write:
            if intent == "MAINTENANCE":
                log_debug(f"Allowing maintenance write: {command}")
                sys.exit(0)
            # NEW or AMBIGUOUS => enforce hygiene
            issues = check_workflow_status(root)
            if not has_active_spec(root):
                reason = "No active spec detected (.agent-os/specs). Run /create-spec first."
                print(reason, file=sys.stderr)
                sys.exit(2)
            if issues:
                reason = "; ".join(issues)
                print(reason, file=sys.stderr)
                sys.exit(2)
            sys.exit(0)
        
        # Default: unknown read action; allow if not detected as write
        sys.exit(0)
    
    # Only check for tools that indicate new work
    elif tool_name not in NEW_WORK_TOOLS:
        sys.exit(0)
    
    # Check workflow status for other tools
    else:
        root = resolve_workspace_root(input_data)
        intent = get_user_intent(tool_input.get("description", ""))
        
        # Docs-only exception for Write/Edit/MultiEdit: allow if editing docs
        file_path = tool_input.get("file_path", "") or tool_input.get("path", "")
        if file_path:
            lower = file_path.lower()
            if lower.endswith(".md") or lower.endswith(".mdc") or lower.startswith("docs/") or os.path.basename(lower) == "claude.md":
                sys.exit(0)

        if intent == "MAINTENANCE":
            sys.exit(0)

        issues = check_workflow_status(root)
        if not has_active_spec(root):
            reason = "No active spec detected (.agent-os/specs). Run /create-spec first."
            print(reason, file=sys.stderr)
            sys.exit(2)
        if issues:
            reason = "; ".join(issues)
            print(reason, file=sys.stderr)
            sys.exit(2)
        sys.exit(0)
    
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

    # Proceed attempts are blocked if hygiene issues exist (unless maintenance intent)
    root = resolve_workspace_root(input_data)
    intent = get_user_intent(prompt)
    if intent == "MAINTENANCE":
        sys.exit(0)

    issues = check_workflow_status(root)
    if issues:
        message = "⚠️ Cannot proceed: workflow issues detected.\n\n" + "\n".join(f"• {i}" for i in issues)
        # For userprompt, return structured JSON to block explicitly
        output = {
            "decision": "block",
            "hookSpecificOutput": {"additionalContext": message}
        }
        print(json.dumps(output))
        sys.exit(0)
    sys.exit(0)


def handle_posttool(input_data):
    """Handle PostToolUse - auto-commit Agent OS documentation changes."""
    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})
    
    log_debug(f"PostToolUse called for tool: {tool_name}")
    
    # If PR-completion flows detected, ensure docs are current
    try:
        # Run updater in dry-run to detect pending docs (exit 2 means proposals exist)
        root = resolve_workspace_root(input_data)
        result = subprocess.run([
            os.path.expanduser("~/.agent-os/scripts/update-documentation.sh"),
            "--dry-run",
            "--deep"
        ], capture_output=True, text=True, timeout=30, cwd=root)
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