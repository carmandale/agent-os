#!/usr/bin/env python3
"""
Agent OS User Experience System
===============================
Enhances user experience with clear feedback messages, guidance when work is
blocked or allowed, and educational content about Agent OS workflow concepts.

Usage:
    from user_experience_system import UserExperienceSystem, GuidanceType
    
    ux_system = UserExperienceSystem()
    
    # Create feedback for intent detection results
    feedback = ux_system.create_intent_feedback(intent_result, user_message)
    
    # Create guidance when work is blocked
    guidance = ux_system.create_blocked_work_guidance(intent_result, workspace_state, user_message)
"""

import os
import time
from dataclasses import dataclass
from enum import Enum
from typing import Dict, Any, List, Optional

# Import existing modules
from intent_analyzer import WorkIntentResult, IntentType, log_debug
from manual_override_system import OverrideDecision, OverrideType


class GuidanceType(Enum):
    """Types of user guidance messages."""
    ALLOWED_MAINTENANCE = "allowed_maintenance"
    NEW_WORK_GUIDANCE = "new_work_guidance" 
    BLOCKED_NEW_WORK = "blocked_new_work"
    AMBIGUOUS_GUIDANCE = "ambiguous_guidance"
    EDUCATIONAL = "educational"
    DEBUG_INFO = "debug_info"


@dataclass
class FeedbackMessage:
    """User feedback message with guidance type and content."""
    message_type: GuidanceType
    message: str
    confidence_display: Optional[str] = None
    next_steps: Optional[List[str]] = None
    
    def __str__(self) -> str:
        return f"FeedbackMessage(type={self.message_type.value}, message='{self.message[:50]}...')"


