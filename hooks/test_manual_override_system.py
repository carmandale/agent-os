#!/usr/bin/env python3
"""
Tests for Agent OS Manual Override System
========================================
Test suite for the manual override functionality that allows users to bypass
workflow enforcement when needed, with clear messaging and configuration options.
"""

import os
import tempfile
import unittest
from unittest.mock import patch, mock_open, MagicMock
from io import StringIO
import sys

# Import modules to test (will be created)
try:
    from manual_override_system import ManualOverrideSystem, OverrideDecision, OverrideType
except ImportError:
    # Module doesn't exist yet - we'll create it
    ManualOverrideSystem = None
    OverrideDecision = None
    OverrideType = None


class TestManualOverrideSystem(unittest.TestCase):
    """Test suite for ManualOverrideSystem class."""
    
    def setUp(self):
        """Set up test fixtures."""
        if ManualOverrideSystem is None:
            self.skipTest("ManualOverrideSystem not yet implemented")
            
        self.override_system = ManualOverrideSystem()
        
        # Test configuration
        self.test_config = {
            'override_behavior': {
                'prompt_on_ambiguous': True,
                'allow_manual_override': True,
                'log_decisions': True,
                'default_override_choice': 'prompt'
            }
        }

    def test_command_line_flag_parsing(self):
        """Test command-line flag support for overrides."""
        # Test --force-new-work flag
        args = ['--force-new-work']
        result = self.override_system.parse_override_args(args)
        self.assertEqual(result.override_type, OverrideType.FORCE_NEW_WORK)
        
        # Test --force-maintenance flag  
        args = ['--force-maintenance']
        result = self.override_system.parse_override_args(args)
        self.assertEqual(result.override_type, OverrideType.FORCE_MAINTENANCE)
        
        # Test --interactive flag
        args = ['--interactive']
        result = self.override_system.parse_override_args(args)
        self.assertEqual(result.override_type, OverrideType.INTERACTIVE)
        
        # Test no flags (default behavior)
        args = []
        result = self.override_system.parse_override_args(args)
        self.assertEqual(result.override_type, OverrideType.NONE)

    @patch('builtins.input')
    def test_interactive_prompts_maintenance_choice(self, mock_input):
        """Test interactive prompt when user chooses maintenance work."""
        mock_input.return_value = 'm'
        
        result = self.override_system.prompt_for_disambiguation(
            "refactor the authentication system",
            confidence_maintenance=0.4,
            confidence_new_work=0.3
        )
        
        self.assertEqual(result.override_type, OverrideType.FORCE_MAINTENANCE)
        self.assertIn("maintenance", result.reasoning.lower())

    @patch('builtins.input')  
    def test_interactive_prompts_new_work_choice(self, mock_input):
        """Test interactive prompt when user chooses new work."""
        mock_input.return_value = 'n'
        
        result = self.override_system.prompt_for_disambiguation(
            "update the user interface",
            confidence_maintenance=0.3,
            confidence_new_work=0.4
        )
        
        self.assertEqual(result.override_type, OverrideType.FORCE_NEW_WORK)
        self.assertIn("new work", result.reasoning.lower())

    @patch('builtins.input')
    def test_interactive_prompts_abort_choice(self, mock_input):
        """Test interactive prompt when user chooses to abort."""
        mock_input.return_value = 'a'
        
        result = self.override_system.prompt_for_disambiguation(
            "work on the system",
            confidence_maintenance=0.2,
            confidence_new_work=0.2
        )
        
        self.assertEqual(result.override_type, OverrideType.ABORT)

    @patch('builtins.input')
    def test_interactive_prompts_invalid_input_retry(self, mock_input):
        """Test interactive prompt handles invalid input with retry."""
        # First invalid input, then valid choice
        mock_input.side_effect = ['x', 'invalid', 'm']
        
        result = self.override_system.prompt_for_disambiguation(
            "refactor something",
            confidence_maintenance=0.3,
            confidence_new_work=0.3
        )
        
        self.assertEqual(result.override_type, OverrideType.FORCE_MAINTENANCE)
        # Should have prompted 3 times (2 invalid + 1 valid)
        self.assertEqual(mock_input.call_count, 3)

    def test_override_decision_validation(self):
        """Test validation of override decisions."""
        # Valid override decision
        decision = OverrideDecision(
            override_type=OverrideType.FORCE_NEW_WORK,
            reasoning="User explicitly requested new work override",
            user_message="User chose new work from interactive prompt"
        )
        
        self.assertTrue(self.override_system.validate_override_decision(decision))
        
        # Invalid override decision (missing reasoning)
        invalid_decision = OverrideDecision(
            override_type=OverrideType.FORCE_MAINTENANCE,
            reasoning="",
            user_message=""
        )
        
        self.assertFalse(self.override_system.validate_override_decision(invalid_decision))

    @patch('manual_override_system.log_debug')
    def test_override_logging(self, mock_log):
        """Test that override decisions are properly logged."""
        decision = OverrideDecision(
            override_type=OverrideType.FORCE_NEW_WORK,
            reasoning="Command line override flag used",
            user_message="--force-new-work"
        )
        
        self.override_system.log_override_decision(decision, "test message")
        
        # Verify logging was called
        mock_log.assert_called()
        logged_message = mock_log.call_args[0][0]
        self.assertIn("FORCE_NEW_WORK", logged_message)
        self.assertIn("test message", logged_message)

    def test_configuration_loading(self):
        """Test loading override configuration from YAML."""
        config = {
            'override_behavior': {
                'prompt_on_ambiguous': False,
                'allow_manual_override': True,
                'log_decisions': False
            }
        }
        
        override_system = ManualOverrideSystem(config=config)
        
        self.assertFalse(override_system.config.prompt_on_ambiguous)
        self.assertTrue(override_system.config.allow_manual_override)
        self.assertFalse(override_system.config.log_decisions)

    def test_user_messaging_force_new_work(self):
        """Test user messaging when force new work override is used."""
        decision = OverrideDecision(
            override_type=OverrideType.FORCE_NEW_WORK,
            reasoning="Command line override",
            user_message="--force-new-work flag used"
        )
        
        message = self.override_system.get_user_message(decision)
        
        self.assertIn("new work", message.lower())
        self.assertIn("override", message.lower())
        self.assertIn("workspace", message.lower())

    def test_user_messaging_force_maintenance(self):
        """Test user messaging when force maintenance override is used."""
        decision = OverrideDecision(
            override_type=OverrideType.FORCE_MAINTENANCE,
            reasoning="Interactive prompt selection",
            user_message="User selected maintenance work"
        )
        
        message = self.override_system.get_user_message(decision)
        
        self.assertIn("maintenance", message.lower())
        self.assertIn("allowed", message.lower())

    def test_integration_with_intent_analyzer_results(self):
        """Test override system integration with ambiguous intent results."""
        from intent_analyzer import WorkIntentResult, IntentType
        
        # Simulate ambiguous intent result
        ambiguous_result = WorkIntentResult(
            intent_type=IntentType.AMBIGUOUS,
            confidence=0.2,
            matched_patterns=[],
            reasoning="Low confidence scores for both maintenance and new work"
        )
        
        # Test that override system can handle ambiguous results
        override_available = self.override_system.can_override(ambiguous_result)
        self.assertTrue(override_available)

    def test_educational_messaging(self):
        """Test educational messaging about maintenance vs new work."""
        help_message = self.override_system.get_educational_message()
        
        # Should explain both work types
        self.assertIn("maintenance work", help_message.lower())
        self.assertIn("new work", help_message.lower())
        
        # Should explain when each is appropriate
        self.assertIn("fix", help_message.lower())
        self.assertIn("debug", help_message.lower())
        self.assertIn("implement", help_message.lower())
        self.assertIn("create", help_message.lower())

    def test_override_disabled_in_config(self):
        """Test behavior when manual overrides are disabled in config."""
        config = {
            'override_behavior': {
                'allow_manual_override': False
            }
        }
        
        override_system = ManualOverrideSystem(config=config)
        
        # Should not allow any overrides when disabled
        result = override_system.parse_override_args(['--force-new-work'])
        self.assertEqual(result.override_type, OverrideType.DISABLED)

    def test_performance_requirement(self):
        """Test that override processing meets performance requirements."""
        import time
        
        start_time = time.time()
        
        # Test typical override decision processing
        result = self.override_system.parse_override_args(['--force-new-work'])
        message = self.override_system.get_user_message(result)
        
        processing_time = time.time() - start_time
        
        # Should complete quickly (much less than 100ms)
        self.assertLess(processing_time, 0.1)


