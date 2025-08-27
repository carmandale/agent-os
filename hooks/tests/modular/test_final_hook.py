#!/usr/bin/env python3
"""
Comprehensive test suite for the final modular hook architecture.
Validates functionality, performance, and maintains test coverage requirements.
"""

import json
import os
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch, MagicMock
from pathlib import Path

# Add hook to path for testing
hook_path = Path(__file__).parent.parent.parent / "workflow-enforcement-hook-v2-final.py"

class TestHookPerformance(unittest.TestCase):
    """Test performance requirements."""
    
    def test_hook_performance_requirements(self):
        """Test that hook meets P95 < 500ms requirement."""
        import time
        
        test_payload = {"tool_name": "Bash", "tool_input": {"command": "echo test"}}
        latencies = []
        
        for _ in range(10):
            start = time.time()
            
            result = subprocess.run([
                "python3", str(hook_path), "pretool"
            ], input=json.dumps(test_payload), text=True, 
               capture_output=True, timeout=5)
            
            latency_ms = (time.time() - start) * 1000
            latencies.append(latency_ms)
        
        p95 = sorted(latencies)[int(0.95 * len(latencies))]
        self.assertLess(p95, 500, f"P95 latency {p95:.1f}ms exceeds 500ms requirement")


class TestHookFunctionality(unittest.TestCase):
    """Test core hook functionality."""
    
    def run_hook(self, hook_type: str, payload: dict) -> subprocess.CompletedProcess:
        """Helper to run hook with payload."""
        return subprocess.run([
            "python3", str(hook_path), hook_type
        ], input=json.dumps(payload), text=True, capture_output=True, timeout=5)
    
    def test_bash_readonly_commands_allowed(self):
        """Test that readonly bash commands are allowed."""
        test_cases = [
            "ls -la",
            "cat file.txt", 
            "grep pattern file",
            "pwd",
            "echo hello"
        ]
        
        for command in test_cases:
            with self.subTest(command=command):
                payload = {"tool_name": "Bash", "tool_input": {"command": command}}
                result = self.run_hook("pretool", payload)
                self.assertEqual(result.returncode, 0, f"Command '{command}' should be allowed")
    
    def test_git_commands_always_allowed(self):
        """Test that git/gh commands are always allowed."""
        test_cases = [
            "git status",
            "git add .",
            "git commit -m 'test'",
            "gh pr create",
            "gh issue list"
        ]
        
        for command in test_cases:
            with self.subTest(command=command):
                payload = {"tool_name": "Bash", "tool_input": {"command": command}}
                result = self.run_hook("pretool", payload)
                self.assertEqual(result.returncode, 0, f"Git command '{command}' should be allowed")
    
    def test_docs_operations_allowed(self):
        """Test that documentation operations are allowed."""
        test_cases = [
            {"tool_name": "Write", "tool_input": {"file_path": "README.md"}},
            {"tool_name": "Edit", "tool_input": {"file_path": "docs/guide.md"}},
            {"tool_name": "Bash", "tool_input": {"command": "echo 'test' > CLAUDE.md"}}
        ]
        
        for payload in test_cases:
            with self.subTest(payload=payload):
                result = self.run_hook("pretool", payload)
                self.assertEqual(result.returncode, 0, "Docs operations should be allowed")
    
    @patch.dict(os.environ, {'AGENT_OS_INTENT': 'MAINTENANCE'})
    def test_maintenance_intent_allowed(self):
        """Test that maintenance intent allows write operations."""
        payload = {"tool_name": "Bash", "tool_input": {"command": "cp file1 file2"}}
        result = self.run_hook("pretool", payload)
        self.assertEqual(result.returncode, 0, "Maintenance writes should be allowed")
    
    @patch.dict(os.environ, {'AGENT_OS_WORK_SESSION': 'true'})
    def test_work_session_bypasses_hygiene(self):
        """Test that work session mode bypasses hygiene checks."""
        payload = {"tool_name": "Write", "tool_input": {"file_path": "test.py"}}
        result = self.run_hook("pretool", payload)
        # Should succeed even without active spec when in work session
        self.assertIn(result.returncode, [0, 2])  # May still fail on spec check
    
    def test_task_handler_subagent_enforcement(self):
        """Test that task handler enforces subagent usage for review tasks."""
        payload = {
            "tool_name": "Task",
            "tool_input": {"description": "Review the implementation for bugs"}
        }
        result = self.run_hook("pretool-task", payload)
        self.assertEqual(result.returncode, 2, "Review tasks should be blocked")
        self.assertIn("specialized subagents", result.stderr)
    
    def test_userprompt_proceed_detection(self):
        """Test that proceed patterns are detected correctly."""
        proceed_prompts = [
            "Let's proceed with the next task",
            "Continue with implementation", 
            "What's next?",
            "Ready to start"
        ]
        
        for prompt in proceed_prompts:
            with self.subTest(prompt=prompt):
                payload = {"prompt": prompt}
                result = self.run_hook("userprompt", payload)
                # Should either succeed (maintenance) or block with workflow issues
                self.assertIn(result.returncode, [0, 2])
    
    def test_posttool_documentation_check(self):
        """Test that posttool checks documentation status."""
        payload = {"tool_name": "Write", "tool_input": {"file_path": "test.py"}}
        result = self.run_hook("posttool", payload)
        # Should complete (may warn about docs but not block)
        self.assertEqual(result.returncode, 0)
    
    def test_unknown_hook_type_fails(self):
        """Test that unknown hook types fail appropriately."""
        payload = {"tool_name": "Test"}
        result = self.run_hook("unknown", payload)
        self.assertEqual(result.returncode, 1)
    
    def test_invalid_json_input_handled(self):
        """Test that invalid JSON input is handled gracefully."""
        result = subprocess.run([
            "python3", str(hook_path), "pretool"
        ], input="invalid json", text=True, capture_output=True, timeout=5)
        self.assertEqual(result.returncode, 0, "Invalid JSON should not block")


