#!/bin/bash

# Agent OS Claude Code Local Setup Script
# This script installs Agent OS commands for Claude Code from local files
# Use this when developing/testing Agent OS locally

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_OS_PATH="$SCRIPT_DIR"

echo -e "${BLUE}🚀 Agent OS Claude Code Local Setup${NC}"
echo "====================================="
echo ""

# Check if Agent OS base installation is present
if [ ! -d "$HOME/.agent-os/instructions" ] || [ ! -d "$HOME/.agent-os/standards" ]; then
    echo -e "${RED}⚠️  Agent OS base installation not found!${NC}"
    echo ""
    echo "Please install the Agent OS base installation first:"
    echo ""
    echo "Option 1 - Run local setup from this directory:"
    echo "  ./setup.sh"
    echo ""
    echo "Option 2 - Automatic installation:"
    echo "  curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash"
    echo ""
    exit 1
fi

# Check if Claude Code CLI is available
echo "🔍 Checking Claude Code CLI..."
if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}⚠️  Claude Code CLI not found.${NC}"
    echo "Please install Claude Code first: https://claude.ai/code"
    echo "This setup will continue, but commands won't work until Claude Code is installed."
    echo ""
else
    echo -e "${GREEN}✅ Claude Code CLI found${NC}"
fi

# Create directories
echo "📁 Creating directories..."
mkdir -p "$HOME/.claude/commands"
echo -e "${GREEN}✅ Created ~/.claude/commands/${NC}"

# Define expected commands (keep in sync with setup-claude-code.sh and commands/)
COMMANDS=(
    plan-product
    create-spec
    execute-tasks
    analyze-product
    hygiene-check
    update-documentation
    workflow-status
    workflow-complete
)
INSTALLED_COMMANDS=()
MISSING_COMMANDS=()
FAILED_COMMANDS=()

# Copy Agent OS commands to Claude Code
echo ""
echo "📥 Installing Claude Code command files..."

for cmd in "${COMMANDS[@]}"; do
    if [ -f "$AGENT_OS_PATH/commands/$cmd.md" ]; then
        if cp "$AGENT_OS_PATH/commands/$cmd.md" "$HOME/.claude/commands/" 2>/dev/null; then
            INSTALLED_COMMANDS+=("$cmd")
            echo -e "  ${GREEN}✓ Installed /$cmd command${NC}"
        else
            FAILED_COMMANDS+=("$cmd")
            echo -e "  ${RED}✗ Failed to install /$cmd command${NC}"
        fi
    else
        MISSING_COMMANDS+=("$cmd")
        echo -e "  ${YELLOW}⚠ Warning: $cmd.md not found in commands directory${NC}"
    fi
done

# Claude Code configuration handled by main setup.sh
echo ""
echo "📥 Claude Code configuration handled by main setup.sh script"

# Installation verification
echo ""
echo "🔍 Verifying installation..."

# Check installed commands
VERIFIED_COMMANDS=()
BROKEN_COMMANDS=()

for cmd in "${INSTALLED_COMMANDS[@]}"; do
    if [ -f "$HOME/.claude/commands/$cmd.md" ] && [ -r "$HOME/.claude/commands/$cmd.md" ]; then
        # Check if file has content
        if [ -s "$HOME/.claude/commands/$cmd.md" ]; then
            VERIFIED_COMMANDS+=("$cmd")
            echo -e "  ${GREEN}✓ /$cmd command verified${NC}"
        else
            BROKEN_COMMANDS+=("$cmd")
            echo -e "  ${RED}✗ /$cmd command is empty${NC}"
        fi
    else
        BROKEN_COMMANDS+=("$cmd")
        echo -e "  ${RED}✗ /$cmd command not accessible${NC}"
    fi
done

# Summary report
echo ""
echo "📊 Installation Summary"
echo "======================"
echo ""

if [ ${#VERIFIED_COMMANDS[@]} -gt 0 ]; then
    echo -e "${GREEN}✅ Successfully installed (${#VERIFIED_COMMANDS[@]} commands):${NC}"
    for cmd in "${VERIFIED_COMMANDS[@]}"; do
        echo "   /$cmd"
    done
    echo ""
fi

if [ ${#MISSING_COMMANDS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Missing source files (${#MISSING_COMMANDS[@]} commands):${NC}"
    for cmd in "${MISSING_COMMANDS[@]}"; do
        echo "   $cmd.md (not found in $AGENT_OS_PATH/commands/)"
    done
    echo ""
fi

if [ ${#FAILED_COMMANDS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Failed to install (${#FAILED_COMMANDS[@]} commands):${NC}"
    for cmd in "${FAILED_COMMANDS[@]}"; do
        echo "   $cmd (check file permissions)"
    done
    echo ""
fi

if [ ${#BROKEN_COMMANDS[@]} -gt 0 ]; then
    echo -e "${RED}❌ Broken installations (${#BROKEN_COMMANDS[@]} commands):${NC}"
    for cmd in "${BROKEN_COMMANDS[@]}"; do
        echo "   /$cmd (file exists but not working)"
    done
    echo ""
fi

# Overall status
TOTAL_EXPECTED=${#COMMANDS[@]}
TOTAL_WORKING=${#VERIFIED_COMMANDS[@]}

echo "📈 Installation Score: $TOTAL_WORKING/$TOTAL_EXPECTED commands working"

if [ $TOTAL_WORKING -eq $TOTAL_EXPECTED ]; then
    echo -e "${GREEN}🎉 Perfect installation! All commands are working.${NC}"
    INSTALL_STATUS="perfect"
elif [ $TOTAL_WORKING -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Partial installation. Some commands are working.${NC}"
    INSTALL_STATUS="partial" 
else
    echo -e "${RED}❌ Installation failed. No commands are working.${NC}"
    INSTALL_STATUS="failed"
fi

echo ""

# Next steps based on installation status
if [ "$INSTALL_STATUS" = "perfect" ]; then
    echo -e "${GREEN}✅ Agent OS Claude Code installation complete!${NC}"
    echo ""
    echo "📍 Files installed to:"
    echo "   ~/.claude/commands/        - Claude Code commands"
    echo "   ~/.claude/CLAUDE.md        - Claude Code configuration"
    echo ""
    echo "🚀 Available commands:"
    for cmd in "${VERIFIED_COMMANDS[@]}"; do
        echo "   /$cmd"
    done
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
    echo "Check workspace cleanliness with:"
    echo "  /hygiene-check"
    echo ""
    echo "Keep documentation in sync with:"
    echo "  /update-documentation --dry-run"
    echo ""
    echo "Check workflow health with:"
    echo "  /workflow-status"
    echo ""
    echo "Complete the workflow with:"
    echo "  /workflow-complete"
    echo ""
elif [ "$INSTALL_STATUS" = "partial" ]; then
    echo -e "${YELLOW}⚠️  Partial installation completed.${NC}"
    echo ""
    echo "Working commands:"
    for cmd in "${VERIFIED_COMMANDS[@]}"; do
        echo "   /$cmd"
    done
    echo ""
    echo "To fix issues:"
    echo "1. Check file permissions in $AGENT_OS_PATH/commands/"
    echo "2. Ensure all command files exist"
    echo "3. Re-run this script"
    echo ""
else
    echo -e "${RED}❌ Installation failed.${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check that you're running this script from the Agent OS directory"
    echo "2. Verify file permissions: ls -la $AGENT_OS_PATH/commands/"
    echo "3. Ensure ~/.claude/commands/ directory is writable"
    echo "4. Try running with: sudo $0 (if permission issues)"
    echo ""
fi

echo "Learn more at https://github.com/carmandale/agent-os"
echo ""
