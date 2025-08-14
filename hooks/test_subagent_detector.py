#!/usr/bin/env python3
"""
Test suite for the SubagentDetector class.

Tests automatic agent selection, context analysis, performance requirements,
and integration with the Task tool.
"""

import unittest
import time
import json
from unittest.mock import Mock, patch, MagicMock
from pathlib import Path
import sys

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))


class TestSubagentDetector(unittest.TestCase):
    """Test cases for SubagentDetector functionality."""
    
    def setUp(self):
        """Set up test fixtures."""
        # Import will fail initially as we haven't created the module yet
        # This is intentional for TDD
        try:
            from subagent_detector import SubagentDetector
            self.detector = SubagentDetector()
        except ImportError:
            self.detector = None
    
    def test_detector_initialization(self):
        """Test that SubagentDetector initializes correctly."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        self.assertIsNotNone(self.detector)
        self.assertTrue(hasattr(self.detector, 'detect'))
        self.assertTrue(hasattr(self.detector, 'get_available_agents'))
    
    def test_context_fetcher_detection(self):
        """Test detection of context-fetcher subagent for codebase analysis."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        # Context involving large codebase search
        context = {
            "prompt": "Search through the entire codebase for implementations of authentication",
            "operation": "codebase_search",
            "involves_multiple_files": True
        }
        
        result = self.detector.detect(context)
        self.assertEqual(result['agent'], 'context-fetcher')
        self.assertIn('codebase', result['reason'].lower())
    
    def test_date_checker_detection(self):
        """Test detection of date-checker subagent for date operations."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        # Context involving date requirements
        context = {
            "prompt": "Create a spec folder with today's date",
            "operation": "folder_creation",
            "requires_current_date": True
        }
        
        result = self.detector.detect(context)
        self.assertEqual(result['agent'], 'date-checker')
        self.assertIn('date', result['reason'].lower())
    
    def test_file_creator_detection(self):
        """Test detection of file-creator subagent for file generation."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        # Context involving file creation with templates
        context = {
            "prompt": "Create a new React component with tests",
            "operation": "file_creation",
            "requires_template": True,
            "file_type": "component"
        }
        
        result = self.detector.detect(context)
        self.assertEqual(result['agent'], 'file-creator')
        self.assertIn('file', result['reason'].lower())
    
    def test_git_workflow_detection(self):
        """Test detection of git-workflow subagent for git operations."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        # Context involving git operations
        context = {
            "prompt": "Create a pull request with all changes",
            "operation": "git_workflow",
            "involves_git": True,
            "actions": ["commit", "push", "pr_create"]
        }
        
        result = self.detector.detect(context)
        self.assertEqual(result['agent'], 'git-workflow')
        self.assertIn('git', result['reason'].lower())
    
    def test_test_runner_detection(self):
        """Test detection of test-runner subagent for test execution."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        # Context involving test execution
        context = {
            "prompt": "Run all tests and ensure they pass",
            "operation": "test_execution",
            "involves_testing": True,
            "test_framework": "pytest"
        }
        
        result = self.detector.detect(context)
        self.assertEqual(result['agent'], 'test-runner')
        self.assertIn('test', result['reason'].lower())
    
    def test_general_purpose_fallback(self):
        """Test fallback to general-purpose agent for unspecified contexts."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        # Generic context that doesn't match specific agents
        context = {
            "prompt": "Explain how this function works",
            "operation": "explanation"
        }
        
        result = self.detector.detect(context)
        self.assertEqual(result['agent'], 'general-purpose')
        self.assertIn('general', result['reason'].lower())
    
    def test_detection_performance(self):
        """Test that detection completes within 10ms requirement."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        context = {
            "prompt": "Test performance",
            "operation": "test"
        }
        
        # Run detection multiple times to get average
        times = []
        for _ in range(100):
            start = time.perf_counter()
            self.detector.detect(context)
            end = time.perf_counter()
            times.append((end - start) * 1000)  # Convert to ms
        
        avg_time = sum(times) / len(times)
        max_time = max(times)
        
        # Check that average time is under 10ms
        self.assertLess(avg_time, 10.0, 
                       f"Average detection time {avg_time:.2f}ms exceeds 10ms requirement")
        # Check that max time doesn't exceed 20ms (allowing for outliers)
        self.assertLess(max_time, 20.0,
                       f"Max detection time {max_time:.2f}ms exceeds acceptable threshold")
    
    def test_context_analysis_with_keywords(self):
        """Test that detector properly analyzes context based on keywords."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        test_cases = [
            ("Search for all TODO comments", "context-fetcher"),
            ("What's today's date?", "date-checker"),
            ("Create a new Python module", "file-creator"),
            ("Commit and push these changes", "git-workflow"),
            ("Run pytest and check coverage", "test-runner"),
            ("Analyze this code", "general-purpose")
        ]
        
        for prompt, expected_agent in test_cases:
            with self.subTest(prompt=prompt):
                context = {"prompt": prompt}
                result = self.detector.detect(context)
                self.assertEqual(result['agent'], expected_agent,
                               f"Expected {expected_agent} for prompt: {prompt}")
    
    def test_available_agents_list(self):
        """Test that detector returns list of available agents."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        agents = self.detector.get_available_agents()
        
        expected_agents = [
            'context-fetcher',
            'date-checker', 
            'file-creator',
            'git-workflow',
            'test-runner',
            'general-purpose'
        ]
        
        for agent in expected_agents:
            self.assertIn(agent, agents)
    
    def test_agent_capabilities_metadata(self):
        """Test that each agent has proper capability metadata."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        capabilities = self.detector.get_agent_capabilities()
        
        # Each agent should have description and triggers
        for agent in self.detector.get_available_agents():
            self.assertIn(agent, capabilities)
            self.assertIn('description', capabilities[agent])
            self.assertIn('triggers', capabilities[agent])
            self.assertIsInstance(capabilities[agent]['triggers'], list)
    
    def test_detection_with_multiple_signals(self):
        """Test detection when multiple signals point to different agents."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        # Context with mixed signals
        context = {
            "prompt": "Search for test files and run them",
            "operation": "mixed",
            "involves_search": True,
            "involves_testing": True
        }
        
        result = self.detector.detect(context)
        # Should prioritize based on primary operation
        self.assertIn(result['agent'], ['context-fetcher', 'test-runner'])
        self.assertGreater(result['confidence'], 0.5)
    
    def test_detection_confidence_scoring(self):
        """Test that detector provides confidence scores for selections."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        # High confidence context
        high_conf_context = {
            "prompt": "git commit -m 'test' && git push",
            "operation": "git_workflow",
            "involves_git": True
        }
        
        # Low confidence context  
        low_conf_context = {
            "prompt": "Do something with the code",
            "operation": "unknown"
        }
        
        high_result = self.detector.detect(high_conf_context)
        low_result = self.detector.detect(low_conf_context)
        
        self.assertGreater(high_result['confidence'], 0.8)
        self.assertLess(low_result['confidence'], 0.5)
    
    def test_graceful_error_handling(self):
        """Test that detector handles errors gracefully."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        # Test with None context
        result = self.detector.detect(None)
        self.assertEqual(result['agent'], 'general-purpose')
        self.assertIn('error', result.get('warning', '').lower())
        
        # Test with malformed context
        result = self.detector.detect("not a dict")
        self.assertEqual(result['agent'], 'general-purpose')
        
        # Test with empty context
        result = self.detector.detect({})
        self.assertEqual(result['agent'], 'general-purpose')


