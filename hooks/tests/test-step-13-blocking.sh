#!/bin/bash

# test-step-13-blocking.sh
# Test the Step 13 blocking detection for Agent OS workflows

set -e

# Source the workflow detector
HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HOOKS_DIR/lib/workflow-detector.sh"
source "$HOOKS_DIR/lib/context-builder.sh"

# Test 1: Generic task completion (should trigger)
echo "Test 1: Generic task completion message"
CONVERSATION="Task 2: Copy-to-Clipboard Functionality COMPLETE
Quality checks passed
All tests passing
git commit -m 'feat: add clipboard functionality #123'
Created PR #456"

echo "Abandonment risk: $(detect_abandonment_risk "$CONVERSATION")"
echo "Needs Step 13: $(needs_step_13_blocking "$CONVERSATION" && echo "YES" || echo "NO")"
echo ""

# Test 2: Already at Step 13 (should NOT trigger)
echo "Test 2: Already at Step 13 blocking"
CONVERSATION="Task complete
Quality checks passed
🚨🛑 WORKFLOW COMPLETE - MERGE APPROVAL REQUIRED 🛑🚨
Type merge to complete workflow"

echo "Abandonment risk: $(detect_abandonment_risk "$CONVERSATION")"
echo "Needs Step 13: $(needs_step_13_blocking "$CONVERSATION" && echo "YES" || echo "NO")"
echo ""

# Test 3: No git workflow started (should NOT trigger)
echo "Test 3: No git workflow started yet"
CONVERSATION="Task 2: Copy-to-Clipboard Functionality COMPLETE
Quality checks passed
All tests passing"

echo "Abandonment risk: $(detect_abandonment_risk "$CONVERSATION")"
echo "Needs Step 13: $(needs_step_13_blocking "$CONVERSATION" && echo "YES" || echo "NO")"
echo ""

# Test 4: Full context build with Step 13 needed
echo "Test 4: Full stop context when Step 13 is needed"
CONVERSATION="execute-tasks.md
Task 2: Copy-to-Clipboard Functionality COMPLETE
Quality checks passed
All tests passing
git commit -m 'feat: add clipboard functionality #123'
Created PR #456"

echo "Stop context output:"
build_stop_context "$CONVERSATION"