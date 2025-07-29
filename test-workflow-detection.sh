#!/bin/bash

# Test workflow detection
set -e

# Check if the file exists
if [ ! -f ~/.agent-os/hooks/lib/workflow-detector.sh ]; then
    echo "ERROR: workflow-detector.sh not found at ~/.agent-os/hooks/lib/workflow-detector.sh"
    exit 1
fi

# Source with full path
. ~/.agent-os/hooks/lib/workflow-detector.sh

echo "Testing workflow detection..."
echo "============================="

# Test cases
test_conversations=(
    "Testing execute-tasks.md workflow"
    "Using /create-spec command"
    "Working with @.agent-os/product/mission.md"
    "Just a regular conversation"
    "Looking at code in the project"
    "The file path is execute-tasks.md"
)

for conv in "${test_conversations[@]}"; do
    echo ""
    echo "Test: '$conv'"
    if is_agent_os_workflow "$conv"; then
        echo "✓ Detected as Agent OS workflow"
        echo "  Phase: $(detect_workflow_phase "$conv")"
        echo "  Risk: $(detect_abandonment_risk "$conv")"
    else
        echo "✗ NOT detected as Agent OS workflow"
    fi
done

echo ""
echo "Testing high-risk patterns..."
echo "============================="

high_risk_test="Quality checks passed and all tests passing. Implementation complete and ready for testing."
echo ""
echo "Test: '$high_risk_test'"
if is_agent_os_workflow "$high_risk_test"; then
    echo "✓ Detected as Agent OS workflow"
    echo "  Risk: $(detect_abandonment_risk "$high_risk_test")"
else
    echo "✗ NOT detected as Agent OS workflow"
    echo "  Risk: $(detect_abandonment_risk "$high_risk_test")"
fi