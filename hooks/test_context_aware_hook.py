#!/usr/bin/env python3
"""
Comprehensive tests for Context-Aware Hook Wrapper
=================================================
Tests the ContextAwareWorkflowHook class that integrates intent analysis
with workflow enforcement to provide intelligent behavior based on work type.
"""

import json
import os
import sys
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch, call, MagicMock
from pathlib import Path

# Add hooks directory to path for imports
sys.path.insert(0, os.path.dirname(__file__))

# Import the modules we're testing (will be created after tests)
from intent_analyzer import IntentAnalyzer, IntentType, WorkIntentResult


class TestContextAwareHook(unittest.TestCase):
    """Test suite for ContextAwareWorkflowHook class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.test_dir = tempfile.mkdtemp()
        self.config_dir = os.path.join(self.test_dir, '.agent-os', 'config')
        os.makedirs(self.config_dir, exist_ok=True)
        
        # Create mock config file
        self.config_path = os.path.join(self.config_dir, 'workflow-enforcement.yaml')
        with open(self.config_path, 'w') as f:
            f.write("""
maintenance_patterns:
  - "fix tests"
  - "debug"
  - "resolve conflicts"
new_work_patterns:
  - "implement feature"
  - "create component"
override_behavior:
  prompt_on_ambiguous: true
  allow_manual_override: true
