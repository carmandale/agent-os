#!/usr/bin/env python3
"""
Agent OS Workflow Enforcement Hook - Modular Architecture
=========================================================
Lightweight dispatcher for Agent OS workflow enforcement in Claude Code.
Routes hook calls to specialized handler modules for improved performance and maintainability.

Usage: python3 workflow-enforcement-hook-modular.py [hook-type]
Hook types: pretool, pretool-task, userprompt, posttool
"""

import json
import sys
import os
from typing import Dict, Any, Optional

# Add modules directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'modules'))

try:
    from modules import (
        PreToolHandler,
        PostToolHandler, 
        UserPromptHandler,
        TaskHandler,
        HookLogger,
        HookError
    )
except ImportError as e:
    print(f"Failed to import hook modules: {e}", file=sys.stderr)
    sys.exit(1)


class HookDispatcher:
    """Lightweight dispatcher that routes hooks to appropriate handlers."""
    
    def __init__(self):
        self.handlers = {
            "pretool": self._handle_pretool,
            "pretool-task": self._handle_pretool_task, 
            "userprompt": self._handle_userprompt,
            "posttool": self._handle_posttool
        }
    
    def dispatch(self, hook_type: str, input_data: Dict[str, Any]) -> None:
        """Dispatch hook to appropriate handler."""
        HookLogger.debug(f"Dispatching hook: {hook_type}")
        
        handler = self.handlers.get(hook_type)
        if not handler:
            HookLogger.debug(f"Unknown hook type: {hook_type}")
            sys.exit(1)
        
        try:
            handler(input_data)
        except HookError as e:
            HookLogger.debug(f"Hook error: {e}")
            print(str(e), file=sys.stderr)
            sys.exit(2)
        except Exception as e:
            HookLogger.debug(f"Unexpected error in {hook_type}: {e}")
            # Don't block on unexpected errors to maintain stability
            sys.exit(0)
    
    def _handle_pretool(self, input_data: Dict[str, Any]) -> None:
        """Handle PreToolUse hook."""
        handler = PreToolHandler(input_data)
        handler.handle()
    
    def _handle_pretool_task(self, input_data: Dict[str, Any]) -> None:
        """Handle Task-specific PreToolUse hook."""
        handler = TaskHandler(input_data)
        handler.handle()
    
    def _handle_userprompt(self, input_data: Dict[str, Any]) -> None:
        """Handle UserPromptSubmit hook."""
        handler = UserPromptHandler(input_data)
        handler.handle()
    
    def _handle_posttool(self, input_data: Dict[str, Any]) -> None:
        """Handle PostToolUse hook."""
        handler = PostToolHandler(input_data)
        handler.handle()


def parse_input() -> Optional[Dict[str, Any]]:
    """Parse JSON input from stdin with error handling."""
    try:
        return json.load(sys.stdin)
    except json.JSONDecodeError as e:
        HookLogger.debug(f"Failed to parse JSON input: {e}")
        # Don't block on parse errors
        return None
    except Exception as e:
        HookLogger.debug(f"Unexpected input parsing error: {e}")
        return None


def main():
    """Main entry point - lightweight dispatcher."""
    if len(sys.argv) < 2:
        print("Error: Hook type not specified", file=sys.stderr)
        sys.exit(1)
    
    hook_type = sys.argv[1]
    
    # Parse input data
    input_data = parse_input()
    if input_data is None:
        # Don't block on input parsing failures
        sys.exit(0)
    
    # Log the hook call
    HookLogger.debug(f"Hook {hook_type} called with data keys: {list(input_data.keys())}")
    
    # Dispatch to appropriate handler
    dispatcher = HookDispatcher()
    dispatcher.dispatch(hook_type, input_data)


if __name__ == "__main__":
    main()
