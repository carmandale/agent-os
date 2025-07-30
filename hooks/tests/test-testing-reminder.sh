#!/bin/bash

# Simple test for testing reminder system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the testing reminder
source "$HOOKS_DIR/lib/testing-reminder.sh"

# Test cases
echo "=== Testing Reminder System ==="

# Test 1: Should trigger reminder
echo "Test 1: Completion claim should trigger reminder"
result=$(inject_reminder "Working on @.agent-os/specs/feature-#123/tasks.md - implementation complete")
if echo "$result" | grep -q "Before marking complete"; then
    echo "✓ PASS: Reminder triggered for completion claim"
else
    echo "✗ FAIL: Reminder not triggered"
fi

# Test 2: Should not trigger reminder
echo ""
echo "Test 2: Normal message should not trigger reminder"
result=$(inject_reminder "How do I configure this setting?")
if [ -z "$result" ]; then
    echo "✓ PASS: No reminder for normal message"
else
    echo "✗ FAIL: Unexpected reminder triggered"
fi

# Test 3: Direct reminder content test
echo ""
echo "Test 3: Reminder content test"
result=$(get_testing_reminder)
if echo "$result" | grep -q "actually test it" && echo "$result" | grep -q "curl"; then
    echo "✓ PASS: Reminder contains expected content"
else
    echo "✗ FAIL: Reminder missing expected content"
fi

echo ""
echo "=== Testing Reminder System Complete ==="