""")
    
    def tearDown(self):
        """Clean up test fixtures."""
        import shutil
        shutil.rmtree(self.test_dir, ignore_errors=True)
    
    @patch.dict(os.environ, {})
    def test_context_aware_hook_initialization(self):
        """Test that ContextAwareWorkflowHook initializes correctly."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        hook = ContextAwareWorkflowHook()
        
        # Should initialize intent analyzer
        self.assertIsInstance(hook.intent_analyzer, IntentAnalyzer)
        
        # Should have required methods
        self.assertTrue(hasattr(hook, 'should_allow_work'))
        self.assertTrue(hasattr(hook, 'process_hook'))
        self.assertTrue(hasattr(hook, 'check_workspace_state'))
    
    @patch('subprocess.run')
    def test_workspace_state_checking_clean(self, mock_run):
        """Test workspace state detection when workspace is clean."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        # Mock clean git status
        mock_run.side_effect = [
            Mock(stdout='', returncode=0),  # git status --porcelain
            Mock(stdout='[]', returncode=0)  # gh pr list
        ]
        
        hook = ContextAwareWorkflowHook()
        workspace_state = hook.check_workspace_state()
        
        self.assertFalse(workspace_state['has_uncommitted_changes'])
        self.assertFalse(workspace_state['has_open_prs'])
        self.assertTrue(workspace_state['is_clean'])
    
    @patch('subprocess.run')
    def test_workspace_state_checking_dirty(self, mock_run):
        """Test workspace state detection when workspace is dirty."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        # Mock dirty git status and open PRs
        mock_run.side_effect = [
            Mock(stdout=' M file.py\n', returncode=0),  # git status --porcelain
            Mock(stdout='[{"number": 123}]', returncode=0)  # gh pr list
        ]
        
        hook = ContextAwareWorkflowHook()
        workspace_state = hook.check_workspace_state()
        
        self.assertTrue(workspace_state['has_uncommitted_changes'])
        self.assertTrue(workspace_state['has_open_prs'])
        self.assertFalse(workspace_state['is_clean'])
    
    def test_maintenance_work_allowed_with_dirty_workspace(self):
        """Test that maintenance work is allowed even with dirty workspace."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        # Create hook with mocked dependencies
        hook = ContextAwareWorkflowHook()
        
        # Mock workspace state as dirty
        dirty_workspace = {
            'has_uncommitted_changes': True,
            'has_open_prs': True,
            'is_clean': False
        }
        
        # Test various maintenance messages
        maintenance_messages = [
            "fix the failing tests",
            "debug the CI pipeline issue", 
            "resolve merge conflicts",
            "fix broken functionality",
            "update dependencies to fix security vulnerability"
        ]
        
        for message in maintenance_messages:
            with self.subTest(message=message):
                result = hook.should_allow_work(message, dirty_workspace)
                self.assertTrue(result, f"Should allow maintenance work: '{message}'")
    
    def test_new_work_blocked_with_dirty_workspace(self):
        """Test that new work is blocked with dirty workspace."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        hook = ContextAwareWorkflowHook()
        
        # Mock workspace state as dirty
        dirty_workspace = {
            'has_uncommitted_changes': True,
            'has_open_prs': False,
            'is_clean': False
        }
        
        # Test various new work messages
        new_work_messages = [
            "implement user authentication feature",
            "create a new dashboard component",
            "add search functionality",
            "build the user profile interface"
        ]
        
        for message in new_work_messages:
            with self.subTest(message=message):
                result = hook.should_allow_work(message, dirty_workspace)
                self.assertFalse(result, f"Should block new work: '{message}'")
    
    def test_new_work_allowed_with_clean_workspace(self):
        """Test that new work is allowed with clean workspace."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        hook = ContextAwareWorkflowHook()
        
        # Mock workspace state as clean
        clean_workspace = {
            'has_uncommitted_changes': False,
            'has_open_prs': False,
            'is_clean': True
        }
        
        # Test various new work messages
        new_work_messages = [
            "implement user authentication feature",
            "create a new dashboard component",
            "add search functionality",
            "build the user profile interface"
        ]
        
        for message in new_work_messages:
            with self.subTest(message=message):
                result = hook.should_allow_work(message, clean_workspace)
                self.assertTrue(result, f"Should allow new work in clean workspace: '{message}'")
    
    @patch.dict(os.environ, {'AGENT_OS_WORK_TYPE': 'maintenance'})
    def test_manual_override_maintenance(self):
        """Test manual override for maintenance work."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        hook = ContextAwareWorkflowHook()
        
        dirty_workspace = {
            'has_uncommitted_changes': True,
            'has_open_prs': True,
            'is_clean': False
        }
        
        # Even with new work message, should be treated as maintenance due to override
        result = hook.should_allow_work("implement new feature", dirty_workspace)
        self.assertTrue(result, "Manual override should allow work")
    
    @patch.dict(os.environ, {'AGENT_OS_WORK_TYPE': 'new_work'})
    def test_manual_override_new_work(self):
        """Test manual override for new work."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        hook = ContextAwareWorkflowHook()
        
        # Clean workspace required even with override for new work
        clean_workspace = {
            'has_uncommitted_changes': False,
            'has_open_prs': False,
            'is_clean': True
        }
        
        dirty_workspace = {
            'has_uncommitted_changes': True,
            'has_open_prs': False,
            'is_clean': False
        }
        
        # Should allow with clean workspace
        result = hook.should_allow_work("fix tests", clean_workspace)
        self.assertTrue(result, "Override with clean workspace should allow work")
        
        # Should still block with dirty workspace
        result = hook.should_allow_work("fix tests", dirty_workspace)
        self.assertFalse(result, "Override should still require clean workspace for new work")
    
    @patch('builtins.input', return_value='maintenance')
    @patch('sys.stderr')
    def test_ambiguous_intent_user_prompt(self, mock_stderr, mock_input):
        """Test user prompt handling for ambiguous intent."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        hook = ContextAwareWorkflowHook()
        
        # Mock ambiguous result from intent analyzer
        with patch.object(hook.intent_analyzer, 'analyze_intent') as mock_analyze:
            mock_analyze.return_value = WorkIntentResult(
                intent_type=IntentType.AMBIGUOUS,
                confidence=0.5,
                matched_patterns=[],
                reasoning="Could not determine intent"
            )
            
            dirty_workspace = {
                'has_uncommitted_changes': True,
                'has_open_prs': False,
                'is_clean': False
            }
            
            result = hook.should_allow_work("refactor something", dirty_workspace)
            
            # Should prompt user and allow work based on user choice
            self.assertTrue(result)
            mock_input.assert_called_once()
    
    @patch('builtins.input', return_value='new_work')
    @patch('sys.stderr')
    def test_ambiguous_intent_user_prompt_new_work(self, mock_stderr, mock_input):
        """Test user prompt handling when user chooses new work for ambiguous intent."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        hook = ContextAwareWorkflowHook()
        
        # Mock ambiguous result from intent analyzer
        with patch.object(hook.intent_analyzer, 'analyze_intent') as mock_analyze:
            mock_analyze.return_value = WorkIntentResult(
                intent_type=IntentType.AMBIGUOUS,
                confidence=0.5,
                matched_patterns=[],
                reasoning="Could not determine intent"
            )
            
            dirty_workspace = {
                'has_uncommitted_changes': True,
                'has_open_prs': False,
                'is_clean': False
            }
            
            result = hook.should_allow_work("refactor something", dirty_workspace)
            
            # Should block since workspace is dirty and user chose new work
            self.assertFalse(result)
            mock_input.assert_called_once()
    
    @patch('subprocess.run')
    def test_process_hook_integration_pretool(self, mock_run):
        """Test full hook processing for pretool hook type."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        # Mock clean workspace
        mock_run.side_effect = [
            Mock(stdout='', returncode=0),  # git status --porcelain
            Mock(stdout='[]', returncode=0)  # gh pr list
        ]
        
        hook = ContextAwareWorkflowHook()
        
        # Mock hook input data
        input_data = {
            "tool_name": "Edit",
            "tool_input": {"file_path": "/test/file.py"},
            "user_message": "implement user login feature"
        }
        
        # Should allow work with clean workspace and new work intent
        result = hook.process_hook("pretool", input_data)
        self.assertEqual(result, 0)  # Exit code 0 = allow
    
    @patch('subprocess.run')
    def test_process_hook_integration_pretool_blocked(self, mock_run):
        """Test hook processing blocks work when appropriate."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        # Mock dirty workspace
        mock_run.side_effect = [
            Mock(stdout=' M file.py\n', returncode=0),  # git status --porcelain
            Mock(stdout='[]', returncode=0)  # gh pr list
        ]
        
        hook = ContextAwareWorkflowHook()
        
        # Mock hook input data for new work with dirty workspace
        input_data = {
            "tool_name": "Write",
            "tool_input": {"file_path": "/test/new_file.py"},
            "user_message": "create new user dashboard"
        }
        
        # Should block work
        result = hook.process_hook("pretool", input_data)
        self.assertEqual(result, 2)  # Exit code 2 = block with feedback
    
    @patch('subprocess.run')
    def test_process_hook_maintenance_with_dirty_workspace(self, mock_run):
        """Test that maintenance work is allowed even with dirty workspace."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        # Mock dirty workspace
        mock_run.side_effect = [
            Mock(stdout=' M file.py\n', returncode=0),  # git status --porcelain  
            Mock(stdout='[]', returncode=0)  # gh pr list
        ]
        
        hook = ContextAwareWorkflowHook()
        
        # Mock hook input data for maintenance work
        input_data = {
            "tool_name": "Edit",
            "tool_input": {"file_path": "/test/broken_test.py"},
            "user_message": "fix the failing unit tests"
        }
        
        # Should allow maintenance work despite dirty workspace
        result = hook.process_hook("pretool", input_data)
        self.assertEqual(result, 0)  # Exit code 0 = allow
    
    @patch('context_aware_hook.log_debug')
    def test_logging_integration(self, mock_log):
        """Test that logging works correctly throughout the hook."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        hook = ContextAwareWorkflowHook()
        
        # Mock a hook call
        input_data = {
            "tool_name": "Edit",
            "tool_input": {"file_path": "/test/file.py"},
            "user_message": "fix broken tests"
        }
        
        with patch.object(hook, 'check_workspace_state') as mock_check:
            mock_check.return_value = {'is_clean': True, 'has_uncommitted_changes': False, 'has_open_prs': False}
            
            hook.process_hook("pretool", input_data)
            
            # Verify debug logging was called
            mock_log.assert_called()
    
    def test_backward_compatibility_preserves_original_behavior(self):
        """Test that the wrapper preserves original hook behavior when appropriate."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        hook = ContextAwareWorkflowHook()
        
        # Test with tool that original hook would allow (Read tool)
        input_data = {
            "tool_name": "Read",
            "tool_input": {"file_path": "/test/file.py"},
            "user_message": "check the current implementation"
        }
        
        with patch.object(hook, 'check_workspace_state') as mock_check:
            mock_check.return_value = {'is_clean': False, 'has_uncommitted_changes': True, 'has_open_prs': False}
            
            result = hook.process_hook("pretool", input_data)
            
            # Read tools should always be allowed regardless of workspace state
            self.assertEqual(result, 0)
    
    def test_performance_requirement_met(self):
        """Test that hook processing meets performance requirements (<10% overhead)."""
        import time
        from context_aware_hook import ContextAwareWorkflowHook
        
        hook = ContextAwareWorkflowHook()
        
        input_data = {
            "tool_name": "Edit", 
            "tool_input": {"file_path": "/test/file.py"},
            "user_message": "implement user authentication system"
        }
        
        with patch.object(hook, 'check_workspace_state') as mock_check:
            mock_check.return_value = {'is_clean': True, 'has_uncommitted_changes': False, 'has_open_prs': False}
            
            # Measure processing time
            start_time = time.time()
            hook.process_hook("pretool", input_data)
            end_time = time.time()
            
            processing_time = end_time - start_time
            
            # Should complete within reasonable time (allowing for test environment overhead)
            self.assertLess(processing_time, 0.5, "Hook processing should be fast")


