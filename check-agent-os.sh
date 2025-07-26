#!/bin/bash

echo "🔍 Agent OS Sanity Check"
echo "========================"
echo ""

# Check 1: Cursor rules exist
if [ -d ".cursor/rules" ]; then
    echo "✅ Cursor rules folder exists"
    echo "   Files: $(ls .cursor/rules/ | wc -l | tr -d ' ') rule files found"
else
    echo "❌ No .cursor/rules/ folder found"
    echo "   Run: curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup-cursor.sh | bash"
    exit 1
fi

# Check 2: Rules reference home directory
if grep -r "~/.agent-os" .cursor/rules/ >/dev/null 2>&1; then
    echo "✅ Rules reference ~/.agent-os/"
else
    echo "❌ Rules don't reference ~/.agent-os/"
    exit 1
fi

# Check 3: Home directory exists
if [ -d "$HOME/.agent-os" ]; then
    echo "✅ Home directory ~/.agent-os/ exists"
else
    echo "❌ Home directory ~/.agent-os/ missing"
    echo "   Run: curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash"
    exit 1
fi

# Check 4: Your customizations are present
echo ""
echo "🎯 Custom Standards Check:"

# GitHub Issues workflow
if grep -q "GitHub Issue" ~/.agent-os/standards/best-practices.md 2>/dev/null; then
    echo "✅ GitHub Issues workflow integrated"
else
    echo "❌ Missing GitHub Issues workflow"
fi

# Tabs indentation
if grep -q "tabs for indentation" ~/.agent-os/standards/code-style.md 2>/dev/null; then
    echo "✅ Tabs indentation preference set"
else
    echo "❌ Missing tabs indentation preference"
fi

# Python/React tech stack
if grep -q "Python\|React" ~/.agent-os/standards/tech-stack.md 2>/dev/null; then
    echo "✅ Python/React tech stack configured"
else
    echo "❌ Missing Python/React tech stack"
fi

echo ""
echo "🚀 Agent OS is ready to use!"
echo ""
echo "Commands available:"
echo "   /create-spec    - Create feature specification"
echo "   /execute-tasks  - Execute planned tasks"
echo "   /analyze-product - Analyze existing codebase" 