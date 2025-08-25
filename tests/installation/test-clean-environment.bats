#!/usr/bin/env bats
#
# test-clean-environment.bats
# Tests Agent OS installation on completely clean systems
#
# This test suite verifies that Agent OS can be installed on fresh systems
# without any prior setup or dependencies beyond standard Unix utilities.

load '../test_helper'

# Setup for testing installation in completely isolated environment
setup() {
	export TEST_HOME=$(mktemp -d)
	export HOME="$TEST_HOME"
	export REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
	
	# Ensure we have a completely clean environment
	unset AGENT_OS_VERSION 2>/dev/null || true
	unset BASE_URL 2>/dev/null || true
}

teardown() {
	if [ -n "$TEST_HOME" ] && [ -d "$TEST_HOME" ]; then
		rm -rf "$TEST_HOME"
	fi
}

@test "installation works with no existing .agent-os directory" {
	cd "$REPO_ROOT"
	
	# Ensure no .agent-os directory exists
	[ ! -d "$TEST_HOME/.agent-os" ]
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify complete installation was created
	[ -d "$TEST_HOME/.agent-os" ]
	[ -d "$TEST_HOME/.agent-os/standards" ]
	[ -d "$TEST_HOME/.agent-os/instructions" ]
	[ -d "$TEST_HOME/.agent-os/scripts" ]
	[ -d "$TEST_HOME/.agent-os/workflow-modules" ]
	[ -d "$TEST_HOME/.agent-os/tools" ]
	
	# Verify critical files exist
	[ -f "$TEST_HOME/.agent-os/VERSION" ]
	[ -f "$TEST_HOME/.agent-os/standards/tech-stack.md" ]
	[ -f "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md" ]
}

@test "installation works with empty HOME directory" {
	cd "$REPO_ROOT"
	
	# Verify HOME is empty
	[ "$(ls -A "$TEST_HOME" 2>/dev/null | wc -l)" -eq 0 ]
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify installation completed successfully
	[ -d "$TEST_HOME/.agent-os" ]
	[ -f "$TEST_HOME/.agent-os/VERSION" ]
}

@test "installation requires only standard Unix utilities" {
	cd "$REPO_ROOT"
	
	# Test that required utilities are available in clean environment
	run which curl
	[ "$status" -eq 0 ]
	
	run which mkdir
	[ "$status" -eq 0 ]
	
	run which chmod
	[ "$status" -eq 0 ]
	
	run which cat
	[ "$status" -eq 0 ]
	
	run which head
	[ "$status" -eq 0 ]
	
	run which bash
	[ "$status" -eq 0 ]
	
	# Run installation to verify these are sufficient
	run ./setup.sh
	[ "$status" -eq 0 ]
}

@test "installation handles missing curl gracefully" {
	cd "$REPO_ROOT"
	
	# Mock missing curl
	export PATH="$BATS_TMPDIR:$PATH"
	cat > "$BATS_TMPDIR/curl" << 'EOF'
#!/bin/bash
echo "curl: command not found" >&2
exit 127
EOF
	chmod +x "$BATS_TMPDIR/curl"
	
	# Run installation - should fail gracefully
	run ./setup.sh
	[ "$status" -ne 0 ]
	
	# Should provide helpful error message
	[[ "$output" == *"curl"* ]]
}

@test "claude-code setup works in clean environment after base installation" {
	cd "$REPO_ROOT"
	
	# Verify no .claude directory exists
	[ ! -d "$TEST_HOME/.claude" ]
	
	# Run base installation first
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Run Claude Code setup
	run bash -c 'echo -e "n\nn" | ./setup-claude-code.sh'
	[ "$status" -eq 0 ]
	
	# Verify Claude Code installation completed
	[ -d "$TEST_HOME/.claude" ]
	[ -d "$TEST_HOME/.claude/commands" ]
	[ -d "$TEST_HOME/.claude/agents" ]
	[ -f "$TEST_HOME/.claude/commands/execute-tasks.md" ]
	[ -f "$TEST_HOME/.claude/agents/context-fetcher.md" ]
}

