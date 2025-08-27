#!/usr/bin/env bats

# Test suite for update-documentation-wrapper.sh
# Tests exit code translation and user-friendly messaging for Claude Code

setup() {
	# Create a temporary test directory
	export TEST_DIR="$(mktemp -d)"
	export ORIG_DIR="$(pwd)"
	cd "$TEST_DIR"
	
	# Initialize git repo for testing
	git init >/dev/null 2>&1
	git config user.email "test@example.com"
	git config user.name "Test User"
	
	# Create initial commit
	touch README.md
	git add README.md
	git commit -m "Initial commit" >/dev/null 2>&1
	
	# Path to the scripts under test
	export WRAPPER_PATH="$ORIG_DIR/scripts/update-documentation-wrapper.sh"
	export ORIGINAL_SCRIPT="$ORIG_DIR/scripts/update-documentation.sh"
}

teardown() {
	cd "$ORIG_DIR"
	rm -rf "$TEST_DIR"
}

# Test exit code translation: 0 → 0
@test "Exit code translation: Clean workspace (0 → 0)" {
	run bash "$WRAPPER_PATH" --dry-run
	[ "$status" -eq 0 ]
	[[ "$output" =~ "✅ Documentation is up-to-date" ]]
	[[ "$output" =~ "No changes detected" ]]
}

# Test exit code translation: 2 → 0  
@test "Exit code translation: Documentation updates needed (2 → 0)" {
	# Create change that requires documentation update
	echo "function test() {}" > script.sh
	git add script.sh
	
	run bash "$WRAPPER_PATH" --dry-run
	[ "$status" -eq 0 ]
	[[ "$output" =~ "📝 Documentation updates recommended" ]]
	[[ "$output" =~ "CHANGELOG.md" ]]
}

# Test exit code translation: 1+ → preserve
@test "Exit code translation: True errors preserved (1 → 1)" {
	# Mock a scenario that would cause the original script to fail
	# For now, test that wrapper preserves non-zero exit codes other than 2
	
	# Create a mock failing script scenario
	export MOCK_EXIT_1="true"
	run bash "$WRAPPER_PATH" --dry-run
	
	# This test will fail initially - wrapper doesn't exist yet
	# When implemented, it should preserve exit code 1
	[ "$status" -eq 1 ] || { 
		echo "Expected exit code 1, got $status"
		return 1
	}
	[[ "$output" =~ "❌ Documentation check failed" ]]
}

# Test argument pass-through
@test "Argument pass-through: All arguments forwarded to original script" {
	run bash "$WRAPPER_PATH" --deep --create-missing --diff-only
	
	# Should pass all arguments to original script
	# Original script should receive: --deep --create-missing --diff-only
	[[ "$output" =~ "Git Diff Statistics" ]] || [[ "$output" =~ "Deep Evidence Audit" ]]
}

@test "Argument pass-through: No arguments defaults to original behavior" {
	run bash "$WRAPPER_PATH"
	
	# Should behave exactly like original script with no arguments
	[ "$status" -eq 0 ]
}

@test "Argument pass-through: Single argument" {
	echo "test" > test.txt
	git add test.txt
	
	run bash "$WRAPPER_PATH" --diff-only
	[ "$status" -eq 0 ]
	[[ "$output" =~ "✅ Documentation is up-to-date" ]]
	[[ "$output" =~ "Git Diff Statistics" ]]
}

# Test output handling
@test "Output handling: Original output preserved" {
	echo "function test() {}" > script.sh
	git add script.sh
	
	run bash "$WRAPPER_PATH" --dry-run
	
	# Should contain both wrapper message AND original script output
	[[ "$output" =~ "📝 Documentation updates recommended" ]]
	[[ "$output" =~ "# Discovery" ]]
	[[ "$output" =~ "# Proposed Documentation Updates" ]]
	[[ "$output" =~ "CHANGELOG.md" ]]
}

@test "Output handling: Wrapper messages are distinct" {
	echo "function test() {}" > script.sh
	git add script.sh
	
	run bash "$WRAPPER_PATH" --dry-run
	
	# Wrapper should add clear prefix messages
	[[ "$output" =~ "📝 Documentation updates recommended" ]]
	
	# But not interfere with original detailed output
	[[ "$output" =~ "- script.sh" ]]
}

