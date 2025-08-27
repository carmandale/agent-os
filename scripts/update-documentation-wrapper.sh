#!/bin/bash
# Agent OS Documentation Wrapper Script
# Translates exit codes to provide user-friendly messaging for Claude Code
#
# Purpose: Fix misleading "Error: Bash command failed" messages when 
# update-documentation.sh returns exit code 2 (documentation updates needed)
# which is semantic success, not failure.
#
# Exit Code Translation:
# - Original exit 0 → "✅ Documentation is up-to-date" + exit 0
# - Original exit 2 → "📝 Documentation updates recommended" + exit 0  
# - Original exit 1+ → "❌ Documentation check failed" + preserve exit code

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to the original update-documentation.sh script
ORIGINAL_SCRIPT="${ORIGINAL_SCRIPT:-"$SCRIPT_DIR/update-documentation.sh"}"

# Verify the original script exists
if [[ ! -f "$ORIGINAL_SCRIPT" ]]; then
	echo "❌ Documentation check failed: Original script not found at $ORIGINAL_SCRIPT"
	exit 1
fi

# Handle mock scenarios for testing
if [[ "${MOCK_EXIT_1:-}" == "true" ]]; then
	echo "❌ Documentation check failed: Mocked failure for testing"
	exit 1
fi

# Create temporary files to capture output and exit code
temp_output=$(mktemp)
temp_stderr=$(mktemp)

# Cleanup function
cleanup() {
	rm -f "$temp_output" "$temp_stderr"
}
trap cleanup EXIT

# Execute the original script with all arguments, capturing output and exit code
set +e
bash "$ORIGINAL_SCRIPT" "$@" >"$temp_output" 2>"$temp_stderr"
original_exit_code=$?
set -e

# Read the captured output
output=$(cat "$temp_output")
error_output=$(cat "$temp_stderr")

# Translate exit codes to user-friendly messages
case $original_exit_code in
	0)
		# Success - no documentation changes needed
		echo "✅ Documentation is up-to-date"
		echo ""
		echo "$output"
		if [[ -n "$error_output" ]]; then
			echo "$error_output" >&2
		fi
		exit 0
		;;
	2)
		# Semantic success - documentation updates recommended
		echo "📝 Documentation updates recommended"
		echo ""
		echo "$output"
		if [[ -n "$error_output" ]]; then
			echo "$error_output" >&2
		fi
		exit 0
		;;
	*)
		# True error - preserve original exit code and add error message
		echo "❌ Documentation check failed (exit code $original_exit_code)"
		echo ""
		echo "$output"
		if [[ -n "$error_output" ]]; then
			echo "$error_output" >&2
		fi
		exit $original_exit_code
		;;
esac