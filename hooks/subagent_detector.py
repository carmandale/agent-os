#!/usr/bin/env python3
"""
SubagentDetector - Automatic agent selection for Agent OS.

This module provides intelligent detection and selection of specialized subagents
based on context analysis. It enables automatic performance optimization through
specialized agent routing without user configuration.
"""

import re
import time
import logging
from typing import Dict, Any, List, Optional, Tuple
from dataclasses import dataclass

# Configure logging
logging.basicConfig(level=logging.WARNING)
logger = logging.getLogger(__name__)


@dataclass
class DetectionResult:
    """Result of subagent detection."""
    agent: str
    reason: str
    confidence: float
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for Task tool integration."""
        return {
            'agent': self.agent,
            'reason': self.reason,
            'confidence': self.confidence
        }


class SubagentDetector:
    """
    Automatically detects and selects the optimal subagent for a given context.
    
    This class provides zero-configuration agent selection that improves
    performance and accuracy without user intervention.
    """
    
    # Agent capability definitions
    AGENT_CAPABILITIES = {
        'context-fetcher': {
            'description': 'Specialized for codebase analysis and searching across multiple files',
            'triggers': [
                'search', 'find', 'locate', 'grep', 'analyze codebase',
                'look for', 'scan', 'explore', 'review code', 'examine'
            ],
            'patterns': [
                r'search.*(?:for|through|in)',
                r'find.*(?:all|every|instances|occurrences)',
                r'(?:analyze|examine|review).*(?:code|codebase|files)',
                r'look.*(?:for|through).*files?'
            ]
        },
        'date-checker': {
            'description': 'Accurate date determination and time-based operations',
            'triggers': [
                'date', 'today', 'current date', 'now', 'time',
                'yesterday', 'tomorrow', 'week', 'month', 'year'
            ],
            'patterns': [
                r"(?:what'?s?|get|current|today'?s?).*date",
                r'(?:create|make|new).*(?:with|using).*date',
                r'(?:folder|file|directory).*date'
            ]
        },
        'file-creator': {
            'description': 'Template-based file generation and scaffolding',
            'triggers': [
                'create file', 'new file', 'generate', 'scaffold',
                'template', 'boilerplate', 'component', 'module'
            ],
            'patterns': [
                r'(?:create|make|new|generate).*(?:file|component|module|class)',
                r'(?:scaffold|template|boilerplate)',
                r'(?:add|write).*(?:new|fresh).*(?:file|component)'
            ]
        },
        'git-workflow': {
            'description': 'Complete git operations and GitHub integration',
            'triggers': [
                'git', 'commit', 'push', 'pull', 'merge', 'branch',
                'pr', 'pull request', 'github', 'repository', 'clone'
            ],
            'patterns': [
                r'git\s+\w+',
                r'(?:create|make|open).*(?:pr|pull request)',
                r'(?:commit|push|pull|merge|branch)',
                r'(?:github|repository|repo)'
            ]
        },
        'test-runner': {
            'description': 'Test execution, validation, and coverage reporting',
            'triggers': [
                'test', 'tests', 'testing', 'pytest', 'unittest',
                'coverage', 'run tests', 'validate', 'verify'
            ],
            'patterns': [
                r'(?:run|execute|perform).*test',
                r'test.*(?:pass|fail|coverage)',
                r'(?:verify|validate|check).*(?:work|implementation|code)',
                r'(?:pytest|unittest|jest|mocha)'
            ]
        },
        'general-purpose': {
            'description': 'General AI assistance for varied tasks',
            'triggers': [],
            'patterns': []
        }
    }
    
    def __init__(self):
        """Initialize the SubagentDetector."""
        self._compile_patterns()
        logger.info("SubagentDetector initialized with %d agents", 
                   len(self.AGENT_CAPABILITIES))
    
    def _compile_patterns(self):
        """Pre-compile regex patterns for performance."""
        self._compiled_patterns = {}
        for agent, capabilities in self.AGENT_CAPABILITIES.items():
            self._compiled_patterns[agent] = [
                re.compile(pattern, re.IGNORECASE)
                for pattern in capabilities.get('patterns', [])
            ]
    
    def detect(self, context: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        """
        Detect the optimal subagent for the given context.
        
        Args:
            context: Dictionary containing prompt and operation details
            
        Returns:
            Dictionary with agent selection, reason, and confidence
        """
        # Handle error cases gracefully
        if context is None:
            return DetectionResult(
                agent='general-purpose',
                reason='No context provided, using general-purpose agent',
                confidence=0.3
            ).to_dict()
        
        if not isinstance(context, dict):
            return {
                'agent': 'general-purpose',
                'reason': 'Invalid context format, using general-purpose agent',
                'confidence': 0.3,
                'warning': 'Context should be a dictionary'
            }
        
        if not context:
            return DetectionResult(
                agent='general-purpose',
                reason='Empty context, using general-purpose agent',
                confidence=0.3
            ).to_dict()
        
        # Analyze context for agent selection
        scores = self._calculate_agent_scores(context)
        
        # Select agent with highest score
        best_agent, best_score = max(scores.items(), key=lambda x: x[1])
        
        # Generate reason based on detection
        reason = self._generate_reason(best_agent, context)
        
        # Calculate confidence based on score differential
        confidence = self._calculate_confidence(scores, best_score)
        
        return DetectionResult(
            agent=best_agent,
            reason=reason,
            confidence=confidence
        ).to_dict()
    
    def _calculate_agent_scores(self, context: Dict[str, Any]) -> Dict[str, float]:
        """Calculate scores for each agent based on context."""
        scores = {}
        
        # Extract relevant text from context
        prompt = str(context.get('prompt', '')).lower()
        operation = str(context.get('operation', '')).lower()
        combined_text = f"{prompt} {operation}"
        
        for agent, capabilities in self.AGENT_CAPABILITIES.items():
            score = 0.0
            
            # Check for explicit operation match
            if operation:
                if agent == 'git-workflow' and 'git' in operation:
                    score += 5.0
                elif agent == 'test-runner' and 'test' in operation:
                    score += 5.0
                elif agent == 'file-creator' and 'file_creation' in operation:
                    score += 5.0
                elif agent == 'date-checker' and 'date' in operation:
                    score += 5.0
                elif agent == 'context-fetcher' and 'search' in operation:
                    score += 5.0
            
            # Check for context flags
            if context.get('involves_git') and agent == 'git-workflow':
                score += 3.0
            if context.get('involves_testing') and agent == 'test-runner':
                score += 3.0
            if context.get('requires_current_date') and agent == 'date-checker':
                score += 3.0
            if context.get('involves_multiple_files') and agent == 'context-fetcher':
                score += 3.0
            if context.get('requires_template') and agent == 'file-creator':
                score += 3.0
            
            # Check trigger words
            for trigger in capabilities.get('triggers', []):
                if trigger in combined_text:
                    score += 2.0
            
            # Check regex patterns
            for pattern in self._compiled_patterns.get(agent, []):
                if pattern.search(combined_text):
                    score += 2.5
            
            scores[agent] = score
        
        # Ensure general-purpose has a baseline score
        if scores.get('general-purpose', 0) == 0:
            scores['general-purpose'] = 0.5
        
        return scores
    
    def _generate_reason(self, agent: str, context: Dict[str, Any]) -> str:
        """Generate a reason for the agent selection."""
        prompt = str(context.get('prompt', ''))[:50]
        
        reasons = {
            'context-fetcher': f'Detected codebase search/analysis task',
            'date-checker': f'Detected date/time requirement',
            'file-creator': f'Detected file creation with template needs',
            'git-workflow': f'Detected git/GitHub operations',
            'test-runner': f'Detected test execution requirement',
            'general-purpose': f'Using general-purpose agent for broad task'
        }
        
        base_reason = reasons.get(agent, 'Selected based on context analysis')
        
        # Add context snippet if available
        if prompt:
            return f"{base_reason}: '{prompt}...'"
        return base_reason
    
    def _calculate_confidence(self, scores: Dict[str, float], 
                            best_score: float) -> float:
        """Calculate confidence based on score distribution."""
        if best_score == 0:
            return 0.3
        
        # Get second-best score
        sorted_scores = sorted(scores.values(), reverse=True)
        if len(sorted_scores) > 1:
            second_best = sorted_scores[1]
            # Higher confidence if clear winner
            if best_score > second_best * 2:
                return min(0.95, 0.5 + (best_score / 10))
            else:
                return min(0.75, 0.3 + (best_score / 10))
        
        return min(0.9, 0.5 + (best_score / 10))
    
    def get_available_agents(self) -> List[str]:
        """Get list of available subagents."""
        return list(self.AGENT_CAPABILITIES.keys())
    
    def get_agent_capabilities(self) -> Dict[str, Dict[str, Any]]:
        """Get capabilities metadata for all agents."""
        return self.AGENT_CAPABILITIES.copy()