#!/usr/bin/env python3
"""
Tests for Agent OS Intent Analysis Engine
========================================
Comprehensive test suite for the IntentAnalyzer class that distinguishes
between maintenance work and new development work based on user messages.
"""

import os
import tempfile
import unittest
from unittest.mock import patch, mock_open
import yaml
from intent_analyzer import IntentAnalyzer, WorkIntentResult, IntentType


class TestIntentAnalyzer(unittest.TestCase):
    """Test suite for IntentAnalyzer class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.analyzer = IntentAnalyzer()
        
        # Test message datasets
        self.maintenance_messages = [
            "fix the failing unit tests",
            "debug authentication issues",
            "resolve merge conflicts in PR #123",
            "address CI pipeline failures",
            "fix bug in user validation",
            "update dependencies to resolve security issues",
            "refactor existing code without adding new features",
            "fix broken styles in the login page",
            "debug performance issues in the API",
            "resolve TypeScript compilation errors"
        ]
        
        self.new_work_messages = [
            "implement user profile dashboard",
            "build new authentication system", 
            "create payment processing feature",
            "add real-time notifications",
            "develop admin panel interface",
            "implement OAuth integration",
            "create user management system",
            "build responsive mobile interface",
            "add advanced search functionality",
            "develop API rate limiting"
        ]
        
        self.ambiguous_messages = [
            "update the user authentication system",
            "refactor the database layer",
            "improve the UI components", 
            "work on the API endpoints",
            "handle the user management features",
            "enhance the notification system",
            "modify the payment processing",
            "adjust the admin interface",
            "change the authentication flow",
            "update user profile functionality"
        ]
        
        self.edge_case_messages = [
            "",  # Empty message
            "   ",  # Whitespace only
            "a" * 1000,  # Very long message
            "fix @#$%^&*() special chars",  # Special characters
            "FIX THE FAILING TESTS",  # All caps
            "Fix The Failing Tests",  # Mixed case
        ]

    def test_maintenance_work_detection(self):
        """Test that maintenance work messages are correctly identified."""
        for message in self.maintenance_messages:
            with self.subTest(message=message):
                result = self.analyzer.analyze_intent(message)
                self.assertEqual(result.intent_type, IntentType.MAINTENANCE,
                    f"Message '{message}' should be detected as maintenance work")
                self.assertGreater(result.confidence, 0.5,
                    f"Confidence should be > 0.5 for maintenance message: {message}")

    def test_new_work_detection(self):
        """Test that new work messages are correctly identified."""
        for message in self.new_work_messages:
            with self.subTest(message=message):
                result = self.analyzer.analyze_intent(message)
                self.assertEqual(result.intent_type, IntentType.NEW_WORK,
                    f"Message '{message}' should be detected as new work")
                self.assertGreater(result.confidence, 0.5,
                    f"Confidence should be > 0.5 for new work message: {message}")

    def test_ambiguous_intent_detection(self):
        """Test that ambiguous messages are correctly identified."""
        for message in self.ambiguous_messages:
            with self.subTest(message=message):
                result = self.analyzer.analyze_intent(message)
                self.assertEqual(result.intent_type, IntentType.AMBIGUOUS,
                    f"Message '{message}' should be detected as ambiguous")
                self.assertLessEqual(result.confidence, 0.7,
                    f"Confidence should be <= 0.7 for ambiguous message: {message}")

    def test_edge_cases(self):
        """Test edge cases and boundary conditions."""
        # Empty message
        result = self.analyzer.analyze_intent("")
        self.assertEqual(result.intent_type, IntentType.AMBIGUOUS)
        
        # Whitespace only
        result = self.analyzer.analyze_intent("   ")
        self.assertEqual(result.intent_type, IntentType.AMBIGUOUS)
        
        # Very long message
        long_message = "fix the failing tests " * 100
        result = self.analyzer.analyze_intent(long_message)
        self.assertEqual(result.intent_type, IntentType.MAINTENANCE)
        
        # Special characters
        result = self.analyzer.analyze_intent("fix @#$%^&*() authentication issues")
        self.assertEqual(result.intent_type, IntentType.MAINTENANCE)

    def test_case_insensitive_matching(self):
        """Test that pattern matching is case insensitive."""
        test_cases = [
            ("FIX THE FAILING TESTS", IntentType.MAINTENANCE),
            ("Fix The Failing Tests", IntentType.MAINTENANCE),
            ("IMPLEMENT USER DASHBOARD", IntentType.NEW_WORK),
            ("Implement User Dashboard", IntentType.NEW_WORK),
        ]
        
        for message, expected_type in test_cases:
            with self.subTest(message=message):
                result = self.analyzer.analyze_intent(message)
                self.assertEqual(result.intent_type, expected_type)

    def test_performance_requirement(self):
        """Test that intent analysis completes within performance requirements."""
        import time
        
        message = "fix the failing authentication tests in the user module"
        
        # Measure analysis time
        start_time = time.time()
        result = self.analyzer.analyze_intent(message)
        analysis_time = time.time() - start_time
        
        # Should complete in under 100ms
        self.assertLess(analysis_time, 0.1, 
            f"Intent analysis took {analysis_time:.3f}s, should be < 0.1s")
        self.assertIsInstance(result, WorkIntentResult)


class TestWorkIntentResult(unittest.TestCase):
    """Test suite for WorkIntentResult data class."""
    
    def test_result_creation(self):
        """Test WorkIntentResult creation and properties."""
        result = WorkIntentResult(
            intent_type=IntentType.MAINTENANCE,
            confidence=0.85,
            matched_patterns=["fix.*tests"],
            reasoning="Matched maintenance pattern: fix tests"
        )
        
        self.assertEqual(result.intent_type, IntentType.MAINTENANCE)
        self.assertEqual(result.confidence, 0.85)
        self.assertEqual(result.matched_patterns, ["fix.*tests"])
        self.assertEqual(result.reasoning, "Matched maintenance pattern: fix tests")
    
    def test_result_string_representation(self):
        """Test string representation of WorkIntentResult."""
        result = WorkIntentResult(
            intent_type=IntentType.NEW_WORK,
            confidence=0.9,
            matched_patterns=["implement.*feature"],
            reasoning="Matched new work pattern: implement feature"
        )
        
        result_str = str(result)
        self.assertIn("NEW_WORK", result_str)
        self.assertIn("0.9", result_str)


class TestConfigurationLoading(unittest.TestCase):
    """Test suite for configuration loading and validation."""
    
    def setUp(self):
        """Set up test configuration."""
        self.test_config = {
            'maintenance_patterns': [
                r'\bfix\b.*\btests?\b',
                r'\bdebug\b',
                r'\bresolve\b.*\bconflict',
            ],
            'new_work_patterns': [
                r'\bimplement\b.*\bfeature\b',
                r'\bbuild\b.*\bnew\b',
                r'\bcreate\b.*\bcomponent\b',
            ],
            'confidence_threshold': 0.6,
            'ambiguous_threshold': 0.3
        }
    
    @patch('builtins.open', new_callable=mock_open)
    @patch('os.path.exists')
    def test_config_loading_success(self, mock_exists, mock_file):
        """Test successful configuration loading."""
        mock_exists.return_value = True
        mock_file.return_value.read.return_value = yaml.dump(self.test_config)
        
        analyzer = IntentAnalyzer(config_path="test_config.yaml")
        
        # Verify patterns were loaded
        self.assertEqual(len(analyzer.maintenance_patterns), 3)
        self.assertEqual(len(analyzer.new_work_patterns), 3)
    
    @patch('os.path.exists')
    def test_config_loading_missing_file(self, mock_exists):
        """Test behavior when configuration file is missing."""
        mock_exists.return_value = False
        
        analyzer = IntentAnalyzer(config_path="missing_config.yaml")
        
        # Should fall back to default patterns
        self.assertGreater(len(analyzer.maintenance_patterns), 0)
        self.assertGreater(len(analyzer.new_work_patterns), 0)
    
    @patch('builtins.open', new_callable=mock_open)
    @patch('os.path.exists')
    def test_config_loading_invalid_yaml(self, mock_exists, mock_file):
        """Test behavior with invalid YAML configuration."""
        mock_exists.return_value = True
        mock_file.return_value.read.return_value = "invalid: yaml: content: ["
        
        # Should not raise exception, should use defaults
        analyzer = IntentAnalyzer(config_path="invalid_config.yaml")
        self.assertGreater(len(analyzer.maintenance_patterns), 0)
    
    def test_pattern_compilation(self):
        """Test that regex patterns are properly compiled."""
        analyzer = IntentAnalyzer()
        
        # Check that patterns are compiled regex objects
        for pattern in analyzer.compiled_maintenance_patterns:
            self.assertIsNotNone(pattern.pattern)
        
        for pattern in analyzer.compiled_new_work_patterns:
            self.assertIsNotNone(pattern.pattern)


class TestLoggingAndDebugging(unittest.TestCase):
    """Test suite for logging and debugging functionality."""
    
    @patch('intent_analyzer.log_debug')
    def test_debug_logging_called(self, mock_log):
        """Test that debug logging is called during analysis."""
        analyzer = IntentAnalyzer()
        analyzer.analyze_intent("fix the failing tests")
        
        # Verify debug logging was called
        mock_log.assert_called()
    
    @patch.dict(os.environ, {'AGENT_OS_DEBUG': 'true'})
    def test_debug_mode_enabled(self):
        """Test behavior when debug mode is enabled."""
        analyzer = IntentAnalyzer()
        result = analyzer.analyze_intent("fix the failing tests")
        
        # Should still work normally
        self.assertEqual(result.intent_type, IntentType.MAINTENANCE)


if __name__ == '__main__':
    unittest.main()