@test "installation works without pre-existing configuration files" {
	cd "$REPO_ROOT"
	
	# Verify no configuration files exist
	[ ! -f "$TEST_HOME/.bashrc" ]
	[ ! -f "$TEST_HOME/.bash_profile" ]
	[ ! -f "$TEST_HOME/.profile" ]
	[ ! -f "$TEST_HOME/.zshrc" ]
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify installation succeeded despite no shell config
	[ -f "$TEST_HOME/.agent-os/VERSION" ]
}

@test "installation creates proper file permissions in clean environment" {
	cd "$REPO_ROOT"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify script files have executable permissions
	[ -x "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh" ]
	[ -x "$TEST_HOME/.agent-os/scripts/project-context-loader.sh" ]
	[ -x "$TEST_HOME/.agent-os/scripts/task-validator.sh" ]
	
	# Verify data files are readable but not executable
	[ -f "$TEST_HOME/.agent-os/standards/tech-stack.md" ]
	[ -r "$TEST_HOME/.agent-os/standards/tech-stack.md" ]
	[ ! -x "$TEST_HOME/.agent-os/standards/tech-stack.md" ]
}

@test "installation handles network-based VERSION fallback correctly" {
	cd "$REPO_ROOT"
	
	# Remove local VERSION file to test network fallback
	mv VERSION VERSION.backup 2>/dev/null || true
	
	# Mock curl for VERSION retrieval to simulate network call
	export PATH="$BATS_TMPDIR:$PATH"
	cat > "$BATS_TMPDIR/curl" << 'EOF'
#!/bin/bash
if [[ "$*" == *"/VERSION"* ]]; then
	echo "4.0.2"
else
	# Pass through to real curl for other files
	exec /usr/bin/curl "$@"
fi
EOF
	chmod +x "$BATS_TMPDIR/curl"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify VERSION was set correctly
	[ -f "$TEST_HOME/.agent-os/VERSION" ]
	run cat "$TEST_HOME/.agent-os/VERSION"
	[ "$output" = "4.0.2" ]
	
	# Restore original VERSION file
	mv VERSION.backup VERSION 2>/dev/null || true
}

@test "installation works with minimal PATH" {
	cd "$REPO_ROOT"
	
	# Set minimal PATH with only essential directories
	export PATH="/bin:/usr/bin:/usr/local/bin"
	
	# Verify curl is still available
	run which curl
	[ "$status" -eq 0 ]
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify installation completed
	[ -f "$TEST_HOME/.agent-os/VERSION" ]
}

@test "installation handles umask variations correctly" {
	cd "$REPO_ROOT"
	
	# Test with restrictive umask
	umask 077
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify files were created and are accessible
	[ -f "$TEST_HOME/.agent-os/standards/tech-stack.md" ]
	[ -r "$TEST_HOME/.agent-os/standards/tech-stack.md" ]
	
	# Verify scripts are executable
	[ -x "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh" ]
	
	# Reset umask
	umask 022
}

@test "installation works without git in PATH" {
	cd "$REPO_ROOT"
	
	# Create temporary PATH without git
	export PATH="$(echo "$PATH" | tr ':' '\n' | grep -v git | tr '\n' ':')"
	
	# Verify git is not available
	run which git
	[ "$status" -ne 0 ]
	
	# Run installation (should still work as it doesn't require git)
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify installation completed
	[ -f "$TEST_HOME/.agent-os/VERSION" ]
}

@test "installation produces expected output in clean environment" {
	cd "$REPO_ROOT"
	
	# Run installation and capture output
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify expected progress messages
	[[ "$output" == *"🚀 Agent OS Setup Script"* ]]
	[[ "$output" == *"📁 Creating directories"* ]]
	[[ "$output" == *"📥 Downloading standards files"* ]]
	[[ "$output" == *"📥 Downloading instruction files"* ]]
	[[ "$output" == *"📥 Downloading script files"* ]]
	[[ "$output" == *"📥 Downloading workflow modules"* ]]
	[[ "$output" == *"📥 Downloading background task tools"* ]]
	[[ "$output" == *"✅ Agent OS base installation complete!"* ]]
	
	# Verify next steps are provided
	[[ "$output" == *"Next steps:"* ]]
	[[ "$output" == *"Customize your coding standards"* ]]
}

