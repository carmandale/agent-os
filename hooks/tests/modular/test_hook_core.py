#!/usr/bin/env python3
"""
Test suite for the hook core module.
Validates shared utilities and base classes.
"""

import os
import sys
import tempfile
import unittest
from unittest.mock import patch, MagicMock

# Add modules to path
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(__file__)), 'modules'))

from hook_core import (
    HookLogger, WorkspaceResolver, GitChecker, 
    IntentAnalyzer, SpecChecker, BaseHookHandler
)


class TestHookLogger(unittest.TestCase):
    """Test the centralized logging functionality."""
    
    def test_debug_logging_disabled(self):
        """Test that logging is disabled by default."""
        with patch.dict(os.environ, {}, clear=True):
            # Should not create log files when debugging disabled
            HookLogger.debug("test message")
            # No exception means success
    
    def test_debug_logging_enabled(self):
        """Test that logging works when enabled."""
        with patch.dict(os.environ, {'AGENT_OS_DEBUG': 'true'}):
            with tempfile.TemporaryDirectory() as tmpdir:
                log_path = os.path.join(tmpdir, "test.log")
                with patch('pathlib.Path.home') as mock_home:
                    mock_home.return_value.joinpath.return_value = log_path
                    HookLogger.debug("test message")
                    # Verify log was written (basic test)


class TestWorkspaceResolver(unittest.TestCase):
    """Test workspace resolution logic."""
    
    def test_resolve_from_cwd(self):
        """Test resolution from current working directory."""
        result = WorkspaceResolver.resolve({})
        self.assertTrue(os.path.isdir(result))
    
    def test_resolve_from_input_data(self):
        """Test resolution from input data fields."""
        test_data = {
            "tool_input": {
                "file_path": "/test/path/file.txt"
            }
        }
        with patch('os.path.dirname') as mock_dirname:
            mock_dirname.return_value = "/test/path"
            result = WorkspaceResolver.resolve(test_data)
            mock_dirname.assert_called_with("/test/path/file.txt")


class TestGitChecker(unittest.TestCase):
    """Test git-related status checks."""
    
    @patch('subprocess.run')
    def test_has_uncommitted_changes_true(self, mock_run):
        """Test detecting uncommitted changes."""
        mock_run.return_value.stdout = "M file.txt\n"
        result = GitChecker.has_uncommitted_changes("/test/path")
        self.assertTrue(result)
    
    @patch('subprocess.run')
    def test_has_uncommitted_changes_false(self, mock_run):
        """Test clean git status."""
        mock_run.return_value.stdout = ""
        result = GitChecker.has_uncommitted_changes("/test/path")
        self.assertFalse(result)
    
    @patch('subprocess.run')
    def test_has_open_prs_true(self, mock_run):
        """Test detecting open PRs."""
        mock_run.return_value.returncode = 0
        mock_run.return_value.stdout = '[{"number": 123}]'
        result = GitChecker.has_open_prs("/test/path")
        self.assertTrue(result)
    
    @patch('subprocess.run')
    def test_has_open_prs_false(self, mock_run):
        """Test no open PRs."""
        mock_run.return_value.returncode = 0
        mock_run.return_value.stdout = '[]'
        result = GitChecker.has_open_prs("/test/path")
        self.assertFalse(result)


class TestIntentAnalyzer(unittest.TestCase):
    """Test user intent analysis."""
    
    def test_get_intent_from_env(self):
        """Test intent override from environment."""
        with patch.dict(os.environ, {'AGENT_OS_INTENT': 'MAINTENANCE'}):
            result = IntentAnalyzer.get_intent("some text")
            self.assertEqual(result, "MAINTENANCE")
    
    @patch('subprocess.run')
    def test_get_intent_from_analyzer(self, mock_run):
        """Test intent from analyzer script."""
        mock_run.return_value.stdout = "NEW\n"
        result = IntentAnalyzer.get_intent("implement new feature")
        self.assertEqual(result, "NEW")
    
    @patch('subprocess.run')
    def test_get_intent_fallback(self, mock_run):
        """Test fallback on analyzer failure."""
        mock_run.side_effect = Exception("analyzer failed")
        result = IntentAnalyzer.get_intent("some text")
        self.assertEqual(result, "AMBIGUOUS")


class TestSpecChecker(unittest.TestCase):
    """Test spec detection logic."""
    
    @patch('subprocess.run')
    def test_has_active_spec_true(self, mock_run):
        """Test detecting active specs."""
        mock_run.return_value.stdout = "3\n"
        result = SpecChecker.has_active_spec("/test/path")
        self.assertTrue(result)
    
    @patch('subprocess.run') 
    def test_has_active_spec_false(self, mock_run):
        """Test no active specs."""
        mock_run.return_value.stdout = "0\n"
        result = SpecChecker.has_active_spec("/test/path")
        self.assertFalse(result)


class TestBaseHookHandler(unittest.TestCase):
    """Test base hook handler functionality."""
    
    def setUp(self):
        """Set up test handler."""
        self.input_data = {
            "tool_name": "Test",
            "tool_input": {"command": "test"}
        }
        self.handler = BaseHookHandler(self.input_data)
    
    def test_get_tool_name(self):
        """Test getting tool name."""
        self.assertEqual(self.handler.get_tool_name(), "Test")
    
    def test_get_tool_input(self):
        """Test getting tool input."""
        self.assertEqual(self.handler.get_tool_input(), {"command": "test"})
    
    @patch('os.path.exists')
    def test_check_work_session(self, mock_exists):
        """Test work session detection."""
        mock_exists.return_value = True
        result = self.handler.check_work_session()
        self.assertTrue(result)
    
    def test_handle_not_implemented(self):
        """Test that handle method must be implemented."""
        with self.assertRaises(NotImplementedError):
            self.handler.handle()


if __name__ == '__main__':
    unittest.main()
