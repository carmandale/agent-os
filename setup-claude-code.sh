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
for cmd in plan-product create-spec execute-tasks analyze-product hygiene-check update-documentation; do
    if [ -f "$HOME/.claude/commands/${cmd}.md" ]; then
        echo "  ⚠️  ~/.claude/commands/${cmd}.md already exists - skipping"
    else
        curl -s -o "$HOME/.claude/commands/${cmd}.md" "${BASE_URL}/commands/${cmd}.md"
        echo "  ✓ ~/.claude/commands/${cmd}.md"
    fi
done

# Download Claude Code agents for subagent architecture
echo ""
echo "📥 Downloading Claude Code agent definitions to ~/.claude/agents/"
mkdir -p "$HOME/.claude/agents"

# Agent definitions for Builder Methods subagent architecture
agents=("context-fetcher" "date-checker" "file-creator" "git-workflow" "test-runner")
for agent in "${agents[@]}"; do
    if [ -f "$HOME/.claude/agents/${agent}.md" ]; then
        echo "  ⚠️  ~/.claude/agents/${agent}.md already exists - skipping"
    else
        curl -s -o "$HOME/.claude/agents/${agent}.md" "${BASE_URL}/claude-code/agents/${agent}.md"
        echo "  ✓ ~/.claude/agents/${agent}.md"
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
echo "   ~/.claude/agents/          - Claude Code agent definitions"
echo "   ~/.claude/CLAUDE.md        - Claude Code configuration"
echo ""

# Ask about subagent integration
echo "🤖 Automatic Workflow Enhancement Available"
echo "=========================================="
echo ""
echo "Agent OS can automatically integrate with your Claude Code subagents for:"
echo "• Real-time code review during development"
echo "• Comprehensive testing strategies when writing tests"
echo "• Security analysis for auth and data handling"
echo "• Performance optimization for critical paths"
echo "• Code quality improvements beyond linting"
echo ""
echo "All enhancements are automatic - no extra commands needed!"
echo ""
echo "Install automatic subagent integration? (y/n)"
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

# Ask about Claude Code hooks installation  
echo ""
echo "🪝 Claude Code Hooks Available"
echo "==============================="
echo ""
echo "Agent OS Claude Code hooks provide advanced workflow integration:"
echo "• Prevents workflow abandonment after quality checks"
echo "• Auto-commits Agent OS documentation changes"
echo "• Injects contextual project information automatically"
echo ""
echo "These hooks run transparently during your normal Claude Code interactions."
echo ""
echo "Install Claude Code hooks? (y/n)"
read -r hooks_response

if [[ "$hooks_response" == "y" ]]; then
    echo ""
    echo "📥 Installing Claude Code hooks..."
    
    # Check if hooks are already installed
    if [ -f "$HOME/.agent-os/hooks/install-hooks.sh" ]; then
        echo "  ✓ Hook utilities found"
        
        # Run the hooks installation
        if "$HOME/.agent-os/hooks/install-hooks.sh"; then
            echo "  ✅ Claude Code hooks installed successfully!"
        else
            echo "  ⚠️ Claude Code hooks installation failed"
            echo "     You can install them manually by running:"
            echo "     ~/.agent-os/hooks/install-hooks.sh"
        fi
    else
        echo "  ⚠️ Hook utilities not found. Installing from repository..."
        
        # Create hooks directory
        mkdir -p "$HOME/.agent-os/hooks/lib"
        mkdir -p "$HOME/.agent-os/hooks/tests"
        
        # Download hook utilities
        for util in workflow-detector.sh git-utils.sh context-builder.sh; do
            curl -s -o "$HOME/.agent-os/hooks/lib/$util" "${BASE_URL}/hooks/lib/$util"
            echo "  ✓ Downloaded $util"
        done
        
        # Download hook scripts
        for hook in stop-hook.sh post-tool-use-hook.sh user-prompt-submit-hook.sh install-hooks.sh; do
            curl -s -o "$HOME/.agent-os/hooks/$hook" "${BASE_URL}/hooks/$hook"
            chmod +x "$HOME/.agent-os/hooks/$hook"
            echo "  ✓ Downloaded $hook"
        done
        
        # Download configuration
        curl -s -o "$HOME/.agent-os/hooks/claude-code-hooks.json" "${BASE_URL}/hooks/claude-code-hooks.json"
        echo "  ✓ Downloaded claude-code-hooks.json"
        
        # Run installation
        if "$HOME/.agent-os/hooks/install-hooks.sh"; then
            echo "  ✅ Claude Code hooks installed successfully!"
        else
            echo "  ⚠️ Claude Code hooks installation failed"
        fi
    fi
else
    echo ""
    echo "⚠️ Claude Code hooks installation skipped."
    echo ""
    echo "You can install them later by running:"
    echo "  ~/.agent-os/hooks/install-hooks.sh"
    echo ""
    echo "Or download them from:"
    echo "  https://github.com/carmandale/agent-os/hooks/"
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
echo "Check workspace cleanliness and tool configuration with:"
echo "  /hygiene-check"
echo ""
echo "Learn more at https://github.com/carmandale/agent-os"
echo ""
