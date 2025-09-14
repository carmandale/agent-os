#!/bin/bash

# install-hooks.sh
# Install Agent OS Claude Code hooks

set -e

echo "🪝 Installing Agent OS Claude Code Hooks"
echo "======================================="
echo ""

# Configuration
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check if Claude Code is installed
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "❌ Claude Code directory not found at ~/.claude/"
    echo ""
    echo "Please ensure Claude Code is installed before installing hooks."
    echo "Visit https://claude.ai/code for installation instructions."
    exit 1
fi

# Check if Agent OS hooks directory exists
if [ ! -d "$HOOKS_DIR" ]; then
    echo "❌ Agent OS hooks directory not found"
    echo "Expected: $HOOKS_DIR"
    exit 1
fi

# Check if hook scripts exist
for hook in "stop-hook.sh" "user-prompt-submit-hook.sh" "pre-bash-hook.sh" "post-bash-hook.sh" "notify-hook.sh"; do
    if [ ! -f "$HOOKS_DIR/$hook" ]; then
        echo "❌ Hook script not found: $hook"
        exit 1
    fi
done

echo "✅ Prerequisites check passed"
echo ""

# Create Claude Code settings file if it doesn't exist
echo "📁 Setting up Claude Code settings..."
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
    echo "  ✓ Created ~/.claude/settings.json"
fi

# Check if Agent OS hooks are already installed
if grep -q "agent-os-hooks-v" "$SETTINGS_FILE" 2>/dev/null; then
    echo "⚠️  Agent OS hooks are already installed"
    echo ""
    
    # Skip prompt if running non-interactively (piped input)
    if [ ! -t 0 ]; then
        echo "Running in non-interactive mode - updating hooks..."
        echo ""
    else
        echo "Do you want to reinstall/update them? (y/n)"
        read -r response
        
        if [[ "$response" != "y" ]]; then
            echo "Installation cancelled"
            exit 0
        fi
    fi
    
    echo ""
    echo "🔄 Updating existing installation..."
fi

# Install hooks configuration into settings.json
echo "📋 Installing hooks configuration..."
python3 - <<EOF
import json
import os
import sys

# Read current settings
settings_file = "$SETTINGS_FILE"
try:
    with open(settings_file, 'r') as f:
        settings = json.load(f)
except:
    settings = {}

# Replace hooks section completely to ensure clean installation with new format
agent_os_dir = os.path.expanduser('~/.agent-os/hooks')

# Start with completely new hooks configuration
hooks = {}

# Stop hooks (workflow abandonment prevention)
hooks['Stop'] = [{
    "hooks": [{
        "type": "command",
        "command": f"{agent_os_dir}/stop-hook.sh"
    }]
}]

# PostToolUse hooks (documentation auto-commit)
hooks['PostToolUse'] = [{
    "hooks": [{
        "type": "command",
        "command": f"{agent_os_dir}/post-bash-hook.sh"
    }]
}]

# UserPromptSubmit hooks (context injection)
hooks['UserPromptSubmit'] = [{
    "hooks": [{
        "type": "command",
        "command": f"{agent_os_dir}/user-prompt-submit-hook.sh"
    }]
}]

# PreToolUse hooks (Bash observation)
hooks['PreToolUse'] = [{
    "matcher": "Bash",
    "hooks": [{
        "type": "command",
        "command": f"{agent_os_dir}/pre-bash-hook.sh"
    }]
}]

# Notification hooks
hooks['Notification'] = [{
    "hooks": [{
        "type": "command",
        "command": f"{agent_os_dir}/notify-hook.sh"
    }]
}]

# Replace the hooks section with our new configuration
settings['hooks'] = hooks

# Add marker for detection (update to v3 to indicate new format)
settings['agentOsHooksVersion'] = 'agent-os-hooks-v3'

# Remove old marker if it exists
if '_agent_os_hooks' in settings:
    del settings['_agent_os_hooks']

# Preserve other settings like statusLine and model
# (The python script automatically preserves existing keys)

# Write updated settings
with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)

print("  ✓ Integrated hooks into ~/.claude/settings.json with new format")
EOF

# Ensure hook scripts are executable
echo "🔧 Setting up hook scripts..."
chmod +x "$HOOKS_DIR"/*.sh
chmod +x "$HOOKS_DIR/lib"/*.sh
echo "  ✓ Made hook scripts executable"

# Create log directory
mkdir -p "$HOME/.agent-os/logs"
echo "  ✓ Created log directory at ~/.agent-os/logs/"

# Verify installation
echo ""
echo "✅ Verifying installation..."

# Verify hooks are in settings.json
if grep -q "agent-os-hooks-v3" "$SETTINGS_FILE" 2>/dev/null; then
    echo "  ✓ Agent OS hooks integrated into ~/.claude/settings.json"
else
    echo "  ⚠️ Hook integration verification failed"
fi

# Test hook scripts
echo "🧪 Testing hook scripts..."

# Test workflow detector
if "$HOOKS_DIR/lib/workflow-detector.sh" is_workflow "test @.agent-os/instructions/create-spec.md" | grep -q "true"; then
    echo "  ✓ workflow-detector.sh working"
else
    echo "  ⚠️ workflow-detector.sh test failed"
fi

# Test git utils (if in git repo)
if git rev-parse --git-dir >/dev/null 2>&1; then
    if "$HOOKS_DIR/lib/git-utils.sh" status >/dev/null 2>&1; then
        echo "  ✓ git-utils.sh working"
    else
        echo "  ⚠️ git-utils.sh test failed"
    fi
else
    echo "  ℹ️ git-utils.sh not tested (not in git repository)"
fi

# Test task status sync
if [ -f "$HOOKS_DIR/task-status-sync.sh" ]; then
    if "$HOOKS_DIR/task-status-sync.sh" 2>/dev/null; then
        echo "  ✓ task-status-sync.sh working"
    else
        echo "  ℹ️ task-status-sync.sh not tested (no active specs)"
    fi
else
    echo "  ⚠️ task-status-sync.sh not found"
fi

# Test context builder
if "$HOOKS_DIR/lib/context-builder.sh" project >/dev/null 2>&1; then
    echo "  ✓ context-builder.sh working"
else
    echo "  ⚠️ context-builder.sh test failed"
fi

echo ""
echo "🎉 Agent OS Claude Code hooks installation complete!"
echo ""
echo "📍 Hooks installed:"
echo "   ~/.claude/settings.json - Hook configuration (integrated)"
echo "   ~/.agent-os/hooks/ - Hook scripts and utilities"  
echo "   ~/.agent-os/logs/ - Hook execution logs"
echo ""
echo "🔧 Hooks enabled:"
echo "   • Pre Bash Hook - Observes and classifies Bash commands"
echo "   • Post Bash Hook - Reports Bash execution results"
echo "   • Task Context Hook - Injects project context for Task tool"
echo "   • Notification Hook - Provides helpful reminders"
echo ""
echo "💡 How it works:"
echo "   • Hooks run automatically during Claude Code interactions"
echo "   • No manual intervention required"
echo "   • Check ~/.agent-os/logs/ for detailed execution logs"
echo ""
echo "🚀 Your Agent OS workflows are now enhanced with automatic bash observation!"
echo ""

# Check if there are any existing Agent OS projects to enable context for
if find . -maxdepth 3 -name ".agent-os" -type d 2>/dev/null | grep -q ".agent-os"; then
    echo "🏗️ Agent OS projects detected in current directory tree"
    echo "   Context injection will be automatically available for these projects"
    echo ""
fi

echo "For more information, visit: https://github.com/carmandale/agent-os"