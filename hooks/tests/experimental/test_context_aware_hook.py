#!/usr/bin/env python3
"""
Test suite for the Context-Aware Workflow Hook.

Tests the integration of intent analysis with workflow enforcement,
ensuring maintenance work is allowed while new work requires clean workspace.
"""

import unittest
from unittest.mock import patch, MagicMock, call
import os
import sys
import json
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))


class TestContextAwareWorkflowHook(unittest.TestCase):
    """Test suite for ContextAwareWorkflowHook."""
    
    def setUp(self):
        """Set up test fixtures."""
        # Import will happen after implementation exists
        # Clear any environment variables
        os.environ.pop('AGENT_OS_WORK_TYPE', None)
        os.environ.pop('AGENT_OS_BYPASS', None)
    
    def tearDown(self):
        """Clean up after tests."""
        # Clear any environment variables
        os.environ.pop('AGENT_OS_WORK_TYPE', None)
        os.environ.pop('AGENT_OS_BYPASS', None)
    
    # Test Workspace State Detection
    
    @patch('subprocess.run')
    def test_clean_workspace_detection(self, mock_run):
        """Test detection of clean workspace."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        hook = ContextAwareWorkflowHook()
        
        # Mock git status showing clean workspace
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="",
            stderr=""
        )
        
        state = hook.get_workspace_state()
        
        self.assertFalse(state.has_uncommitted_changes)
        self.assertFalse(state.has_open_prs)
        self.assertTrue(state.is_clean)
    
    @patch('subprocess.run')
    def test_dirty_workspace_detection(self, mock_run):
        """Test detection of dirty workspace with uncommitted changes."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        hook = ContextAwareWorkflowHook()
        
        # Mock git status showing uncommitted changes
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="M  hooks/some_file.py\nA  hooks/new_file.py",
            stderr=""
        )
        
        state = hook.get_workspace_state()
        
        self.assertTrue(state.has_uncommitted_changes)
        self.assertFalse(state.is_clean)
    
    @patch('subprocess.run')
    def test_open_pr_detection(self, mock_run):
        """Test detection of open pull requests."""
        from context_aware_hook import ContextAwareWorkflowHook
        
        hook = ContextAwareWorkflowHook()
        
        def side_effect(*args, **kwargs):
            cmd = args[0]
            if 'git status' in ' '.join(cmd):
                return MagicMock(returncode=0, stdout="", stderr="")
            elif 'gh pr list' in ' '.join(cmd):
                # Mock open PR
                pr_data = [{"number": 123, "title": "Test PR", "state": "OPEN"}]
                return MagicMock(returncode=0, stdout=json.dumps(pr_data), stderr="")
            return MagicMock(returncode=1, stdout="", stderr="error")
        
        mock_run.side_effect = side_effect
        
        state = hook.get_workspace_state()
        
        self.assertTrue(state.has_open_prs)
        self.assertEqual(len(state.open_pr_numbers), 1)
        self.assertEqual(state.open_pr_numbers[0], 123)
    
    # Test Intent-Based Decision Making
    
    def test_maintenance_work_allowed_with_dirty_workspace(self):
        """Test that maintenance work is allowed even with dirty workspace."""
        from context_aware_hook import ContextAwareWorkflowHook, WorkspaceState
        
        hook = ContextAwareWorkflowHook()
        user_message = "fix failing tests in the current PR"
        
        # Create dirty workspace state
        workspace_state = WorkspaceState(
            has_uncommitted_changes=True,
            has_open_prs=True,
            open_pr_numbers=[123],
            is_clean=False
        )
        
        decision = hook.make_decision(user_message, workspace_state)
        
        self.assertEqual(decision.action, 'allow')
        self.assertEqual(decision.work_type, 'maintenance')
        # Accept various forms of maintenance reasoning
        self.assertTrue(
            'maintenance' in decision.reason.lower() or
            'matched' in decision.reason.lower(),
            f"Expected maintenance-related reason, got: {decision.reason}"
        )
    
    def test_new_work_blocked_with_dirty_workspace(self):
        """Test that new work is blocked when workspace is dirty."""
        from context_aware_hook import ContextAwareWorkflowHook, WorkspaceState
        
        hook = ContextAwareWorkflowHook()
        user_message = "implement user authentication feature"
        
        # Create dirty workspace state
        workspace_state = WorkspaceState(
            has_uncommitted_changes=True,
            has_open_prs=True,
            open_pr_numbers=[123],
            is_clean=False
        )
        
        decision = hook.make_decision(user_message, workspace_state)
        
        self.assertEqual(decision.action, 'block')
        self.assertEqual(decision.work_type, 'new_work')
        # Accept various forms of new work blocking reasoning
        self.assertTrue(
            'clean workspace' in decision.reason.lower() or
            'new_work' in decision.reason.lower() or
            'matched' in decision.reason.lower(),
            f"Expected new work blocking reason, got: {decision.reason}"
        )
    
    def test_new_work_allowed_with_clean_workspace(self):
        """Test that new work is allowed when workspace is clean."""
        from context_aware_hook import ContextAwareWorkflowHook, WorkspaceState
        
        hook = ContextAwareWorkflowHook()
        user_message = "implement user authentication feature"
        
        # Create clean workspace state
        workspace_state = WorkspaceState(
            has_uncommitted_changes=False,
            has_open_prs=False,
            open_pr_numbers=[],
            is_clean=True
        )
        
        decision = hook.make_decision(user_message, workspace_state)
        
        self.assertEqual(decision.action, 'allow')
        self.assertEqual(decision.work_type, 'new_work')
    
    # Test Manual Override Mechanisms
    
    def test_environment_variable_override_maintenance(self):
        """Test AGENT_OS_WORK_TYPE=maintenance override."""
        from context_aware_hook import ContextAwareWorkflowHook, WorkspaceState
        
        os.environ['AGENT_OS_WORK_TYPE'] = 'maintenance'
        hook = ContextAwareWorkflowHook()
        
        user_message = "do some work"  # Ambiguous message
        workspace_state = WorkspaceState(
            has_uncommitted_changes=True,
            has_open_prs=True,
            open_pr_numbers=[123],
            is_clean=False
        )
        
        decision = hook.make_decision(user_message, workspace_state)
        
        self.assertEqual(decision.action, 'allow')
        self.assertEqual(decision.work_type, 'maintenance')
        self.assertIn('manual override', decision.reason.lower())
    
    def test_environment_variable_override_new_work(self):
        """Test AGENT_OS_WORK_TYPE=new_work override."""
        from context_aware_hook import ContextAwareWorkflowHook, WorkspaceState
        
        os.environ['AGENT_OS_WORK_TYPE'] = 'new_work'
        hook = ContextAwareWorkflowHook()
        
        user_message = "fix tests"  # Would normally be maintenance
        workspace_state = WorkspaceState(
            has_uncommitted_changes=False,
            has_open_prs=False,
            open_pr_numbers=[],
            is_clean=True
        )
        
        decision = hook.make_decision(user_message, workspace_state)
        
        self.assertEqual(decision.work_type, 'new_work')
        self.assertIn('manual override', decision.reason.lower())
    
    def test_bypass_flag(self):
        """Test AGENT_OS_BYPASS flag to skip all checks."""
        from context_aware_hook import ContextAwareWorkflowHook, WorkspaceState
        
        os.environ['AGENT_OS_BYPASS'] = 'true'
        hook = ContextAwareWorkflowHook()
        
        user_message = "any work"
        workspace_state = WorkspaceState(
            has_uncommitted_changes=True,
            has_open_prs=True,
            open_pr_numbers=[123],
            is_clean=False
        )
        
        decision = hook.make_decision(user_message, workspace_state)
        
        self.assertEqual(decision.action, 'allow')
        self.assertIn('bypass', decision.reason.lower())
    
    # Test Ambiguous Intent Handling
    
    @patch('builtins.input')
    def test_ambiguous_intent_prompting(self, mock_input):
        """Test user prompting for ambiguous intent."""
        from context_aware_hook import ContextAwareWorkflowHook, WorkspaceState
        
        mock_input.return_value = 'maintenance'
        hook = ContextAwareWorkflowHook()
        
        user_message = "work on the code"  # Ambiguous
        workspace_state = WorkspaceState(
            has_uncommitted_changes=True,
            has_open_prs=True,
            open_pr_numbers=[123],
            is_clean=False
        )
        
        decision = hook.make_decision(user_message, workspace_state)
        
        # Should prompt user and then allow maintenance work
        mock_input.assert_called_once()
        self.assertEqual(decision.action, 'allow')
        self.assertEqual(decision.work_type, 'maintenance')
    
    # Test Performance
    
    def test_performance_requirement(self):
        """Test that decision making meets performance requirements."""
        from context_aware_hook import ContextAwareWorkflowHook, WorkspaceState
        import time
        
        hook = ContextAwareWorkflowHook()
        user_message = "implement new feature with complex requirements"
        workspace_state = WorkspaceState(
            has_uncommitted_changes=False,
            has_open_prs=False,
            open_pr_numbers=[],
            is_clean=True
        )
        
        start_time = time.time()
        decision = hook.make_decision(user_message, workspace_state)
        elapsed_time = time.time() - start_time
        
        # Should complete within 100ms (with significant margin)
        self.assertLess(elapsed_time, 0.1)


if __name__ == '__main__':
    # Note: Tests will fail until implementation is complete
    print("Note: Running tests before implementation exists will fail.")
    print("This is expected in TDD - tests are written first.")
    unittest.main()