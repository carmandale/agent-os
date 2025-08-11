#!/bin/bash

# Agent OS v4 Alias Function
# This function provides the aos command with background task support

function aos() {
    # Check if aos-v4 is available
    local aos_v4_path
    
    # Priority order: local install, then ~/.agent-os/tools/
    if [ -f "$HOME/.agent-os/tools/aos-v4" ]; then
        aos_v4_path="$HOME/.agent-os/tools/aos-v4"
    elif command -v aos-v4 >/dev/null 2>&1; then
        aos_v4_path="aos-v4"
    else
        # Fallback: download and execute directly
        echo "⚠️  aos v4 not found locally. Using latest from GitHub..."
        local temp_file="/tmp/aos-v4-$$"
        
        if curl -sSL -o "$temp_file" "https://raw.githubusercontent.com/carmandale/agent-os/main/tools/aos-v4"; then
            chmod +x "$temp_file"
            "$temp_file" "$@"
            local exit_code=$?
            rm -f "$temp_file"
            return $exit_code
        else
            echo "❌ Failed to download aos v4. Please check your internet connection."
            return 1
        fi
    fi
    
    # Execute aos-v4 with all arguments
    "$aos_v4_path" "$@"
}

# Create alias for backwards compatibility
alias agentos=aos