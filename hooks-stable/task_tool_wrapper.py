#!/usr/bin/env python3
"""
Task Tool Wrapper for Subagent Integration.

This module wraps the Claude Code Task tool to automatically detect and launch
appropriate subagents while maintaining backward compatibility.
"""

import os
import sys
import json
import logging
from typing import Dict, Any, Optional
from dataclasses import dataclass

# Add hooks directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from subagent_detector import SubagentDetector
from subagents import (
    ContextFetcherAgent,
    DateCheckerAgent,
    FileCreatorAgent,
    GitWorkflowAgent,
    TestRunnerAgent
)

# Configure logging for debug without visibility
logging.basicConfig(
    level=logging.DEBUG,
    filename='/tmp/agent-os-task-wrapper.log',
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@dataclass
class TaskContext:
    """Enhanced task context for subagent execution."""
    description: str
    prompt: str
    subagent_type: Optional[str] = None
    raw_params: Dict[str, Any] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for processing."""
        return {
            'description': self.description,
            'prompt': self.prompt,
            'message': self.prompt,  # Support both formats
            'subagent_type': self.subagent_type
        }


class TaskToolWrapper:
    """
    Wrapper for Claude Code Task tool with automatic subagent integration.
    
    This class provides:
    - Automatic subagent detection based on context
    - Transparent execution with no interface changes
    - Graceful fallback to general-purpose agent
    - Performance optimization through specialized routing
    """
    
    def __init__(self):
        """Initialize the Task tool wrapper."""
        self.detector = SubagentDetector()
        self.agents = self._initialize_agents()
        logger.info("TaskToolWrapper initialized with subagent support")
    
    def _initialize_agents(self) -> Dict[str, Any]:
        """Initialize available subagents."""
        return {
            'context-fetcher': ContextFetcherAgent(),
            'date-checker': DateCheckerAgent(),
            'file-creator': FileCreatorAgent(),
            'git-workflow': GitWorkflowAgent(),
            'test-runner': TestRunnerAgent()
        }
    
    def execute(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a task with automatic subagent selection.
        
        Args:
            params: Task parameters from Claude Code
            
        Returns:
            Task execution results
        """
        try:
            # Parse task context
            context = self._parse_context(params)
            logger.debug(f"Parsed context: {context.to_dict()}")
            
            # Check for explicit subagent type (backward compatibility)
            if context.subagent_type:
                logger.info(f"Using explicitly specified agent: {context.subagent_type}")
                return self._execute_with_agent(context.subagent_type, context)
            
            # Automatic detection
            detection_result = self.detector.detect(context.to_dict())
            agent_type = detection_result['agent']
            confidence = detection_result.get('confidence', 0)
            
            logger.info(f"Detected agent: {agent_type} (confidence: {confidence:.2f})")
            
            # Execute with detected agent
            return self._execute_with_agent(agent_type, context)
            
        except Exception as e:
            logger.error(f"Task execution failed: {e}")
            return self._fallback_execution(params, str(e))
    
    def _parse_context(self, params: Dict[str, Any]) -> TaskContext:
        """Parse parameters into TaskContext."""
        return TaskContext(
            description=params.get('description', ''),
            prompt=params.get('prompt', ''),
            subagent_type=params.get('subagent_type'),
            raw_params=params
        )
    
    def _execute_with_agent(self, agent_type: str, 
                          context: TaskContext) -> Dict[str, Any]:
        """Execute task with specified agent."""
        # Use specialized agent if available
        if agent_type in self.agents:
            logger.debug(f"Executing with specialized agent: {agent_type}")
            
            # Prepare agent-specific context
            agent_context = self._prepare_agent_context(agent_type, context)
            
            # Execute with specialized agent
            agent = self.agents[agent_type]
            result = agent.execute(agent_context)
            
            # Enhance result with metadata
            result['_agent_used'] = agent_type
            result['_optimized'] = True
            
            logger.info(f"Specialized execution completed: {agent_type}")
            return result
        
        # Fallback to general-purpose
        logger.debug(f"Using general-purpose agent for: {agent_type}")
        return self._execute_general_purpose(context)
    
    def _prepare_agent_context(self, agent_type: str, 
                              context: TaskContext) -> Dict[str, Any]:
        """Prepare context for specific agent type."""
        base_context = {
            'prompt': context.prompt,
            'description': context.description
        }
        
        # Add agent-specific parameters
        if agent_type == 'context-fetcher':
            base_context.update({
                'operation': self._detect_search_operation(context.prompt),
                'query': self._extract_search_query(context.prompt),
                'path': '.'
            })
        elif agent_type == 'date-checker':
            base_context.update({
                'operation': 'current',
                'format': 'spec'
            })
        elif agent_type == 'file-creator':
            base_context.update({
                'operation': 'create',
                'path': self._extract_file_path(context.prompt),
                'template': None
            })
        elif agent_type == 'git-workflow':
            base_context.update({
                'operation': self._detect_git_operation(context.prompt),
                'type': 'feat'
            })
        elif agent_type == 'test-runner':
            base_context.update({
                'operation': 'run',
                'coverage': 'coverage' in context.prompt.lower()
            })
        
        return base_context
    
    def _detect_search_operation(self, prompt: str) -> str:
        """Detect the type of search operation."""
        prompt_lower = prompt.lower()
        if 'grep' in prompt_lower:
            return 'grep'
        elif 'find' in prompt_lower and 'file' in prompt_lower:
            return 'find'
        elif 'analyze' in prompt_lower:
            return 'analyze'
        return 'search'
    
    def _extract_search_query(self, prompt: str) -> str:
        """Extract search query from prompt."""
        # Simple extraction - look for quoted strings or key terms
        import re
        
        # Look for quoted strings
        quoted = re.findall(r'"([^"]*)"', prompt)
        if quoted:
            return quoted[0]
        
        # Look for common patterns
        patterns = [
            r'(?:search|find|look) for ([\w\s]+)',
            r'(?:containing|with) ([\w\s]+)',
            r'all ([\w\s]+) (?:comments|files|functions)'
        ]
        
        for pattern in patterns:
            match = re.search(pattern, prompt.lower())
            if match:
                return match.group(1).strip()
        
        # Fallback to key terms
        if 'TODO' in prompt:
            return 'TODO'
        if 'import' in prompt:
            return 'import'
        
        return prompt[:50]
    
    def _extract_file_path(self, prompt: str) -> str:
        """Extract file path from prompt."""
        import re
        
        # Look for file extensions
        patterns = [
            r'(\w+\.(?:md|py|js|ts|txt|json|yaml|yml))',
            r'(?:create|new|generate)\s+(\w+)',
            r'(?:file|component|module)\s+(?:named|called)?\s*(\w+)'
        ]
        
        for pattern in patterns:
            match = re.search(pattern, prompt.lower())
            if match:
                return match.group(1)
        
        return 'output.txt'
    
    def _detect_git_operation(self, prompt: str) -> str:
        """Detect git operation type."""
        prompt_lower = prompt.lower()
        
        operations = {
            'commit': ['commit', 'save changes'],
            'push': ['push'],
            'pull': ['pull', 'update'],
            'branch': ['branch', 'create branch'],
            'pr': ['pr', 'pull request'],
            'status': ['status', 'check git'],
            'stash': ['stash'],
            'log': ['log', 'history']
        }
        
        for op, keywords in operations.items():
            if any(kw in prompt_lower for kw in keywords):
                return op
        
        return 'status'
    
    def _execute_general_purpose(self, context: TaskContext) -> Dict[str, Any]:
        """Execute with general-purpose agent."""
        # This would call the original Task tool
        # For now, return a mock response
        return {
            'success': True,
            '_agent_used': 'general-purpose',
            '_optimized': False,
            'result': f"Executed general task: {context.description}"
        }
    
    def _fallback_execution(self, params: Dict[str, Any], 
                          error: str) -> Dict[str, Any]:
        """Fallback execution on error."""
        logger.warning(f"Falling back to general-purpose due to: {error}")
        
        return {
            'success': False,
            '_agent_used': 'general-purpose',
            '_optimized': False,
            '_fallback': True,
            'error': error,
            'result': 'Task execution failed, using fallback'
        }
    
    def get_status(self) -> Dict[str, Any]:
        """Get wrapper status and statistics."""
        return {
            'enabled': True,
            'detector_ready': self.detector is not None,
            'agents_loaded': list(self.agents.keys()),
            'version': '1.0.0'
        }


# Entry point for Claude Code Task tool integration
def handle_task(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Main entry point for Task tool requests.
    
    This function is called by Claude Code when the Task tool is invoked.
    It provides transparent subagent integration while maintaining
    backward compatibility.
    """
    wrapper = TaskToolWrapper()
    return wrapper.execute(params)


if __name__ == '__main__':
    # Test the wrapper
    test_tasks = [
        {'description': 'Search for TODOs', 'prompt': 'Find all TODO comments'},
        {'description': 'Get date', 'prompt': "What's today's date?"},
        {'description': 'Create file', 'prompt': 'Create README.md'},
        {'description': 'Git work', 'prompt': 'Commit changes'},
        {'description': 'Run tests', 'prompt': 'Run test suite with coverage'}
    ]
    
    wrapper = TaskToolWrapper()
    for task in test_tasks:
        result = wrapper.execute(task)
        print(f"\nTask: {task['description']}")
        print(f"Agent used: {result.get('_agent_used')}")
        print(f"Optimized: {result.get('_optimized')}")