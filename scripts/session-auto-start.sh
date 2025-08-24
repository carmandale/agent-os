#!/bin/bash

# Agent OS Session Auto-Start
# Implements transparent work session detection and auto-start logic

set -e

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ️${NC}  $1"
}

# Check workflow conditions using validator
echo "🔍 Checking workflow conditions for transparent work session auto-start..."
if ~/.agent-os/scripts/workflow-validator.sh check-with-override; then
    # All conditions met - start transparent session
    print_success "Workflow conditions met - enabling transparent work session batching"
    
    # Start work session
    ~/.agent-os/scripts/work-session-manager.sh start "Auto-started for execute-tasks workflow" > /dev/null 2>&1 || true
    
    # Set environment for current process
    export AGENT_OS_WORK_SESSION=true
    
    print_info "Transparent session enabled - commits will be batched at logical boundaries"
    echo
    exit 0
else
    # Conditions not met - validator already printed helpful guidance
    echo
    print_info "Transparent work session not started - continuing with standard workflow"
    exit 1
fi
