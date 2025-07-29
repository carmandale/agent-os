#!/bin/bash

# Agent OS Alias Installer
# This script installs the 'aos' alias to your shell configuration

set -e

echo "🚀 Agent OS Alias Installer"
echo "==========================="
echo ""

# Detect user's default shell
USER_SHELL=$(basename "$SHELL")

# Detect shell configuration file
if [[ "$USER_SHELL" == "zsh" ]]; then
	SHELL_CONFIG="$HOME/.zshrc"
	SHELL_NAME="zsh"
elif [[ "$USER_SHELL" == "bash" ]]; then
	SHELL_CONFIG="$HOME/.bashrc"
	SHELL_NAME="bash"
else
	# Fallback to checking for config files
	if [ -f "$HOME/.zshrc" ]; then
		SHELL_CONFIG="$HOME/.zshrc"
		SHELL_NAME="zsh"
	elif [ -f "$HOME/.bashrc" ]; then
		SHELL_CONFIG="$HOME/.bashrc"
		SHELL_NAME="bash"
	else
		echo "⚠️  Could not detect shell configuration. Please specify manually."
		echo "Common options: ~/.zshrc (macOS) or ~/.bashrc (Linux)"
		exit 1
	fi
fi

echo "Detected shell: $SHELL_NAME"
echo "Configuration file: $SHELL_CONFIG"
echo ""

# Check if alias already exists
if grep -q "function aos()" "$SHELL_CONFIG" 2>/dev/null || grep -q "alias aos=" "$SHELL_CONFIG" 2>/dev/null; then
	echo "⚠️  'aos' alias already exists in $SHELL_CONFIG"
	echo ""
	echo "Would you like to update it? (y/n)"
	read -r response
	if [[ "$response" != "y" ]]; then
		echo "Installation cancelled."
		exit 0
	fi
	
	# Remove existing alias
	echo "Removing existing alias..."
	# Create a backup
	cp "$SHELL_CONFIG" "$SHELL_CONFIG.backup"
	# Remove the function and alias
	sed -i.tmp '/^function aos()/,/^}/d' "$SHELL_CONFIG"
	sed -i.tmp '/^alias agentos=/d' "$SHELL_CONFIG"
	rm -f "$SHELL_CONFIG.tmp"
fi

# Download and append the alias function
echo "Installing 'aos' alias..."

# Add a marker and the source command
cat >> "$SHELL_CONFIG" << 'EOF'

# Agent OS Quick Init Alias
if [ -f "$HOME/.agent-os/tools/agentos-alias.sh" ]; then
	source "$HOME/.agent-os/tools/agentos-alias.sh"
fi
EOF

# Create the tools directory and download the alias file
mkdir -p "$HOME/.agent-os/tools"
curl -s -o "$HOME/.agent-os/tools/agentos-alias.sh" "https://raw.githubusercontent.com/carmandale/agent-os/main/tools/agentos-alias.sh"

echo ""
echo "✅ Installation complete!"
echo ""
echo "To use the alias in your current session, run:"
echo "  source $SHELL_CONFIG"
echo ""
echo "Available commands:"
echo "  aos         - Interactive Agent OS setup"
echo "  aos init    - Initialize Agent OS in current project"
echo "  aos update  - Update Agent OS installation"
echo "  aos check   - Check installation status"
echo "  aos help    - Show help message"
echo ""
echo "You can also use 'agentos' as an alternative to 'aos'"
echo ""