@test "installation creates consistent directory structure" {
	cd "$REPO_ROOT"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify exact directory structure matches expectations
	[ -d "$TEST_HOME/.agent-os" ]
	[ -d "$TEST_HOME/.agent-os/standards" ]
	[ -d "$TEST_HOME/.agent-os/instructions" ]
	[ -d "$TEST_HOME/.agent-os/instructions/core" ]
	[ -d "$TEST_HOME/.agent-os/instructions/meta" ]
	[ -d "$TEST_HOME/.agent-os/scripts" ]
	[ -d "$TEST_HOME/.agent-os/workflow-modules" ]
	[ -d "$TEST_HOME/.agent-os/hooks" ]
	[ -d "$TEST_HOME/.agent-os/tools" ]
	
	# Verify no unexpected directories were created
	run find "$TEST_HOME/.agent-os" -type d
	[ "$status" -eq 0 ]
	[ $(echo "$output" | wc -l) -eq 8 ]  # Exactly 8 directories (including .agent-os itself)
}

@test "installation validates downloaded content is not empty" {
	cd "$REPO_ROOT"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify critical files have content (not empty)
	[ -s "$TEST_HOME/.agent-os/VERSION" ]
	[ -s "$TEST_HOME/.agent-os/standards/tech-stack.md" ]
	[ -s "$TEST_HOME/.agent-os/standards/code-style.md" ]
	[ -s "$TEST_HOME/.agent-os/standards/best-practices.md" ]
	[ -s "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md" ]
	[ -s "$TEST_HOME/.agent-os/instructions/core/create-spec.md" ]
	[ -s "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh" ]
	[ -s "$TEST_HOME/.agent-os/workflow-modules/step-1-hygiene-and-setup.md" ]
	[ -s "$TEST_HOME/.agent-os/tools/aos" ]
}

@test "clean environment installation passes self-validation" {
	cd "$REPO_ROOT"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Test that installation passes its own validation
	# (This would be integration with future validation tools)
	
	# For now, verify that key validation points pass
	[ -f "$TEST_HOME/.agent-os/VERSION" ]
	run cat "$TEST_HOME/.agent-os/VERSION"
	[[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+.*$ ]]
	
	# Verify no broken symlinks were created
	run find "$TEST_HOME/.agent-os" -type l -exec test ! -e {} \; -print
	[ "$status" -eq 0 ]
	[ -z "$output" ]  # No broken symlinks found
}

@test "installation handles filesystem edge cases" {
	cd "$REPO_ROOT"
	
	# Test installation in directory with spaces
	export TEST_HOME_WITH_SPACES="$(mktemp -d "/tmp/agent os test XXXXXX")"
	export HOME="$TEST_HOME_WITH_SPACES"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify installation worked despite spaces in path
	[ -f "$TEST_HOME_WITH_SPACES/.agent-os/VERSION" ]
	
	# Cleanup
	rm -rf "$TEST_HOME_WITH_SPACES"
}

@test "parallel installations do not conflict" {
	cd "$REPO_ROOT"
	
	# Create second test environment
	export TEST_HOME_2=$(mktemp -d)
	
	# Run installation in both environments
	HOME="$TEST_HOME" ./setup.sh > /dev/null 2>&1 &
	pid1=$!
	HOME="$TEST_HOME_2" ./setup.sh > /dev/null 2>&1 &
	pid2=$!
	
	# Wait for both to complete
	wait $pid1
	status1=$?
	wait $pid2
	status2=$?
	
	# Both should succeed
	[ "$status1" -eq 0 ]
	[ "$status2" -eq 0 ]
	
	# Both should have valid installations
	[ -f "$TEST_HOME/.agent-os/VERSION" ]
	[ -f "$TEST_HOME_2/.agent-os/VERSION" ]
	
	# Cleanup second environment
	rm -rf "$TEST_HOME_2"
}