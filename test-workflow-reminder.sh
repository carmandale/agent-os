#!/bin/bash

# Simple test of workflow reminder
echo "Testing workflow reminder..."

# Source the reminder
source hooks/lib/workflow-reminder.sh

# Test current state
echo "Current workflow guidance:"
echo "========================="
build_workflow_reminder "test"