#!/bin/bash

# uninstall-hooks.sh
# Uninstall Agent OS Claude Code hooks

set -e

echo "🗑️  Uninstalling Agent OS Claude Code Hooks"
echo "==========================================="
echo ""

# Configuration
CLAUDE_DIR="$HOME/.claude"
HOOKS_CONFIG="$CLAUDE_DIR/hooks"
AGENT_OS_LOGS="$HOME/.agent-os/logs"

# Check if hooks are installed
if [ ! -f "$HOOKS_CONFIG/agent-os-hooks.json" ]; then
    echo "ℹ️  Agent OS hooks are not currently installed"
    echo ""
    echo "Nothing to uninstall."
    exit 0
fi

echo "🔍 Found Agent OS hooks installation"
echo ""

# Confirm uninstallation
echo "This will remove:"
echo "  • ~/.claude/hooks/agent-os-hooks.json"
echo "  • Hook integration with Claude Code"
echo ""
echo "Note: Hook scripts in ~/.agent-os/hooks/ will be preserved"
echo "      Log files in ~/.agent-os/logs/ will be preserved"
echo ""
echo "Are you sure you want to uninstall Agent OS hooks? (y/n)"
read -r response

if [[ "$response" != "y" ]]; then
    echo "Uninstallation cancelled"
    exit 0
fi

echo ""
echo "🗑️  Removing Agent OS hooks..."

# Remove hooks configuration
if [ -f "$HOOKS_CONFIG/agent-os-hooks.json" ]; then
    rm -f "$HOOKS_CONFIG/agent-os-hooks.json"
    echo "  ✓ Removed ~/.claude/hooks/agent-os-hooks.json"
fi

# Check if hooks directory is empty and remove if so
if [ -d "$HOOKS_CONFIG" ] && [ ! "$(ls -A "$HOOKS_CONFIG" 2>/dev/null)" ]; then
    rmdir "$HOOKS_CONFIG"
    echo "  ✓ Removed empty ~/.claude/hooks/ directory"
fi

echo ""
echo "✅ Agent OS Claude Code hooks uninstalled successfully!"
echo ""
echo "📍 What was removed:"
echo "   • Hook configuration from Claude Code"
echo "   • Automatic workflow enforcement"
echo "   • Context injection during interactions"
echo ""
echo "📍 What was preserved:"
echo "   • Hook scripts at ~/.agent-os/hooks/"
echo "   • Log files at ~/.agent-os/logs/"
echo "   • Agent OS core installation"
echo ""
echo "💡 To reinstall hooks later:"
echo "   ~/.agent-os/hooks/install-hooks.sh"
echo ""
echo "💡 To completely remove all Agent OS hooks files:"
echo "   rm -rf ~/.agent-os/hooks/"
echo "   rm -rf ~/.agent-os/logs/"
echo ""