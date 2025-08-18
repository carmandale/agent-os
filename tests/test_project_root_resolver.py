#!/usr/bin/env python3
"""
Test suite for ProjectRootResolver module.
Tests priority-based resolution, caching, and error handling.
"""

import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock, mock_open

# Add parent directory to path to import the module
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


class TestProjectRootResolver(unittest.TestCase):
    """Test cases for ProjectRootResolver class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.test_dir = tempfile.mkdtemp()
        self.original_cwd = os.getcwd()
        self.original_env = os.environ.copy()
        
        # Clear any existing CLAUDE_PROJECT_DIR
        if 'CLAUDE_PROJECT_DIR' in os.environ:
            del os.environ['CLAUDE_PROJECT_DIR']
    
    def tearDown(self):
        """Clean up test fixtures."""
        os.chdir(self.original_cwd)
        os.environ.clear()
        os.environ.update(self.original_env)
        
        # Clean up test directory
        import shutil
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir)
    
    def test_priority_1_env_variable(self):
        """Test that CLAUDE_PROJECT_DIR takes highest priority."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        # Create test structure
        project_dir = os.path.join(self.test_dir, 'my-project')
        os.makedirs(project_dir)
        
        # Set environment variable
        os.environ['CLAUDE_PROJECT_DIR'] = project_dir
        
        resolver = ProjectRootResolver()
        result = resolver.resolve()
        
        # Normalize paths for comparison (macOS /private prefix)
        self.assertEqual(os.path.realpath(result), os.path.realpath(project_dir))
    
    def test_priority_1_env_variable_invalid(self):
        """Test that invalid CLAUDE_PROJECT_DIR is ignored."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        # Set invalid environment variable
        os.environ['CLAUDE_PROJECT_DIR'] = '/nonexistent/path'
        
        # Create a fallback directory
        os.chdir(self.test_dir)
        
        resolver = ProjectRootResolver()
        result = resolver.resolve()
        
        # Should fall back to current directory
        self.assertEqual(os.path.realpath(result), os.path.realpath(self.test_dir))
    
    def test_priority_2_hook_payload_workspace_dir(self):
        """Test resolution from hook payload workspaceDir field."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        # Create test structure with .agent-os
        project_dir = os.path.join(self.test_dir, 'workspace')
        agent_os_dir = os.path.join(project_dir, '.agent-os')
        os.makedirs(agent_os_dir)
        
        payload = {'workspaceDir': project_dir}
        
        resolver = ProjectRootResolver()
        result = resolver.resolve(hook_payload=payload)
        
        self.assertEqual(result, project_dir)
    
    def test_priority_2_hook_payload_project_root(self):
        """Test resolution from hook payload projectRoot field."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        # Create test structure with .git
        project_dir = os.path.join(self.test_dir, 'project')
        git_dir = os.path.join(project_dir, '.git')
        os.makedirs(git_dir)
        
        payload = {'projectRoot': project_dir}
        
        resolver = ProjectRootResolver()
        result = resolver.resolve(hook_payload=payload)
        
        self.assertEqual(result, project_dir)
    
    def test_priority_2_hook_payload_root_dir(self):
        """Test resolution from hook payload rootDir field."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        # Create test structure
        project_dir = os.path.join(self.test_dir, 'root')
        agent_os_dir = os.path.join(project_dir, '.agent-os')
        os.makedirs(agent_os_dir)
        
        payload = {'rootDir': project_dir}
        
        resolver = ProjectRootResolver()
        result = resolver.resolve(hook_payload=payload)
        
        self.assertEqual(result, project_dir)
    
    def test_priority_3_file_path_ascent_agent_os(self):
        """Test ascending from file path to find .agent-os directory."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        # Create nested structure with .agent-os at root
        project_dir = os.path.join(self.test_dir, 'project')
        agent_os_dir = os.path.join(project_dir, '.agent-os')
        subdir = os.path.join(project_dir, 'frontend', 'src', 'components')
        os.makedirs(agent_os_dir)
        os.makedirs(subdir)
        
        file_path = os.path.join(subdir, 'Component.jsx')
        
        resolver = ProjectRootResolver()
        result = resolver.resolve(file_path=file_path)
        
        self.assertEqual(result, project_dir)
    
    def test_priority_3_file_path_ascent_git(self):
        """Test ascending from file path to find .git directory."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        # Create nested structure with .git at root
        project_dir = os.path.join(self.test_dir, 'git-project')
        git_dir = os.path.join(project_dir, '.git')
        subdir = os.path.join(project_dir, 'backend', 'api', 'handlers')
        os.makedirs(git_dir)
        os.makedirs(subdir)
        
        file_path = os.path.join(subdir, 'handler.py')
        
        resolver = ProjectRootResolver()
        result = resolver.resolve(file_path=file_path)
        
        self.assertEqual(result, project_dir)
    
    def test_priority_3_cwd_ascent_agent_os(self):
        """Test ascending from current directory to find .agent-os."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        # Create nested structure
        project_dir = os.path.join(self.test_dir, 'cwd-project')
        agent_os_dir = os.path.join(project_dir, '.agent-os')
        subdir = os.path.join(project_dir, 'tests', 'unit')
        os.makedirs(agent_os_dir)
        os.makedirs(subdir)
        
        # Change to subdirectory
        os.chdir(subdir)
        
        resolver = ProjectRootResolver()
        result = resolver.resolve()
        
        self.assertEqual(result, project_dir)
    
    @patch('subprocess.run')
    def test_priority_3_git_rev_parse(self, mock_run):
        """Test fast-path resolution using git rev-parse."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        project_dir = os.path.join(self.test_dir, 'git-repo')
        os.makedirs(project_dir)
        os.chdir(project_dir)
        
        # Mock successful git command
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout=project_dir + '\n',
            stderr=''
        )
        
        resolver = ProjectRootResolver()
        result = resolver.resolve(use_git_fallback=True)
        
        self.assertEqual(result, project_dir)
        mock_run.assert_called_once()
    
    def test_priority_4_fallback_to_cwd(self):
        """Test fallback to current directory when no markers found."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        # Create directory with no markers
        plain_dir = os.path.join(self.test_dir, 'plain')
        os.makedirs(plain_dir)
        os.chdir(plain_dir)
        
        resolver = ProjectRootResolver()
        result = resolver.resolve()
        
        self.assertEqual(result, plain_dir)
    
    def test_agent_os_preferred_over_git(self):
        """Test that .agent-os is preferred over .git when both exist."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        # Create structure with both markers
        project_dir = os.path.join(self.test_dir, 'both-markers')
        agent_os_dir = os.path.join(project_dir, '.agent-os')
        git_dir = os.path.join(project_dir, '.git')
        subdir = os.path.join(project_dir, 'src')
        
        os.makedirs(agent_os_dir)
        os.makedirs(git_dir)
        os.makedirs(subdir)
        
        os.chdir(subdir)
        
        resolver = ProjectRootResolver()
        result = resolver.resolve()
        
        self.assertEqual(result, project_dir)
        # Verify it found .agent-os, not just any marker
        self.assertTrue(os.path.exists(os.path.join(result, '.agent-os')))
    
    def test_caching_mechanism(self):
        """Test that results are cached for performance."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        project_dir = os.path.join(self.test_dir, 'cached')
        os.makedirs(project_dir)
        os.environ['CLAUDE_PROJECT_DIR'] = project_dir
        
        resolver = ProjectRootResolver()
        
        # First call
        result1 = resolver.resolve()
        
        # Change environment (should be ignored due to cache)
        os.environ['CLAUDE_PROJECT_DIR'] = '/different/path'
        
        # Second call should return cached result
        result2 = resolver.resolve()
        
        self.assertEqual(result1, result2)
        self.assertEqual(result2, project_dir)
    
    def test_cache_invalidation(self):
        """Test that cache can be invalidated."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        project_dir1 = os.path.join(self.test_dir, 'proj1')
        project_dir2 = os.path.join(self.test_dir, 'proj2')
        os.makedirs(project_dir1)
        os.makedirs(project_dir2)
        
        os.environ['CLAUDE_PROJECT_DIR'] = project_dir1
        
        resolver = ProjectRootResolver()
        result1 = resolver.resolve()
        
        # Change environment and clear cache
        os.environ['CLAUDE_PROJECT_DIR'] = project_dir2
        resolver.clear_cache()
        
        result2 = resolver.resolve()
        
        self.assertEqual(result1, project_dir1)
        self.assertEqual(result2, project_dir2)
    
    def test_symlink_handling(self):
        """Test that symlinks are resolved correctly."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        # Create real directory
        real_dir = os.path.join(self.test_dir, 'real-project')
        agent_os_dir = os.path.join(real_dir, '.agent-os')
        os.makedirs(agent_os_dir)
        
        # Create symlink
        link_dir = os.path.join(self.test_dir, 'linked-project')
        os.symlink(real_dir, link_dir)
        
        os.chdir(link_dir)
        
        resolver = ProjectRootResolver()
        result = resolver.resolve()
        
        # Should resolve to the real path
        self.assertEqual(os.path.realpath(result), os.path.realpath(real_dir))
    
    def test_permission_error_handling(self):
        """Test graceful handling of permission errors."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        restricted_dir = os.path.join(self.test_dir, 'restricted')
        os.makedirs(restricted_dir)
        os.chdir(restricted_dir)
        
        # Mock os.path.exists to raise PermissionError for parent
        with patch('os.path.exists') as mock_exists:
            def side_effect(path):
                if path != restricted_dir:
                    raise PermissionError("Access denied")
                return True
            
            mock_exists.side_effect = side_effect
            
            resolver = ProjectRootResolver()
            result = resolver.resolve()
            
            # Should fall back to current directory
            self.assertEqual(result, restricted_dir)
    
    def test_deep_nesting(self):
        """Test resolution from deeply nested directories."""
        from scripts.project_root_resolver import ProjectRootResolver
        
        # Create very deep structure
        project_dir = os.path.join(self.test_dir, 'deep-project')
        agent_os_dir = os.path.join(project_dir, '.agent-os')
        os.makedirs(agent_os_dir)
        
        # Create 10 levels deep
        deep_dir = project_dir
        for i in range(10):
            deep_dir = os.path.join(deep_dir, f'level{i}')
        os.makedirs(deep_dir)
        
        os.chdir(deep_dir)
        
        resolver = ProjectRootResolver()
        result = resolver.resolve()
        
        self.assertEqual(result, project_dir)


