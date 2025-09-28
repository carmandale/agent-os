"""
Agent OS Hook Modules
Modular hook architecture for Agent OS workflow enforcement.
Each module handles a specific hook type with single responsibility.
"""

from .hook_core_optimized import (
    BaseHookHandler,
    HookError,
    HookLogger,
    WorkspaceResolver,
    GitChecker,
    IntentAnalyzer,
    SpecChecker
)

from .pretool_handler_optimized import PreToolHandler
from .posttool_handler_optimized import PostToolHandler
from .userprompt_handler_optimized import UserPromptHandler
from .task_handler_optimized import TaskHandler

__all__ = [
    'BaseHookHandler',
    'HookError', 
    'HookLogger',
    'WorkspaceResolver',
    'GitChecker',
    'IntentAnalyzer',
    'SpecChecker',
    'PreToolHandler',
    'PostToolHandler', 
    'UserPromptHandler',
    'TaskHandler'
]
