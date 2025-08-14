#!/usr/bin/env python3
"""
Integration tests for Agent OS Subagents System.

These tests verify that all subagents work correctly together
and can be properly executed through the SubagentDetector.
"""

import os
import sys
import unittest
import tempfile
import shutil
import subprocess
from pathlib import Path
from unittest.mock import patch, MagicMock

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


class TestSubagentIntegration(unittest.TestCase):
    """Integration tests for subagent system."""
    
    def setUp(self):
        """Set up test environment."""
        self.detector = SubagentDetector()
        self.test_dir = tempfile.mkdtemp()
        self.original_cwd = os.getcwd()
        os.chdir(self.test_dir)
    
    def tearDown(self):
        """Clean up test environment."""
        os.chdir(self.original_cwd)
        shutil.rmtree(self.test_dir, ignore_errors=True)
    
    def test_context_fetcher_execution(self):
        """Test ContextFetcherAgent can execute searches."""
        agent = ContextFetcherAgent()
        
        # Create test files
        test_file = Path('test.py')
        test_file.write_text('def test_function():\n    return "test"')
        
        # Test grep operation
        result = agent.execute({
            'operation': 'grep',
            'query': 'test_function',
            'path': '.'
        })
        
        self.assertTrue(result['success'])
        self.assertIn('test.py', result['files'][0])
    
    def test_date_checker_execution(self):
        """Test DateCheckerAgent can get current date."""
        agent = DateCheckerAgent()
        
        # Test current date
        result = agent.execute({
            'operation': 'current'
        })
        
        self.assertTrue(result['success'])
        self.assertIn('date', result)
        self.assertIn('formatted', result)
    
    def test_file_creator_execution(self):
        """Test FileCreatorAgent can create files."""
        agent = FileCreatorAgent()
        
        # Test file creation
        result = agent.execute({
            'operation': 'create',
            'path': 'test_output.txt',
            'content': 'Test content'
        })
        
        self.assertTrue(result['success'])
        self.assertTrue(Path('test_output.txt').exists())
        self.assertEqual(Path('test_output.txt').read_text(), 'Test content')
    
    @patch('subprocess.run')
    def test_git_workflow_execution(self, mock_run):
        """Test GitWorkflowAgent can execute git operations."""
        agent = GitWorkflowAgent()
        
        # Mock git status output
        mock_run.return_value = MagicMock(
            stdout='## main...origin/main',
            stderr='',
            returncode=0
        )
        
        # Test status operation
        result = agent.execute({
            'operation': 'status'
        })
        
        self.assertTrue(result['success'])
        self.assertIn('branch', result)
    
    def test_test_runner_execution(self):
        """Test TestRunnerAgent can detect test frameworks."""
        agent = TestRunnerAgent()
        
        # Create a simple Python test file
        test_file = Path('test_sample.py')
        test_file.write_text('''
import unittest

class TestSample(unittest.TestCase):
    def test_example(self):
        self.assertTrue(True)
''')
        
        # Test discovery operation
        result = agent.execute({
            'operation': 'discover',
            'path': '.'
        })
        
        self.assertTrue(result['success'])
        self.assertIn('framework', result)
    
    def test_detector_selects_correct_agent(self):
        """Test that detector selects appropriate agent for context."""
        contexts = [
            {
                'message': 'Search for all Python files containing "import"',
                'expected': 'context-fetcher'
            },
            {
                'message': 'What is today\'s date?',
                'expected': 'date-checker'
            },
            {
                'message': 'Create a new README.md file',
                'expected': 'file-creator'
            },
            {
                'message': 'Commit these changes and create a PR',
                'expected': 'git-workflow'
            },
            {
                'message': 'Run the test suite and check coverage',
                'expected': 'test-runner'
            }
        ]
        
        for ctx in contexts:
            result = self.detector.detect({'message': ctx['message']})
            self.assertEqual(
                result['agent'], 
                ctx['expected'],
                f"Failed for message: {ctx['message']}"
            )
    
    def test_subagents_handle_errors_gracefully(self):
        """Test that all subagents handle errors without crashing."""
        agents = [
            ContextFetcherAgent(),
            DateCheckerAgent(),
            FileCreatorAgent(),
            GitWorkflowAgent(),
            TestRunnerAgent()
        ]
        
        # Test with invalid operations
        for agent in agents:
            result = agent.execute({
                'operation': 'invalid_operation_xyz'
            })
            
            # Should return error, not crash
            self.assertIn('error', result)
    
    def test_end_to_end_workflow(self):
        """Test a complete workflow using multiple subagents."""
        # 1. Use date checker to get current date
        date_agent = DateCheckerAgent()
        date_result = date_agent.execute({'operation': 'current'})
        self.assertTrue(date_result['success'])
        
        # 2. Create a file with the date
        file_agent = FileCreatorAgent()
        content = f"Created on: {date_result['formatted']}"
        file_result = file_agent.execute({
            'operation': 'create',
            'path': 'workflow_test.txt',
            'content': content
        })
        self.assertTrue(file_result['success'])
        
        # 3. Search for the created file
        context_agent = ContextFetcherAgent()
        search_result = context_agent.execute({
            'operation': 'find',
            'pattern': 'workflow_test.txt',
            'path': '.'
        })
        self.assertTrue(search_result['success'])
        self.assertIn('workflow_test.txt', search_result['files'][0])
    
    def test_performance_requirements(self):
        """Test that detection meets performance requirements."""
        import time
        
        # Test 100 detections
        times = []
        for _ in range(100):
            start = time.perf_counter()
            self.detector.detect({'message': 'test query'})
            end = time.perf_counter()
            times.append((end - start) * 1000)  # Convert to ms
        
        avg_time = sum(times) / len(times)
        
        # Should be well under 10ms requirement
        self.assertLess(avg_time, 10, 
                       f"Average detection time {avg_time:.2f}ms exceeds 10ms requirement")
        
        # Most detections should be under 1ms
        fast_detections = sum(1 for t in times if t < 1)
        self.assertGreater(fast_detections, 90, 
                          "Less than 90% of detections completed in under 1ms")


if __name__ == '__main__':
    unittest.main()