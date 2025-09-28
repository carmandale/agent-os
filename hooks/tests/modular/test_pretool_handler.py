#!/usr/bin/env python3
"""
Test suite for the PreTool handler module.
Validates PreToolUse hook logic and command analysis.
"""

import os
import sys
import unittest
from unittest.mock import patch, MagicMock

# Add modules to path
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'modules'))

from pretool_handler_optimized import PreToolHandler, BashCommandAnalyzer, DocumentationChecker


class TestBashCommandAnalyzer(unittest.TestCase):
    """Test bash command analysis functionality."""
    
    def test_is_write_command_true(self):
        """Test detecting write commands."""
        self.assertTrue(BashCommandAnalyzer.is_write_command("cp file1 file2"))
        self.assertTrue(BashCommandAnalyzer.is_write_command("echo 'test' > file.txt"))
        self.assertTrue(BashCommandAnalyzer.is_write_command("sed -i 's/old/new/g' file.txt"))
        self.assertTrue(BashCommandAnalyzer.is_write_command("npm install"))
    
    def test_is_write_command_false(self):
        """Test non-write commands."""
        self.assertFalse(BashCommandAnalyzer.is_write_command("ls -la"))
        self.assertFalse(BashCommandAnalyzer.is_write_command("cat file.txt"))
        self.assertFalse(BashCommandAnalyzer.is_write_command("grep pattern file"))
        self.assertFalse(BashCommandAnalyzer.is_write_command("echo hello"))
    
    def test_is_readonly_command_true(self):
        """Test detecting read-only commands."""
        self.assertTrue(BashCommandAnalyzer.is_readonly_command("ls -la"))
        self.assertTrue(BashCommandAnalyzer.is_readonly_command("cat file.txt"))
        self.assertTrue(BashCommandAnalyzer.is_readonly_command("grep pattern file"))
        self.assertTrue(BashCommandAnalyzer.is_readonly_command("pwd"))
    
    def test_is_readonly_command_false(self):
        """Test commands that are not read-only."""
        self.assertFalse(BashCommandAnalyzer.is_readonly_command("cp file1 file2"))
        self.assertFalse(BashCommandAnalyzer.is_readonly_command("echo 'test' > file.txt"))
    
    def test_is_docs_only_command(self):
        """Test detecting docs-only commands."""
        self.assertTrue(BashCommandAnalyzer.is_docs_only_command("echo 'test' > README.md"))
        self.assertTrue(BashCommandAnalyzer.is_docs_only_command("cp file docs/guide.md"))
        self.assertTrue(BashCommandAnalyzer.is_docs_only_command("vim CLAUDE.md"))
    
    def test_is_git_gh_command(self):
        """Test detecting git/gh commands."""
        self.assertTrue(BashCommandAnalyzer.is_git_gh_command("git status"))
        self.assertTrue(BashCommandAnalyzer.is_git_gh_command("gh pr create"))
        self.assertFalse(BashCommandAnalyzer.is_git_gh_command("npm install"))


class TestDocumentationChecker(unittest.TestCase):
    """Test documentation validation functionality."""
    
    @patch('subprocess.run')
    def test_check_docs_before_pr_clean(self, mock_run):
        """Test when docs are up to date."""
        mock_run.return_value.returncode = 0
        # Should not raise exception
        DocumentationChecker.check_docs_before_pr("gh pr create", "/test/path")
    
    @patch('subprocess.run')
    def test_check_docs_before_pr_needs_update(self, mock_run):
        """Test when docs need updates."""
        mock_run.return_value.returncode = 2
        with self.assertRaises(SystemExit):
            DocumentationChecker.check_docs_before_pr("gh pr create", "/test/path")
    
    @patch('subprocess.run')
    def test_check_docs_non_pr_command(self, mock_run):
        """Test non-PR commands are ignored."""
        # Should not call subprocess for non-PR commands
        DocumentationChecker.check_docs_before_pr("git status", "/test/path")
        mock_run.assert_not_called()


class TestPreToolHandler(unittest.TestCase):
    """Test PreTool handler logic."""
    
    def setUp(self):
        """Set up test handler."""
        self.bash_input = {
            "tool_name": "Bash",
            "tool_input": {"command": "echo test"}
        }
        self.write_input = {
            "tool_name": "Write", 
            "tool_input": {"file_path": "test.py"}
        }
    
    def test_handle_bash_readonly(self):
        """Test handling read-only bash commands."""
        handler = PreToolHandler(self.bash_input)
        with patch.object(handler, 'exit_allow') as mock_exit:
            handler.handle()
            mock_exit.assert_called()
    
    @patch('pretool_handler.IntentAnalyzer.get_intent')
    @patch('pretool_handler.SpecChecker.has_active_spec') 
    def test_handle_bash_write_new_work(self, mock_spec, mock_intent):
        """Test handling write commands for new work."""
        write_input = {
            "tool_name": "Bash",
            "tool_input": {"command": "cp file1 file2"}
        }
        mock_intent.return_value = "NEW"
        mock_spec.return_value = True
        
        handler = PreToolHandler(write_input)
        with patch.object(handler, 'check_workflow_status', return_value=[]):
            with patch.object(handler, 'exit_allow') as mock_exit:
                handler.handle()
                mock_exit.assert_called()
    
    @patch('pretool_handler.IntentAnalyzer.get_intent')
    def test_handle_bash_write_maintenance(self, mock_intent):
        """Test allowing maintenance writes."""
        write_input = {
            "tool_name": "Bash", 
            "tool_input": {"command": "cp file1 file2"}
        }
        mock_intent.return_value = "MAINTENANCE"
        
        handler = PreToolHandler(write_input)
        with patch.object(handler, 'exit_allow') as mock_exit:
            handler.handle()
            mock_exit.assert_called()
    
    def test_handle_non_new_work_tool(self):
        """Test allowing non-new-work tools."""
        read_input = {
            "tool_name": "Read",
            "tool_input": {"file_path": "test.py"}  
        }
        
        handler = PreToolHandler(read_input)
        with patch.object(handler, 'exit_allow') as mock_exit:
            handler.handle()
            mock_exit.assert_called()
    
    @patch('pretool_handler.IntentAnalyzer.get_intent')
    @patch('pretool_handler.SpecChecker.has_active_spec')
    def test_handle_new_work_no_spec(self, mock_spec, mock_intent):
        """Test blocking new work without active spec."""
        mock_intent.return_value = "NEW"
        mock_spec.return_value = False
        
        handler = PreToolHandler(self.write_input)
        with patch.object(handler, 'exit_block') as mock_exit:
            handler.handle()
            mock_exit.assert_called_with("No active spec detected (.agent-os/specs). Run /create-spec first.")


if __name__ == '__main__':
    unittest.main()
