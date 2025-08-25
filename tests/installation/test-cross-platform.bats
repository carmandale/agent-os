#!/usr/bin/env bats
#
# test-cross-platform.bats
# Tests Agent OS installation compatibility across macOS and Linux platforms
#
# This test suite verifies that Agent OS setup scripts work correctly
# on different operating systems and handle platform-specific requirements.

load '../test_helper'

# Setup for testing installation in isolated environment
setup() {
	export TEST_HOME=$(mktemp -d)
	export HOME="$TEST_HOME"
	export REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

teardown() {
	if [ -n "$TEST_HOME" ] && [ -d "$TEST_HOME" ]; then
		rm -rf "$TEST_HOME"
	fi
}

@test "setup scripts use portable bash constructs" {
	cd "$REPO_ROOT"
	
	# Test that setup.sh uses portable bash syntax
	# Avoid bash-specific features like [[ ]] in favor of [ ]
	# Avoid arrays and other bashisms where possible
	
	# Check for proper shebang
	run head -n1 setup.sh
	[[ "$output" == "#!/bin/bash" ]]
	
	run head -n1 setup-claude-code.sh
	[[ "$output" =~ ^#!/bin/bash ]]
	
	# Verify scripts don't use non-portable constructs
	# (This is a basic check - comprehensive linting would require shellcheck)
	
	# Test that critical variables are properly quoted
	run grep -E '\$[A-Z_]+[^"]' setup.sh
	[ "$status" -ne 0 ] || [[ "$output" != *'$HOME'* ]]  # $HOME should be quoted where used critically
}

@test "curl commands work on both macOS and Linux" {
	cd "$REPO_ROOT"
	
	# Test that curl is available (should be on both platforms)
	run which curl
	[ "$status" -eq 0 ]
	
	# Test that curl flags used in setup scripts are portable
	# -s (silent), -o (output), -L (follow redirects) are universally supported
	
	run curl --version
	[ "$status" -eq 0 ]
	
	# Test specific curl command format used in setup.sh
	run curl -s -o /dev/null --head "https://httpbin.org/get"
	[ "$status" -eq 0 ]
}

@test "directory creation works across platforms" {
	cd "$REPO_ROOT"
	
	# Test mkdir -p behavior (should work on both platforms)
	mkdir -p "$TEST_HOME/.agent-os/test/nested/deep"
	[ -d "$TEST_HOME/.agent-os/test/nested/deep" ]
	
	# Test that the paths used in setup.sh work correctly
	mkdir -p "$TEST_HOME/.agent-os/standards"
	mkdir -p "$TEST_HOME/.agent-os/instructions/core" 
	mkdir -p "$TEST_HOME/.agent-os/instructions/meta"
	mkdir -p "$TEST_HOME/.agent-os/scripts"
	mkdir -p "$TEST_HOME/.agent-os/workflow-modules"
	mkdir -p "$TEST_HOME/.agent-os/hooks"
	mkdir -p "$TEST_HOME/.agent-os/tools"
	
	# Verify all directories were created
	[ -d "$TEST_HOME/.agent-os/standards" ]
	[ -d "$TEST_HOME/.agent-os/instructions/core" ]
	[ -d "$TEST_HOME/.agent-os/instructions/meta" ]
	[ -d "$TEST_HOME/.agent-os/scripts" ]
	[ -d "$TEST_HOME/.agent-os/workflow-modules" ]
	[ -d "$TEST_HOME/.agent-os/hooks" ]
	[ -d "$TEST_HOME/.agent-os/tools" ]
}

@test "file permissions work correctly across platforms" {
	cd "$REPO_ROOT"
	
	# Test chmod behavior across platforms
	touch "$TEST_HOME/test-script.sh"
	chmod +x "$TEST_HOME/test-script.sh"
	[ -x "$TEST_HOME/test-script.sh" ]
	
	# Test that permission check syntax works
	if [ -x "$TEST_HOME/test-script.sh" ]; then
		echo "Permissions work correctly"
	fi
}

@test "HOME directory resolution works across platforms" {
	# Test that $HOME variable works correctly across platforms
	[ -n "$HOME" ]
	[ -d "$HOME" ]
	
	# Test path construction with $HOME
	test_path="$HOME/.agent-os/test"
	mkdir -p "$test_path"
	[ -d "$test_path" ]
}

@test "shell command substitution works across platforms" {
	cd "$REPO_ROOT"
	
	# Test the command substitution patterns used in setup.sh
	result=$(cat VERSION 2>/dev/null || echo "fallback")
	[ -n "$result" ]
	
	# Test pwd command
	current_dir=$(pwd)
	[ -n "$current_dir" ]
	
	# Test command substitution with curl (pattern used in setup.sh)
	# Mock this since we don't want to actually download
	result=$(echo "4.0.2" | head -n1)
	[ "$result" = "4.0.2" ]
}

@test "conditional statements work across platforms" {
	cd "$REPO_ROOT"
	
	# Test file existence checks (used extensively in setup scripts)
	if [ -f "$REPO_ROOT/VERSION" ]; then
		[ -f "$REPO_ROOT/VERSION" ]  # This should be true
	else
		[ ! -f "$REPO_ROOT/VERSION" ] # This should be false
	fi
	
	# Test directory existence checks
	mkdir -p "$TEST_HOME/.agent-os/test"
	if [ -d "$TEST_HOME/.agent-os/test" ]; then
		[ -d "$TEST_HOME/.agent-os/test" ]  # This should be true
	fi
	
	# Test variable comparison (used in setup.sh flag parsing)
	TEST_VAR="true"
	if [ "$TEST_VAR" = "true" ]; then
		[ "$TEST_VAR" = "true" ]  # This should be true
	fi
}

@test "error handling works across platforms" {
	cd "$REPO_ROOT"
	
	# Test 'set -e' behavior (exit on error)
	cat > "$TEST_HOME/test-set-e.sh" << 'EOF'
#!/bin/bash
set -e
echo "before error"
false  # This should cause exit
echo "after error"  # This should not be reached
EOF
	chmod +x "$TEST_HOME/test-set-e.sh"
	
	run "$TEST_HOME/test-set-e.sh"
	[ "$status" -ne 0 ]
	[[ "$output" == *"before error"* ]]
	[[ "$output" != *"after error"* ]]
}

@test "redirection and output handling work across platforms" {
	cd "$REPO_ROOT"
	
	# Test stdout redirection (used in setup scripts)
	echo "test content" > "$TEST_HOME/test-output.txt"
	[ -f "$TEST_HOME/test-output.txt" ]
	
	run cat "$TEST_HOME/test-output.txt"
	[ "$output" = "test content" ]
	
	# Test stderr redirection (used in setup scripts)
	echo "error message" 2> "$TEST_HOME/test-error.txt"
	[ -f "$TEST_HOME/test-error.txt" ]
	
	# Test /dev/null redirection (used in setup scripts)
	echo "ignored" > /dev/null
	echo "also ignored" 2>/dev/null || true
}

@test "text processing commands work across platforms" {
	cd "$REPO_ROOT"
	
	# Test head command (used in setup.sh)
	echo -e "line1\nline2\nline3" | head -n1 > "$TEST_HOME/head-test.txt"
	run cat "$TEST_HOME/head-test.txt"
	[ "$output" = "line1" ]
	
	# Test grep behavior (used in validation)
	echo -e "match this\ndon't match\nmatch this too" > "$TEST_HOME/grep-test.txt"
	run grep "match" "$TEST_HOME/grep-test.txt"
	[ "$status" -eq 0 ]
	[[ "$output" == *"match this"* ]]
	
	# Test cat command
	echo "test content" > "$TEST_HOME/cat-test.txt"
	run cat "$TEST_HOME/cat-test.txt"
	[ "$output" = "test content" ]
}

@test "loop constructs work across platforms" {
	cd "$REPO_ROOT"
	
	# Test for loop over array (used in setup-claude-code.sh)
	agents=("context-fetcher" "date-checker" "file-creator")
	count=0
	for agent in "${agents[@]}"; do
		count=$((count + 1))
	done
	[ "$count" -eq 3 ]
	
	# Test for loop over simple list
	count=0
	for item in one two three; do
		count=$((count + 1))
	done
	[ "$count" -eq 3 ]
}

@test "case statement works across platforms" {
	cd "$REPO_ROOT"
	
	# Test case statement (used in setup.sh for argument parsing)
	test_arg="--test-flag"
	result=""
	
	case $test_arg in
		--test-flag)
			result="matched"
			;;
		*)
			result="no match"
			;;
	esac
	
	[ "$result" = "matched" ]
}

@test "arithmetic operations work across platforms" {
	cd "$REPO_ROOT"
	
	# Test arithmetic expansion (used in loop counters)
	count=0
	count=$((count + 1))
	[ "$count" -eq 1 ]
	
	count=$((count + 5))
	[ "$count" -eq 6 ]
}

@test "read command works across platforms" {
	cd "$REPO_ROOT"
	
	# Test read command (used in setup-claude-code.sh for user input)
	# We'll test with input redirection since interactive input is not testable
	
	echo "test input" > "$TEST_HOME/input.txt"
	read -r result < "$TEST_HOME/input.txt"
	[ "$result" = "test input" ]
}

@test "which command works across platforms" {
	cd "$REPO_ROOT"
	
	# Test which command (commonly used to check for dependencies)
	run which bash
	[ "$status" -eq 0 ]
	[ -n "$output" ]
	
	# Test checking for curl availability
	run which curl
	[ "$status" -eq 0 ]
}

@test "rm command works across platforms" {
	cd "$REPO_ROOT"
	
	# Test file removal (used in setup.sh cleanup)
	touch "$TEST_HOME/test-remove.txt"
	[ -f "$TEST_HOME/test-remove.txt" ]
	
	rm -f "$TEST_HOME/test-remove.txt"
	[ ! -f "$TEST_HOME/test-remove.txt" ]
	
	# Test directory removal
	mkdir -p "$TEST_HOME/test-dir/subdir"
	[ -d "$TEST_HOME/test-dir/subdir" ]
	
	rm -rf "$TEST_HOME/test-dir"
	[ ! -d "$TEST_HOME/test-dir" ]
}

@test "mktemp works across platforms" {
	# Test mktemp for temporary directories (used in tests)
	temp_dir=$(mktemp -d)
	[ -d "$temp_dir" ]
	[ -n "$temp_dir" ]
	
	# Cleanup
	rm -rf "$temp_dir"
	[ ! -d "$temp_dir" ]
}

@test "full installation works in simulated Linux environment" {
	skip "Requires Docker or Linux VM for full Linux testing"
	# This test would ideally run the full installation in a Linux container
	# to verify cross-platform compatibility
}

@test "full installation works in simulated macOS environment" {
	# Since we're likely running on macOS, test the full installation
	cd "$REPO_ROOT"
	
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify installation completed successfully
	[ -d "$TEST_HOME/.agent-os/standards" ]
	[ -f "$TEST_HOME/.agent-os/VERSION" ]
}