class TestContextAwareHookCLI(unittest.TestCase):
    """Test command-line interface for the context-aware hook."""
    
    @patch('sys.argv', ['context_aware_hook.py', 'pretool'])
    @patch('sys.stdin')
    @patch('subprocess.run')
    def test_cli_main_function(self, mock_run, mock_stdin):
        """Test main CLI function processes hooks correctly."""
        from context_aware_hook import main
        
        # Mock clean workspace
        mock_run.side_effect = [
            Mock(stdout='', returncode=0),  # git status --porcelain
            Mock(stdout='[]', returncode=0)  # gh pr list  
        ]
        
        # Mock stdin input
        mock_stdin.read.return_value = json.dumps({
            "tool_name": "Edit",
            "tool_input": {"file_path": "/test/file.py"},
            "user_message": "implement new feature"
        })
        
        # Should exit with code 0 (allow) for clean workspace + new work
        with self.assertRaises(SystemExit) as context:
            main()
        
        self.assertEqual(context.exception.code, 0)
    
    @patch('sys.argv', ['context_aware_hook.py', 'pretool'])
    @patch('sys.stdin')
    @patch('subprocess.run')
    def test_cli_blocked_work(self, mock_run, mock_stdin):
        """Test CLI blocks work when appropriate."""
        from context_aware_hook import main
        
        # Mock dirty workspace
        mock_run.side_effect = [
            Mock(stdout=' M file.py\n', returncode=0),  # git status --porcelain
            Mock(stdout='[]', returncode=0)  # gh pr list
        ]
        
        # Mock stdin input for new work
        mock_stdin.read.return_value = json.dumps({
            "tool_name": "Write",
            "tool_input": {"file_path": "/test/new_file.py"},
            "user_message": "create user dashboard component"
        })
        
        # Should exit with code 2 (block with feedback)
        with self.assertRaises(SystemExit) as context:
            main()
        
        self.assertEqual(context.exception.code, 2)


if __name__ == '__main__':
    # Set up test environment
    os.environ["AGENT_OS_DEBUG"] = "false"  # Disable debug logging during tests
    
    unittest.main()