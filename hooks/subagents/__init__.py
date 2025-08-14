"""
Agent OS Subagents Module.

This module provides specialized subagents for optimized task execution:
- context_fetcher: Codebase analysis and searching
- date_checker: Accurate date determination
- file_creator: Template-based file generation
- git_workflow: Complete git operations
- test_runner: Test execution and reporting
"""

from .context_fetcher import ContextFetcherAgent
from .date_checker import DateCheckerAgent
from .file_creator import FileCreatorAgent
from .git_workflow import GitWorkflowAgent
from .test_runner import TestRunnerAgent

__all__ = [
    'ContextFetcherAgent',
    'DateCheckerAgent',
    'FileCreatorAgent',
    'GitWorkflowAgent',
    'TestRunnerAgent',
]

# Version info
__version__ = '1.0.0'