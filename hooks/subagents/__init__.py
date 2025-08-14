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

__all__ = [
    'ContextFetcherAgent',
]

# Version info
__version__ = '1.0.0'