@test "Output handling: Clean workspace gets success message" {
	run bash "$WRAPPER_PATH" --dry-run
	
	[[ "$output" =~ "✅ Documentation is up-to-date" ]]
	[[ "$output" =~ "No changes detected" ]]
}

# Test error handling
@test "Error handling: Original script errors are preserved" {
	# Test with invalid git repository (should cause git commands to fail)
	rm -rf .git
	
	run bash "$WRAPPER_PATH" --dry-run
	
	# Should preserve error behavior and add error message
	[ "$status" -ne 0 ]
	[[ "$output" =~ "❌" ]] || [[ "$output" =~ "failed" ]]
}

@test "Error handling: Wrapper script not found" {
	# Test behavior when original script is missing
	export ORIGINAL_SCRIPT="/nonexistent/script.sh"
	
	run bash "$WRAPPER_PATH" --dry-run
	
	[ "$status" -ne 0 ]
	[[ "$output" =~ "❌" ]] || [[ "$output" =~ "failed" ]] || [[ "$output" =~ "not found" ]]
}

# Test performance
@test "Performance: Wrapper adds minimal overhead" {
	start_time=$(date +%s%N)
	
	run bash "$WRAPPER_PATH" --dry-run
	
	end_time=$(date +%s%N)
	duration_ms=$(( (end_time - start_time) / 1000000 ))
	
	# Wrapper should add less than 50ms overhead (generous allowance)
	[ "$duration_ms" -lt 50 ]
}

# Test deep mode compatibility
@test "Deep mode compatibility: --deep argument works with wrapper" {
	mkdir -p .agent-os/product
	
	run bash "$WRAPPER_PATH" --deep
	
	# Should work with deep mode and provide appropriate status
	[ "$status" -eq 0 ]
	[[ "$output" =~ "✅ Documentation is up-to-date" ]] || [[ "$output" =~ "📝 Documentation updates recommended" ]]
}

# Test create-missing compatibility
@test "Create-missing compatibility: --create-missing works with wrapper" {
	echo "code" > feature.sh
	git add feature.sh
	
	run bash "$WRAPPER_PATH" --create-missing
	
	[ "$status" -eq 0 ]
	# Should show success status even when creating files
	[[ "$output" =~ "✅" ]] || [[ "$output" =~ "📝" ]]
}

# Test Claude Code specific messaging
@test "Claude Code messaging: User-friendly status messages" {
	echo "function test() {}" > script.sh
	git add script.sh
	
	run bash "$WRAPPER_PATH" --dry-run
	
	# Messages should be Claude Code friendly
	[[ "$output" =~ "📝 Documentation updates recommended" ]]
	! [[ "$output" =~ "Error:" ]]
	! [[ "$output" =~ "failed" ]]
}

@test "Claude Code messaging: Success is clearly indicated" {
	run bash "$WRAPPER_PATH" --dry-run
	
	[[ "$output" =~ "✅ Documentation is up-to-date" ]]
	[ "$status" -eq 0 ]
}

# Integration test: Compare wrapper vs original behavior
@test "Integration: Wrapper preserves original functionality" {
	echo "function test() {}" > script.sh
	git add script.sh
	
	# Run original script
	run bash "$ORIGINAL_SCRIPT" --dry-run
	original_output="$output"
	original_status="$status"
	
	# Run wrapper
	run bash "$WRAPPER_PATH" --dry-run
	wrapper_output="$output"
	wrapper_status="$status"
	
	# Wrapper should contain all original output content
	# (but status should be different for exit code 2)
	if [ "$original_status" -eq 2 ]; then
		[ "$wrapper_status" -eq 0 ]
		[[ "$wrapper_output" =~ "📝 Documentation updates recommended" ]]
	else
		[ "$wrapper_status" -eq "$original_status" ]
	fi
	
	# Original output should be contained in wrapper output
	[[ "$wrapper_output" =~ "# Discovery" ]]
	[[ "$wrapper_output" =~ "CHANGELOG.md" ]]
}