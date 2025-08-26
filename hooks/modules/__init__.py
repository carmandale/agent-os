"""
Agent OS Hook Modules
====================
Modular hook architecture for Agent OS workflow enforcement.
Each module handles a specific hook type with single responsibility.
"""

from .hook_core import (
    BaseHookHandler,
    HookError,
    HookLogger,
    WorkspaceResolver,
    GitChecker,
    IntentAnalyzer,
    SpecChecker
)

from .pretool_handler import PreToolHandler
from .posttool_handler import PostToolHandler
from .userprompt_handler import UserPromptHandler
from .task_handler import TaskHandler

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