class UserExperienceSystem:
    """
    Enhances user experience with clear feedback, guidance, and educational content.
    
    Provides context-aware messaging for intent detection results, workspace state
    guidance, and educational content to help users understand Agent OS workflows.
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the UserExperienceSystem.
        
        Args:
            config: Optional configuration dictionary
        """
        self.config = config or {}
        self.verbose_debug = os.environ.get("AGENT_OS_DEBUG_VERBOSE", "").lower() == "true"
        
    def create_intent_feedback(self, intent_result: WorkIntentResult, user_message: str) -> FeedbackMessage:
        """
        Create feedback message for intent detection results.
        
        Args:
            intent_result: Result from intent analyzer
            user_message: Original user message
            
        Returns:
            FeedbackMessage with appropriate guidance
        """
        confidence_display = self._format_confidence_display(intent_result.confidence)
        
        if intent_result.intent_type == IntentType.MAINTENANCE:
            message = (
                f"🔧 **Maintenance Work Detected**\n\n"
                f"Your message: '{user_message}'\n"
                f"Confidence: {confidence_display}\n"
                f"Reasoning: {intent_result.reasoning}\n\n"
                f"✅ **You are allowed to proceed** with maintenance work regardless of workspace state.\n"
                f"This includes fixing bugs, debugging issues, resolving conflicts, and updating dependencies."
            )
            
            if intent_result.matched_patterns:
                message += f"\n\n📋 **Matched patterns:** {', '.join(intent_result.matched_patterns[:3])}"
                
            return FeedbackMessage(
                message_type=GuidanceType.ALLOWED_MAINTENANCE,
                message=message,
                confidence_display=confidence_display,
                next_steps=["Proceed with your maintenance work", "Commit changes when complete"]
            )
            
        elif intent_result.intent_type == IntentType.NEW_WORK:
            message = (
                f"🚀 **New Work Detected**\n\n"
                f"Your message: '{user_message}'\n"
                f"Confidence: {confidence_display}\n"
                f"Reasoning: {intent_result.reasoning}\n\n"
                f"⚠️ **New work requires a clean workspace and proper planning.**\n"
                f"Please ensure you have:\n"
                f"• Clean git status (no uncommitted changes)\n"
                f"• No open PRs that need attention\n" 
                f"• Proper feature specification via Agent OS specs"
            )
            
            if intent_result.matched_patterns:
                message += f"\n\n📋 **Matched patterns:** {', '.join(intent_result.matched_patterns[:3])}"
                
            return FeedbackMessage(
                message_type=GuidanceType.NEW_WORK_GUIDANCE,
                message=message,
                confidence_display=confidence_display,
                next_steps=["Check workspace status", "Create feature spec if needed", "Proceed with implementation"]
            )
            
        else:  # AMBIGUOUS
            message = (
                f"🤔 **Ambiguous Work Intent**\n\n"
                f"Your message: '{user_message}'\n"
                f"Confidence: {confidence_display}\n"
                f"Reasoning: {intent_result.reasoning}\n\n"
                f"⚡ **Clarification needed** to determine if this is maintenance or new work.\n"
                f"Consider using manual override flags or interactive mode:\n"
                f"• `--force-maintenance` - Treat as maintenance work\n"
                f"• `--force-new-work` - Treat as new feature work\n"
                f"• `--interactive` - Get prompted to choose"
            )
            
            return FeedbackMessage(
                message_type=GuidanceType.AMBIGUOUS_GUIDANCE,
                message=message,
                confidence_display=confidence_display,
                next_steps=["Clarify work intent", "Use override flags if needed", "Consider rewording your request"]
            )
    
    def create_blocked_work_guidance(self, intent_result: WorkIntentResult, 
                                   workspace_state: Dict[str, Any], 
                                   user_message: str) -> FeedbackMessage:
        """
        Create guidance message when work is blocked.
        
        Args:
            intent_result: Intent analysis result
            workspace_state: Current workspace state information
            user_message: Original user message
            
        Returns:
            FeedbackMessage with blocking guidance and next steps
        """
        issues = []
        next_steps = []
        
        if workspace_state.get('has_uncommitted_changes'):
            issues.append("uncommitted changes in working directory")
            next_steps.append("1. Review changes with `git diff`")
            next_steps.append("2. Commit changes with `git add -A && git commit -m 'descriptive message'`")
            
        if workspace_state.get('has_untracked_files'):
            issues.append("untracked files present")
            next_steps.append("3. Add untracked files with `git add` or add to `.gitignore`")
            
        if workspace_state.get('has_open_prs'):
            issues.append("open PRs requiring attention")
            next_steps.append("4. Review and merge open PRs")
            
        current_branch = workspace_state.get('current_branch', 'unknown')
        if current_branch not in ['main', 'master', 'develop']:
            issues.append(f"working on feature branch '{current_branch}'")
            next_steps.append("5. Switch to main branch or complete current feature")
        
        issues_text = ", ".join(issues)
        next_steps_text = "\n".join(next_steps) if next_steps else "Clean up workspace and try again"
        
        message = (
            f"🚫 **New Work Blocked**\n\n"
            f"Your message: '{user_message}'\n"
            f"Intent: New feature development (confidence: {self._format_confidence_display(intent_result.confidence)})\n\n"
            f"❌ **Workspace issues preventing new work:**\n"
            f"• {issues_text}\n\n"
            f"🛠️ **Next steps to resolve:**\n"
            f"{next_steps_text}\n\n"
            f"💡 **Why this matters:** New feature development requires a clean workspace to avoid "
            f"conflicts and ensure proper version control history."
        )
        
        return FeedbackMessage(
            message_type=GuidanceType.BLOCKED_NEW_WORK,
            message=message,
            confidence_display=self._format_confidence_display(intent_result.confidence),
            next_steps=next_steps
        )
    
    def create_allowed_work_confirmation(self, intent_result: WorkIntentResult,
                                       workspace_state: Dict[str, Any],
                                       user_message: str) -> FeedbackMessage:
        """
        Create confirmation message when work is allowed to proceed.
        
        Args:
            intent_result: Intent analysis result
            workspace_state: Current workspace state information  
            user_message: Original user message
            
        Returns:
            FeedbackMessage with confirmation and guidance
        """
        workspace_notes = []
        
        if workspace_state.get('has_uncommitted_changes'):
            workspace_notes.append("uncommitted changes")
        if workspace_state.get('has_untracked_files'):
            workspace_notes.append("untracked files")
        if workspace_state.get('has_open_prs'):
            workspace_notes.append("open PRs")
            
        workspace_status = ", ".join(workspace_notes) if workspace_notes else "clean workspace"
        
        message = (
            f"✅ **Proceeding with Maintenance Work**\n\n"
            f"Your message: '{user_message}'\n"
            f"Intent: Maintenance work (confidence: {self._format_confidence_display(intent_result.confidence)})\n"
            f"Workspace status: {workspace_status}\n\n"
            f"🔧 **You are allowed to proceed** with maintenance work in the current workspace state.\n"
            f"This is appropriate for bug fixes, debugging, testing fixes, and dependency updates.\n\n"
            f"📝 **Remember to:** Commit your changes when the maintenance work is complete."
        )
        
        return FeedbackMessage(
            message_type=GuidanceType.ALLOWED_MAINTENANCE,
            message=message,
            confidence_display=self._format_confidence_display(intent_result.confidence),
            next_steps=["Proceed with maintenance work", "Test your changes", "Commit when complete"]
        )
    
    def create_educational_message(self, context: str, user_message: str) -> str:
        """
        Create educational content tailored to specific context.
        
        Args:
            context: Context for educational content (e.g., "blocked_new_work", "allowed_maintenance")
            user_message: Original user message for personalization
            
        Returns:
            Educational content string
        """
        base_content = """
📚 **Understanding Agent OS Work Types**

Agent OS distinguishes between two types of work to optimize your development workflow:

**🔧 Maintenance Work** - Fixing and maintaining existing functionality:
• Fix failing tests, bugs, or compilation errors
• Debug performance issues or authentication problems  
• Resolve merge conflicts or CI pipeline failures
• Update dependencies to fix security issues
• Refactor existing code without adding new features

**🚀 New Work** - Building new features and functionality:
• Implement new user interfaces, dashboards, or components
• Create new API endpoints, services, or integrations
• Build new authentication, payment, or notification systems
• Add entirely new features or user-facing capabilities
• Design new system architecture or data models

**💡 Why This Distinction Matters:**
• Maintenance work can proceed with a "messy" workspace (uncommitted changes, open PRs)
• New work requires a clean workspace and proper planning to prevent conflicts
• This keeps your codebase organized and reduces merge conflicts
"""
        
        if context == "blocked_new_work":
            specific_content = f"""
**🚫 Your Current Situation:**
Your message "{user_message}" was classified as new work, but your workspace has uncommitted changes or open PRs.

**🛠️ Why We Require Clean Workspace for New Work:**
• Prevents mixing unrelated changes in git history
• Reduces risk of merge conflicts
• Ensures proper feature isolation and testing
• Maintains clear commit history for code reviews

**✅ Quick Resolution:**
1. Finish and commit your current work, OR
2. Use `--force-maintenance` flag if this is actually maintenance work
"""
            
        elif context == "allowed_maintenance":
            specific_content = f"""
**✅ Your Current Situation:**
Your message "{user_message}" was classified as maintenance work, so you can proceed immediately.

**🔧 Benefits of Maintenance Work Classification:**
• Continue working on bug fixes without stopping to clean workspace
• Fix urgent issues even with work-in-progress changes
• Maintain development momentum for debugging sessions
• Handle hotfixes and critical issues efficiently
"""
            
        elif context == "ambiguous_intent":
            specific_content = f"""
**🤔 Your Current Situation:**
Your message "{user_message}" could be interpreted as either maintenance or new work.

**🎯 How to Clarify:**
• If you're fixing something broken → Use `--force-maintenance`
• If you're building something new → Use `--force-new-work` 
• If you're unsure → Use `--interactive` for guided prompts
• Consider rewording your message to be more specific

**💡 Examples of Clear Messages:**
• Maintenance: "fix authentication bug", "debug failing tests", "resolve merge conflict"
• New Work: "implement user dashboard", "create payment integration", "build notification system"
"""
            
        else:
            specific_content = ""
            
        return base_content + specific_content
    
    def create_debug_output(self, intent_result: WorkIntentResult, 
                          user_message: str,
                          processing_time: float,
                          pattern_matches: Dict[str, List[str]]) -> str:
        """
        Create debugging output for troubleshooting intent decisions.
        
        Args:
            intent_result: Intent analysis result
            user_message: Original user message
            processing_time: Time taken for analysis
            pattern_matches: Dictionary of pattern matches by category
            
        Returns:
            Formatted debug output string
        """
        debug_output = []
        
        if self.verbose_debug:
            debug_output.append("🐛 **VERBOSE DEBUG OUTPUT**")
            debug_output.append("=" * 50)
        else:
            debug_output.append("🐛 **DEBUG INFO**")
            
        debug_output.extend([
            f"📝 **User Message:** '{user_message}'",
            f"⏱️ **Processing Time:** {processing_time:.3f}s",
            f"🎯 **Final Decision:** {intent_result.intent_type.value.upper()}",
            f"📊 **Confidence Score:** {intent_result.confidence:.3f}",
            f"💭 **Reasoning:** {intent_result.reasoning}",
            ""
        ])
        
        # Pattern matching details
        if pattern_matches:
            debug_output.append("🔍 **Pattern Matching Details:**")
            for category, matches in pattern_matches.items():
                count = len(matches)
                debug_output.append(f"   {category}: {count} matches")
                if self.verbose_debug and matches:
                    for match in matches[:3]:  # Show first 3 matches
                        debug_output.append(f"     - {match}")
                    if len(matches) > 3:
                        debug_output.append(f"     ... and {len(matches) - 3} more")
            debug_output.append("")
        
        # Performance metrics in verbose mode
        if self.verbose_debug:
            debug_output.extend([
                "⚡ **Performance Metrics:**",
                f"   Intent Analysis: {processing_time:.3f}s",
                f"   Pattern Matching: {processing_time * 0.6:.3f}s (estimated)",
                f"   Decision Logic: {processing_time * 0.4:.3f}s (estimated)",
                ""
            ])
            
        # Configuration info in verbose mode
        if self.verbose_debug:
            debug_output.extend([
                "⚙️ **Configuration:**",
                f"   Debug Mode: {'Verbose' if self.verbose_debug else 'Standard'}",
                f"   Matched Patterns Count: {len(intent_result.matched_patterns)}",
                ""
            ])
        
        return "\n".join(debug_output)
    
    def create_performance_debug_output(self, intent_analysis_time: float,
                                      pattern_matching_time: float,
                                      total_processing_time: float,
                                      memory_usage_mb: float) -> str:
        """
        Create performance-focused debug output.
        
        Args:
            intent_analysis_time: Time for intent analysis
            pattern_matching_time: Time for pattern matching
            total_processing_time: Total processing time
            memory_usage_mb: Memory usage in MB
            
        Returns:
            Formatted performance debug output
        """
        return f"""
⚡ **Performance Debug Output**

🕐 **Timing Breakdown:**
   Intent Analysis: {intent_analysis_time:.3f}s
   Pattern Matching: {pattern_matching_time:.3f}s  
   Total Processing: {total_processing_time:.3f}s

💾 **Memory Usage:**
   Current: {memory_usage_mb:.1f} MB

📈 **Performance Status:**
   Target: <100ms for intent analysis
   Actual: {total_processing_time * 1000:.1f}ms
   Status: {'✅ PASS' if total_processing_time < 0.1 else '❌ SLOW'}
"""
    
    def explain_confidence_score(self, confidence: float, 
                                pattern_matches: List[str],
                                total_patterns: int) -> str:
        """
        Explain confidence score to users in understandable terms.
        
        Args:
            confidence: Confidence score (0-1)
            pattern_matches: List of matched patterns
            total_patterns: Total number of patterns checked
            
        Returns:
            User-friendly confidence explanation
        """
        percentage = confidence * 100
        match_ratio = f"{len(pattern_matches)} out of {total_patterns}"
        
        if confidence >= 0.8:
            confidence_level = "Very High"
        elif confidence >= 0.6:
            confidence_level = "High"  
        elif confidence >= 0.4:
            confidence_level = "Moderate"
        elif confidence >= 0.2:
            confidence_level = "Low"
        else:
            confidence_level = "Very Low"
            
        explanation = f"""
📊 **Confidence Score Explanation**

**Score:** {percentage:.0f}% ({confidence_level} confidence)
**Pattern Matches:** {match_ratio} patterns matched your message
"""
        
        if pattern_matches:
            explanation += f"**Matched Patterns:** {', '.join(pattern_matches[:3])}"
            if len(pattern_matches) > 3:
                explanation += f" (and {len(pattern_matches) - 3} more)"
        else:
            explanation += "**Matched Patterns:** None - your message was unclear or ambiguous"
            
        if confidence < 0.3:
            explanation += "\n\n💡 **Suggestion:** Try being more specific about whether you're fixing existing functionality or building something new."
            
        return explanation
    
    def create_next_step_guidance(self, scenario: str,
                                workspace_state: Dict[str, Any],
                                user_message: str) -> str:
        """
        Create specific next-step guidance for different scenarios.
        
        Args:
            scenario: Scenario type ("blocked_new_work", "allowed_maintenance", etc.)
            workspace_state: Current workspace state
            user_message: Original user message
            
        Returns:
            Formatted next-step guidance
        """
        if scenario == "blocked_new_work":
            steps = ["🛠️ **Next Steps to Proceed with New Work:**", ""]
            step_num = 1
            
            if workspace_state.get('has_uncommitted_changes'):
                steps.extend([
                    f"{step_num}. **Commit your current changes:**",
                    "   ```bash",
                    "   git add -A",
                    "   git commit -m 'Complete current work before new feature'",
                    "   ```",
                    ""
                ])
                step_num += 1
                
            if workspace_state.get('has_open_prs'):
                steps.extend([
                    f"{step_num}. **Review and merge open PRs:**",
                    "   - Complete code review process",
                    "   - Merge PR when approved",
                    "   - Delete feature branch",
                    ""
                ])
                step_num += 1
                
            steps.extend([
                f"{step_num}. **Create feature specification (recommended):**",
                "   Use Agent OS spec creation for complex features",
                "",
                f"{step_num + 1}. **Start your new work:**",
                f"   Now you can proceed with: '{user_message}'"
            ])
            
            return "\n".join(steps)
            
        elif scenario == "allowed_maintenance":
            return f"""
✅ **You're all set to proceed with maintenance work!**

🔧 **Your task:** {user_message}

📝 **Recommended workflow:**
1. Proceed with fixing/debugging the issue
2. Test your changes to ensure they work
3. Commit your changes when complete
4. Consider updating any relevant documentation

💡 **Tip:** Maintenance work doesn't require a clean workspace, so you can work with your current changes.
"""
        
        else:
            return "No specific guidance available for this scenario."
    
    def explain_pattern_matches(self, matched_patterns: List[str], user_message: str) -> str:
        """
        Explain which patterns matched and why for transparency.
        
        Args:
            matched_patterns: List of matched regex patterns
            user_message: Original user message
            
        Returns:
            Explanation of pattern matches
        """
        if not matched_patterns:
            return "No patterns matched your message, which led to ambiguous classification."
            
        explanation = f"**{len(matched_patterns)} patterns matched your message:**\n\n"
        
        for i, pattern in enumerate(matched_patterns[:5], 1):  # Show first 5
            # Try to make regex patterns more readable
            readable_pattern = pattern.replace(r'\b', '').replace(r'.*', ' ... ').replace(r'\b', '')
            explanation += f"{i}. `{pattern}`\n   Looks for: {readable_pattern}\n"
            
        if len(matched_patterns) > 5:
            explanation += f"\n... and {len(matched_patterns) - 5} more patterns"
            
        explanation += f"\n**In your message:** '{user_message}'"
        
        return explanation
    
    def explain_workspace_state(self, workspace_state: Dict[str, Any]) -> str:
        """
        Explain current workspace state to users.
        
        Args:
            workspace_state: Dictionary with workspace information
            
        Returns:
            User-friendly workspace state explanation
        """
        explanation = ["📁 **Current Workspace State:**", ""]
        
        if workspace_state.get('has_uncommitted_changes'):
            files = workspace_state.get('uncommitted_files', [])
            explanation.append("❌ **Uncommitted changes detected**")
            if files:
                explanation.append(f"   Modified files: {', '.join(files[:3])}")
                if len(files) > 3:
                    explanation.append(f"   ... and {len(files) - 3} more")
        else:
            explanation.append("✅ **No uncommitted changes**")
            
        if workspace_state.get('has_untracked_files'):
            explanation.append("❌ **Untracked files present**")
        else:
            explanation.append("✅ **No untracked files**")
            
        if workspace_state.get('has_open_prs'):
            explanation.append("❌ **Open PRs requiring attention**")
        else:
            explanation.append("✅ **No open PRs**")
            
        current_branch = workspace_state.get('current_branch', 'unknown')
        explanation.append(f"🌿 **Current branch:** {current_branch}")
        
        if current_branch in ['main', 'master', 'develop']:
            explanation.append("   ✅ On main branch - good for new work")
        else:
            explanation.append("   ⚠️ On feature branch - complete current work first for new features")
            
        return "\n".join(explanation)
    
    def enhance_override_message(self, override_decision: OverrideDecision,
                               intent_result: WorkIntentResult,
                               user_message: str) -> str:
        """
        Enhance manual override messages with intent context.
        
        Args:
            override_decision: Override decision from manual override system
            intent_result: Intent analysis result
            user_message: Original user message
            
        Returns:
            Enhanced message with additional context
        """
        base_message = f"""
🎛️ **Manual Override Active**

**Your message:** '{user_message}'
**Original detection:** {intent_result.intent_type.value} (confidence: {self._format_confidence_display(intent_result.confidence)})
**Override applied:** {override_decision.override_type.value.replace('_', ' ').title()}
**Reasoning:** {override_decision.reasoning}
"""
        
        if override_decision.override_type == OverrideType.FORCE_MAINTENANCE:
            base_message += "\n✅ **Proceeding as maintenance work** - workspace hygiene checks bypassed."
        elif override_decision.override_type == OverrideType.FORCE_NEW_WORK:
            base_message += "\n🚀 **Proceeding as new work** - workspace hygiene checks will still apply."
        elif override_decision.override_type == OverrideType.ABORT:
            base_message += "\n⏸️ **Work aborted** - please resolve issues and try again."
            
        return base_message
    
    def enhance_error_message(self, error: str, context: Dict[str, Any]) -> str:
        """
        Enhance error messages with helpful context and guidance.
        
        Args:
            error: Original error message
            context: Context information for the error
            
        Returns:
            Enhanced error message with guidance
        """
        enhanced = f"❌ **Error:** {error}\n\n"
        
        if 'pattern' in context:
            enhanced += f"**Problematic pattern:** `{context['pattern']}`\n"
            
        if 'config_file' in context:
            enhanced += f"**Configuration file:** {context['config_file']}\n"
            
        if 'user_message' in context:
            enhanced += f"**Your message:** '{context['user_message']}'\n"
            
        enhanced += "\n🛠️ **Suggested fixes:**\n"
        enhanced += "1. Check your configuration file for invalid regex patterns\n"
        enhanced += "2. Verify file permissions and accessibility\n" 
        enhanced += "3. Try using default patterns by temporarily renaming config file\n"
        enhanced += "4. Run with `--debug` flag for more detailed error information"
        
        return enhanced
    
    def _format_confidence_display(self, confidence: float) -> str:
        """Format confidence score for user display."""
        percentage = confidence * 100
        
        if confidence >= 0.8:
            return f"High ({percentage:.0f}%)"
        elif confidence >= 0.6:
            return f"Good ({percentage:.0f}%)" 
        elif confidence >= 0.4:
            return f"Moderate ({percentage:.0f}%)"
        elif confidence >= 0.2:
            return f"Low ({percentage:.0f}%)"
        else:
            return f"Very Low ({percentage:.0f}%)"


def main():
    """Command-line interface for testing the user experience system."""
    import argparse
    from intent_analyzer import IntentAnalyzer
    
    parser = argparse.ArgumentParser(description="Test user experience system")
    parser.add_argument("message", help="User message to analyze")
    parser.add_argument("--debug", action="store_true", help="Enable debug output")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose debug output")
    
    args = parser.parse_args()
    
    if args.debug:
        os.environ["AGENT_OS_DEBUG"] = "true"
    if args.verbose:
        os.environ["AGENT_OS_DEBUG_VERBOSE"] = "true"
    
    # Initialize systems
    ux_system = UserExperienceSystem()
    intent_analyzer = IntentAnalyzer()
    
    # Analyze intent
    start_time = time.time()
    intent_result = intent_analyzer.analyze_intent(args.message)
    processing_time = time.time() - start_time
    
    # Create user feedback
    feedback = ux_system.create_intent_feedback(intent_result, args.message)
    
    print("=" * 60)
    print("USER EXPERIENCE SYSTEM TEST")  
    print("=" * 60)
    print(feedback.message)
    
    if args.debug or args.verbose:
        print("\n" + "=" * 60)
        debug_info = ux_system.create_debug_output(
            intent_result, args.message, processing_time,
            {'maintenance': [], 'new_work': []}
        )
        print(debug_info)
    
    # Show educational content for ambiguous cases
    if intent_result.intent_type == IntentType.AMBIGUOUS:
        print("\n" + "=" * 60)
        educational = ux_system.create_educational_message("ambiguous_intent", args.message)
        print(educational)


if __name__ == "__main__":
    main()