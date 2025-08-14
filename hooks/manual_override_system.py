#!/usr/bin/env python3
"""
Agent OS Manual Override System
===============================
Provides manual override capabilities for workflow enforcement, allowing users
to bypass restrictions when needed with clear messaging and proper logging.

Usage:
    from manual_override_system import ManualOverrideSystem, OverrideType
    
    override_system = ManualOverrideSystem()
    
    # Parse command line arguments for overrides
    decision = override_system.parse_override_args(['--force-new-work'])
    
    # Handle ambiguous intent with interactive prompt
    decision = override_system.prompt_for_disambiguation(
        "refactor the authentication system",
        confidence_maintenance=0.4,
        confidence_new_work=0.3
    )
"""

import argparse
import os
import sys
from dataclasses import dataclass
from enum import Enum
from typing import Dict, Any, Optional, List

# Import logging function from intent analyzer
from intent_analyzer import log_debug


class OverrideType(Enum):
    """Enumeration of manual override types."""
    NONE = "none"
    FORCE_NEW_WORK = "force_new_work"
    FORCE_MAINTENANCE = "force_maintenance"
    INTERACTIVE = "interactive"
    ABORT = "abort"
    DISABLED = "disabled"


@dataclass
class OverrideDecision:
    """Result of manual override processing."""
    override_type: OverrideType
    reasoning: str
    user_message: str
    
    def __str__(self) -> str:
        return f"OverrideDecision(type={self.override_type.value}, reasoning='{self.reasoning[:50]}...')"


@dataclass
class OverrideConfig:
    """Configuration for override behavior."""
    prompt_on_ambiguous: bool = True
    allow_manual_override: bool = True
    log_decisions: bool = True
    default_override_choice: str = "prompt"


@dataclass
class HookDecisionResult:
    """Result of applying override to hook decision."""
    allow_work: bool
    reasoning: str
    override_used: bool


def log_override_decision(decision: OverrideDecision, user_message: str) -> None:
    """Log override decision for debugging and audit purposes."""
    log_debug(f"OVERRIDE DECISION: {decision.override_type.value.upper()} for message: '{user_message[:100]}' - {decision.reasoning}")