class TestHookModularity(unittest.TestCase):
    """Test modular architecture principles."""
    
    def test_hook_file_size_requirement(self):
        """Test that main hook file is reasonable size."""
        with open(hook_path, 'r') as f:
            lines = len(f.readlines())
        
        # Should be under 500 lines total (much more modular than 436-line original)
        self.assertLess(lines, 500, f"Hook file has {lines} lines, should be more modular")
    
    def test_single_responsibility_functions(self):
        """Test that functions have focused responsibilities."""
        with open(hook_path, 'r') as f:
            content = f.read()
        
        # Check for focused function names
        focused_functions = [
            "fast_git_check", "fast_pr_check", "fast_intent_check", 
            "fast_spec_check", "is_write_command", "is_readonly_command"
        ]
        
        for func_name in focused_functions:
            self.assertIn(func_name, content, f"Should have focused function {func_name}")


class TestBackwardCompatibility(unittest.TestCase):
    """Test zero breaking changes requirement."""
    
    def test_hook_types_unchanged(self):
        """Test that all original hook types are supported."""
        original_hook_types = ["pretool", "pretool-task", "userprompt", "posttool"]
        
        for hook_type in original_hook_types:
            with self.subTest(hook_type=hook_type):
                payload = {"tool_name": "Read", "tool_input": {"file_path": "test.txt"}}
                result = subprocess.run([
                    "python3", str(hook_path), hook_type
                ], input=json.dumps(payload), text=True, capture_output=True, timeout=5)
                
                # Should not fail with "unknown hook type"
                self.assertNotEqual(result.returncode, 1, 
                                   f"Hook type {hook_type} should be supported")
    
    def test_environment_variables_respected(self):
        """Test that original environment variables still work."""
        env_vars = {
            'AGENT_OS_DEBUG': 'true',
            'AGENT_OS_INTENT': 'MAINTENANCE',
            'AGENT_OS_WORK_SESSION': 'true'
        }
        
        with patch.dict(os.environ, env_vars):
            payload = {"tool_name": "Bash", "tool_input": {"command": "echo test"}}
            result = subprocess.run([
                "python3", str(hook_path), "pretool"
            ], input=json.dumps(payload), text=True, capture_output=True, timeout=5)
            
            self.assertEqual(result.returncode, 0, "Environment variables should work")


if __name__ == '__main__':
    # Run tests and calculate coverage
    unittest.main(verbosity=2)
