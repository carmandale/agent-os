#!/bin/bash

# Agent OS Update Checker
# Checks if updates are available for Agent OS

set -e

echo "🔍 Agent OS Update Checker"
echo "=========================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check current installation
if [ ! -d "$HOME/.agent-os" ]; then
    echo -e "${RED}❌ Agent OS not installed${NC}"
    echo "Install with: curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash"
    exit 1
fi

# Get current version (if versioned)
CURRENT_VERSION="unknown"
if [ -f "$HOME/.agent-os/VERSION" ]; then
    CURRENT_VERSION=$(cat "$HOME/.agent-os/VERSION")
fi

echo "📍 Current Installation:"
echo "  Location: $HOME/.agent-os"
echo "  Version: $CURRENT_VERSION"
echo ""

# Check latest version from GitHub
echo "🌐 Checking latest version from GitHub..."
LATEST_RELEASE=$(curl -s https://api.github.com/repos/carmandale/agent-os/releases/latest 2>/dev/null | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' || echo "")

if [ -z "$LATEST_RELEASE" ]; then
    echo -e "${YELLOW}⚠️  Could not fetch latest release information${NC}"
    echo "  Check manually at: https://github.com/carmandale/agent-os/releases"
else
    echo "  Latest Release: $LATEST_RELEASE"
    
    if [ "$CURRENT_VERSION" = "$LATEST_RELEASE" ]; then
        echo -e "${GREEN}✅ You are on the latest version${NC}"
    else
        echo -e "${YELLOW}🔄 Update available!${NC}"
        echo ""
        echo "To update, run:"
        echo "  curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash"
    fi
fi

echo ""
echo "📊 Installation Status:"

# Check key components
components=(
    "instructions/execute-tasks.md"
    "instructions/create-spec.md"
    "instructions/plan-product.md"
    "standards/tech-stack.md"
    "standards/code-style.md"
    "hooks/workflow-enforcement-hook-v2.py"
)

missing=0
for component in "${components[@]}"; do
    if [ -f "$HOME/.agent-os/$component" ]; then
        echo -e "  ${GREEN}✓${NC} $component"
    else
        echo -e "  ${RED}✗${NC} $component (missing)"
        missing=$((missing + 1))
    fi
done

if [ $missing -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Some components are missing${NC}"
    echo "Run update to restore missing components"
fi

# Check for local modifications
echo ""
echo "📝 Checking for local modifications..."

# Check if any instruction files have been modified recently (last 7 days)
recent_mods=$(find "$HOME/.agent-os/instructions" -type f -mtime -7 2>/dev/null | wc -l)
if [ "$recent_mods" -gt 0 ]; then
    echo -e "${YELLOW}ℹ️  Found $recent_mods recently modified instruction files${NC}"
    echo "  These will be preserved during update if you choose"
fi

# Check hook status
echo ""
echo "🪝 Hook Status:"
if [ -f "$HOME/.claude/settings.json" ] && grep -q "workflow-enforcement-hook" "$HOME/.claude/settings.json" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Claude Code hooks configured"
    
    # Check which version of hook is active
    if grep -q "workflow-enforcement-hook-v2" "$HOME/.claude/settings.json" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Using v2 hooks (latest)"
    elif grep -q "workflow-enforcement-hook-v3" "$HOME/.claude/settings.json" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Using v3 hooks (experimental)"
    else
        echo -e "  ${YELLOW}⚠️${NC} Using v1 hooks (consider updating)"
    fi
else
    echo -e "  ${YELLOW}⚠️${NC} Claude Code hooks not configured"
    echo "  Install with: ~/.agent-os/hooks/install-hooks.sh"
fi

echo ""
echo "📅 Last Check: $(date)"
echo ""
echo "For more information:"
echo "  • Changelog: https://github.com/carmandale/agent-os/releases"
echo "  • Issues: https://github.com/carmandale/agent-os/issues"
echo ""