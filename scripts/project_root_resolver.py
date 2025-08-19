#!/usr/bin/env python3
"""
Project Root Resolver Module

Provides standardized project root resolution for Agent OS hooks and scripts.
Resolves project root with the following priority:
1. CLAUDE_PROJECT_DIR environment variable (if set and exists)
2. Hook payload fields (workspaceDir, projectRoot, rootDir) 
3. File path or cwd ascent to find .agent-os or .git
4. Fallback to current working directory

Usage:
    # As a module
    from scripts.project_root_resolver import ProjectRootResolver
    resolver = ProjectRootResolver()
    root = resolver.resolve()
    
    # From command line
    python scripts/project_root_resolver.py
    python scripts/project_root_resolver.py --file-path /path/to/file
    python scripts/project_root_resolver.py --hook-payload '{"workspaceDir": "/path"}'
"""

import os
import sys
import json
import argparse
import subprocess
from pathlib import Path
from typing import Optional, Dict, Any


class ProjectRootResolver:
    """Resolves project root directory using priority-based approach."""
    
    def __init__(self, debug: bool = False):
        """
        Initialize the resolver.
        
        Args:
            debug: Enable debug output to stderr
        """
        self.debug = debug
        self._cache: Optional[str] = None
        self._markers = ['.agent-os', '.git']  # .agent-os preferred
    
    def _debug_log(self, message: str) -> None:
        """Log debug message to stderr."""
        if self.debug:
            print(f"[DEBUG] {message}", file=sys.stderr)
    
    def clear_cache(self) -> None:
        """Clear the cached result."""
        self._cache = None
        self._debug_log("Cache cleared")
    
    def resolve(
        self,
        file_path: Optional[str] = None,
        hook_payload: Optional[Dict[str, Any]] = None,
        use_git_fallback: bool = True
    ) -> str:
        """
        Resolve the project root directory.
        
        Args:
            file_path: Optional file path to start ascent from
            hook_payload: Optional hook payload with directory fields
            use_git_fallback: Whether to use git rev-parse as fast path
        
        Returns:
            Absolute path to project root directory
        """
        # Return cached result if available
        if self._cache is not None:
            self._debug_log(f"Returning cached result: {self._cache}")
            return self._cache
        
        result = None
        
        # Priority 1: CLAUDE_PROJECT_DIR environment variable
        result = self._resolve_from_env()
        if result:
            self._debug_log(f"Resolved from CLAUDE_PROJECT_DIR: {result}")
            self._cache = result
            return result
        
        # Priority 2: Hook payload fields
        if hook_payload:
            result = self._resolve_from_hook_payload(hook_payload)
            if result:
                self._debug_log(f"Resolved from hook payload: {result}")
                self._cache = result
                return result
        
        # Priority 3: File path or cwd ascent
        start_path = file_path if file_path else os.getcwd()
        
        # Try fast path with git if enabled
        if use_git_fallback:
            result = self._resolve_from_git()
            if result:
                # Verify .agent-os exists at git root, prefer it
                agent_os_path = os.path.join(result, '.agent-os')
                if os.path.exists(agent_os_path):
                    self._debug_log(f"Resolved from git with .agent-os: {result}")
                    self._cache = result
                    return result
        
        # Manual ascent from start path
        result = self._resolve_by_ascent(start_path)
        if result:
            self._debug_log(f"Resolved by ascent: {result}")
            self._cache = result
            return result
        
        # Priority 4: Fallback to current working directory
        result = os.path.abspath(os.getcwd())
        self._debug_log(f"Fallback to cwd: {result}")
        self._cache = result
        return result
    
    def _resolve_from_env(self) -> Optional[str]:
        """Resolve from CLAUDE_PROJECT_DIR environment variable."""
        env_dir = os.environ.get('CLAUDE_PROJECT_DIR')
        if env_dir and os.path.exists(env_dir):
            return os.path.abspath(env_dir)
        return None
    
    def _resolve_from_hook_payload(self, payload: Dict[str, Any]) -> Optional[str]:
        """Resolve from hook payload fields."""
        # Check fields in order of preference
        fields = ['workspaceDir', 'projectRoot', 'rootDir']
        
        for field in fields:
            if field in payload:
                path = payload[field]
                if isinstance(path, str) and os.path.exists(path):
                    # Verify it contains a marker
                    for marker in self._markers:
                        marker_path = os.path.join(path, marker)
                        if os.path.exists(marker_path):
                            return os.path.abspath(path)
        
        return None
    
    def _resolve_from_git(self) -> Optional[str]:
        """Use git rev-parse to find repository root."""
        try:
            result = subprocess.run(
                ['git', 'rev-parse', '--show-toplevel'],
                capture_output=True,
                text=True,
                timeout=1
            )
            if result.returncode == 0:
                git_root = result.stdout.strip()
                if git_root and os.path.exists(git_root):
                    return os.path.abspath(git_root)
        except (subprocess.SubprocessError, FileNotFoundError, OSError):
            # Git not available or command failed
            pass
        return None
    
    def _resolve_by_ascent(self, start_path: str) -> Optional[str]:
        """Ascend from start path to find project markers."""
        # If start_path is a file (or doesn't exist but looks like a file), start from its directory
        if os.path.isfile(start_path):
            current = os.path.dirname(start_path)
        elif not os.path.exists(start_path):
            # If path doesn't exist, assume it's a file path and use its directory
            current = os.path.dirname(start_path)
            # If the directory doesn't exist either, this path is invalid
            if not os.path.exists(current):
                return None
        else:
            current = start_path
        
        current = os.path.abspath(current)
        
        # Ascend until we find a marker or reach root
        while True:
            try:
                # Check for markers (.agent-os preferred)
                for marker in self._markers:
                    marker_path = os.path.join(current, marker)
                    if os.path.exists(marker_path):
                        return current
                
                # Move up one directory
                parent = os.path.dirname(current)
                
                # Stop if we've reached the root
                if parent == current:
                    break
                
                current = parent
                
            except (OSError, PermissionError) as e:
                # Handle permission errors gracefully
                self._debug_log(f"Error accessing {current}: {e}")
                break
        
        return None


def main():
    """CLI entry point for project root resolver."""
    parser = argparse.ArgumentParser(
        description='Resolve project root directory for Agent OS'
    )
    parser.add_argument(
        '--file-path',
        help='File path to start resolution from'
    )
    parser.add_argument(
        '--hook-payload',
        help='JSON hook payload with directory fields'
    )
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Enable debug output to stderr'
    )
    parser.add_argument(
        '--no-git',
        action='store_true',
        help='Disable git rev-parse fast path'
    )
    
    args = parser.parse_args()
    
    # Parse hook payload if provided
    hook_payload = None
    if args.hook_payload:
        try:
            hook_payload = json.loads(args.hook_payload)
        except json.JSONDecodeError as e:
            print(f"Error parsing hook payload: {e}", file=sys.stderr)
            sys.exit(1)
    
    # Create resolver and resolve
    resolver = ProjectRootResolver(debug=args.debug)
    root = resolver.resolve(
        file_path=args.file_path,
        hook_payload=hook_payload,
        use_git_fallback=not args.no_git
    )
    
    # Output result to stdout
    print(root)


if __name__ == '__main__':
    main()