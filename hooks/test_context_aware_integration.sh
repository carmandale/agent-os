#!/bin/bash
# Safe testing script for context-aware workflow enforcement
# This allows testing WITHOUT affecting other Claude Code instances

echo "🧪 Context-Aware Workflow Testing Script"
echo "======================================="
echo ""
echo "This script allows SAFE testing of the context-aware features"
echo "without affecting other Claude Code instances on your system."
echo ""

# Function to run a test
run_test() {
    local message="$1"
    local flags="$2"
    
    echo "📝 Testing: '$message'"
    if [ -n "$flags" ]; then
        echo "   Flags: $flags"
    fi
    
    # Simulate the hook environment
    export CLAUDE_USER_MESSAGE="$message"
    export AGENT_OS_CONTEXT_AWARE="true"
    
    # Run the intent analyzer directly for testing
    python3 -c "
from intent_analyzer import IntentAnalyzer
from user_experience_system import UserExperienceSystem

analyzer = IntentAnalyzer()
ux = UserExperienceSystem()

result = analyzer.analyze_intent('$message')
feedback = ux.create_intent_feedback(result, '$message')

print(f'   Intent: {result.intent_type.value.upper()}')
print(f'   Confidence: {result.confidence:.0%}')
print(f'   Decision: {feedback.message_type.value}')
"
    
    echo ""
}

# Main menu
while true; do
    echo "🎯 Test Options:"
    echo "1. Test maintenance work detection"
    echo "2. Test new work detection"
    echo "3. Test ambiguous cases"
    echo "4. Test your own message"
    echo "5. Enable for real Claude Code (CAREFUL!)"
    echo "6. Disable for Claude Code (SAFE MODE)"
    echo "0. Exit"
    echo ""
    read -p "Choose option: " choice
    
    case $choice in
        1)
            echo ""
            echo "🔧 Testing Maintenance Work Scenarios:"
            echo "--------------------------------------"
            run_test "fix authentication bug"
            run_test "debug performance issues"
            run_test "resolve merge conflicts"
            ;;
        2)
            echo ""
            echo "🚀 Testing New Work Scenarios:"
            echo "-------------------------------"
            run_test "implement user dashboard"
            run_test "create payment system"
            run_test "build notification service"
            ;;
        3)
            echo ""
            echo "🤔 Testing Ambiguous Scenarios:"
            echo "--------------------------------"
            run_test "update user management"
            run_test "improve the dashboard"
            run_test "refactor authentication"
            ;;
        4)
            echo ""
            read -p "Enter your test message: " custom_message
            run_test "$custom_message"
            ;;
        5)
            echo ""
            echo "⚠️  WARNING: This will enable context-aware features for ALL Claude Code instances!"
            read -p "Are you sure? (type 'yes' to confirm): " confirm
            if [ "$confirm" = "yes" ]; then
                echo "export AGENT_OS_CONTEXT_AWARE=true" >> ~/.zshrc
                echo "export AGENT_OS_CONTEXT_AWARE=true" >> ~/.bashrc
                export AGENT_OS_CONTEXT_AWARE=true
                echo "✅ Context-aware features ENABLED globally"
                echo "⚠️  To disable, use option 6"
            else
                echo "❌ Cancelled"
            fi
            ;;
        6)
            echo ""
            # Remove from shell configs
            sed -i.bak '/AGENT_OS_CONTEXT_AWARE/d' ~/.zshrc 2>/dev/null
            sed -i.bak '/AGENT_OS_CONTEXT_AWARE/d' ~/.bashrc 2>/dev/null
            unset AGENT_OS_CONTEXT_AWARE
            echo "✅ Context-aware features DISABLED (safe mode)"
            ;;
        0)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    echo ""
    echo "Press Enter to continue..."
    read
    clear
done