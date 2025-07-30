#!/bin/bash

# Test script for stop hook integration with testing enforcer

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Test with completion claim but no evidence
echo "=== Testing stop hook with completion claim ==="
echo "Using @.agent-os/specs/test-spec/tasks.md workflow. The feature is complete and ready for review" | bash "$HOOKS_DIR/stop-hook.sh"

echo ""
echo "=== Testing stop hook with completion claim and evidence ==="
echo "Using @.agent-os/specs/test-spec/tasks.md workflow. The feature is complete. Ran all tests and they pass." | bash "$HOOKS_DIR/stop-hook.sh"

echo ""
echo "=== Testing stop hook with normal conversation ==="
echo "Using @.agent-os/specs/test-spec/tasks.md workflow. Working on the implementation" | bash "$HOOKS_DIR/stop-hook.sh"