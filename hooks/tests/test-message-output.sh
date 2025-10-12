#!/bin/bash

# test-message-output.sh
# Manual test to verify message output with context

set -e

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$TESTS_DIR")"

# Source libraries
source "$HOOKS_DIR/lib/git-utils.sh"
source "$HOOKS_DIR/lib/workflow-detector.sh"

# Create test repository
TEST_DIR="/tmp/agent-os-message-output-test-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Initialize git repo
git init -q
git config user.email "test@example.com"
git config user.name "Test User"

# Create Agent OS structure
mkdir -p ".agent-os/specs/2025-10-12-stop-hook-context-#98"
echo "# Spec" > ".agent-os/specs/2025-10-12-stop-hook-context-#98/spec.md"

# Create initial commit
echo "initial" > README.md
git add .
git commit -q -m "Initial commit"

# Create feature branch with issue
git checkout -q -b "feature/stop-hook-context-#98"

# Create uncommitted file
echo "#!/bin/bash\necho 'test'" > script.sh

# Source the stop-hook to get generate_stop_message function
source "$HOOKS_DIR/stop-hook.sh" 2>/dev/null || true

echo "========================================="
echo "Testing Message Generation with Context"
echo "========================================="
echo ""

# Extract context
BRANCH=$(get_current_branch)
ISSUE=$(extract_github_issue "branch")
SPEC=$(detect_current_spec)

echo "Extracted Context:"
echo "  Branch: $BRANCH"
echo "  Issue: $ISSUE"
echo "  Spec: $SPEC"
echo ""

echo "Generated Message:"
echo "-----------------"
generate_stop_message "$TEST_DIR" "1" "  - script.sh"
echo ""

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo "✅ Message output test complete"
