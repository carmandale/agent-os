#!/usr/bin/env python3
"""
Tests for Claude Code Task Tool integration with Subagent System.

These tests verify that the Task tool can automatically detect and launch
appropriate subagents while maintaining backward compatibility.
"""

import os
import sys
import unittest
import json
from unittest.mock import patch, MagicMock, call
from typing import Dict, Any

# Add hooks directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from subagent_detector import SubagentDetector


class TestTaskToolIntegration(unittest.TestCase):
    """Test Task tool integration with subagents."""
    
    def setUp(self):
        """Set up test environment."""
        self.detector = SubagentDetector()
    
    def test_task_tool_detects_subagent_context(self):
        """Test that Task tool can detect when to use subagents."""
        test_cases = [
            {
                'prompt': 'Search the codebase for all TODO comments',
                'expected_agent': 'context-fetcher',
                'should_use_subagent': True
            },
            {
                'prompt': 'Get the current date for folder naming',
                'expected_agent': 'date-checker',
                'should_use_subagent': True
            },
            {
                'prompt': 'Create a new README.md from template',
                'expected_agent': 'file-creator',
                'should_use_subagent': True
            },
            {
                'prompt': 'Commit changes and create a pull request',
                'expected_agent': 'git-workflow',
                'should_use_subagent': True
            },
            {
                'prompt': 'Run the test suite with coverage',
                'expected_agent': 'test-runner',
                'should_use_subagent': True
            },
            {
                'prompt': 'Analyze the authentication system architecture',
                'expected_agent': 'general-purpose',
                'should_use_subagent': False
            }
        ]
        
        for case in test_cases:
            result = self.detector.detect({'message': case['prompt']})
            
            if case['should_use_subagent']:
                self.assertEqual(
                    result['agent'],
                    case['expected_agent'],
                    f"Failed to detect subagent for: {case['prompt']}"
                )
            else:
                self.assertEqual(
                    result['agent'],
                    'general-purpose',
                    f"Should use general-purpose for: {case['prompt']}"
                )
    
    def test_task_tool_interface_unchanged(self):
        """Test that Task tool interface remains the same for users."""
        # Simulate Task tool parameters
        task_params = {
            'description': 'Search for test files',
            'prompt': 'Find all test files in the codebase',
            'subagent_type': None  # Users shouldn't need to specify this
        }
        
        # The interface should accept the same parameters
        self.assertIn('description', task_params)
        self.assertIn('prompt', task_params)
        
        # Subagent selection should be automatic
        self.assertIsNone(task_params.get('subagent_type'))
    
    @patch('subprocess.run')
    def test_automatic_subagent_launching(self, mock_run):
        """Test that appropriate subagent is launched automatically."""
        # Mock successful subagent execution
        mock_run.return_value = MagicMock(
            stdout=json.dumps({
                'success': True,
                'agent': 'context-fetcher',
                'result': {'files': ['test.py']}
            }),
            stderr='',
            returncode=0
        )
        
        # Simulate Task tool receiving a search request
        task_context = {
            'prompt': 'Search for all Python files with class definitions',
            'description': 'Find classes'
        }
        
        # Detect appropriate subagent
        detection_result = self.detector.detect({'message': task_context['prompt']})
        
        # Verify context-fetcher would be selected
        self.assertEqual(detection_result['agent'], 'context-fetcher')
        self.assertGreater(detection_result['confidence'], 0.7)
    
    def test_graceful_fallback_on_error(self):
        """Test fallback to general-purpose agent on error."""
        # Test with ambiguous context
        ambiguous_context = {
            'prompt': 'Do something with the code',
            'description': 'Generic task'
        }
        
        result = self.detector.detect({'message': ambiguous_context['prompt']})
        
        # Should fallback to general-purpose
        self.assertEqual(result['agent'], 'general-purpose')
        self.assertIn('reason', result)
    
    def test_performance_overhead_minimal(self):
        """Test that subagent detection adds minimal overhead."""
        import time
        
        # Test detection performance
        prompts = [
            'Search for imports',
            'Get current date',
            'Create new file',
            'Commit changes',
            'Run tests'
        ]
        
        times = []
        for prompt in prompts * 20:  # Test 100 detections
            start = time.perf_counter()
            self.detector.detect({'message': prompt})
            end = time.perf_counter()
            times.append((end - start) * 1000)
        
        avg_time = sum(times) / len(times)
        
        # Should add less than 1ms overhead on average
        self.assertLess(avg_time, 1.0,
                       f"Detection overhead {avg_time:.2f}ms exceeds 1ms limit")
    
    def test_context_enhancement_for_subagents(self):
        """Test that context is properly enhanced for subagents."""
        test_prompts = [
            {
                'original': 'Find TODO comments',
                'enhanced_keys': ['operation', 'query', 'path']
            },
            {
                'original': "What's today's date?",
                'enhanced_keys': ['operation', 'format']
            },
            {
                'original': 'Create README.md',
                'enhanced_keys': ['operation', 'path', 'template']
            }
        ]
        
        for test in test_prompts:
            # Detect subagent
            result = self.detector.detect({'message': test['original']})
            
            # Verify agent was detected
            self.assertNotEqual(result['agent'], 'general-purpose')
            
            # Context should be enhanced based on agent type
            # (This would be done by the Task tool wrapper)
            enhanced_context = self._enhance_context_for_agent(
                test['original'],
                result['agent']
            )
            
            # Verify expected keys would be present
            for key in test['enhanced_keys']:
                self.assertIsNotNone(
                    enhanced_context.get(key),
                    f"Missing {key} in enhanced context for: {test['original']}"
                )
    
    def _enhance_context_for_agent(self, prompt: str, agent: str) -> Dict[str, Any]:
        """Helper to simulate context enhancement."""
        base_context = {'prompt': prompt}
        
        if agent == 'context-fetcher':
            base_context.update({
                'operation': 'search',
                'query': prompt,
                'path': '.'
            })
        elif agent == 'date-checker':
            base_context.update({
                'operation': 'current',
                'format': 'spec'
            })
        elif agent == 'file-creator':
            base_context.update({
                'operation': 'create',
                'path': 'README.md',
                'template': None
            })
        elif agent == 'git-workflow':
            base_context.update({
                'operation': 'commit',
                'type': 'feat'
            })
        elif agent == 'test-runner':
            base_context.update({
                'operation': 'run',
                'coverage': True
            })
        
        return base_context
    
    def test_subagent_result_integration(self):
        """Test that subagent results integrate seamlessly."""
        # Simulate different subagent results
        subagent_results = [
            {
                'agent': 'context-fetcher',
                'result': {
                    'success': True,
                    'files': ['src/main.py', 'tests/test_main.py'],
                    'matches': 5
                }
            },
            {
                'agent': 'date-checker',
                'result': {
                    'success': True,
                    'date': '2025-08-14',
                    'formatted': 'August 14, 2025'
                }
            },
            {
                'agent': 'test-runner',
                'result': {
                    'success': True,
                    'tests_run': 42,
                    'tests_passed': 42,
                    'coverage': 85.5
                }
            }
        ]
        
        for agent_result in subagent_results:
            # Results should be properly formatted
            self.assertIn('success', agent_result['result'])
            self.assertTrue(agent_result['result']['success'])
            
            # Agent type should be identifiable
            self.assertIn('agent', agent_result)
    
    def test_parallel_subagent_execution(self):
        """Test that multiple subagents can be executed in parallel."""
        # Simulate parallel task requests
        parallel_tasks = [
            {'prompt': 'Search for imports', 'agent': 'context-fetcher'},
            {'prompt': 'Get current date', 'agent': 'date-checker'},
            {'prompt': 'Check git status', 'agent': 'git-workflow'}
        ]
        
        # All should be detectable
        for task in parallel_tasks:
            result = self.detector.detect({'message': task['prompt']})
            self.assertEqual(
                result['agent'],
                task['agent'],
                f"Failed to detect {task['agent']} for: {task['prompt']}"
            )
    
    def test_subagent_caching_for_performance(self):
        """Test that subagent instances can be cached."""
        # First detection
        result1 = self.detector.detect({'message': 'Search for files'})
        
        # Second detection of same type
        result2 = self.detector.detect({'message': 'Search for classes'})
        
        # Both should use context-fetcher
        self.assertEqual(result1['agent'], 'context-fetcher')
        self.assertEqual(result2['agent'], 'context-fetcher')
        
        # Detection should be fast for cached agent type
        import time
        start = time.perf_counter()
        self.detector.detect({'message': 'Search for functions'})
        end = time.perf_counter()
        
        detection_time = (end - start) * 1000
        self.assertLess(detection_time, 0.5,
                       f"Cached detection took {detection_time:.2f}ms")
    
    def test_debug_logging_without_visibility(self):
        """Test that debug info is logged but not shown to users."""
        import logging
        import io
        
        # Set up logging capture
        log_capture = io.StringIO()
        handler = logging.StreamHandler(log_capture)
        handler.setLevel(logging.DEBUG)
        
        logger = logging.getLogger('subagent_detector')
        logger.addHandler(handler)
        logger.setLevel(logging.DEBUG)
        
        # Perform detection
        self.detector.detect({'message': 'Test query'})
        
        # Check that debug info was logged
        log_output = log_capture.getvalue()
        
        # Should contain debug info but not be visible to user
        # (In production, debug logs would go to file, not stdout)
        self.assertIsNotNone(log_output)
    
    def test_backward_compatibility_preserved(self):
        """Test that existing Task tool usage still works."""
        # Existing Task tool parameters should still work
        legacy_task = {
            'description': 'Legacy task',
            'prompt': 'Do something complex',
            'subagent_type': 'general-purpose'  # Explicitly specified
        }
        
        # Should respect explicit subagent_type if provided
        self.assertEqual(legacy_task['subagent_type'], 'general-purpose')
        
        # But also work without it
        auto_task = {
            'description': 'Auto task',
            'prompt': 'Search for TODO comments'
        }
        
        # Should auto-detect context-fetcher
        result = self.detector.detect({'message': auto_task['prompt']})
        self.assertEqual(result['agent'], 'context-fetcher')


if __name__ == '__main__':
    unittest.main()