# Exit Code Wrapper Pattern

> **Problem Solved**: Claude Code displays misleading "Error: Bash command failed" messages when scripts use semantic exit codes (like exit 2 for "updates needed") instead of traditional 0/1 success/failure patterns.

## Overview

The Exit Code Wrapper Pattern provides a solution for Agent OS commands that use semantic exit codes by translating them into user-friendly messages while preserving CI/CD compatibility.

## Implementation Pattern

### 1. Wrapper Script Structure

```bash
#!/bin/bash
# [Script Name] Wrapper Script
# Translates exit codes to provide user-friendly messaging for Claude Code

set -euo pipefail

# Get the directory where this wrapper script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to the original script
ORIGINAL_SCRIPT="${ORIGINAL_SCRIPT:-"$SCRIPT_DIR/original-script.sh"}"

# Verify the original script exists
if [[ ! -f "$ORIGINAL_SCRIPT" ]]; then
	echo "❌ [Operation] failed: Original script not found at $ORIGINAL_SCRIPT"
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
		# Success
		echo "✅ [Success message]"
		echo ""
		echo "$output"
		if [[ -n "$error_output" ]]; then
			echo "$error_output" >&2
		fi
		exit 0
		;;
	2)
		# Semantic success - action recommended but not failure
		echo "📝 [Action recommended message]"
		echo ""
		echo "$output"
		if [[ -n "$error_output" ]]; then
			echo "$error_output" >&2
		fi
		exit 0
		;;
	*)
		# True error - preserve original exit code
		echo "❌ [Operation] failed (exit code $original_exit_code)"
		echo ""
		echo "$output"
		if [[ -n "$error_output" ]]; then
			echo "$error_output" >&2
		fi
		exit $original_exit_code
		;;
esac
```

### 2. Command Integration

Update the Claude Code command definition to use the wrapper:

```markdown
---
allowed-tools: Bash(~/.agent-os/scripts/original-script-wrapper.sh:*)
---

!`~/.agent-os/scripts/original-script-wrapper.sh $ARGUMENTS`
```

### 3. Setup Script Integration

Add wrapper installation to setup.sh:

```bash
# original-script-wrapper.sh (Claude Code friendly exit code translation)
curl -s -o "$HOME/.agent-os/scripts/original-script-wrapper.sh" "${BASE_URL}/scripts/original-script-wrapper.sh"
chmod +x "$HOME/.agent-os/scripts/original-script-wrapper.sh"
echo "  ✓ ~/.agent-os/scripts/original-script-wrapper.sh"
```

## Exit Code Translation Strategy

| Original Exit Code | Wrapper Behavior | Use Case |
|-------------------|------------------|----------|
| `0` | Exit 0 + ✅ Success message | No action needed |
| `2` | Exit 0 + 📝 Action recommended | Semantic success (prevents Claude Code errors) |
| `1`, `3+` | Preserve exit code + ❌ Error message | True errors (maintains CI/CD compatibility) |

## Benefits

### For Claude Code Users
- ✅ No more misleading "Error: Bash command failed" messages
- ✅ Clear, actionable status messages with appropriate icons
- ✅ Preserved detailed output from original script

### For CI/CD Systems
- ✅ Exit code 0 and 1 behavior unchanged
- ✅ True errors still cause pipeline failures
- ✅ Original script remains available for direct usage

### For Development Teams
- ✅ Backward compatibility maintained
- ✅ Gradual adoption possible (wrapper optional)
- ✅ Consistent user experience across Agent OS commands

## Testing Pattern

Create comprehensive test suite covering:

```bash
# Test exit code translation
@test "Exit code translation: Clean state (0 → 0)"
@test "Exit code translation: Action needed (2 → 0)" 
@test "Exit code translation: True errors preserved (1+ → 1+)"

# Test argument pass-through
@test "Argument pass-through: All arguments forwarded"
@test "Argument pass-through: No arguments handled"

# Test output preservation  
@test "Output handling: Original output preserved"
@test "Output handling: Wrapper messages distinct"

# Test error scenarios
@test "Error handling: Script not found"
@test "Error handling: Permission errors"

# Test performance
@test "Performance: Minimal overhead added"
```

## Real-World Example: update-documentation Command

**Problem**: The `/update-documentation` command returned exit code 2 when documentation updates were recommended, causing Claude Code to display "Error: Bash command failed" even though the script worked correctly.

**Solution**: Created `update-documentation-wrapper.sh` that:
- Exit 0 → "✅ Documentation is up-to-date"  
- Exit 2 → "📝 Documentation updates recommended"
- Exit 1+ → "❌ Documentation check failed" (preserved)

**Result**: Users now see clear, actionable messages instead of confusing error messages.

## When to Use This Pattern

✅ **Good candidates:**
- Scripts that use exit code 2 for semantic success
- Commands with multiple success states  
- Tools that recommend actions (not just succeed/fail)
- Scripts used in both interactive and CI contexts

❌ **Not needed for:**
- Simple success/failure scripts (exit 0/1 only)
- Scripts that already provide clear error messages
- Internal tools not used through Claude Code commands

## Pattern Variations

### Multiple Semantic Codes
```bash
case $original_exit_code in
	0) echo "✅ No action needed"; exit 0 ;;
	2) echo "📝 Updates recommended"; exit 0 ;;
	3) echo "⚠️  Warnings detected"; exit 0 ;;
	*) echo "❌ Failed (exit $original_exit_code)"; exit $original_exit_code ;;
esac
```

### Context-Specific Messages
```bash
2) 
	if [[ "$output" =~ "CHANGELOG" ]]; then
		echo "📝 CHANGELOG updates recommended"
	elif [[ "$output" =~ "README" ]]; then
		echo "📝 README updates recommended"  
	else
		echo "📝 Documentation updates recommended"
	fi
	exit 0 ;;
```

## Maintenance Notes

1. **Keep Original Available**: Always maintain the original script for CI/CD and direct usage
2. **Test Both Paths**: Verify both wrapper and original script functionality  
3. **Performance Impact**: Wrapper adds minimal overhead (~10ms) through temp files
4. **Error Forwarding**: Ensure stderr is properly forwarded in all cases
5. **Argument Safety**: Use `"$@"` to preserve argument quoting and spacing

---

*This pattern was developed as part of Issue #80 to fix misleading error messages in the /update-documentation command.*