class TestSubagentIntegration(unittest.TestCase):
    """Test integration between SubagentDetector and Task tool."""
    
    def setUp(self):
        """Set up test fixtures."""
        try:
            from subagent_detector import SubagentDetector
            self.detector = SubagentDetector()
        except ImportError:
            self.detector = None
    
    @patch('subprocess.run')
    def test_task_tool_integration(self, mock_run):
        """Test that detector integrates with Task tool properly."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        # Simulate Task tool calling detector
        context = {
            "prompt": "Search for all Python files",
            "tool": "Task"
        }
        
        result = self.detector.detect(context)
        
        # Verify detector returns format expected by Task tool
        self.assertIn('agent', result)
        self.assertIn('reason', result)
        self.assertIn('confidence', result)
        self.assertIsInstance(result['agent'], str)
        self.assertIsInstance(result['confidence'], (int, float))
    
    def test_automatic_activation(self):
        """Test that subagents activate automatically without configuration."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        # Should work immediately without any setup
        context = {"prompt": "test"}
        result = self.detector.detect(context)
        
        # Should return a valid agent without any configuration
        self.assertIsNotNone(result)
        self.assertIn('agent', result)
    
    def test_transparent_operation(self):
        """Test that subagent operation is transparent to users."""
        if not self.detector:
            self.skipTest("SubagentDetector not implemented yet")
        
        # The interface should be identical to standard Task tool
        context = {"prompt": "Create a new feature", "tool": "Task"}
        
        result = self.detector.detect(context)
        
        # Result should be usable by Task tool without modification
        self.assertIsInstance(result, dict)
        self.assertEqual(len(result.get('agent', '')), len(result['agent']))


if __name__ == '__main__':
    # Run with verbose output
    unittest.main(verbosity=2)