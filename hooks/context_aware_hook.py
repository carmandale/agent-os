#!/usr/bin/env python3
"""
Context-Aware Workflow Hook for Agent OS.

This module provides intelligent workflow enforcement that distinguishes between
maintenance work (bug fixes, test fixes, debugging) and new development work
(new features, new specs) based on user intent analysis.

Maintenance work is allowed even with dirty workspace/open PRs, while new work
requires following the full Agent OS workflow with clean workspace.
"""

import os
import sys
import json
import logging
import subprocess
from dataclasses import dataclass
from typing import List, Optional, Tuple
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

# Import the intent analyzer from Task 1
from intent_analyzer import IntentAnalyzer

# Configure logging
logging.basicConfig(
    level=logging.INFO if os.environ.get('DEBUG') else logging.WARNING,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@dataclass
class WorkspaceState:
    """Represents the current state of the Git workspace."""
    has_uncommitted_changes: bool
    has_open_prs: bool
    open_pr_numbers: List[int]
    is_clean: bool
    
    def __str__(self):
        """String representation of workspace state."""
        parts = []
        if self.has_uncommitted_changes:
            parts.append("uncommitted changes")
        if self.has_open_prs:
            parts.append(f"open PRs: {self.open_pr_numbers}")
        if self.is_clean:
            parts.append("clean")
        return f"WorkspaceState({', '.join(parts) if parts else 'unknown'})"


@dataclass
class WorkflowDecision:
    """Represents a workflow enforcement decision."""
    action: str  # 'allow', 'block', or 'prompt'
    work_type: str  # 'maintenance', 'new_work', or 'unknown'
    reason: str
    confidence: float
    
    def __str__(self):
        """String representation of workflow decision."""
        return f"WorkflowDecision(action={self.action}, work_type={self.work_type}, confidence={self.confidence:.2f})"


class ContextAwareWorkflowHook:
    """
    Context-aware wrapper around workflow enforcement that intelligently
    allows maintenance work while enforcing clean workspace for new work.
    """
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize the context-aware workflow hook.
        
        Args:
            config_path: Optional path to configuration file
        """
        self.intent_analyzer = IntentAnalyzer(config_path)
        logger.info("Context-aware workflow hook initialized")
    
    def get_workspace_state(self) -> WorkspaceState:
        """
        Check the current state of the Git workspace.
        
        Returns:
            WorkspaceState object describing the current workspace
        """
        has_uncommitted = self._check_uncommitted_changes()
        has_prs, pr_numbers = self._check_open_prs()
        
        is_clean = not has_uncommitted and not has_prs
        
        state = WorkspaceState(
            has_uncommitted_changes=has_uncommitted,
            has_open_prs=has_prs,
            open_pr_numbers=pr_numbers,
            is_clean=is_clean
        )
        
        logger.info(f"Workspace state: {state}")
        return state
    
    def _check_uncommitted_changes(self) -> bool:
        """
        Check if there are uncommitted changes in the workspace.
        
        Returns:
            True if there are uncommitted changes, False otherwise
        """
        try:
            result = subprocess.run(
                ['git', 'status', '--porcelain'],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode != 0:
                logger.warning(f"Git status failed: {result.stderr}")
                return False
            
            # If output is not empty, there are uncommitted changes
            has_changes = bool(result.stdout.strip())
            logger.debug(f"Uncommitted changes: {has_changes}")
            return has_changes
            
        except Exception as e:
            logger.error(f"Error checking git status: {e}")
            return False
    
    def _check_open_prs(self) -> Tuple[bool, List[int]]:
        """
        Check if there are open pull requests.
        
        Returns:
            Tuple of (has_open_prs, list_of_pr_numbers)
        """
        try:
            result = subprocess.run(
                ['gh', 'pr', 'list', '--json', 'number,state', '--state', 'open'],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode != 0:
                logger.warning(f"GitHub CLI failed: {result.stderr}")
                return False, []
            
            prs = json.loads(result.stdout) if result.stdout else []
            pr_numbers = [pr['number'] for pr in prs]
            
            logger.debug(f"Open PRs: {pr_numbers}")
            return bool(pr_numbers), pr_numbers
            
        except json.JSONDecodeError as e:
            logger.error(f"Error parsing PR data: {e}")
            return False, []
        except Exception as e:
            logger.error(f"Error checking PRs: {e}")
            return False, []
    
    def make_decision(self, user_message: str, workspace_state: WorkspaceState) -> WorkflowDecision:
        """
        Make a workflow enforcement decision based on user intent and workspace state.
        
        Args:
            user_message: The user's message/command
            workspace_state: Current workspace state
            
        Returns:
            WorkflowDecision with action to take
        """
        # Check for bypass flag first
        if os.environ.get('AGENT_OS_BYPASS', '').lower() == 'true':
            logger.info("AGENT_OS_BYPASS is set - allowing all work")
            return WorkflowDecision(
                action='allow',
                work_type='bypass',
                reason='Workflow enforcement bypassed via AGENT_OS_BYPASS',
                confidence=1.0
            )
        
        # Check for manual work type override
        manual_work_type = os.environ.get('AGENT_OS_WORK_TYPE', '').lower()
        if manual_work_type in ['maintenance', 'new_work']:
            logger.info(f"Manual override: AGENT_OS_WORK_TYPE={manual_work_type}")
            work_type = manual_work_type
            confidence = 1.0
            reason = f"Manual override via AGENT_OS_WORK_TYPE={manual_work_type}"
        else:
            # Analyze user intent
            intent_result = self.intent_analyzer.analyze(user_message)
            work_type = intent_result['classification']
            confidence = intent_result['confidence']
            reason = intent_result.get('reasoning', '')
            
            logger.info(f"Intent analysis: {work_type} (confidence: {confidence:.2f})")
        
        # Handle ambiguous intent
        if work_type == 'unknown' and confidence < 0.7:
            # Prompt user for clarification
            work_type = self._prompt_for_clarification(user_message)
            confidence = 1.0
            reason = f"User specified work type as {work_type}"
        
        # Make decision based on work type and workspace state
        if work_type == 'maintenance':
            # Allow maintenance work even with dirty workspace
            action = 'allow'
            if not reason:
                reason = "Maintenance work detected - allowed even with dirty workspace"
        elif work_type == 'new_work':
            # New work requires clean workspace
            if workspace_state.is_clean:
                action = 'allow'
                if not reason:
                    reason = "New work with clean workspace - allowed"
            else:
                action = 'block'
                if not reason:
                    reason = "New work requires clean workspace - blocked"
        else:
            # Unknown intent - be conservative
            if workspace_state.is_clean:
                action = 'allow'
                reason = "Unknown intent but workspace is clean - allowed"
            else:
                action = 'block'
                reason = "Unknown intent with dirty workspace - blocked for safety"
        
        decision = WorkflowDecision(
            action=action,
            work_type=work_type,
            reason=reason,
            confidence=confidence
        )
        
        logger.info(f"Workflow decision: {decision}")
        return decision
    
    def _prompt_for_clarification(self, user_message: str) -> str:
        """
        Prompt the user to clarify their intent when it's ambiguous.
        
        Args:
            user_message: The original user message
            
        Returns:
            'maintenance' or 'new_work' based on user response
        """
        print("\n⚠️  Ambiguous Intent Detected")
        print(f"Your message: '{user_message}'")
        print("\nPlease clarify the type of work you're doing:")
        print("1. Maintenance work (bug fixes, test fixes, debugging)")
        print("2. New development work (new features, new specs)")
        print()
        
        while True:
            response = input("Enter 'maintenance' or 'new' (or 'm'/'n'): ").strip().lower()
            
            if response in ['maintenance', 'm', '1']:
                logger.info("User clarified: maintenance work")
                return 'maintenance'
            elif response in ['new', 'n', '2', 'new_work']:
                logger.info("User clarified: new work")
                return 'new_work'
            else:
                print("Invalid response. Please enter 'maintenance' or 'new'.")
    
    def format_block_message(self, workspace_state: WorkspaceState) -> str:
        """
        Format a helpful message when work is blocked.
        
        Args:
            workspace_state: Current workspace state
            
        Returns:
            Formatted message explaining why work is blocked
        """
        lines = [
            "⚠️ Cannot start new work - Agent OS workflow incomplete:",
            ""
        ]
        
        if workspace_state.has_uncommitted_changes:
            lines.append("• Uncommitted changes detected")
        
        if workspace_state.has_open_prs:
            pr_list = ", ".join(f"#{pr}" for pr in workspace_state.open_pr_numbers)
            lines.append(f"• Open pull requests: {pr_list}")
        
        lines.extend([
            "",
            "📋 To resolve:",
            "1. Commit or stash your changes",
            "2. Merge or close open PRs",
            "3. Return to a clean workspace",
            "",
            "💡 Tip: If you're fixing bugs or tests, your message should indicate maintenance work.",
            "   Examples: 'fix failing tests', 'debug issue', 'address CI failures'"
        ])
        
        return "\n".join(lines)
    
    def format_allow_message(self, decision: WorkflowDecision) -> str:
        """
        Format a message when work is allowed.
        
        Args:
            decision: The workflow decision
            
        Returns:
            Formatted message explaining why work is allowed
        """
        if decision.work_type == 'maintenance':
            return (
                "✅ Proceeding with maintenance work\n"
                f"   Detected: {decision.reason}\n"
                "   Maintenance work is allowed even with dirty workspace."
            )
        else:
            return (
                "✅ Proceeding with work\n"
                f"   {decision.reason}"
            )
    
    def run(self, tool_name: str, user_message: str) -> int:
        """
        Main entry point for the hook.
        
        Args:
            tool_name: Name of the tool being used
            user_message: User's message/command
            
        Returns:
            0 to allow, 1 to block
        """
        try:
            # Get current workspace state
            workspace_state = self.get_workspace_state()
            
            # Make decision based on intent and state
            decision = self.make_decision(user_message, workspace_state)
            
            # Output appropriate message
            if decision.action == 'block':
                print(self.format_block_message(workspace_state))
                return 1
            else:
                if os.environ.get('VERBOSE'):
                    print(self.format_allow_message(decision))
                return 0
                
        except Exception as e:
            logger.error(f"Error in context-aware hook: {e}")
            # On error, fail open (allow work) to not block users
            return 0


def main():
    """Main entry point for CLI usage."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Context-aware workflow enforcement hook'
    )
    parser.add_argument(
        'phase',
        choices=['pretool', 'posttool', 'userprompt'],
        help='Hook phase'
    )
    parser.add_argument(
        '--config',
        help='Path to configuration file'
    )
    
    args = parser.parse_args()
    
    # Read input from stdin (from Claude Code)
    try:
        input_data = json.loads(sys.stdin.read())
        tool_name = input_data.get('tool_name', '')
        user_message = input_data.get('user_message', '')
    except:
        # Fallback for testing
        tool_name = os.environ.get('TOOL_NAME', 'Edit')
        user_message = os.environ.get('USER_MESSAGE', '')
    
    # Only enforce on write operations
    if args.phase == 'pretool' and tool_name in ['Write', 'Edit', 'MultiEdit']:
        hook = ContextAwareWorkflowHook(args.config)
        exit_code = hook.run(tool_name, user_message)
        sys.exit(exit_code)
    
    # Allow all other operations
    sys.exit(0)


if __name__ == '__main__':
    main()