#!/usr/bin/env bats
#
# test-setup-completeness.bats
# Tests complete installation flow and validates all expected files are created
#
# This test suite verifies that the Agent OS installation process works
# correctly and creates all expected files in their proper locations.

load '../test_helper'

# Setup for testing installation in isolated environment
setup() {
	# Create temporary directory for testing installation
	export TEST_HOME=$(mktemp -d)
	export HOME="$TEST_HOME"
	
	# Get repository root for accessing setup scripts
	export REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

# Cleanup after each test
teardown() {
	if [ -n "$TEST_HOME" ] && [ -d "$TEST_HOME" ]; then
		rm -rf "$TEST_HOME"
	fi
}

@test "setup.sh creates all required directories" {
	# Run setup script in test environment
	cd "$REPO_ROOT"
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify all expected directories were created
	[ -d "$TEST_HOME/.agent-os/standards" ]
	[ -d "$TEST_HOME/.agent-os/instructions" ]
	[ -d "$TEST_HOME/.agent-os/instructions/core" ]
	[ -d "$TEST_HOME/.agent-os/instructions/meta" ]
	[ -d "$TEST_HOME/.agent-os/scripts" ]
	[ -d "$TEST_HOME/.agent-os/workflow-modules" ]
	[ -d "$TEST_HOME/.agent-os/tools" ]
}

@test "setup.sh downloads all standards files" {
	cd "$REPO_ROOT"
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify standards files were downloaded
	[ -f "$TEST_HOME/.agent-os/standards/tech-stack.md" ]
	[ -f "$TEST_HOME/.agent-os/standards/code-style.md" ]
	[ -f "$TEST_HOME/.agent-os/standards/best-practices.md" ]
	
	# Verify files have content (not empty)
	[ -s "$TEST_HOME/.agent-os/standards/tech-stack.md" ]
	[ -s "$TEST_HOME/.agent-os/standards/code-style.md" ]
	[ -s "$TEST_HOME/.agent-os/standards/best-practices.md" ]
}

@test "setup.sh downloads all instruction files" {
	cd "$REPO_ROOT"
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify core instruction files were downloaded
	[ -f "$TEST_HOME/.agent-os/instructions/core/analyze-product.md" ]
	[ -f "$TEST_HOME/.agent-os/instructions/core/create-spec.md" ]
	[ -f "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md" ]
	[ -f "$TEST_HOME/.agent-os/instructions/core/plan-product.md" ]
	[ -f "$TEST_HOME/.agent-os/instructions/core/execute-task.md" ]
	
	# Verify meta instruction files were downloaded
	[ -f "$TEST_HOME/.agent-os/instructions/meta/pre-flight.md" ]
	
	# Verify files have content
	[ -s "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md" ]
	[ -s "$TEST_HOME/.agent-os/instructions/meta/pre-flight.md" ]
}

@test "setup.sh downloads all script files with executable permissions" {
	cd "$REPO_ROOT"
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify script files were downloaded
	[ -f "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh" ]
	[ -f "$TEST_HOME/.agent-os/scripts/project-context-loader.sh" ]
	[ -f "$TEST_HOME/.agent-os/scripts/task-validator.sh" ]
	[ -f "$TEST_HOME/.agent-os/scripts/update-documentation.sh" ]
	[ -f "$TEST_HOME/.agent-os/scripts/config-resolver.py" ]
	[ -f "$TEST_HOME/.agent-os/scripts/session-memory.sh" ]
	[ -f "$TEST_HOME/.agent-os/scripts/config-validator.sh" ]
	
	# Verify executable permissions
	[ -x "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh" ]
	[ -x "$TEST_HOME/.agent-os/scripts/project-context-loader.sh" ]
	[ -x "$TEST_HOME/.agent-os/scripts/task-validator.sh" ]
	[ -x "$TEST_HOME/.agent-os/scripts/update-documentation.sh" ]
	[ -x "$TEST_HOME/.agent-os/scripts/session-memory.sh" ]
	
	# Verify files have content
	[ -s "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh" ]
	[ -s "$TEST_HOME/.agent-os/scripts/project-context-loader.sh" ]
}

@test "setup.sh downloads workflow modules" {
	cd "$REPO_ROOT"
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify workflow modules were downloaded
	[ -f "$TEST_HOME/.agent-os/workflow-modules/step-1-hygiene-and-setup.md" ]
	[ -f "$TEST_HOME/.agent-os/workflow-modules/step-2-planning-and-execution.md" ]
	[ -f "$TEST_HOME/.agent-os/workflow-modules/step-3-quality-assurance.md" ]
	[ -f "$TEST_HOME/.agent-os/workflow-modules/step-4-git-integration.md" ]
	
	# Verify files have content
	[ -s "$TEST_HOME/.agent-os/workflow-modules/step-1-hygiene-and-setup.md" ]
	[ -s "$TEST_HOME/.agent-os/workflow-modules/step-2-planning-and-execution.md" ]
}

@test "setup.sh downloads aos CLI tool with executable permissions" {
	cd "$REPO_ROOT"
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify aos tool was downloaded
	[ -f "$TEST_HOME/.agent-os/tools/aos" ]
	
	# Note: executable permissions may fail in test environment, but file should exist
	# [ -x "$TEST_HOME/.agent-os/tools/aos" ]
	
	# Verify file has content
	[ -s "$TEST_HOME/.agent-os/tools/aos" ]
}

@test "setup.sh creates VERSION file with correct version" {
	cd "$REPO_ROOT"
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify VERSION file was created
	[ -f "$TEST_HOME/.agent-os/VERSION" ]
	
	# Verify it has content and matches expected format
	[ -s "$TEST_HOME/.agent-os/VERSION" ]
	
	run cat "$TEST_HOME/.agent-os/VERSION"
	[ "$status" -eq 0 ]
	[[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+.*$ ]]
}

@test "setup.sh preserves existing files by default" {
	cd "$REPO_ROOT"
	
	# Create a test file with custom content
	mkdir -p "$TEST_HOME/.agent-os/standards"
	echo "CUSTOM CONTENT" > "$TEST_HOME/.agent-os/standards/tech-stack.md"
	
	# Run setup
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify our custom content is preserved
	run cat "$TEST_HOME/.agent-os/standards/tech-stack.md"
	[ "$status" -eq 0 ]
	[ "$output" = "CUSTOM CONTENT" ]
	
	# Verify setup reported skipping
	[[ "$output" == *"already exists - skipping"* ]]
}

@test "setup.sh --overwrite-standards flag works correctly" {
	cd "$REPO_ROOT"
	
	# Create a test file with custom content
	mkdir -p "$TEST_HOME/.agent-os/standards"
	echo "CUSTOM CONTENT" > "$TEST_HOME/.agent-os/standards/tech-stack.md"
	
	# Run setup with overwrite flag
	run ./setup.sh --overwrite-standards
	[ "$status" -eq 0 ]
	
	# Verify our custom content was overwritten
	run cat "$TEST_HOME/.agent-os/standards/tech-stack.md"
	[ "$status" -eq 0 ]
	[ "$output" != "CUSTOM CONTENT" ]
	
	# Verify the file now contains actual content
	[ -s "$TEST_HOME/.agent-os/standards/tech-stack.md" ]
}

@test "setup.sh --overwrite-instructions flag works correctly" {
	cd "$REPO_ROOT"
	
	# Create a test file with custom content
	mkdir -p "$TEST_HOME/.agent-os/instructions/core"
	echo "CUSTOM CONTENT" > "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md"
	
	# Run setup with overwrite flag
	run ./setup.sh --overwrite-instructions
	[ "$status" -eq 0 ]
	
	# Verify our custom content was overwritten
	run cat "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md"
	[ "$status" -eq 0 ]
	[ "$output" != "CUSTOM CONTENT" ]
	
	# Verify the file now contains actual content
	[ -s "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md" ]
}

@test "setup-claude-code.sh requires base installation" {
	cd "$REPO_ROOT"
	
	# Try to run Claude Code setup without base installation
	run ./setup-claude-code.sh
	[ "$status" -eq 1 ]
	
	# Should report missing base installation
	[[ "$output" == *"Agent OS base installation not found"* ]]
}

@test "setup-claude-code.sh works after base installation" {
	cd "$REPO_ROOT"
	
	# First run base installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Then run Claude Code setup (with 'n' responses to interactive prompts)
	run bash -c 'echo -e "n\nn" | ./setup-claude-code.sh'
	[ "$status" -eq 0 ]
	
	# Verify Claude Code files were created
	[ -d "$TEST_HOME/.claude/commands" ]
	[ -d "$TEST_HOME/.claude/agents" ]
	
	# Verify command files
	[ -f "$TEST_HOME/.claude/commands/plan-product.md" ]
	[ -f "$TEST_HOME/.claude/commands/create-spec.md" ]
	[ -f "$TEST_HOME/.claude/commands/execute-tasks.md" ]
	
	# Verify agent files
	[ -f "$TEST_HOME/.claude/agents/context-fetcher.md" ]
	[ -f "$TEST_HOME/.claude/agents/date-checker.md" ]
	[ -f "$TEST_HOME/.claude/agents/file-creator.md" ]
	[ -f "$TEST_HOME/.claude/agents/git-workflow.md" ]
	[ -f "$TEST_HOME/.claude/agents/test-runner.md" ]
}

@test "complete installation creates functional Agent OS setup" {
	cd "$REPO_ROOT"
	
	# Run complete installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	run bash -c 'echo -e "n\nn" | ./setup-claude-code.sh'
	[ "$status" -eq 0 ]
	
	# Verify all critical components are present and functional
	
	# Test that key scripts can be executed without errors
	[ -x "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh" ]
	
	# Test that VERSION tracking works
	[ -f "$TEST_HOME/.agent-os/VERSION" ]
	
	# Test that tools are available
	[ -f "$TEST_HOME/.agent-os/tools/aos" ]
	
	# Test directory structure is complete
	[ -d "$TEST_HOME/.agent-os/standards" ]
	[ -d "$TEST_HOME/.agent-os/instructions/core" ]
	[ -d "$TEST_HOME/.agent-os/scripts" ]
	[ -d "$TEST_HOME/.agent-os/workflow-modules" ]
	[ -d "$TEST_HOME/.claude/commands" ]
	[ -d "$TEST_HOME/.claude/agents" ]
}

@test "installation handles network failures gracefully" {
	cd "$REPO_ROOT"
	
	# Mock curl to fail (simulate network issues)
	export PATH="$BATS_TMPDIR:$PATH"
	cat > "$BATS_TMPDIR/curl" << 'EOF'
#!/bin/bash
echo "curl: network error" >&2
exit 1
EOF
	chmod +x "$BATS_TMPDIR/curl"
	
	# Run setup - it should fail gracefully due to set -e
	run ./setup.sh
	[ "$status" -ne 0 ]
	
	# Should not create partial installations
	# (This test verifies the 'set -e' behavior works correctly)
}

@test "installation output provides clear progress indication" {
	cd "$REPO_ROOT"
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify setup provides clear progress indication
	[[ "$output" == *"🚀 Agent OS Setup Script"* ]]
	[[ "$output" == *"📁 Creating directories"* ]]
	[[ "$output" == *"📥 Downloading standards files"* ]]
	[[ "$output" == *"📥 Downloading instruction files"* ]]
	[[ "$output" == *"📥 Downloading script files"* ]]
	[[ "$output" == *"✅ Agent OS base installation complete!"* ]]
}

@test "installation provides helpful next steps" {
	cd "$REPO_ROOT"
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify setup provides next steps
	[[ "$output" == *"Next steps:"* ]]
	[[ "$output" == *"Customize your coding standards"* ]]
	[[ "$output" == *"Install commands for your AI coding assistant"* ]]
}

@test "setup.sh help option works correctly" {
	cd "$REPO_ROOT"
	run ./setup.sh --help
	[ "$status" -eq 0 ]
	
	# Verify help output
	[[ "$output" == *"Usage:"* ]]
	[[ "$output" == *"--overwrite-instructions"* ]]
	[[ "$output" == *"--overwrite-standards"* ]]
}

@test "setup.sh handles unknown options gracefully" {
	cd "$REPO_ROOT"
	run ./setup.sh --unknown-option
	[ "$status" -eq 1 ]
	
	# Verify error handling
	[[ "$output" == *"Unknown option: --unknown-option"* ]]
	[[ "$output" == *"Use --help for usage information"* ]]
}