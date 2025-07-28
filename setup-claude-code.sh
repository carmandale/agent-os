 #!/bin/bash

# Agent OS Claude Code Setup Script
# This script installs Agent OS commands for Claude Code

set -e  # Exit on error

echo "🚀 Agent OS Claude Code Setup"
echo "============================="
echo ""

# Check if Agent OS base installation is present
if [ ! -d "$HOME/.agent-os/instructions" ] || [ ! -d "$HOME/.agent-os/standards" ]; then
    echo "⚠️  Agent OS base installation not found!"
    echo ""
    echo "Please install the Agent OS base installation first:"
    echo ""
    echo "Option 1 - Automatic installation:"
    echo "  curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash"
    echo ""
    echo "Option 2 - Manual installation:"
    echo "  Follow instructions at https://github.com/carmandale/agent-os"
    echo ""
    exit 1
fi

# Base URL for raw GitHub content
BASE_URL="https://raw.githubusercontent.com/carmandale/agent-os/main"

# Create directories
echo "📁 Creating directories..."
mkdir -p "$HOME/.claude/commands"

# Download command files for Claude Code
echo ""
echo "📥 Downloading Claude Code command files to ~/.claude/commands/"

# Commands
for cmd in plan-product create-spec execute-tasks analyze-product hygiene-check enhance; do
    if [ -f "$HOME/.claude/commands/${cmd}.md" ]; then
        echo "  ⚠️  ~/.claude/commands/${cmd}.md already exists - skipping"
    else
        curl -s -o "$HOME/.claude/commands/${cmd}.md" "${BASE_URL}/commands/${cmd}.md"
        echo "  ✓ ~/.claude/commands/${cmd}.md"
    fi
done

# Download Claude Code user CLAUDE.md
echo ""
echo "📥 Downloading Claude Code configuration to ~/.claude/"

if [ -f "$HOME/.claude/CLAUDE.md" ]; then
    echo "  ⚠️  ~/.claude/CLAUDE.md already exists - skipping"
else
    curl -s -o "$HOME/.claude/CLAUDE.md" "${BASE_URL}/claude-code/user/CLAUDE.md"
    echo "  ✓ ~/.claude/CLAUDE.md"
fi

echo ""
echo "✅ Agent OS Claude Code installation complete!"
echo ""
echo "📍 Files installed to:"
echo "   ~/.claude/commands/        - Claude Code commands"
echo "   ~/.claude/CLAUDE.md        - Claude Code configuration"
echo ""

# Ask about subagent integration
echo "🤖 Enhanced Workflows Available"
echo "==============================="
echo ""
echo "Agent OS can integrate with your existing Claude Code subagents for:"
echo "• Professional PRDs and architecture review (automatic)"
echo "• Comprehensive testing strategies (automatic)"
echo "• Security analysis when you want it (opt-in only)"
echo "• Code quality improvements (automatic)"
echo ""
echo "Would you like to install the subagent integration? (y/n)"
read -r response

if [[ "$response" == "y" ]]; then
    echo ""
    echo "📥 Installing subagent integration..."
    
    # Download and run subagent setup
    curl -s -o "/tmp/setup-subagent-integration.sh" "${BASE_URL}/integrations/setup-subagent-integration.sh"
    if [ -f "/tmp/setup-subagent-integration.sh" ]; then
        chmod +x "/tmp/setup-subagent-integration.sh"
        /tmp/setup-subagent-integration.sh
        rm -f "/tmp/setup-subagent-integration.sh"
    else
        echo "⚠️ Could not download subagent integration setup. You can install it later from:"
        echo "   https://github.com/carmandale/agent-os/integrations/"
    fi
else
    echo ""
    echo "⚠️ Subagent integration skipped."
    echo ""
    echo "You can install it later by running:"
    echo "  curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/integrations/setup-subagent-integration.sh | bash"
fi

echo ""
echo "Next steps:"
echo ""
echo "Initiate Agent OS in a new product's codebase with:"
echo "  /plan-product"
echo ""
echo "Initiate Agent OS in an existing product's codebase with:"
echo "  /analyze-product"
echo ""
echo "Initiate a new feature with:"
echo "  /create-spec (or simply ask 'what's next?')"
echo ""
echo "Build and ship code with:"
echo "  /execute-tasks"
echo ""
echo "Add professional enhancements when ready:"
echo "  /enhance --security --architecture"
echo ""
echo "Check workspace cleanliness and tool configuration with:"
echo "  /hygiene-check"
echo ""
echo "Learn more at https://github.com/carmandale/agent-os"
echo ""
