#!/usr/bin/env python3
"""
Agent OS Workflow Enforcement Hook v2.0 - Performance Optimized
===============================================================
High-performance modular dispatcher for Agent OS workflow enforcement.
Optimized for P95 < 500ms latency with caching and async patterns.

Usage: python3 workflow-enforcement-hook-v2.py [hook-type]
Hook types: pretool, pretool-task, userprompt, posttool
"""

import json
import sys
import os

# Add modules directory to path
modules_dir = os.path.join(os.path.dirname(__file__), 'modules')
sys.path.insert(0, modules_dir)

# Import individual modules directly
try:
    import hook_core_optimized as core
    
    # Import handler classes
    from pretool_handler import PreToolHandler
    from posttool_handler import PostToolHandler
    from userprompt_handler import UserPromptHandler  
    from task_handler import TaskHandler
    
    # Replace the core module with optimized version
    sys.modules['hook_core'] = core
    
except ImportError as e:
    print(f"Import error: {e}", file=sys.stderr)
    sys.exit(1)


class OptimizedHookDispatcher:
    """High-performance dispatcher with minimal overhead."""
    
    @staticmethod
    def dispatch(hook_type: str, input_data: dict) -> None:
        """Fast dispatch to appropriate handler."""
        try:
            if hook_type == "pretool":
                handler = PreToolHandler(input_data)
            elif hook_type == "pretool-task":
                handler = TaskHandler(input_data)
            elif hook_type == "userprompt":
                handler = UserPromptHandler(input_data)
            elif hook_type == "posttool":
                handler = PostToolHandler(input_data)
            else:
                core.HookLogger.debug(f"Unknown hook type: {hook_type}")
                sys.exit(1)
            
            handler.handle()
            
        except core.HookError as e:
            core.HookLogger.debug(f"Hook error: {e}")
            print(str(e), file=sys.stderr)
            sys.exit(2)
        except SystemExit:
            raise  # Allow explicit exits from handlers
        except Exception as e:
            core.HookLogger.debug(f"Unexpected error in {hook_type}: {e}")
            # Don't block on unexpected errors to maintain stability
            sys.exit(0)


def main():
    """Optimized main entry point."""
    # Fast argument validation
    if len(sys.argv) < 2:
        sys.exit(1)
    
    hook_type = sys.argv[1]
    
    # Fast input parsing
    try:
        input_data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)  # Don't block on parse errors
    
    # Minimal logging
    core.HookLogger.debug(f"Hook {hook_type} dispatch")
    
    # Fast dispatch
    OptimizedHookDispatcher.dispatch(hook_type, input_data)


if __name__ == "__main__":
    main()