class ManualOverrideSystem:
    """
    Manages manual overrides for Agent OS workflow enforcement.
    
    Provides command-line flags, interactive prompts, and configuration-based
    override mechanisms to allow users to bypass workflow restrictions when appropriate.
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the ManualOverrideSystem.
        
        Args:
            config: Optional configuration dictionary
        """
        self.config = self._load_config(config or {})
        
    def _load_config(self, config_dict: Dict[str, Any]) -> OverrideConfig:
        """Load override configuration with defaults."""
        override_config = config_dict.get('override_behavior', {})
        
        return OverrideConfig(
            prompt_on_ambiguous=override_config.get('prompt_on_ambiguous', True),
            allow_manual_override=override_config.get('allow_manual_override', True),
            log_decisions=override_config.get('log_decisions', True),
            default_override_choice=override_config.get('default_override_choice', 'prompt')
        )
    
    def parse_override_args(self, args: List[str]) -> OverrideDecision:
        """
        Parse command-line arguments for override flags.
        
        Args:
            args: List of command-line arguments
            
        Returns:
            OverrideDecision with the requested override type
        """
        # Check if overrides are disabled
        if not self.config.allow_manual_override:
            return OverrideDecision(
                override_type=OverrideType.DISABLED,
                reasoning="Manual overrides disabled in configuration",
                user_message=""
            )
        
        parser = argparse.ArgumentParser(add_help=False)
        parser.add_argument('--force-new-work', action='store_true',
                          help='Force treating work as new development (bypasses workspace checks)')
        parser.add_argument('--force-maintenance', action='store_true', 
                          help='Force treating work as maintenance (allows dirty workspace)')
        parser.add_argument('--interactive', action='store_true',
                          help='Use interactive prompts for ambiguous work classification')
        
        try:
            parsed_args, _ = parser.parse_known_args(args)
        except SystemExit:
            # argparse calls sys.exit on error, catch and return no override
            return OverrideDecision(
                override_type=OverrideType.NONE,
                reasoning="Argument parsing failed",
                user_message=""
            )
        
        # Determine override type based on flags
        if parsed_args.force_new_work:
            decision = OverrideDecision(
                override_type=OverrideType.FORCE_NEW_WORK,
                reasoning="Command line override flag --force-new-work",
                user_message="--force-new-work flag used"
            )
        elif parsed_args.force_maintenance:
            decision = OverrideDecision(
                override_type=OverrideType.FORCE_MAINTENANCE,
                reasoning="Command line override flag --force-maintenance", 
                user_message="--force-maintenance flag used"
            )
        elif parsed_args.interactive:
            decision = OverrideDecision(
                override_type=OverrideType.INTERACTIVE,
                reasoning="Interactive mode requested via --interactive flag",
                user_message="--interactive flag used"
            )
        else:
            decision = OverrideDecision(
                override_type=OverrideType.NONE,
                reasoning="No override flags provided",
                user_message=""
            )
        
        # Log decision if configured to do so
        if self.config.log_decisions and decision.override_type != OverrideType.NONE:
            log_override_decision(decision, " ".join(args))
            
        return decision
    
    def prompt_for_disambiguation(self, user_message: str, 
                                confidence_maintenance: float,
                                confidence_new_work: float) -> OverrideDecision:
        """
        Prompt user to disambiguate between maintenance and new work.
        
        Args:
            user_message: The original user message
            confidence_maintenance: Confidence score for maintenance work
            confidence_new_work: Confidence score for new work
            
        Returns:
            OverrideDecision based on user choice
        """
        if not self.config.allow_manual_override:
            return OverrideDecision(
                override_type=OverrideType.DISABLED,
                reasoning="Manual overrides disabled in configuration",
                user_message=""
            )
        
        print(f"\n🤔 **Ambiguous Work Intent Detected**")
        print(f"Message: '{user_message}'")
        print(f"")
        print(f"📊 **Confidence Scores:**")
        print(f"   Maintenance work: {confidence_maintenance:.2f}")
        print(f"   New work: {confidence_new_work:.2f}")
        print(f"")
        print(f"💡 **What type of work is this?**")
        print(f"")
        print(f"   [m] Maintenance work - Fixing, debugging, or maintaining existing features")
        print(f"       → Allows work with dirty workspace, open PRs, uncommitted changes")
        print(f"")
        print(f"   [n] New work - Building new features, implementing new functionality") 
        print(f"       → Requires clean workspace, proper spec planning")
        print(f"")
        print(f"   [a] Abort - Cancel this work and clean up workspace first")
        print(f"")
        
        max_retries = 3
        for attempt in range(max_retries):
            try:
                choice = input("Choose [m/n/a]: ").strip().lower()
                
                if choice == 'm':
                    decision = OverrideDecision(
                        override_type=OverrideType.FORCE_MAINTENANCE,
                        reasoning="User selected maintenance work via interactive prompt",
                        user_message="User chose maintenance work from interactive prompt"
                    )
                    print(f"✅ **Treating as maintenance work** - proceeding with current workspace state")
                    break
                    
                elif choice == 'n':
                    decision = OverrideDecision(
                        override_type=OverrideType.FORCE_NEW_WORK,
                        reasoning="User selected new work via interactive prompt", 
                        user_message="User chose new work from interactive prompt"
                    )
                    print(f"🚀 **Treating as new work** - workspace hygiene checks will apply")
                    break
                    
                elif choice == 'a':
                    decision = OverrideDecision(
                        override_type=OverrideType.ABORT,
                        reasoning="User chose to abort work via interactive prompt",
                        user_message="User aborted work from interactive prompt"
                    )
                    print(f"⏸️  **Work aborted** - please clean up workspace and try again")
                    break
                    
                else:
                    print(f"❌ Invalid choice '{choice}'. Please enter 'm', 'n', or 'a'.")
                    if attempt < max_retries - 1:
                        continue
                    else:
                        # Max retries reached, abort
                        decision = OverrideDecision(
                            override_type=OverrideType.ABORT,
                            reasoning="Max retries reached for interactive prompt",
                            user_message="User failed to provide valid choice"
                        )
                        print(f"❌ **Max retries reached** - aborting work")
                        
            except (EOFError, KeyboardInterrupt):
                # User pressed Ctrl+C or EOF
                decision = OverrideDecision(
                    override_type=OverrideType.ABORT,
                    reasoning="User interrupted interactive prompt",
                    user_message="User interrupted prompt (Ctrl+C or EOF)"
                )
                print(f"\n⏸️  **Work aborted** - user interrupted prompt")
                break
        
        # Log decision
        if self.config.log_decisions:
            log_override_decision(decision, user_message)
            
        return decision
    
    def validate_override_decision(self, decision: OverrideDecision) -> bool:
        """
        Validate an override decision.
        
        Args:
            decision: The override decision to validate
            
        Returns:
            True if decision is valid, False otherwise
        """
        # Check required fields
        if not decision.reasoning or not isinstance(decision.reasoning, str):
            return False
            
        if decision.override_type not in OverrideType:
            return False
            
        # NONE type is valid even without user message
        if decision.override_type == OverrideType.NONE:
            return True
            
        # Other types should have meaningful reasoning
        if len(decision.reasoning.strip()) < 10:
            return False
            
        return True
    
    def log_override_decision(self, decision: OverrideDecision, user_message: str) -> None:
        """Log override decision for debugging and audit purposes."""
        if self.config.log_decisions:
            log_override_decision(decision, user_message)
    
    def get_user_message(self, decision: OverrideDecision) -> str:
        """
        Get informative user message for override decision.
        
        Args:
            decision: The override decision
            
        Returns:
            Formatted message explaining the override
        """
        if decision.override_type == OverrideType.FORCE_NEW_WORK:
            return (
                "🚀 **New Work Override Active**\n"
                "Your work will be treated as new development. Workspace hygiene checks "
                "will still apply - please ensure you have a clean workspace and proper "
                "spec planning before proceeding with new features."
            )
            
        elif decision.override_type == OverrideType.FORCE_MAINTENANCE:
            return (
                "🔧 **Maintenance Work Override Active**\n"
                "Your work will be treated as maintenance. You are allowed to proceed with the "
                "current workspace state, including uncommitted changes and open PRs."
            )
            
        elif decision.override_type == OverrideType.INTERACTIVE:
            return (
                "🤔 **Interactive Mode Active**\n"
                "You will be prompted to clarify work intent when ambiguous messages "
                "are detected."
            )
            
        elif decision.override_type == OverrideType.ABORT:
            return (
                "⏸️  **Work Aborted**\n"
                "Please clean up your workspace and clarify your work intent before "
                "proceeding."
            )
            
        elif decision.override_type == OverrideType.DISABLED:
            return (
                "🚫 **Manual Overrides Disabled**\n"
                "Manual overrides have been disabled in the configuration. Please "
                "follow standard workflow procedures."
            )
            
        else:
            return ""
    
    def get_educational_message(self) -> str:
        """Get educational message about maintenance vs new work."""
        return """
📚 **Understanding Work Types in Agent OS**

**🔧 Maintenance Work** - Fixing and maintaining existing functionality:
• Fix failing tests, bugs, or errors
• Debug performance issues or authentication problems  
• Resolve merge conflicts or CI pipeline failures
• Update dependencies or refactor existing code
• Address security vulnerabilities

**🚀 New Work** - Building new features and functionality:
• Implement new user interfaces or dashboards
• Create new API endpoints or services
• Build new authentication or payment systems
• Add entirely new features or capabilities
• Design new system components

**💡 Why This Matters:**
• Maintenance work can proceed with uncommitted changes and open PRs
• New work requires clean workspace and proper planning via specs
• This keeps your development organized and prevents conflicts

**🤔 When In Doubt:**
• If you're fixing something that's broken → Maintenance
• If you're building something that doesn't exist → New work
• If you're enhancing existing features → Could be either (we'll help you decide!)
"""
    
    def can_override(self, intent_result) -> bool:
        """
        Check if overrides are available for given intent result.
        
        Args:
            intent_result: WorkIntentResult from intent analyzer
            
        Returns:
            True if overrides can be applied
        """
        return (self.config.allow_manual_override and 
                hasattr(intent_result, 'intent_type'))
    
    def apply_override_to_hook_decision(self, original_decision: bool,
                                      override_decision: OverrideDecision,
                                      user_message: str) -> HookDecisionResult:
        """
        Apply override decision to original hook decision.
        
        Args:
            original_decision: Original hook decision (True = allow, False = block)
            override_decision: Override decision to apply
            user_message: Original user message
            
        Returns:
            HookDecisionResult with final decision and reasoning
        """
        if override_decision.override_type == OverrideType.NONE:
            # No override - preserve original decision
            return HookDecisionResult(
                allow_work=original_decision,
                reasoning="No override applied - using original hook decision",
                override_used=False
            )
            
        elif override_decision.override_type == OverrideType.FORCE_NEW_WORK:
            # Force new work - may still be blocked by workspace hygiene
            return HookDecisionResult(
                allow_work=True,  # Override allows work but other checks may apply
                reasoning=f"Manual override: {override_decision.reasoning}",
                override_used=True
            )
            
        elif override_decision.override_type == OverrideType.FORCE_MAINTENANCE:
            # Force maintenance - allows work regardless of workspace state
            return HookDecisionResult(
                allow_work=True,
                reasoning=f"Maintenance override: {override_decision.reasoning}", 
                override_used=True
            )
            
        elif override_decision.override_type == OverrideType.ABORT:
            # Abort work
            return HookDecisionResult(
                allow_work=False,
                reasoning=f"Work aborted: {override_decision.reasoning}",
                override_used=True
            )
            
        elif override_decision.override_type == OverrideType.DISABLED:
            # Overrides disabled - preserve original decision
            return HookDecisionResult(
                allow_work=original_decision,
                reasoning="Manual overrides disabled - using original hook decision",
                override_used=False
            )
            
        else:
            # Unknown override type - preserve original decision
            return HookDecisionResult(
                allow_work=original_decision,
                reasoning=f"Unknown override type {override_decision.override_type} - using original decision",
                override_used=False
            )


