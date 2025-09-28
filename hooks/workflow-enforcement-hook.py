#!/usr/bin/env python3
"""
Agent OS Workflow Enforcement Hook - Thin Dispatcher
Delegates hook handling to optimized module handlers.
Usage:
  python3 workflow-enforcement-hook.py [pretool|pretool-task|userprompt|posttool]
Reads JSON payload from stdin.
"""

import json
import os
import sys

# Ensure modules package path is available when installed to ~/.agent-os/hooks
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
if CURRENT_DIR not in sys.path:
    sys.path.insert(0, CURRENT_DIR)

try:
    from modules import PreToolHandler, TaskHandler, UserPromptHandler, PostToolHandler  # type: ignore
except Exception as e:
    # Fail open to avoid blocking developer flows if hooks aren't fully installed yet
    print(f"Agent OS hook import error: {e}", file=sys.stderr)
    sys.exit(0)

HANDLERS = {
    "pretool": PreToolHandler,
    "pretool-task": TaskHandler,
    "userprompt": UserPromptHandler,
    "posttool": PostToolHandler
}

def main():
    if len(sys.argv) < 2:
        # Unknown invocation; do not block developer flows
        sys.exit(0)

    hook_type = sys.argv[1]

    # Parse JSON from stdin; fail open on parsing issues
    try:
        input_data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    Handler = HANDLERS.get(hook_type)
    if Handler is None:
        # Unknown hook type; do not block
        sys.exit(0)

    try:
        Handler(input_data).handle()
    except SystemExit as e:
        # Preserve explicit exit codes from handlers
        raise e
    except Exception as e:
        # Fail open on unexpected runtime errors to avoid blocking development
        print(f"Agent OS hook runtime error: {e}", file=sys.stderr)
        sys.exit(0)

if __name__ == "__main__":
    main()
