#!/bin/bash

# Test full stop hook flow with testing enforcement

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test message that should trigger both workflow detection and testing enforcement
test_message="I'm using @.agent-os/specs/test-spec/tasks.md to implement this. The feature is complete and ready for review."

echo "Testing stop hook with message:"
echo "$test_message"
echo ""
echo "Expected: Should block completion without testing evidence"
echo ""
echo "=== Stop Hook Output ==="
echo "$test_message" | bash "$HOOKS_DIR/stop-hook.sh"
echo "=== End Output ==="