#!/bin/bash

# Agent OS Project Context Loader Script  
# Loads tech stack configuration, environment files, and project settings
# Part of slash command refactoring to reduce execute-tasks.md size

set -e

echo "📋 **PROJECT CONFIGURATION LOADING**"
echo ""

# Initialize variables
python_package_manager="NOT_FOUND"
javascript_package_manager="NOT_FOUND"  
frontend_port="NOT_FOUND"
backend_port="NOT_FOUND"
startup_command="NOT_FOUND"
e2e_testing="NOT_FOUND"
project_structure="NOT_FOUND"

# Check for tech-stack.md
if [[ -f ".agent-os/product/tech-stack.md" ]]; then
    echo "✅ Found .agent-os/product/tech-stack.md"
    
    # Extract package managers
    if grep -q "Python Package Manager" ".agent-os/product/tech-stack.md"; then
        python_package_manager=$(grep "Python Package Manager" ".agent-os/product/tech-stack.md" | sed 's/.*: //' | head -1)
    fi
    
    if grep -q "JavaScript Package Manager" ".agent-os/product/tech-stack.md"; then
        javascript_package_manager=$(grep "JavaScript Package Manager" ".agent-os/product/tech-stack.md" | sed 's/.*: //' | head -1)
    fi
    
    # Extract ports
    if grep -q "Frontend Port" ".agent-os/product/tech-stack.md"; then
        frontend_port=$(grep "Frontend Port" ".agent-os/product/tech-stack.md" | sed 's/.*: //' | head -1)
    fi
    
    if grep -q "Backend Port" ".agent-os/product/tech-stack.md"; then
        backend_port=$(grep "Backend Port" ".agent-os/product/tech-stack.md" | sed 's/.*: //' | head -1)
    fi
    
    # Extract other settings
    if grep -q "E2E Testing" ".agent-os/product/tech-stack.md"; then
        e2e_testing=$(grep "E2E Testing" ".agent-os/product/tech-stack.md" | sed 's/.*: //' | head -1)
    fi
    
    if grep -q "Project Structure" ".agent-os/product/tech-stack.md"; then
        project_structure=$(grep "Project Structure" ".agent-os/product/tech-stack.md" | sed 's/.*: //' | head -1)
    fi
else
    echo "⚠️ Missing .agent-os/product/tech-stack.md - run /plan-product first"
fi

# Check environment files
if [[ -f ".env.local" ]]; then
    echo "✅ Found .env.local (frontend environment)"
    if [[ "$frontend_port" == "NOT_FOUND" ]] && grep -q "PORT=" ".env.local"; then
        frontend_port=$(grep "PORT=" ".env.local" | cut -d'=' -f2)
    fi
else
    echo "⚠️ Missing .env.local (frontend environment file)"
fi

if [[ -f ".env" ]]; then
    echo "✅ Found .env (backend environment)"  
    if [[ "$backend_port" == "NOT_FOUND" ]] && grep -q "API_PORT=" ".env"; then
        backend_port=$(grep "API_PORT=" ".env" | cut -d'=' -f2)
    fi
else
    echo "⚠️ Missing .env (backend environment file)"
fi

# Check startup script
if [[ -f "start.sh" ]]; then
    echo "✅ Found start.sh"
    startup_command="./start.sh"
else
    echo "⚠️ Missing start.sh startup script"
fi

# Refresh and export session memory
if command -v jq >/dev/null 2>&1; then
  bash scripts/session-memory.sh refresh-and-export || true
fi

echo ""
echo "✅ **PROJECT CONFIGURATION CONFIRMED:**"
echo "- **Python Package Manager:** ${AGENT_OS_PYPM:-$python_package_manager}"
echo "- **JavaScript Package Manager:** ${AGENT_OS_JSPM:-$javascript_package_manager}"  
echo "- **Frontend Port:** ${AGENT_OS_FRONTEND_PORT:-$frontend_port}"
echo "- **Backend Port:** ${AGENT_OS_BACKEND_PORT:-$backend_port}"
echo "- **Startup Command:** ${AGENT_OS_START_CMD:-$startup_command}"
echo "- **E2E Testing:** $e2e_testing"
echo "- **Project Structure:** $project_structure"
echo ""

# Check for NOT_FOUND values
not_found_count=$(echo "$python_package_manager $javascript_package_manager $frontend_port $backend_port $startup_command $e2e_testing $project_structure" | grep -o "NOT_FOUND" | wc -l)

if [[ $not_found_count -gt 0 ]]; then
    echo "⚠️ **Warning:** $not_found_count configuration values not found"
    echo "Consider running /plan-product to initialize project properly"
    exit 1
else
    echo "✅ **Memory refreshed - maintaining consistency with these settings**"
    exit 0
fi