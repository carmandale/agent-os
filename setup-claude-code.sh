 #!/bin/bash

# Agent OS Claude Code Setup Script
# This script installs Agent OS commands for Claude Code

set -e  # Exit on error

# Initialize flags
OVERWRITE_COMMANDS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --overwrite-commands)
            OVERWRITE_COMMANDS=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --overwrite-commands    Overwrite existing command files"
            echo "  -h, --help              Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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
for cmd in plan-product create-spec execute-tasks analyze-product hygiene-check update-documentation workflow-status workflow-complete; do
    if [ -f "$HOME/.claude/commands/${cmd}.md" ] && [ "$OVERWRITE_COMMANDS" = false ]; then
        echo "  ⚠️  ~/.claude/commands/${cmd}.md already exists - skipping"
    else
        curl -s -o "$HOME/.claude/commands/${cmd}.md" "${BASE_URL}/commands/${cmd}.md"
        if [ -f "$HOME/.claude/commands/${cmd}.md" ] && [ "$OVERWRITE_COMMANDS" = true ]; then
            echo "  ✓ ~/.claude/commands/${cmd}.md (overwritten)"
        else
            echo "  ✓ ~/.claude/commands/${cmd}.md"
        fi
    fi
done

# Download Claude Code agents for subagent architecture
echo ""
echo "📥 Downloading Claude Code agent definitions to ~/.claude/agents/"
mkdir -p "$HOME/.claude/agents"

# Agent definitions for Builder Methods subagent architecture
agents=("context-fetcher" "date-checker" "file-creator" "git-workflow" "test-runner")
for agent in "${agents[@]}"; do
    if [ -f "$HOME/.claude/agents/${agent}.md" ] && [ "$OVERWRITE_COMMANDS" = false ]; then
        echo "  ⚠️  ~/.claude/agents/${agent}.md already exists - skipping"
    else
        curl -s -o "$HOME/.claude/agents/${agent}.md" "${BASE_URL}/claude-code/agents/${agent}.md"
        if [ -f "$HOME/.claude/agents/${agent}.md" ] && [ "$OVERWRITE_COMMANDS" = true ]; then
            echo "  ✓ ~/.claude/agents/${agent}.md (overwritten)"
        else
            echo "  ✓ ~/.claude/agents/${agent}.md"
        fi
    fi
done

# Download Claude Code user CLAUDE.md
echo ""
echo "📥 Claude Code configuration handled by main setup.sh script"

echo ""
echo "✅ Agent OS Claude Code installation complete!"
echo ""
echo "📍 Files installed to:"
echo "   ~/.claude/commands/        - Claude Code commands"
echo "   ~/.claude/agents/          - Claude Code agent definitions"
echo "   ~/.claude/CLAUDE.md        - Claude Code configuration"
echo ""

# Install subagent integration automatically
echo "🤖 Installing Agent OS Subagent Integration"
echo "==========================================="
echo ""
echo "Agent OS subagents provide automatic workflow enhancement:"
echo "• Real-time code review during development"
echo "• Comprehensive testing strategies when writing tests"
echo "• Security analysis for auth and data handling"
echo "• Performance optimization for critical paths"
echo "• Code quality improvements beyond linting"
echo ""

echo "📥 Installing subagent integration..."

# Download and run subagent setup
curl -s -o "/tmp/setup-subagent-integration.sh" "${BASE_URL}/integrations/setup-subagent-integration.sh"
if [ -f "/tmp/setup-subagent-integration.sh" ]; then
    chmod +x "/tmp/setup-subagent-integration.sh"
    /tmp/setup-subagent-integration.sh < /dev/null
    
    # Check if installation actually completed by verifying config file exists
    if [ -f "$HOME/.agent-os/subagent-config.yaml" ]; then
        echo "✅ Subagent integration installed successfully!"
    else
        echo "⚠️ Subagent integration setup did not complete properly"
    fi
    
    rm -f "/tmp/setup-subagent-integration.sh"
else
    echo "⚠️ Could not download subagent integration setup"
fi

