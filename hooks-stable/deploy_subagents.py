#!/usr/bin/env python3
"""
Zero-Configuration Deployment System for Agent OS Subagents.

This module provides automatic deployment of the subagent system
without requiring any user configuration or setup.
"""

import os
import sys
import json
import shutil
import logging
from pathlib import Path
from typing import Dict, Any, Optional, List

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SubagentDeployer:
    """
    Zero-configuration deployment system for Agent OS subagents.
    
    This class handles automatic deployment and integration of subagents
    into the Agent OS environment without requiring user intervention.
    """
    
    def __init__(self):
        """Initialize the deployer."""
        self.agent_os_dir = Path.home() / '.agent-os'
        self.hooks_dir = self.agent_os_dir / 'hooks'
        self.subagents_dir = self.hooks_dir / 'subagents'
        self.deployed = False
    
    def deploy(self) -> Dict[str, Any]:
        """
        Deploy subagents system with zero configuration.
        
        Returns:
            Deployment status and information
        """
        try:
            # Create directories if needed
            self._ensure_directories()
            
            # Deploy subagent files
            self._deploy_subagent_files()
            
            # Create integration hooks
            self._create_integration_hooks()
            
            # Verify deployment
            if self._verify_deployment():
                self.deployed = True
                logger.info("Subagents system deployed successfully")
                return {
                    'success': True,
                    'message': 'Subagents deployed successfully',
                    'location': str(self.subagents_dir),
                    'agents_available': self._get_available_agents()
                }
            else:
                return {
                    'success': False,
                    'message': 'Deployment verification failed',
                    'error': 'Some components could not be verified'
                }
                
        except Exception as e:
            logger.error(f"Deployment failed: {e}")
            return {
                'success': False,
                'message': 'Deployment failed',
                'error': str(e)
            }
    
    def _ensure_directories(self):
        """Ensure required directories exist."""
        directories = [
            self.agent_os_dir,
            self.hooks_dir,
            self.subagents_dir
        ]
        
        for directory in directories:
            directory.mkdir(parents=True, exist_ok=True)
            logger.debug(f"Ensured directory: {directory}")
    
    def _deploy_subagent_files(self):
        """Deploy subagent files to Agent OS directory."""
        # Get source directory (where this script is located)
        source_dir = Path(__file__).parent
        
        # Files to deploy
        subagent_files = [
            'subagent_detector.py',
            'task_tool_wrapper.py',
            'subagents/__init__.py',
            'subagents/context_fetcher.py',
            'subagents/date_checker.py',
            'subagents/file_creator.py',
            'subagents/git_workflow.py',
            'subagents/test_runner.py'
        ]
        
        for file_path in subagent_files:
            source_file = source_dir / file_path
            
            # Determine target path
            if '/' in file_path:
                # Nested file
                target_file = self.hooks_dir / file_path
                target_file.parent.mkdir(parents=True, exist_ok=True)
            else:
                # Top-level file
                target_file = self.hooks_dir / file_path
            
            # Copy if source exists
            if source_file.exists():
                shutil.copy2(source_file, target_file)
                logger.debug(f"Deployed: {file_path}")
            else:
                logger.warning(f"Source file not found: {source_file}")
    
    def _create_integration_hooks(self):
        """Create integration hooks for Claude Code."""
        # Create Task tool integration hook
        task_hook = self.hooks_dir / 'task_integration.py'
        
        task_hook_content = '''#!/usr/bin/env python3
"""
Task Tool Integration Hook for Claude Code.

This hook automatically integrates subagents with the Task tool.
"""

import sys
import os

# Add hooks directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from task_tool_wrapper import handle_task

# Export the handler for Claude Code
__all__ = ['handle_task']
'''
        
        task_hook.write_text(task_hook_content)
        task_hook.chmod(0o755)
        logger.debug("Created Task tool integration hook")
        
        # Create activation script
        activation_script = self.hooks_dir / 'activate_subagents.sh'
        
        activation_content = '''#!/bin/bash
# Activation script for Agent OS subagents

export AGENT_OS_SUBAGENTS_ENABLED=true
export AGENT_OS_HOOKS_DIR="$HOME/.agent-os/hooks"

echo "Agent OS Subagents activated"
echo "Available agents:"
python3 -c "
import sys
sys.path.insert(0, '$AGENT_OS_HOOKS_DIR')
from subagent_detector import SubagentDetector
detector = SubagentDetector()
for agent in detector.get_available_agents():
    print(f'  - {agent}')
"
'''
        
        activation_script.write_text(activation_content)
        activation_script.chmod(0o755)
        logger.debug("Created activation script")
    
    def _verify_deployment(self) -> bool:
        """Verify that deployment was successful."""
        # Check core files exist
        required_files = [
            self.hooks_dir / 'subagent_detector.py',
            self.hooks_dir / 'task_tool_wrapper.py',
            self.subagents_dir / '__init__.py'
        ]
        
        for file_path in required_files:
            if not file_path.exists():
                logger.error(f"Missing required file: {file_path}")
                return False
        
        # Try to import and initialize
        try:
            sys.path.insert(0, str(self.hooks_dir))
            from subagent_detector import SubagentDetector
            
            detector = SubagentDetector()
            agents = detector.get_available_agents()
            
            if len(agents) >= 5:  # Should have at least 5 subagents
                logger.debug(f"Verified {len(agents)} agents available")
                return True
            else:
                logger.error(f"Only {len(agents)} agents available")
                return False
                
        except Exception as e:
            logger.error(f"Import verification failed: {e}")
            return False
    
    def _get_available_agents(self) -> List[str]:
        """Get list of available agents."""
        try:
            sys.path.insert(0, str(self.hooks_dir))
            from subagent_detector import SubagentDetector
            
            detector = SubagentDetector()
            return detector.get_available_agents()
        except:
            return []
    
    def status(self) -> Dict[str, Any]:
        """
        Get deployment status.
        
        Returns:
            Current deployment status
        """
        if not self.hooks_dir.exists():
            return {
                'deployed': False,
                'message': 'Not deployed',
                'location': None
            }
        
        # Check what's deployed
        agents = self._get_available_agents()
        
        return {
            'deployed': len(agents) > 0,
            'message': f'{len(agents)} agents available' if agents else 'Not deployed',
            'location': str(self.hooks_dir),
            'agents': agents
        }
    
    def uninstall(self) -> Dict[str, Any]:
        """
        Uninstall the subagents system.
        
        Returns:
            Uninstall status
        """
        try:
            if self.subagents_dir.exists():
                shutil.rmtree(self.subagents_dir)
            
            # Remove integration files
            files_to_remove = [
                self.hooks_dir / 'subagent_detector.py',
                self.hooks_dir / 'task_tool_wrapper.py',
                self.hooks_dir / 'task_integration.py',
                self.hooks_dir / 'activate_subagents.sh'
            ]
            
            for file_path in files_to_remove:
                if file_path.exists():
                    file_path.unlink()
            
            logger.info("Subagents system uninstalled")
            return {
                'success': True,
                'message': 'Subagents uninstalled successfully'
            }
            
        except Exception as e:
            logger.error(f"Uninstall failed: {e}")
            return {
                'success': False,
                'message': 'Uninstall failed',
                'error': str(e)
            }


def main():
    """Main entry point for deployment."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Deploy Agent OS Subagents System'
    )
    parser.add_argument(
        'action',
        choices=['deploy', 'status', 'uninstall'],
        help='Action to perform'
    )
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Verbose output'
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    deployer = SubagentDeployer()
    
    if args.action == 'deploy':
        result = deployer.deploy()
    elif args.action == 'status':
        result = deployer.status()
    elif args.action == 'uninstall':
        result = deployer.uninstall()
    
    # Print result
    print(json.dumps(result, indent=2))
    
    # Exit with appropriate code
    sys.exit(0 if result.get('success', result.get('deployed', False)) else 1)


if __name__ == '__main__':
    main()