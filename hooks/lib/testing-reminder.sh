#!/bin/bash

# Simple testing reminder system
# Helps Claude remember to test before claiming completion

# Simple reminder content
get_testing_reminder() {
    echo "⚠️ Before marking complete: Did you actually test it?"
    echo ""
    echo "Quick testing examples:"
    echo "• Scripts: Run it and show output"
    echo "• APIs: Make actual requests with curl"
    echo "• Frontend: Open browser and test the feature"
    echo "• Tests: Run them and show passing results"
    echo ""
    echo "💡 Completion = Working + Tested + Proven"
}

# Check if we should show reminder
should_remind() {
    local input="$1"
    
    # Look for completion words
    if echo "$input" | grep -qi -E "(complete|done|finished|ready|working)" && 
       echo "$input" | grep -qi -E "(@\.agent-os/specs|task|implement)"; then
        return 0
    fi
    
    return 1
}

# Main function
inject_reminder() {
    local user_input="$1"
    
    if should_remind "$user_input"; then
        get_testing_reminder
    fi
}

# If script is called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    inject_reminder "$@"
fi