#!/bin/bash

# Test lock file detection patterns
echo "=== Testing Lock File Detection ==="

# Create temporary test directory
TEST_DIR="./temp_test_project"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Function to detect package manager
detect_python_manager() {
    if [[ -f "uv.lock" ]]; then echo "uv"
    elif [[ -f "poetry.lock" ]]; then echo "poetry"  
    elif [[ -f "Pipfile.lock" ]]; then echo "pipenv"
    elif [[ -f "requirements.txt" ]]; then echo "pip"
    else echo "unknown"
    fi
}

detect_js_manager() {
    if [[ -f "bun.lockb" ]]; then echo "bun"
    elif [[ -f "pnpm-lock.yaml" ]]; then echo "pnpm"
    elif [[ -f "yarn.lock" ]]; then echo "yarn"
    elif [[ -f "package-lock.json" ]]; then echo "npm"
    elif [[ -f "package.json" ]]; then echo "npm" 
    else echo "unknown"
    fi
}

# Test different scenarios
echo "Test 1 - Empty project: $(detect_python_manager) / $(detect_js_manager)"

touch uv.lock
echo "Test 2 - uv.lock present: $(detect_python_manager)"
rm uv.lock

touch poetry.lock  
echo "Test 3 - poetry.lock present: $(detect_python_manager)"
rm poetry.lock

touch yarn.lock
echo "Test 4 - yarn.lock present: $(detect_js_manager)"
rm yarn.lock

touch package-lock.json
echo "Test 5 - package-lock.json present: $(detect_js_manager)"

cd ..
rm -rf "$TEST_DIR"

# Test against real projects (if they exist)
echo -e "\n=== Real Project Detection ==="
if [[ -f "package-lock.json" ]]; then
    echo "Current project uses: npm (package-lock.json found)"
elif [[ -f "yarn.lock" ]]; then
    echo "Current project uses: yarn (yarn.lock found)"
else
    echo "Current project: No JS package manager detected"
fi