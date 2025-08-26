#!/bin/bash
# Install modular hooks to ~/.agent-os

HOOKS_SOURCE="./hooks"
HOOKS_DEST="$HOME/.agent-os/hooks"

echo "Installing modular hooks..."

# Create destination if needed
mkdir -p "$HOOKS_DEST"

# Install hooks (using symlinks for development)
ln -sf "$PWD/$HOOKS_SOURCE/pretool"/* "$HOOKS_DEST/"
ln -sf "$PWD/$HOOKS_SOURCE/posttool"/* "$HOOKS_DEST/"
ln -sf "$PWD/$HOOKS_SOURCE/userprompt"/* "$HOOKS_DEST/"
ln -sf "$PWD/$HOOKS_SOURCE/shared" "$HOOKS_DEST/"

echo "Hooks installed successfully"
