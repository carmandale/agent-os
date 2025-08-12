#!/usr/bin/env python3
"""
Tests for Agent OS User Experience System
========================================
Test suite for user experience enhancements including feedback messages,
guidance when work is blocked/allowed, and debugging output functionality.
"""

import os
import tempfile
import unittest
from unittest.mock import patch, mock_open, MagicMock
from io import StringIO
import sys

# Import existing modules
from intent_analyzer import IntentAnalyzer, WorkIntentResult, IntentType
from manual_override_system import ManualOverrideSystem, OverrideDecision, OverrideType

# Import modules to test (will be created)
try:
    from user_experience_system import UserExperienceSystem, FeedbackMessage, GuidanceType
except ImportError:
    # Module doesn't exist yet - we'll create it
    UserExperienceSystem = None
    FeedbackMessage = None
    GuidanceType = None


class TestUserExperienceSystem(unittest.TestCase):
    """Test suite for UserExperienceSystem class."""
    
    def setUp(self):
        """Set up test fixtures."""
        if UserExperienceSystem is None:
            self.skipTest("UserExperienceSystem not yet implemented")
            
        self.ux_system = UserExperienceSystem()
        self.intent_analyzer = IntentAnalyzer()
        
        # Test intent results for different scenarios
        self.maintenance_result = WorkIntentResult(
            intent_type=IntentType.MAINTENANCE,
            confidence=0.85,
            matched_patterns=["fix.*tests", "debug"],
            reasoning="Matched maintenance patterns for bug fixing"
        )
        
        self.new_work_result = WorkIntentResult(
            intent_type=IntentType.NEW_WORK,
            confidence=0.92,
            matched_patterns=["implement.*dashboard", "create.*feature"],
            reasoning="Matched new work patterns for feature development"
        )
        
        self.ambiguous_result = WorkIntentResult(
            intent_type=IntentType.AMBIGUOUS,
            confidence=0.25,
            matched_patterns=[],
            reasoning="Low confidence scores for both work types"
        )

    def test_intent_detection_feedback_maintenance_work(self):
        """Test feedback messages for maintenance work detection."""
        feedback = self.ux_system.create_intent_feedback(
            self.maintenance_result,
            user_message="fix the failing authentication tests"
        )
        
        self.assertEqual(feedback.message_type, GuidanceType.ALLOWED_MAINTENANCE)
        self.assertIn("maintenance work", feedback.message.lower())
        self.assertIn("allowed", feedback.message.lower())
        self.assertIn("0.85", feedback.message)  # Should show confidence
        self.assertIn("fix.*tests", feedback.message)  # Should show matched patterns

    def test_intent_detection_feedback_new_work(self):
        """Test feedback messages for new work detection."""
        feedback = self.ux_system.create_intent_feedback(
            self.new_work_result,
            user_message="implement user dashboard feature"
        )
        
        self.assertEqual(feedback.message_type, GuidanceType.NEW_WORK_GUIDANCE)
        self.assertIn("new work", feedback.message.lower())
        self.assertIn("dashboard", feedback.message.lower())
        self.assertIn("0.92", feedback.message)  # Should show confidence
        self.assertIn("workspace", feedback.message.lower())  # Should mention workspace requirements

    def test_intent_detection_feedback_ambiguous(self):
        """Test feedback messages for ambiguous intent detection."""
        feedback = self.ux_system.create_intent_feedback(
            self.ambiguous_result,
            user_message="update the authentication system"
        )
        
        self.assertEqual(feedback.message_type, GuidanceType.AMBIGUOUS_GUIDANCE)
        self.assertIn("ambiguous", feedback.message.lower())
        self.assertIn("clarification", feedback.message.lower())
        self.assertIn("0.25", feedback.message)  # Should show low confidence

    def test_blocked_work_guidance_dirty_workspace(self):
        """Test guidance messages when work is blocked due to dirty workspace."""
        workspace_state = {
            'has_uncommitted_changes': True,
            'has_untracked_files': False,
            'has_open_prs': True,
            'current_branch': 'feature-branch'
        }
        
        guidance = self.ux_system.create_blocked_work_guidance(
            self.new_work_result,
            workspace_state,
            "implement new payment system"
        )
        
        self.assertEqual(guidance.message_type, GuidanceType.BLOCKED_NEW_WORK)
        self.assertIn("new work", guidance.message.lower())
        self.assertIn("clean workspace", guidance.message.lower())
        self.assertIn("uncommitted changes", guidance.message.lower())
        self.assertIn("open PRs", guidance.message.lower())
        # Should provide specific next steps
        self.assertIn("git", guidance.message.lower())

    def test_allowed_work_confirmation_maintenance(self):
        """Test confirmation messages when maintenance work is allowed."""
        workspace_state = {
            'has_uncommitted_changes': True,
            'has_untracked_files': True,
            'has_open_prs': True,
            'current_branch': 'feature-branch'
        }
        
        confirmation = self.ux_system.create_allowed_work_confirmation(
            self.maintenance_result,
            workspace_state,
            "fix authentication bug in login flow"
        )
        
        self.assertEqual(confirmation.message_type, GuidanceType.ALLOWED_MAINTENANCE)
        self.assertIn("proceeding", confirmation.message.lower())
        self.assertIn("maintenance", confirmation.message.lower())
        self.assertIn("authentication", confirmation.message.lower())
        # Should acknowledge current workspace state
        self.assertIn("uncommitted", confirmation.message.lower())

    def test_educational_messaging_context_specific(self):
        """Test educational messaging tailored to specific context."""
        educational_msg = self.ux_system.create_educational_message(
            context="blocked_new_work",
            user_message="create user profile dashboard"
        )
        
        self.assertIn("new work", educational_msg.lower())
        self.assertIn("dashboard", educational_msg.lower())
        self.assertIn("spec", educational_msg.lower())
        self.assertIn("clean workspace", educational_msg.lower())
        # Should explain why these requirements exist
        self.assertIn("why", educational_msg.lower())

    def test_educational_messaging_maintenance_context(self):
        """Test educational messaging for maintenance work context."""
        educational_msg = self.ux_system.create_educational_message(
            context="allowed_maintenance",
            user_message="fix failing CI tests"
        )
        
        self.assertIn("maintenance", educational_msg.lower())
        self.assertIn("fix", educational_msg.lower())
        self.assertIn("allowed", educational_msg.lower())
        # Should explain maintenance work benefits
        self.assertIn("dirty workspace", educational_msg.lower())

    def test_debugging_output_verbose_mode(self):
        """Test debugging output in verbose mode."""
        with patch.dict(os.environ, {'AGENT_OS_DEBUG_VERBOSE': 'true'}):
            debug_info = self.ux_system.create_debug_output(
                self.maintenance_result,
                user_message="debug authentication issues",
                processing_time=0.025,
                pattern_matches={
                    'maintenance': ['debug', 'authentication.*issues'],
                    'new_work': []
                }
            )
            
            self.assertIn("VERBOSE DEBUG", debug_info)
            self.assertIn("0.025", debug_info)  # Processing time
            self.assertIn("debug", debug_info)  # Matched patterns
            self.assertIn("authentication.*issues", debug_info)
            self.assertIn("maintenance: 2 matches", debug_info)  # Match counts

    def test_confidence_score_explanation(self):
        """Test confidence score explanations for users."""
        explanation = self.ux_system.explain_confidence_score(
            confidence=0.75,
            pattern_matches=["fix.*tests", "debug.*authentication"],
            total_patterns=20
        )
        
        self.assertIn("75%", explanation)
        self.assertIn("confident", explanation)
        self.assertIn("2 out of 20", explanation)  # Pattern match ratio
        self.assertIn("fix.*tests", explanation)  # Should list matched patterns

    def test_confidence_score_explanation_low(self):
        """Test confidence score explanations for low confidence."""
        explanation = self.ux_system.explain_confidence_score(
            confidence=0.15,
            pattern_matches=[],
            total_patterns=20
        )
        
        self.assertIn("15%", explanation)
        self.assertIn("low confidence", explanation.lower())
        self.assertIn("0 out of 20", explanation)  # No pattern matches
        self.assertIn("unclear", explanation.lower())

    def test_next_step_guidance_blocked_work(self):
        """Test next step guidance for blocked work scenarios."""
        workspace_state = {
            'has_uncommitted_changes': True,
            'has_untracked_files': False,
            'has_open_prs': True,
            'current_branch': 'feature-branch'
        }
        
        next_steps = self.ux_system.create_next_step_guidance(
            scenario="blocked_new_work",
            workspace_state=workspace_state,
            user_message="implement notification system"
        )
        
        # Should provide ordered steps
        self.assertIn("1.", next_steps)
        self.assertIn("2.", next_steps)
        self.assertIn("git add", next_steps.lower())
        self.assertIn("git commit", next_steps.lower())
        self.assertIn("merge", next_steps.lower())  # For open PRs

    def test_next_step_guidance_maintenance_work(self):
        """Test next step guidance for allowed maintenance work."""
        workspace_state = {
            'has_uncommitted_changes': True,
            'has_untracked_files': True,
            'has_open_prs': False,
            'current_branch': 'main'
        }
        
        next_steps = self.ux_system.create_next_step_guidance(
            scenario="allowed_maintenance",
            workspace_state=workspace_state,
            user_message="fix broken test suite"
        )
        
        # Should encourage proceeding with maintenance
        self.assertIn("proceed", next_steps.lower())
        self.assertIn("fix", next_steps.lower())
        self.assertIn("test", next_steps.lower())
        # Should mention committing when done
        self.assertIn("commit", next_steps.lower())

    def test_pattern_match_explanation(self):
        """Test explanation of pattern matches for transparency."""
        explanation = self.ux_system.explain_pattern_matches(
            matched_patterns=["fix.*tests", "debug.*authentication"],
            user_message="fix authentication tests that are failing"
        )
        
        self.assertIn("fix.*tests", explanation)
        self.assertIn("debug.*authentication", explanation)
        self.assertIn("authentication tests", explanation)  # Should highlight matching text
        self.assertIn("2 patterns", explanation)

    def test_workspace_state_explanation(self):
        """Test explanation of workspace state for users."""
        workspace_state = {
            'has_uncommitted_changes': True,
            'has_untracked_files': False,
            'has_open_prs': True,
            'current_branch': 'feature-dashboard',
            'uncommitted_files': ['src/auth.py', 'tests/test_auth.py']
        }
        
        explanation = self.ux_system.explain_workspace_state(workspace_state)
        
        self.assertIn("uncommitted changes", explanation.lower())
        self.assertIn("open PR", explanation.lower())
        self.assertIn("feature-dashboard", explanation)  # Branch name
        self.assertIn("src/auth.py", explanation)  # Specific files
        self.assertIn("tests/test_auth.py", explanation)

    def test_integration_with_manual_override_system(self):
        """Test integration with existing manual override system."""
        override_system = ManualOverrideSystem()
        
        # Test that UX system can enhance override messaging
        override_decision = OverrideDecision(
            override_type=OverrideType.FORCE_MAINTENANCE,
            reasoning="User selected maintenance via interactive prompt",
            user_message="User chose maintenance work"
        )
        
        enhanced_message = self.ux_system.enhance_override_message(
            override_decision,
            self.maintenance_result,
            "fix authentication bug"
        )
        
        self.assertIn("override", enhanced_message.lower())
        self.assertIn("maintenance", enhanced_message.lower())
        self.assertIn("authentication", enhanced_message.lower())
        # Should include intent detection context
        self.assertIn("detected", enhanced_message.lower())

    def test_performance_debugging_metrics(self):
        """Test performance metrics in debug output."""
        debug_info = self.ux_system.create_performance_debug_output(
            intent_analysis_time=0.015,
            pattern_matching_time=0.008,
            total_processing_time=0.025,
            memory_usage_mb=2.4
        )
        
        self.assertIn("0.015", debug_info)  # Intent analysis time
        self.assertIn("0.008", debug_info)  # Pattern matching time
        self.assertIn("0.025", debug_info)  # Total time
        self.assertIn("2.4", debug_info)    # Memory usage
        self.assertIn("Performance", debug_info)

    def test_error_message_enhancement(self):
        """Test enhancement of error messages with helpful context."""
        enhanced_error = self.ux_system.enhance_error_message(
            error="Pattern compilation failed",
            context={
                'pattern': r'\bfix\b.*\btests?\b',
                'user_message': 'fix the failing tests',
                'config_file': '/Users/test/.agent-os/config/workflow-enforcement.yaml'
            }
        )
        
        self.assertIn("Pattern compilation failed", enhanced_error)
        self.assertIn("fix.*tests", enhanced_error)
        self.assertIn("config", enhanced_error.lower())
        self.assertIn("workflow-enforcement.yaml", enhanced_error)
        # Should provide guidance for fixing
        self.assertIn("check", enhanced_error.lower())


