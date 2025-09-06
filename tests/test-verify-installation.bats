#!/usr/bin/env bats
# Test suite for verify-installation.sh script
# Follows Agent OS TDD practices with comprehensive coverage

load "test_helper"

# Test constants
readonly TEST_SCRIPT="./scripts/verify-installation.sh"
readonly MOCK_HOME="${BATS_TMPDIR}/mock_home"
readonly MOCK_AGENT_OS="${MOCK_HOME}/.agent-os"
readonly MOCK_CLAUDE="${MOCK_HOME}/.claude"

setup() {
	# Create mock directory structure for testing
	mkdir -p "${MOCK_AGENT_OS}/"{hooks,instructions,standards,scripts,tools}
	mkdir -p "${MOCK_CLAUDE}/"{commands,agents}
	
	# Set up mock files with valid content
	echo '{"hooks": {"post": ["~/.agent-os/hooks/post-hook.sh"]}}' > "${MOCK_CLAUDE}/settings.json"
	echo '#!/bin/bash\necho "mock hook"' > "${MOCK_AGENT_OS}/hooks/post-hook.sh"
	chmod +x "${MOCK_AGENT_OS}/hooks/post-hook.sh"
	
	# Create mock instruction and standard files
	echo "# Mock instruction" > "${MOCK_AGENT_OS}/instructions/plan-product.md"
	echo "# Mock standard" > "${MOCK_AGENT_OS}/standards/tech-stack.md"
	
	# Mock aos command availability
	echo '#!/bin/bash\necho "aos version 4.0.0"' > "${MOCK_AGENT_OS}/tools/aos"
	chmod +x "${MOCK_AGENT_OS}/tools/aos"
	
	export HOME="${MOCK_HOME}"
	export PATH="${MOCK_AGENT_OS}/tools:${PATH}"
}

teardown() {
	# Clean up mock environment
	rm -rf "${MOCK_HOME}"
	unset HOME
}

# Directory structure validation tests
@test "validate_directory_structure detects missing .agent-os directory" {
	rm -rf "${MOCK_AGENT_OS}"
	
	run bash -c ". ${TEST_SCRIPT}; validate_directory_structure"
	
	[ "$status" -eq 1 ]
	[[ "$output" =~ "ERROR" ]]
	[[ "$output" =~ ".agent-os" ]]
}

@test "validate_directory_structure passes with complete directory structure" {
	run bash -c ". ${TEST_SCRIPT}; validate_directory_structure"
	
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Directory structure" ]]
}

@test "validate_directory_structure detects missing subdirectories" {
	rm -rf "${MOCK_AGENT_OS}/hooks"
	
	run bash -c ". ${TEST_SCRIPT}; validate_directory_structure"
	
	[ "$status" -eq 1 ]
	[[ "$output" =~ "hooks" ]]
}

@test "validate_directory_structure checks directory permissions" {
	chmod 444 "${MOCK_AGENT_OS}"
	
	run bash -c ". ${TEST_SCRIPT}; validate_directory_structure"
	
	[ "$status" -eq 1 ]
	[[ "$output" =~ "permission" ]]
}

# File integrity validation tests
@test "validate_file_integrity detects missing core files" {
	rm "${MOCK_AGENT_OS}/instructions/plan-product.md"
	
	run bash -c ". ${TEST_SCRIPT}; validate_file_integrity"
	
	[ "$status" -eq 1 ]
	[[ "$output" =~ "plan-product.md" ]]
}

@test "validate_file_integrity validates executable permissions" {
	chmod -x "${MOCK_AGENT_OS}/hooks/post-hook.sh"
	
	run bash -c ". ${TEST_SCRIPT}; validate_file_integrity"
	
	[ "$status" -eq 1 ]
	[[ "$output" =~ "executable" ]]
}

@test "validate_file_integrity detects corrupted JSON configuration" {
	echo "invalid json {" > "${MOCK_CLAUDE}/settings.json"
	
	run bash -c ". ${TEST_SCRIPT}; validate_file_integrity"
	
	[ "$status" -eq 1 ]
	[[ "$output" =~ "JSON" ]]
}

# Claude Code hooks validation tests
@test "validate_claude_hooks detects missing settings.json" {
	rm "${MOCK_CLAUDE}/settings.json"
	
	run bash -c ". ${TEST_SCRIPT}; validate_claude_hooks"
	
	[ "$status" -eq 1 ]
	[[ "$output" =~ "settings.json" ]]
}

@test "validate_claude_hooks validates hook file references" {
	rm "${MOCK_AGENT_OS}/hooks/post-hook.sh"
	
	run bash -c ". ${TEST_SCRIPT}; validate_claude_hooks"
	
	[ "$status" -eq 1 ]
	[[ "$output" =~ "post-hook.sh" ]]
}

@test "validate_claude_hooks passes with valid configuration" {
	run bash -c ". ${TEST_SCRIPT}; validate_claude_hooks"
	
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Claude Code hooks" ]]
}

# CLI command validation tests
@test "validate_cli_commands detects missing aos command" {
	rm "${MOCK_AGENT_OS}/tools/aos"
	
	run bash -c ". ${TEST_SCRIPT}; validate_cli_commands"
	
	[ "$status" -eq 1 ]
	[[ "$output" =~ "aos command" ]]
}

@test "validate_cli_commands validates aos functionality" {
	run bash -c ". ${TEST_SCRIPT}; validate_cli_commands"
	
	[ "$status" -eq 0 ]
	[[ "$output" =~ "CLI commands" ]]
}

# Git integration validation tests
@test "validate_git_integration checks git availability" {
	# Mock git command not available
	run bash -c "PATH=/dev/null; . ${TEST_SCRIPT}; validate_git_integration"
	
	[ "$status" -eq 1 ]
	[[ "$output" =~ "git" ]]
}

# Main script functionality tests
@test "verify-installation.sh accepts --quick flag" {
	skip "Script not yet implemented"
	
	run "${TEST_SCRIPT}" --quick
	
	[ "$status" -eq 0 ]
}

@test "verify-installation.sh accepts --full flag" {
	skip "Script not yet implemented"
	
	run "${TEST_SCRIPT}" --full
	
	[ "$status" -eq 0 ]
}

@test "verify-installation.sh provides help text" {
	skip "Script not yet implemented"
	
	run "${TEST_SCRIPT}" --help
	
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Usage:" ]]
}

# Performance tests
@test "quick verification completes in under 5 seconds" {
	skip "Performance testing after implementation"
	
	start_time=$(date +%s)
	run "${TEST_SCRIPT}" --quick
	end_time=$(date +%s)
	
	duration=$((end_time - start_time))
	[ "$duration" -lt 5 ]
}

@test "full verification completes in under 30 seconds" {
	skip "Performance testing after implementation"
	
	start_time=$(date +%s)
	run "${TEST_SCRIPT}" --full
	end_time=$(date +%s)
	
	duration=$((end_time - start_time))
	[ "$duration" -lt 30 ]
}

# Error handling tests
@test "script handles invalid arguments gracefully" {
	skip "Error handling after implementation"
	
	run "${TEST_SCRIPT}" --invalid-flag
	
	[ "$status" -eq 3 ]
	[[ "$output" =~ "Invalid argument" ]]
}

@test "script returns appropriate exit codes" {
	skip "Exit code testing after implementation"
	
	# Test success case
	run "${TEST_SCRIPT}" --quick
	[ "$status" -eq 0 ]
	
	# Test failure case would require broken installation
}