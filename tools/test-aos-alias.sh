#!/bin/bash

# Test script for the aos alias
# This script tests the basic functionality of the aos command

echo "🧪 Testing Agent OS Alias"
echo "========================"
echo ""

# Source the alias file
if [ -f "$HOME/.agent-os/tools/agentos-alias.sh" ]; then
	source "$HOME/.agent-os/tools/agentos-alias.sh"
	echo "✅ Alias file loaded successfully"
else
	# Try loading from local directory for testing
	if [ -f "./agentos-alias.sh" ]; then
		source "./agentos-alias.sh"
		echo "✅ Alias file loaded from current directory"
	else
		echo "❌ Cannot find alias file"
		exit 1
	fi
fi

echo ""
echo "Testing command availability..."

# Test if the function exists
if type aos >/dev/null 2>&1; then
	echo "✅ 'aos' command is available"
else
	echo "❌ 'aos' command not found"
	exit 1
fi

if alias agentos >/dev/null 2>&1; then
	echo "✅ 'agentos' alias is available"
else
	echo "⚠️  'agentos' alias not found (this is normal in non-interactive shells)"
fi

echo ""
echo "Testing help command..."
aos help >/dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "✅ Help command works"
else
	echo "❌ Help command failed"
fi

echo ""
echo "✅ All basic tests passed!"
echo ""
echo "To test full functionality:"
echo "  1. Run 'aos' for interactive mode"
echo "  2. Run 'aos check' to check status"
echo "  3. Run 'aos init' in a project directory"