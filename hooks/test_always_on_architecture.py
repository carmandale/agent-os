#!/usr/bin/env python3
"""
Tests for Always-On Architecture for Agent OS Subagents.

These tests verify that the subagent system activates automatically
without user configuration and operates transparently.
"""

import os
import sys
import unittest
import json
import tempfile
import shutil
from unittest.mock import patch, MagicMock, call
from typing import Dict, Any
import time

# Add hooks directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from subagent_detector import SubagentDetector


class TestAlwaysOnArchitecture(unittest.TestCase):
    """Test always-on architecture for automatic subagent activation."""
    
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
    
    def test_automatic_initialization(self):
        """Test that subagent system initializes automatically."""
        # System should initialize without explicit configuration
        detector = SubagentDetector()
        
        self.assertIsNotNone(detector)
        self.assertTrue(len(detector.get_available_agents()) > 0)
        
        # Should have all expected agents available
        expected_agents = [
            'context-fetcher',
            'date-checker',
            'file-creator',
            'git-workflow',
            'test-runner',
            'general-purpose'
        ]
        
        available = detector.get_available_agents()
        for agent in expected_agents:
            self.assertIn(agent, available)
    
    def test_zero_configuration_requirement(self):
        """Test that no configuration files are required."""
        # Remove any potential config files
        config_files = [
            '.agent-os-config.json',
            'subagent.config',
            '.subagents'
        ]
        
        for config in config_files:
            if os.path.exists(config):
                os.remove(config)
        
        # System should still work
        detector = SubagentDetector()
        result = detector.detect({'message': 'Search for files'})
        
        self.assertIsNotNone(result)
        self.assertIn('agent', result)
    
    def test_transparent_operation(self):
        """Test that subagents operate transparently to users."""
        # User sends a normal request
        user_request = {
            'prompt': 'Find all Python files with TODO comments',
            'description': 'Search task'
        }
        
        # Detection happens automatically
        detector = SubagentDetector()
        result = detector.detect({'message': user_request['prompt']})
        
        # User doesn't see the internal routing
        self.assertIn('agent', result)
        # But the result doesn't expose internal details
        self.assertNotIn('_internal', result)
    
    def test_automatic_context_analysis(self):
        """Test automatic context analysis for agent selection."""
        contexts = [
            {
                'user_input': 'I need to search through the codebase',
                'expected_detection': 'context-fetcher'
            },
            {
                'user_input': 'Create a folder with today\'s date',
                'expected_detection': 'date-checker'
            },
            {
                'user_input': 'Generate a new component from template',
                'expected_detection': 'file-creator'
            },
            {
                'user_input': 'Commit my changes to git',
                'expected_detection': 'git-workflow'
            },
            {
                'user_input': 'Run the test suite',
                'expected_detection': 'test-runner'
            }
        ]
        
        detector = SubagentDetector()
        
        for ctx in contexts:
            # Automatic analysis without user intervention
            result = detector.detect({'message': ctx['user_input']})
            
            self.assertEqual(
                result['agent'],
                ctx['expected_detection'],
                f"Failed to auto-detect for: {ctx['user_input']}"
            )
    
    def test_performance_under_10ms(self):
        """Test that detection completes within 10ms requirement."""
        detector = SubagentDetector()
        
        # Warm up
        detector.detect({'message': 'test'})
        
        # Test multiple detections
        times = []
        test_messages = [
            'Search for imports',
            'Get current date',
            'Create new file',
            'Commit changes',
            'Run tests',
            'Analyze code structure',
            'Find TODO comments'
        ]
        
        for _ in range(100):
            for msg in test_messages:
                start = time.perf_counter()
                detector.detect({'message': msg})
                end = time.perf_counter()
                times.append((end - start) * 1000)
        
        # Calculate statistics
        avg_time = sum(times) / len(times)
        max_time = max(times)
        p95_time = sorted(times)[int(len(times) * 0.95)]
        
        # All metrics should meet requirements
        self.assertLess(avg_time, 10, 
                       f"Average time {avg_time:.2f}ms exceeds 10ms")
        self.assertLess(p95_time, 10,
                       f"95th percentile {p95_time:.2f}ms exceeds 10ms")
        
        # Most detections should be under 1ms
        fast_count = sum(1 for t in times if t < 1)
        fast_percentage = (fast_count / len(times)) * 100
        self.assertGreater(fast_percentage, 80,
                          f"Only {fast_percentage:.1f}% under 1ms")
    
    def test_debug_logging_invisible_to_users(self):
        """Test that debug logging doesn't appear in user output."""
        import logging
        import io
        
        # Capture stdout/stderr
        stdout_capture = io.StringIO()
        stderr_capture = io.StringIO()
        
        # Perform detection with potential debug output
        detector = SubagentDetector()
        
        # Temporarily redirect stdout/stderr
        import sys
        old_stdout = sys.stdout
        old_stderr = sys.stderr
        sys.stdout = stdout_capture
        sys.stderr = stderr_capture
        
        try:
            # Perform multiple operations
            for _ in range(10):
                detector.detect({'message': 'Test query'})
            
            # Get captured output
            stdout_output = stdout_capture.getvalue()
            stderr_output = stderr_capture.getvalue()
            
            # Should not contain debug information
            self.assertNotIn('DEBUG', stdout_output)
            self.assertNotIn('DEBUG', stderr_output)
            self.assertNotIn('SubagentDetector', stdout_output)
            
        finally:
            sys.stdout = old_stdout
            sys.stderr = old_stderr
    
    def test_graceful_degradation(self):
        """Test graceful degradation when subagents unavailable."""
        detector = SubagentDetector()
        
        # Test with various error conditions
        error_contexts = [
            None,  # No context
            {},    # Empty context
            {'invalid': 'data'},  # Missing message/prompt
            {'message': ''},  # Empty message
            {'message': None},  # None message
        ]
        
        for ctx in error_contexts:
            result = detector.detect(ctx)
            
            # Should always return a valid result
            self.assertIsNotNone(result)
            self.assertIn('agent', result)
            # Should fallback to general-purpose
            self.assertEqual(result['agent'], 'general-purpose')
    
    def test_concurrent_detection_safety(self):
        """Test that concurrent detections work correctly."""
        import threading
        import queue
        
        detector = SubagentDetector()
        results = queue.Queue()
        
        def detect_worker(msg, result_queue):
            """Worker function for concurrent detection."""
            result = detector.detect({'message': msg})
            result_queue.put(result)
        
        # Create multiple threads
        threads = []
        messages = [
            'Search for files',
            'Get date',
            'Create file',
            'Commit code',
            'Run tests'
        ] * 10  # 50 total detections
        
        for msg in messages:
            t = threading.Thread(target=detect_worker, args=(msg, results))
            threads.append(t)
            t.start()
        
        # Wait for all threads
        for t in threads:
            t.join(timeout=1)
        
        # Check all results
        self.assertEqual(results.qsize(), len(messages))
        
        while not results.empty():
            result = results.get()
            self.assertIn('agent', result)
            self.assertIn('confidence', result)
    
    def test_memory_efficiency(self):
        """Test that the system is memory efficient."""
        import tracemalloc
        
        # Start memory tracking
        tracemalloc.start()
        
        detector = SubagentDetector()
        
        # Get baseline memory
        snapshot1 = tracemalloc.take_snapshot()
        
        # Perform many detections
        for _ in range(1000):
            detector.detect({'message': 'Test query'})
        
        # Get memory after operations
        snapshot2 = tracemalloc.take_snapshot()
        
        # Calculate memory difference
        top_stats = snapshot2.compare_to(snapshot1, 'lineno')
        total_diff = sum(stat.size_diff for stat in top_stats)
        
        # Memory increase should be minimal (less than 1MB)
        self.assertLess(total_diff, 1024 * 1024,
                       f"Memory increased by {total_diff / 1024:.1f}KB")
        
        tracemalloc.stop()
    
    def test_startup_time(self):
        """Test that system starts up quickly."""
        import time
        
        # Measure initialization time
        start = time.perf_counter()
        detector = SubagentDetector()
        end = time.perf_counter()
        
        init_time = (end - start) * 1000
        
        # Should initialize in under 100ms
        self.assertLess(init_time, 100,
                       f"Initialization took {init_time:.1f}ms")
        
        # First detection should also be fast
        start = time.perf_counter()
        detector.detect({'message': 'First query'})
        end = time.perf_counter()
        
        first_detect_time = (end - start) * 1000
        
        # First detection should be under 10ms
        self.assertLess(first_detect_time, 10,
                       f"First detection took {first_detect_time:.1f}ms")
    
    def test_integration_with_claude_code(self):
        """Test integration with Claude Code environment."""
        # Simulate Claude Code context
        claude_context = {
            'tool': 'Task',
            'params': {
                'description': 'Search for TODO comments',
                'prompt': 'Find all TODO and FIXME comments in Python files'
            }
        }
        
        # Extract message for detection
        message = claude_context['params']['prompt']
        
        detector = SubagentDetector()
        result = detector.detect({'message': message})
        
        # Should detect context-fetcher for search task
        self.assertEqual(result['agent'], 'context-fetcher')
        
        # Result should be compatible with Claude Code
        self.assertIn('agent', result)
        self.assertIn('confidence', result)
        self.assertIn('reason', result)
    
    def test_no_external_dependencies(self):
        """Test that core functionality works without external deps."""
        # Test with minimal Python environment
        detector = SubagentDetector()
        
        # Should work with just standard library
        result = detector.detect({'message': 'Basic test'})
        
        self.assertIsNotNone(result)
        self.assertIn('agent', result)
        
        # Check that core agents are available
        agents = detector.get_available_agents()
        self.assertGreater(len(agents), 0)


if __name__ == '__main__':
    unittest.main()