class TestFeedbackMessage(unittest.TestCase):
    """Test suite for FeedbackMessage data class."""
    
    def test_feedback_message_creation(self):
        """Test FeedbackMessage creation and properties."""
        if FeedbackMessage is None:
            self.skipTest("FeedbackMessage not yet implemented")
            
        message = FeedbackMessage(
            message_type=GuidanceType.ALLOWED_MAINTENANCE,
            message="Maintenance work detected and allowed to proceed",
            confidence_display="High (85%)",
            next_steps=["Proceed with fixing the bug", "Commit changes when done"]
        )
        
        self.assertEqual(message.message_type, GuidanceType.ALLOWED_MAINTENANCE)
        self.assertIn("Maintenance work", message.message)
        self.assertEqual(message.confidence_display, "High (85%)")
        self.assertEqual(len(message.next_steps), 2)


class TestIntegrationWithExistingSystems(unittest.TestCase):
    """Test suite for integration with existing intent analyzer and override system."""
    
    def setUp(self):
        """Set up integration test fixtures."""
        if UserExperienceSystem is None:
            self.skipTest("UserExperienceSystem not yet implemented")
            
        self.ux_system = UserExperienceSystem()
        self.intent_analyzer = IntentAnalyzer()
        self.override_system = ManualOverrideSystem()

    def test_end_to_end_user_experience_flow(self):
        """Test complete user experience flow from intent detection to guidance."""
        user_message = "fix the failing authentication tests"
        
        # Step 1: Intent detection
        intent_result = self.intent_analyzer.analyze_intent(user_message)
        
        # Step 2: Create user feedback
        feedback = self.ux_system.create_intent_feedback(intent_result, user_message)
        
        # Step 3: Provide guidance based on result
        workspace_state = {'has_uncommitted_changes': True, 'has_open_prs': False}
        confirmation = self.ux_system.create_allowed_work_confirmation(
            intent_result, workspace_state, user_message
        )
        
        # Verify complete flow works
        self.assertEqual(intent_result.intent_type, IntentType.MAINTENANCE)
        self.assertEqual(feedback.message_type, GuidanceType.ALLOWED_MAINTENANCE)
        self.assertIn("fix", confirmation.message.lower())
        self.assertIn("authentication", confirmation.message.lower())

    def test_ambiguous_intent_to_override_flow(self):
        """Test flow from ambiguous intent to override system integration."""
        user_message = "update the user authentication system"
        
        # Step 1: Intent detection (should be ambiguous)
        intent_result = self.intent_analyzer.analyze_intent(user_message)
        
        # Step 2: Create ambiguous guidance
        ambiguous_feedback = self.ux_system.create_intent_feedback(intent_result, user_message)
        
        # Step 3: Show educational content
        educational_content = self.ux_system.create_educational_message(
            context="ambiguous_intent",
            user_message=user_message
        )
        
        # Verify ambiguous handling
        self.assertEqual(intent_result.intent_type, IntentType.AMBIGUOUS)
        self.assertEqual(ambiguous_feedback.message_type, GuidanceType.AMBIGUOUS_GUIDANCE)
        self.assertIn("clarification", ambiguous_feedback.message.lower())
        self.assertIn("maintenance", educational_content.lower())
        self.assertIn("new work", educational_content.lower())


if __name__ == '__main__':
    # Run tests with verbose output
    unittest.main(verbosity=2)