# Install Claude Code hooks automatically
echo ""
echo "🪝 Installing Agent OS Claude Code Hooks"
echo "========================================"
echo ""
echo "Agent OS Claude Code hooks provide essential workflow integration:"
echo "• Prevents workflow abandonment after quality checks"
echo "• Auto-commits Agent OS documentation changes"
echo "• Injects contextual project information automatically"
echo ""
echo "These hooks run transparently during your normal Claude Code interactions."
echo ""
echo "📥 Installing Claude Code hooks..."
    
    # Check if hooks are already installed
    if [ -f "$HOME/.agent-os/hooks/install-hooks.sh" ]; then
        echo "  ✓ Hook utilities found"
        
        # Run the hooks installation
        "$HOME/.agent-os/hooks/install-hooks.sh"
        
        # Check if installation actually completed by verifying hooks are in settings.json
        if [ -f "$HOME/.claude/settings.json" ] && grep -q "agent-os-hooks-v" "$HOME/.claude/settings.json" 2>/dev/null; then
            echo "  ✅ Claude Code hooks installed successfully!"
        else
            echo "  ⚠️ Claude Code hooks installation did not complete properly"
            echo "     You can install them manually by running:"
            echo "     ~/.agent-os/hooks/install-hooks.sh"
        fi
    else
        echo "  ⚠️ Hook utilities not found. Installing from repository..."
        
        # Create hooks directory
        mkdir -p "$HOME/.agent-os/hooks/lib"
        mkdir -p "$HOME/.agent-os/hooks/tests"
        
        # Download ALL hook utilities
        for util in workflow-detector.sh git-utils.sh context-builder.sh evidence-standards.sh project-config-injector.sh testing-enforcer.sh testing-reminder.sh workflow-reminder.sh; do
            curl -s -o "$HOME/.agent-os/hooks/lib/$util" "${BASE_URL}/hooks/lib/$util"
            chmod +x "$HOME/.agent-os/hooks/lib/$util"
            echo "  ✓ Downloaded lib/$util"
        done
        
        # Download Python hook
        curl -s -o "$HOME/.agent-os/hooks/workflow-enforcement-hook.py" "${BASE_URL}/hooks/workflow-enforcement-hook.py"
        echo "  ✓ Downloaded workflow-enforcement-hook.py"
        
        # Download bash hooks
        for hook in stop-hook.sh user-prompt-submit-hook.sh pre-bash-hook.sh post-bash-hook.sh notify-hook.sh install-hooks.sh; do
            curl -s -o "$HOME/.agent-os/hooks/$hook" "${BASE_URL}/hooks/$hook"
            chmod +x "$HOME/.agent-os/hooks/$hook"
            echo "  ✓ Downloaded $hook"
        done
        
        # Download configuration
        curl -s -o "$HOME/.agent-os/hooks/claude-code-hooks.json" "${BASE_URL}/hooks/claude-code-hooks.json"
        echo "  ✓ Downloaded claude-code-hooks.json"
        
        # Run installation
        "$HOME/.agent-os/hooks/install-hooks.sh"
        
        # Check if installation actually completed by verifying hooks are in settings.json
        if [ -f "$HOME/.claude/settings.json" ] && grep -q "agent-os-hooks-v" "$HOME/.claude/settings.json" 2>/dev/null; then
            echo "  ✅ Claude Code hooks installed successfully!"
        else
            echo "  ⚠️ Claude Code hooks installation did not complete properly"
        fi
    fi

# Context validation hook - validate Claude Code integration
echo ""
echo "🔍 Validating Claude Code integration..."
if command -v claude >/dev/null 2>&1; then
	# Check if commands were properly installed
	if claude list-commands 2>/dev/null | grep -q "/execute-tasks"; then
		echo "  ✅ Claude Code commands validated"
	else
		echo "  ⚠️  Claude Code commands may not be properly registered"
		echo "     Try running: claude reload"
	fi
else
	echo "  ⚠️  Claude Code CLI not found in PATH"
	echo "     Commands installed but require Claude Code to be installed"
fi

# Run context validation if available
if [ -f "tools/context-validator.sh" ]; then
	if ./tools/context-validator.sh --install-only >/dev/null 2>&1; then
		echo "  ✅ Installation context validated"
	else
		echo "  ⚠️  Context validation warnings detected"
		echo "     Run './tools/context-validator.sh' for details"
	fi
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
