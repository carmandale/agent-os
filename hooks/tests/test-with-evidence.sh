#!/bin/bash

# Test stop hook with testing evidence

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test message with testing evidence
test_message="I'm using @.agent-os/specs/test-spec/tasks.md to implement this. The feature is complete. I ran npm test and all tests are passing:

\`\`\`
Test Suites: 12 passed, 12 total
Tests:       84 passed, 84 total
\`\`\`

Also tested in the browser and everything works correctly."

echo "Testing stop hook with message that includes testing evidence:"
echo ""
echo "Expected: Should NOT block (has testing evidence)"
echo ""
echo "=== Stop Hook Output ==="
bash "$HOOKS_DIR/stop-hook.sh" "$test_message"
echo "=== End Output ==="