def main():
    """Command-line interface for testing the manual override system."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Test manual override system")
    parser.add_argument("message", help="User message to process")
    parser.add_argument("--config", help="Path to configuration file")
    parser.add_argument("--force-new-work", action="store_true", help="Force new work override")
    parser.add_argument("--force-maintenance", action="store_true", help="Force maintenance override")  
    parser.add_argument("--interactive", action="store_true", help="Use interactive mode")
    parser.add_argument("--debug", action="store_true", help="Enable debug logging")
    
    args = parser.parse_args()
    
    if args.debug:
        os.environ["AGENT_OS_DEBUG"] = "true"
    
    override_system = ManualOverrideSystem()
    
    # Parse override arguments
    override_args = []
    if args.force_new_work:
        override_args.append("--force-new-work")
    if args.force_maintenance:
        override_args.append("--force-maintenance")
    if args.interactive:
        override_args.append("--interactive")
    
    decision = override_system.parse_override_args(override_args)
    
    print(f"Override Type: {decision.override_type.value}")
    print(f"Reasoning: {decision.reasoning}")
    print(f"User Message: {decision.user_message}")
    
    # Show user message if available
    user_msg = override_system.get_user_message(decision)
    if user_msg:
        print(f"\n{user_msg}")


if __name__ == "__main__":
    main()