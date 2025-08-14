#!/usr/bin/env python3
"""
Git Workflow Subagent - Complete git operations and GitHub integration.

This subagent provides comprehensive git workflow automation for Agent OS,
handling commits, branches, PRs, and GitHub integration with proper
issue tracking and conventional commits.
"""

import os
import subprocess
import json
import re
from typing import Dict, Any, Optional, List, Tuple
from pathlib import Path
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class GitWorkflowAgent:
    """
    Specialized agent for git operations and GitHub workflows.
    
    Provides:
    - Safe git operations without shell injection
    - GitHub CLI integration
    - Conventional commit formatting
    - PR creation and management
    - Issue tracking integration
    """
    
    def __init__(self):
        """Initialize the git workflow agent."""
        self.commit_types = {
            'feat': 'A new feature',
            'fix': 'A bug fix',
            'docs': 'Documentation only changes',
            'style': 'Formatting, missing semi colons, etc',
            'refactor': 'Code change that neither fixes a bug nor adds a feature',
            'test': 'Adding missing tests',
            'chore': 'Maintain tasks',
            'perf': 'Performance improvements'
        }
    
    def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a git workflow task.
        
        Args:
            task: Dictionary containing git operation parameters
            
        Returns:
            Dictionary with operation results
        """
        operation = task.get('operation', 'status')
        
        if operation == 'status':
            return self._get_status()
        elif operation == 'commit':
            return self._create_commit(task)
        elif operation == 'branch':
            return self._manage_branch(task)
        elif operation == 'pr':
            return self._manage_pr(task)
        elif operation == 'push':
            return self._push_changes(task)
        elif operation == 'stash':
            return self._stash_changes(task)
        elif operation == 'log':
            return self._get_log(task)
        elif operation == 'diff':
            return self._get_diff(task)
        else:
            return {'error': f'Unknown operation: {operation}'}
    
    def _run_git_command(self, args: List[str], 
                        capture_output: bool = True) -> subprocess.CompletedProcess:
        """
        Safely run a git command.
        
        Args:
            args: Git command arguments
            capture_output: Whether to capture output
            
        Returns:
            Completed process result
        """
        cmd = ['git'] + args
        logger.debug(f"Running git command: {' '.join(cmd)}")
        
        return subprocess.run(
            cmd,
            capture_output=capture_output,
            text=True,
            timeout=10
        )
    
    def _get_status(self) -> Dict[str, Any]:
        """
        Get comprehensive git status.
        
        Returns:
            Dictionary with status information
        """
        try:
            # Get branch info
            branch_result = self._run_git_command(['branch', '--show-current'])
            current_branch = branch_result.stdout.strip()
            
            # Get status
            status_result = self._run_git_command(['status', '--porcelain'])
            
            # Parse status
            staged = []
            modified = []
            untracked = []
            
            for line in status_result.stdout.splitlines():
                if not line:
                    continue
                status_code = line[:2]
                file_path = line[3:]
                
                if status_code[0] != ' ' and status_code[0] != '?':
                    staged.append(file_path)
                if status_code[1] == 'M':
                    modified.append(file_path)
                if status_code == '??':
                    untracked.append(file_path)
            
            # Check for uncommitted changes
            has_changes = bool(staged or modified or untracked)
            
            # Get remote status
            remote_result = self._run_git_command(
                ['status', '-sb']
            )
            ahead_behind = self._parse_ahead_behind(remote_result.stdout)
            
            return {
                'success': True,
                'branch': current_branch,
                'clean': not has_changes,
                'staged': staged,
                'modified': modified,
                'untracked': untracked,
                'ahead': ahead_behind.get('ahead', 0),
                'behind': ahead_behind.get('behind', 0)
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _parse_ahead_behind(self, status_line: str) -> Dict[str, int]:
        """
        Parse ahead/behind counts from status line.
        
        Args:
            status_line: Git status -sb output
            
        Returns:
            Dictionary with ahead/behind counts
        """
        result = {'ahead': 0, 'behind': 0}
        
        # Look for [ahead X, behind Y] pattern
        match = re.search(r'\[ahead (\d+)(?:, behind (\d+))?\]', status_line)
        if match:
            result['ahead'] = int(match.group(1))
            if match.group(2):
                result['behind'] = int(match.group(2))
        else:
            # Check for just behind
            match = re.search(r'\[behind (\d+)\]', status_line)
            if match:
                result['behind'] = int(match.group(1))
        
        return result
    
    def _create_commit(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a commit with conventional format.
        
        Args:
            task: Commit parameters
            
        Returns:
            Commit result
        """
        try:
            commit_type = task.get('type', 'feat')
            scope = task.get('scope', '')
            description = task.get('description', '')
            body = task.get('body', '')
            issue = task.get('issue', '')
            files = task.get('files', [])
            
            # Validate commit type
            if commit_type not in self.commit_types:
                return {
                    'success': False,
                    'error': f'Invalid commit type: {commit_type}',
                    'valid_types': list(self.commit_types.keys())
                }
            
            # Stage files if specified
            if files:
                if files == ['all']:
                    add_result = self._run_git_command(['add', '-A'])
                else:
                    add_result = self._run_git_command(['add'] + files)
                
                if add_result.returncode != 0:
                    return {
                        'success': False,
                        'error': f'Failed to stage files: {add_result.stderr}'
                    }
            
            # Build commit message
            commit_msg = f"{commit_type}"
            if scope:
                commit_msg += f"({scope})"
            commit_msg += f": {description}"
            if issue:
                commit_msg += f" #{issue}"
            
            if body:
                commit_msg += f"\n\n{body}"
            
            # Add Agent OS signature
            commit_msg += "\n\n🤖 Generated with [Claude Code](https://claude.ai/code)"
            commit_msg += "\n\nCo-Authored-By: Claude <noreply@anthropic.com>"
            
            # Create commit
            commit_result = self._run_git_command(['commit', '-m', commit_msg])
            
            if commit_result.returncode != 0:
                return {
                    'success': False,
                    'error': commit_result.stderr or 'Commit failed'
                }
            
            # Get commit hash
            hash_result = self._run_git_command(['rev-parse', 'HEAD'])
            commit_hash = hash_result.stdout.strip()[:7]
            
            return {
                'success': True,
                'message': commit_msg.split('\n')[0],
                'hash': commit_hash,
                'type': commit_type
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _manage_branch(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Manage git branches.
        
        Args:
            task: Branch operation parameters
            
        Returns:
            Operation result
        """
        try:
            action = task.get('action', 'list')
            branch_name = task.get('name', '')
            
            if action == 'list':
                result = self._run_git_command(['branch', '-a'])
                branches = [b.strip() for b in result.stdout.splitlines()]
                current = next((b[2:] for b in branches if b.startswith('*')), None)
                
                return {
                    'success': True,
                    'branches': [b.replace('* ', '') for b in branches],
                    'current': current
                }
                
            elif action == 'create':
                if not branch_name:
                    return {
                        'success': False,
                        'error': 'Branch name required'
                    }
                
                result = self._run_git_command(['checkout', '-b', branch_name])
                
                return {
                    'success': result.returncode == 0,
                    'branch': branch_name,
                    'message': f'Created and switched to branch: {branch_name}'
                }
                
            elif action == 'switch':
                if not branch_name:
                    return {
                        'success': False,
                        'error': 'Branch name required'
                    }
                
                result = self._run_git_command(['checkout', branch_name])
                
                return {
                    'success': result.returncode == 0,
                    'branch': branch_name,
                    'message': f'Switched to branch: {branch_name}'
                }
                
            elif action == 'delete':
                if not branch_name:
                    return {
                        'success': False,
                        'error': 'Branch name required'
                    }
                
                force = task.get('force', False)
                flag = '-D' if force else '-d'
                result = self._run_git_command(['branch', flag, branch_name])
                
                return {
                    'success': result.returncode == 0,
                    'message': f'Deleted branch: {branch_name}'
                }
            
            else:
                return {
                    'success': False,
                    'error': f'Unknown branch action: {action}'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _manage_pr(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Manage GitHub pull requests.
        
        Args:
            task: PR operation parameters
            
        Returns:
            Operation result
        """
        try:
            action = task.get('action', 'create')
            
            if action == 'create':
                title = task.get('title', '')
                body = task.get('body', '')
                issue = task.get('issue', '')
                draft = task.get('draft', False)
                
                if not title:
                    return {
                        'success': False,
                        'error': 'PR title required'
                    }
                
                # Build PR body
                if issue:
                    body = f"Fixes #{issue}\n\n{body}"
                
                # Add Agent OS signature
                body += "\n\n🤖 Generated with [Claude Code](https://claude.ai/code)"
                body += "\n\nCo-Authored-By: Claude <noreply@anthropic.com>"
                
                # Create PR using gh CLI
                cmd = ['gh', 'pr', 'create', '--title', title, '--body', body]
                if draft:
                    cmd.append('--draft')
                
                result = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                if result.returncode != 0:
                    return {
                        'success': False,
                        'error': result.stderr or 'PR creation failed'
                    }
                
                # Extract PR URL from output
                pr_url = result.stdout.strip()
                
                return {
                    'success': True,
                    'url': pr_url,
                    'message': 'Pull request created successfully'
                }
                
            elif action == 'list':
                result = subprocess.run(
                    ['gh', 'pr', 'list', '--json', 'number,title,state,url'],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                if result.returncode != 0:
                    return {
                        'success': False,
                        'error': 'Failed to list PRs'
                    }
                
                prs = json.loads(result.stdout) if result.stdout else []
                
                return {
                    'success': True,
                    'prs': prs
                }
                
            else:
                return {
                    'success': False,
                    'error': f'Unknown PR action: {action}'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _push_changes(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Push changes to remote.
        
        Args:
            task: Push parameters
            
        Returns:
            Push result
        """
        try:
            branch = task.get('branch', '')
            set_upstream = task.get('set_upstream', False)
            
            if set_upstream:
                if not branch:
                    # Get current branch
                    branch_result = self._run_git_command(['branch', '--show-current'])
                    branch = branch_result.stdout.strip()
                
                result = self._run_git_command(['push', '-u', 'origin', branch])
            else:
                result = self._run_git_command(['push'])
            
            return {
                'success': result.returncode == 0,
                'message': 'Changes pushed successfully',
                'branch': branch if branch else 'current'
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _stash_changes(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Stash uncommitted changes.
        
        Args:
            task: Stash parameters
            
        Returns:
            Stash result
        """
        try:
            action = task.get('action', 'save')
            message = task.get('message', f'WIP: {datetime.now().isoformat()}')
            
            if action == 'save':
                result = self._run_git_command(['stash', 'save', message])
                return {
                    'success': result.returncode == 0,
                    'message': f'Changes stashed: {message}'
                }
                
            elif action == 'pop':
                result = self._run_git_command(['stash', 'pop'])
                return {
                    'success': result.returncode == 0,
                    'message': 'Stashed changes applied'
                }
                
            elif action == 'list':
                result = self._run_git_command(['stash', 'list'])
                stashes = result.stdout.splitlines()
                return {
                    'success': True,
                    'stashes': stashes
                }
                
            else:
                return {
                    'success': False,
                    'error': f'Unknown stash action: {action}'
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _get_log(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Get git log.
        
        Args:
            task: Log parameters
            
        Returns:
            Log entries
        """
        try:
            limit = task.get('limit', 10)
            oneline = task.get('oneline', True)
            
            if oneline:
                result = self._run_git_command(['log', f'-{limit}', '--oneline'])
            else:
                result = self._run_git_command([
                    'log', f'-{limit}', 
                    '--pretty=format:%H|%an|%ae|%ad|%s',
                    '--date=iso'
                ])
            
            if result.returncode != 0:
                return {
                    'success': False,
                    'error': 'Failed to get log'
                }
            
            if oneline:
                entries = result.stdout.splitlines()
            else:
                entries = []
                for line in result.stdout.splitlines():
                    parts = line.split('|')
                    if len(parts) >= 5:
                        entries.append({
                            'hash': parts[0][:7],
                            'author': parts[1],
                            'email': parts[2],
                            'date': parts[3],
                            'message': parts[4]
                        })
            
            return {
                'success': True,
                'entries': entries
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _get_diff(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Get git diff.
        
        Args:
            task: Diff parameters
            
        Returns:
            Diff output
        """
        try:
            staged = task.get('staged', False)
            files = task.get('files', [])
            
            cmd = ['diff']
            if staged:
                cmd.append('--cached')
            if files:
                cmd.extend(files)
            
            result = self._run_git_command(cmd)
            
            return {
                'success': True,
                'diff': result.stdout,
                'has_changes': bool(result.stdout)
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }