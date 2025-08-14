#!/usr/bin/env python3
"""
Context-Aware Workflow Testing Tool
===================================
Interactive testing tool for validating the context-aware workflow enforcement
system before rollout. Allows testing real user messages and scenarios.

Usage:
    python3 test_context_aware_system.py
    python3 test_context_aware_system.py --message "fix authentication bug"
    python3 test_context_aware_system.py --scenario maintenance
"""

import argparse
import os
import sys
import time
from typing import Dict, Any

# Import our modules
from intent_analyzer import IntentAnalyzer, IntentType
from manual_override_system import ManualOverrideSystem, OverrideType
from user_experience_system import UserExperienceSystem, GuidanceType

def print_separator():
    """Print a visual separator."""
    print("=" * 70)

def print_header(title: str):
    """Print a formatted header."""
    print_separator()
    print(f"  {title}")
    print_separator()

def test_intent_analysis(user_message: str, show_debug: bool = False) -> Dict[str, Any]:
    """Test intent analysis for a user message."""
    print_header("INTENT ANALYSIS TEST")
    
    analyzer = IntentAnalyzer()
    start_time = time.time()
    result = analyzer.analyze_intent(user_message)
    processing_time = time.time() - start_time
    
    print(f"📝 **User Message:** '{user_message}'")
    print(f"⏱️ **Processing Time:** {processing_time:.3f}s")
    print(f"🎯 **Detected Intent:** {result.intent_type.value.upper()}")
    print(f"📊 **Confidence:** {result.confidence:.2f} ({result.confidence*100:.0f}%)")
    print(f"💭 **Reasoning:** {result.reasoning}")
    
    if result.matched_patterns:
        print(f"📋 **Matched Patterns:** {', '.join(result.matched_patterns[:3])}")
        if len(result.matched_patterns) > 3:
            print(f"    ... and {len(result.matched_patterns) - 3} more")
    
    if show_debug:
        print(f"\n🐛 **Debug Info:**")
        print(f"   All matched patterns: {result.matched_patterns}")
        print(f"   Processing time: {processing_time:.3f}s")
        print(f"   Performance status: {'✅ PASS' if processing_time < 0.1 else '❌ SLOW'}")
    
    return {
        'result': result,
        'processing_time': processing_time,
        'performance_ok': processing_time < 0.1
    }

def test_user_experience(user_message: str, intent_result) -> None:
    """Test user experience messaging."""
    print_header("USER EXPERIENCE TEST")
    
    ux_system = UserExperienceSystem()
    feedback = ux_system.create_intent_feedback(intent_result, user_message)
    
    print(f"📤 **Feedback Type:** {feedback.message_type.value}")
    print(f"📝 **Message:**")
    print(feedback.message)
    
    if feedback.next_steps:
        print(f"\n📋 **Next Steps:**")
        for i, step in enumerate(feedback.next_steps, 1):
            print(f"   {i}. {step}")

def test_manual_override_system(user_message: str) -> None:
    """Test manual override system."""
    print_header("MANUAL OVERRIDE TEST")
    
    override_system = ManualOverrideSystem()
    
    # Test command line flags
    test_flags = [
        [],
        ['--force-maintenance'],
        ['--force-new-work'],
        ['--interactive']
    ]
    
    for flags in test_flags:
        decision = override_system.parse_override_args(flags)
        flag_desc = ' '.join(flags) if flags else 'none'
        print(f"🎛️ **Flags:** {flag_desc}")
        print(f"   Override Type: {decision.override_type.value}")
        print(f"   Reasoning: {decision.reasoning}")
        
        user_msg = override_system.get_user_message(decision)
        if user_msg:
            print(f"   User Message: {user_msg.split('**')[1] if '**' in user_msg else user_msg[:50]}...")
        print()

def test_workspace_scenarios() -> None:
    """Test different workspace scenarios."""
    print_header("WORKSPACE SCENARIO TESTS")
    
    scenarios = [
        {
            'name': 'Clean Workspace',
            'state': {
                'has_uncommitted_changes': False,
                'has_untracked_files': False,
                'has_open_prs': False,
                'current_branch': 'main'
            }
        },
        {
            'name': 'Dirty Workspace',
            'state': {
                'has_uncommitted_changes': True,
                'has_untracked_files': True,
                'has_open_prs': True,
                'current_branch': 'feature-branch',
                'uncommitted_files': ['src/auth.py', 'tests/test_auth.py']
            }
        },
        {
            'name': 'Feature Branch Only',
            'state': {
                'has_uncommitted_changes': False,
                'has_untracked_files': False,
                'has_open_prs': False,
                'current_branch': 'feature-dashboard'
            }
        }
    ]
    
    ux_system = UserExperienceSystem()
    
    for scenario in scenarios:
        print(f"📁 **Scenario:** {scenario['name']}")
        explanation = ux_system.explain_workspace_state(scenario['state'])
        print(explanation)
        print()

def run_interactive_test_session():
    """Run an interactive testing session."""
    print_header("INTERACTIVE TESTING SESSION")
    print("Test the context-aware workflow system with your own messages!")
    print("Type 'help' for commands, 'quit' to exit")
    print()
    
    while True:
        try:
            user_input = input("💬 Enter test message (or command): ").strip()
            
            if not user_input:
                continue
                
            if user_input.lower() in ['quit', 'exit', 'q']:
                print("👋 Goodbye!")
                break
                
            if user_input.lower() == 'help':
                print("""
Available commands:
  help              - Show this help
  quit/exit/q       - Exit the session
  scenarios         - Test workspace scenarios
  override          - Test manual override system
  debug <message>   - Test with debug output
  
Or enter any message to test intent analysis and user experience.
""")
                continue
                
            if user_input.lower() == 'scenarios':
                test_workspace_scenarios()
                continue
                
            if user_input.lower() == 'override':
                test_manual_override_system("test message")
                continue
                
            if user_input.lower().startswith('debug '):
                message = user_input[6:]  # Remove 'debug '
                result_data = test_intent_analysis(message, show_debug=True)
                test_user_experience(message, result_data['result'])
                continue
            
            # Regular message testing
            result_data = test_intent_analysis(user_input)
            test_user_experience(user_input, result_data['result'])
            
            # Performance warning
            if not result_data['performance_ok']:
                print(f"\n⚠️ **Performance Warning:** Processing took {result_data['processing_time']:.3f}s (target: <0.1s)")
            
            print()
            
        except (EOFError, KeyboardInterrupt):
            print("\n👋 Goodbye!")
            break

def run_predefined_test_scenarios():
    """Run predefined test scenarios."""
    print_header("PREDEFINED TEST SCENARIOS")
    
    test_messages = [
        # Maintenance work examples
        "fix the failing authentication tests",
        "debug performance issues in login",
        "resolve merge conflicts",
        "address CI pipeline failures",
        "update dependencies to fix security issue",
        
        # New work examples  
        "implement user dashboard feature",
        "create payment integration system",
        "build notification service",
        "add user profile management",
        "design new API endpoints",
        
        # Ambiguous examples
        "refactor the authentication system",
        "update user management",
        "improve the dashboard",
        "enhance security features",
        "optimize database queries"
    ]
    
    print(f"Testing {len(test_messages)} predefined scenarios...")
    print()
    
    performance_issues = []
    
    for i, message in enumerate(test_messages, 1):
        print(f"🧪 **Test {i}/{len(test_messages)}**")
        result_data = test_intent_analysis(message)
        
        if not result_data['performance_ok']:
            performance_issues.append((message, result_data['processing_time']))
        
        # Brief summary
        intent = result_data['result'].intent_type.value.upper()
        confidence = result_data['result'].confidence
        print(f"   Result: {intent} ({confidence:.2f})")
        print()
    
    # Performance summary
    if performance_issues:
        print_header("PERFORMANCE ISSUES DETECTED")
        for message, time_taken in performance_issues:
            print(f"⚠️ '{message[:50]}...' took {time_taken:.3f}s")
    else:
        print("✅ **All tests performed within performance targets!**")

def main():
    """Main testing interface."""
    parser = argparse.ArgumentParser(description="Test context-aware workflow system")
    parser.add_argument("--message", help="Test a specific message")
    parser.add_argument("--scenario", choices=['maintenance', 'new-work', 'ambiguous'],
                       help="Test a scenario type")
    parser.add_argument("--interactive", action="store_true", 
                       help="Run interactive testing session")
    parser.add_argument("--predefined", action="store_true",
                       help="Run predefined test scenarios")
    parser.add_argument("--debug", action="store_true", help="Enable debug output")
    
    args = parser.parse_args()
    
    if args.debug:
        os.environ["AGENT_OS_DEBUG"] = "true"
    
    print_header("CONTEXT-AWARE WORKFLOW TESTING")
    print("🧪 Testing the Agent OS context-aware workflow enforcement system")
    print("📋 This validates intent detection, user experience, and override systems")
    print()
    
    if args.message:
        result_data = test_intent_analysis(args.message, show_debug=args.debug)
        test_user_experience(args.message, result_data['result'])
        test_manual_override_system(args.message)
        
    elif args.scenario:
        scenario_messages = {
            'maintenance': "fix the failing authentication tests",
            'new-work': "implement user dashboard feature", 
            'ambiguous': "refactor the authentication system"
        }
        message = scenario_messages[args.scenario]
        result_data = test_intent_analysis(message, show_debug=args.debug)
        test_user_experience(message, result_data['result'])
        
    elif args.interactive:
        run_interactive_test_session()
        
    elif args.predefined:
        run_predefined_test_scenarios()
        
    else:
        # Default: show overview and run interactive session
        print("🎯 **Quick Test:** Let's test a few examples...")
        print()
        
        # Quick examples
        examples = [
            "fix authentication bug",
            "implement user dashboard", 
            "refactor the auth system"
        ]
        
        for example in examples:
            result_data = test_intent_analysis(example)
            intent = result_data['result'].intent_type.value.upper()
            confidence = result_data['result'].confidence
            print(f"   '{example}' → {intent} ({confidence:.2f})")
        
        print()
        print("💡 **Ready for comprehensive testing!**")
        print("   Use --interactive for hands-on testing")
        print("   Use --predefined for automated scenario testing")
        print("   Use --message 'your test' for specific testing")
        print()

if __name__ == "__main__":
    main()