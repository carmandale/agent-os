#!/bin/bash

# Debug workflow detection

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HOOKS_DIR/lib/workflow-detector.sh"

test_message="I'm using @.agent-os/specs/test-spec/tasks.md to implement this. The feature is complete."

echo "Testing message: $test_message"
echo ""

if is_agent_os_workflow "$test_message"; then
    echo "✓ Detected as Agent OS workflow"
else
    echo "✗ NOT detected as Agent OS workflow"
fi

# Test each pattern individually
echo ""
echo "Pattern tests:"

if echo "$test_message" | grep -qE "(execute-tasks\.md|create-spec\.md|plan-product\.md|analyze-product\.md)"; then
    echo "✓ Matches instruction file pattern"
else
    echo "✗ No match for instruction file pattern"
fi

if echo "$test_message" | grep -qE "(/plan-product|/create-spec|/execute-tasks|/analyze-product|/hygiene-check)"; then
    echo "✓ Matches command pattern"
else
    echo "✗ No match for command pattern"
fi

if echo "$test_message" | grep -qE "(@\.agent-os/|@~/\.agent-os/)"; then
    echo "✓ Matches Agent OS file reference pattern"
else
    echo "✗ No match for Agent OS file reference pattern"
fi