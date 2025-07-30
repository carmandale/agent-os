#!/bin/bash

# Test environment variable hierarchy patterns
echo "=== Testing Environment Variable Hierarchy ==="

# Test 1: Standard PORT fallback pattern (used by Next.js, Express, etc.)
unset PORT FRONTEND_PORT
TEST_PORT="${PORT:-${FRONTEND_PORT:-3000}}"
echo "Test 1 - No vars set: $TEST_PORT (expected: 3000)"

export FRONTEND_PORT=3001
TEST_PORT="${PORT:-${FRONTEND_PORT:-3000}}"
echo "Test 2 - FRONTEND_PORT=3001: $TEST_PORT (expected: 3001)"

export PORT=3002
TEST_PORT="${PORT:-${FRONTEND_PORT:-3000}}"
echo "Test 3 - PORT=3002, FRONTEND_PORT=3001: $TEST_PORT (expected: 3002)"

# Test 2: Check if tools actually use this pattern
echo -e "\n=== Checking Real Tool Usage ==="

# Check Next.js
if command -v npx >/dev/null 2>&1; then
    echo "Next.js environment variable usage:"
    echo "PORT=3001 npx next dev would use port 3001"
else
    echo "Next.js not available for testing"
fi

# Check if we can find evidence in package.json files
if find /usr/local -name "package.json" -path "*/next/*" 2>/dev/null | head -1 | xargs grep -l "PORT" 2>/dev/null; then
    echo "Found Next.js PORT usage in system"
else
    echo "Could not verify Next.js PORT usage on this system"
fi