class TestOverrideDecision(unittest.TestCase):
    """Test suite for OverrideDecision data class."""
    
    def test_override_decision_creation(self):
        """Test OverrideDecision creation and properties."""
        if OverrideDecision is None:
            self.skipTest("OverrideDecision not yet implemented")
            
        decision = OverrideDecision(
            override_type=OverrideType.FORCE_NEW_WORK,
            reasoning="User requested new work via flag",
            user_message="--force-new-work flag provided"
        )
        
        self.assertEqual(decision.override_type, OverrideType.FORCE_NEW_WORK)
        self.assertEqual(decision.reasoning, "User requested new work via flag")
        self.assertEqual(decision.user_message, "--force-new-work flag provided")


class TestOverrideIntegration(unittest.TestCase):
    """Test suite for integration with existing hook system."""
    
    def setUp(self):
        """Set up integration test fixtures."""
        if ManualOverrideSystem is None:
            self.skipTest("ManualOverrideSystem not yet implemented")
            
        self.override_system = ManualOverrideSystem()

    @patch('subprocess.run')
    def test_integration_with_hook_execution(self, mock_subprocess):
        """Test that overrides properly integrate with hook execution."""
        # Mock successful hook execution
        mock_subprocess.return_value.returncode = 0
        mock_subprocess.return_value.stdout = "Hook executed successfully"
        
        # Test override allows work that would normally be blocked
        decision = OverrideDecision(
            override_type=OverrideType.FORCE_NEW_WORK,
            reasoning="Command line override",
            user_message="--force-new-work"
        )
        
        # This would normally be blocked but override should allow it
        result = self.override_system.apply_override_to_hook_decision(
            original_decision=False,  # Hook would block
            override_decision=decision,
            user_message="implement new dashboard"
        )
        
        self.assertTrue(result.allow_work)
        self.assertIn("override", result.reasoning.lower())

    def test_override_preserves_original_behavior_when_none(self):
        """Test that no override preserves original hook behavior."""
        decision = OverrideDecision(
            override_type=OverrideType.NONE,
            reasoning="No override requested",
            user_message=""
        )
        
        # Should preserve original hook decision
        result = self.override_system.apply_override_to_hook_decision(
            original_decision=True,  # Hook allows work
            override_decision=decision,
            user_message="fix failing tests"
        )
        
        self.assertTrue(result.allow_work)
        
        # Test with blocking decision
        result = self.override_system.apply_override_to_hook_decision(
            original_decision=False,  # Hook blocks work
            override_decision=decision,
            user_message="implement new feature"
        )
        
        self.assertFalse(result.allow_work)


if __name__ == '__main__':
    # Run tests with verbose output
    unittest.main(verbosity=2)