class TestProjectRootResolverCLI(unittest.TestCase):
    """Test cases for CLI interface of ProjectRootResolver."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.test_dir = tempfile.mkdtemp()
        self.original_cwd = os.getcwd()
    
    def tearDown(self):
        """Clean up test fixtures."""
        os.chdir(self.original_cwd)
        import shutil
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir)
    
    @patch('sys.argv', ['project_root_resolver.py'])
    def test_cli_basic(self):
        """Test basic CLI invocation."""
        from scripts.project_root_resolver import main
        
        os.chdir(self.test_dir)
        
        # Capture output
        from io import StringIO
        import sys
        captured = StringIO()
        sys.stdout = captured
        
        try:
            main()
            output = captured.getvalue().strip()
            self.assertEqual(output, self.test_dir)
        finally:
            sys.stdout = sys.__stdout__
    
    @patch('sys.argv', ['project_root_resolver.py', '--hook-payload', '{"workspaceDir": "/test/path"}'])
    def test_cli_with_hook_payload(self):
        """Test CLI with hook payload argument."""
        from scripts.project_root_resolver import main
        
        test_path = os.path.join(self.test_dir, 'workspace')
        agent_os = os.path.join(test_path, '.agent-os')
        os.makedirs(agent_os)
        
        # Update argv with correct path
        sys.argv[2] = f'{{"workspaceDir": "{test_path}"}}'
        
        from io import StringIO
        import sys
        captured = StringIO()
        sys.stdout = captured
        
        try:
            main()
            output = captured.getvalue().strip()
            self.assertEqual(output, test_path)
        finally:
            sys.stdout = sys.__stdout__
    
    @patch('sys.argv', ['project_root_resolver.py', '--file-path', '/some/file.py'])
    def test_cli_with_file_path(self):
        """Test CLI with file path argument."""
        from scripts.project_root_resolver import main
        
        project_dir = os.path.join(self.test_dir, 'project')
        agent_os = os.path.join(project_dir, '.agent-os')
        file_dir = os.path.join(project_dir, 'src')
        os.makedirs(agent_os)
        os.makedirs(file_dir)
        
        file_path = os.path.join(file_dir, 'file.py')
        sys.argv[2] = file_path
        
        from io import StringIO
        import sys
        captured = StringIO()
        sys.stdout = captured
        
        try:
            main()
            output = captured.getvalue().strip()
            self.assertEqual(output, project_dir)
        finally:
            sys.stdout = sys.__stdout__
    
    @patch('sys.argv', ['project_root_resolver.py', '--debug'])
    def test_cli_debug_mode(self):
        """Test CLI debug output."""
        from scripts.project_root_resolver import main
        
        os.chdir(self.test_dir)
        
        from io import StringIO
        import sys
        captured = StringIO()
        sys.stderr = captured
        sys.stdout = StringIO()
        
        try:
            main()
            debug_output = captured.getvalue()
            # Should contain debug information
            self.assertIn('[DEBUG]', debug_output)
        finally:
            sys.stdout = sys.__stdout__
            sys.stderr = sys.__stderr__


if __name__ == '__main__':
    unittest.main()