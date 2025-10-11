#!/bin/bash
# Agent OS Workflow Status Wrapper Script
# Translates exit codes to provide user-friendly messaging for Claude Code
#
# Purpose: Fix misleading "Error: Bash command failed" messages when
# workflow-status.sh returns exit code 2 (warnings found) which is semantic
# success, not failure.
#
# Exit Code Translation:
# - Original exit 0 → "✅ Workflow is healthy" + exit 0
# - Original exit 2 → "⚠️  Workflow has warnings" + exit 0
# - Original exit 1+ → "❌ Workflow check failed" + preserve exit code

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to the original workflow-status.sh script
ORIGINAL_SCRIPT="${ORIGINAL_SCRIPT:-"$SCRIPT_DIR/workflow-status.sh"}"

# Verify the original script exists
if [[ ! -f "$ORIGINAL_SCRIPT" ]]; then
	echo "❌ Workflow status check failed: Original script not found at $ORIGINAL_SCRIPT"
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
		# Success - workflow is clean
		echo "✅ Workflow is healthy"
		echo ""
		echo "$output"
		if [[ -n "$error_output" ]]; then
			echo "$error_output" >&2
		fi
		exit 0
		;;
	2)
		# Semantic success - workflow has warnings but nothing critical
		echo "⚠️  Workflow has warnings (see details below)"
		echo ""
		echo "$output"
		if [[ -n "$error_output" ]]; then
			echo "$error_output" >&2
		fi
		exit 0
		;;
	*)
		# True error - preserve original exit code and add error message
		echo "❌ Workflow status check failed (exit code $original_exit_code)"
		echo ""
		echo "$output"
		if [[ -n "$error_output" ]]; then
			echo "$error_output" >&2
		fi
		exit $original_exit_code
		;;
esac
