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
HOOKS_CONFIG="$CLAUDE_DIR/hooks"

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
for hook in "stop-hook.sh" "post-tool-use-hook.sh" "user-prompt-submit-hook.sh"; do
    if [ ! -f "$HOOKS_DIR/$hook" ]; then
        echo "❌ Hook script not found: $hook"
        exit 1
    fi
done

echo "✅ Prerequisites check passed"
echo ""

# Create Claude Code hooks directory
echo "📁 Setting up Claude Code hooks directory..."
mkdir -p "$HOOKS_CONFIG"

# Check if hooks are already installed
if [ -f "$HOOKS_CONFIG/agent-os-hooks.json" ]; then
    echo "⚠️  Agent OS hooks are already installed"
    echo ""
    echo "Do you want to reinstall/update them? (y/n)"
    read -r response
    
    if [[ "$response" != "y" ]]; then
        echo "Installation cancelled"
        exit 0
    fi
    
    echo ""
    echo "🔄 Updating existing installation..."
fi

# Copy hooks configuration
echo "📋 Installing hooks configuration..."
cp "$HOOKS_DIR/claude-code-hooks.json" "$HOOKS_CONFIG/agent-os-hooks.json"
echo "  ✓ Copied hooks configuration to ~/.claude/hooks/"

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
echo "   ~/.claude/hooks/agent-os-hooks.json - Hook configuration"
echo "   ~/.agent-os/hooks/ - Hook scripts and utilities"
echo "   ~/.agent-os/logs/ - Hook execution logs"
echo ""
echo "🔧 Hooks enabled:"
echo "   • Stop Hook - Prevents workflow abandonment"
echo "   • Post Tool Use Hook - Auto-commits documentation"
echo "   • User Prompt Submit Hook - Injects project context"
echo ""
echo "💡 How it works:"
echo "   • Hooks run automatically during Claude Code interactions"
echo "   • No manual intervention required"
echo "   • Check ~/.agent-os/logs/ for detailed execution logs"
echo ""
echo "🚀 Your Agent OS workflows are now enhanced with automatic enforcement!"
echo ""

# Check if there are any existing Agent OS projects to enable context for
if find . -maxdepth 3 -name ".agent-os" -type d 2>/dev/null | grep -q ".agent-os"; then
    echo "🏗️ Agent OS projects detected in current directory tree"
    echo "   Context injection will be automatically available for these projects"
    echo ""
fi

echo "For more information, visit: https://github.com/carmandale/agent-os"