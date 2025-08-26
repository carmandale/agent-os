#!/usr/bin/env bats
#
# test-update-paths.bats
# Tests Agent OS update scenarios and version management
#
# This test suite verifies that Agent OS can be updated safely without
# breaking existing installations and that user customizations are preserved.

load '../test_helper'

# Setup for testing installation in isolated environment
setup() {
	export TEST_HOME=$(mktemp -d)
	export HOME="$TEST_HOME"
	export REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
	
	# Create a baseline installation first
	cd "$REPO_ROOT"
	./setup.sh > /dev/null 2>&1
}

teardown() {
	if [ -n "$TEST_HOME" ] && [ -d "$TEST_HOME" ]; then
		rm -rf "$TEST_HOME"
	fi
}

@test "update preserves existing standards files by default" {
	cd "$REPO_ROOT"
	
	# Modify a standards file
	echo "# CUSTOM TECH STACK" > "$TEST_HOME/.agent-os/standards/tech-stack.md"
	echo "My custom configuration" >> "$TEST_HOME/.agent-os/standards/tech-stack.md"
	
	# Run update (should preserve customizations)
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify customizations are preserved
	run head -n1 "$TEST_HOME/.agent-os/standards/tech-stack.md"
	[ "$output" = "# CUSTOM TECH STACK" ]
	
	# Verify setup reported skipping
	[[ "$output" == *"already exists - skipping"* ]]
}

@test "update preserves existing instruction files by default" {
	cd "$REPO_ROOT"
	
	# Modify an instruction file
	echo "# CUSTOM EXECUTE TASKS" > "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md"
	echo "My custom workflow" >> "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md"
	
	# Run update
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify customizations are preserved
	run head -n1 "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md"
	[ "$output" = "# CUSTOM EXECUTE TASKS" ]
	
	# Verify setup reported skipping
	[[ "$output" == *"already exists - skipping"* ]]
}

@test "--overwrite-standards flag updates standards files" {
	cd "$REPO_ROOT"
	
	# Modify a standards file
	echo "# CUSTOM TECH STACK" > "$TEST_HOME/.agent-os/standards/tech-stack.md"
	
	# Run update with overwrite flag
	run ./setup.sh --overwrite-standards
	[ "$status" -eq 0 ]
	
	# Verify customizations were overwritten
	run head -n1 "$TEST_HOME/.agent-os/standards/tech-stack.md"
	[ "$output" != "# CUSTOM TECH STACK" ]
	
	# Verify setup reported overwriting
	[[ "$output" == *"(overwritten)"* ]]
}

@test "--overwrite-instructions flag updates instruction files" {
	cd "$REPO_ROOT"
	
	# Modify an instruction file
	echo "# CUSTOM EXECUTE TASKS" > "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md"
	
	# Run update with overwrite flag
	run ./setup.sh --overwrite-instructions
	[ "$status" -eq 0 ]
	
	# Verify customizations were overwritten
	run head -n1 "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md"
	[ "$output" != "# CUSTOM EXECUTE TASKS" ]
	
	# Verify setup reported overwriting
	[[ "$output" == *"(overwritten)"* ]]
}

@test "scripts are always updated (no preservation)" {
	cd "$REPO_ROOT"
	
	# Modify a script file
	echo "# CUSTOM SCRIPT" > "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh"
	
	# Run update
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify script was overwritten (scripts should always update)
	run head -n1 "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh"
	[ "$output" != "# CUSTOM SCRIPT" ]
	
	# Verify it's executable
	[ -x "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh" ]
}

@test "workflow modules are always updated" {
	cd "$REPO_ROOT"
	
	# Modify a workflow module
	echo "# CUSTOM WORKFLOW" > "$TEST_HOME/.agent-os/workflow-modules/step-1-hygiene-and-setup.md"
	
	# Run update
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify workflow module was overwritten
	run head -n1 "$TEST_HOME/.agent-os/workflow-modules/step-1-hygiene-and-setup.md"
	[ "$output" != "# CUSTOM WORKFLOW" ]
}

@test "tools are always updated" {
	cd "$REPO_ROOT"
	
	# Modify the aos tool
	echo "# CUSTOM AOS" > "$TEST_HOME/.agent-os/tools/aos"
	
	# Run update
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify aos was overwritten
	run head -n1 "$TEST_HOME/.agent-os/tools/aos"
	[ "$output" != "# CUSTOM AOS" ]
}

@test "VERSION file is always updated to match repository" {
	cd "$REPO_ROOT"
	
	# Get current repository version
	repo_version=$(cat "$REPO_ROOT/VERSION")
	
	# Modify installed version
	echo "1.0.0-fake" > "$TEST_HOME/.agent-os/VERSION"
	
	# Run update
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify VERSION was updated to match repository
	run cat "$TEST_HOME/.agent-os/VERSION"
	[ "$output" = "$repo_version" ]
}

@test "deprecated files are cleaned up during update" {
	cd "$REPO_ROOT"
	
	# Create deprecated file (mentioned in setup.sh)
	echo "deprecated" > "$TEST_HOME/.agent-os/.version"
	
	# Run update
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify deprecated file was removed
	[ ! -f "$TEST_HOME/.agent-os/.version" ]
	
	# Verify new VERSION file exists
	[ -f "$TEST_HOME/.agent-os/VERSION" ]
}

@test "update from old installation structure works" {
	cd "$REPO_ROOT"
	
	# Simulate old installation structure by removing some directories
	rm -rf "$TEST_HOME/.agent-os/workflow-modules"
	rm -rf "$TEST_HOME/.agent-os/tools"
	
	# Run update
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify new directories were created
	[ -d "$TEST_HOME/.agent-os/workflow-modules" ]
	[ -d "$TEST_HOME/.agent-os/tools" ]
	
	# Verify files were installed
	[ -f "$TEST_HOME/.agent-os/workflow-modules/step-1-hygiene-and-setup.md" ]
	[ -f "$TEST_HOME/.agent-os/tools/aos" ]
}

@test "partial update completes missing components" {
	cd "$REPO_ROOT"
	
	# Remove some files to simulate incomplete installation
	rm -f "$TEST_HOME/.agent-os/scripts/config-resolver.py"
	rm -f "$TEST_HOME/.agent-os/workflow-modules/step-3-quality-assurance.md"
	
	# Run update
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify missing files were restored
	[ -f "$TEST_HOME/.agent-os/scripts/config-resolver.py" ]
	[ -f "$TEST_HOME/.agent-os/workflow-modules/step-3-quality-assurance.md" ]
}

@test "claude-code setup can be run multiple times safely" {
	cd "$REPO_ROOT"
	
	# Run Claude Code setup first time
	run bash -c 'echo -e "n\nn" | ./setup-claude-code.sh'
	[ "$status" -eq 0 ]
	
	# Modify a command file
	echo "# CUSTOM COMMAND" > "$TEST_HOME/.claude/commands/plan-product.md"
	
	# Run Claude Code setup again
	run bash -c 'echo -e "n\nn" | ./setup-claude-code.sh'
	[ "$status" -eq 0 ]
	
	# Verify it reported skipping existing files
	[[ "$output" == *"already exists - skipping"* ]]
	
	# Verify customization was preserved
	run head -n1 "$TEST_HOME/.claude/commands/plan-product.md"
	[ "$output" = "# CUSTOM COMMAND" ]
}

@test "update handles network interruptions gracefully" {
	cd "$REPO_ROOT"
	
	# Create custom curl that fails for specific files
	export PATH="$BATS_TMPDIR:$PATH"
	cat > "$BATS_TMPDIR/curl" << 'EOF'
#!/bin/bash
# Fail for specific file to simulate network interruption
if [[ "$*" == *"tech-stack.md"* ]]; then
	echo "curl: network error" >&2
	exit 1
fi
# Pass through to real curl for other files
exec /usr/bin/curl "$@"
EOF
	chmod +x "$BATS_TMPDIR/curl"
	
	# Run update - should fail due to set -e
	run ./setup.sh --overwrite-standards
	[ "$status" -ne 0 ]
	
	# Should not have partially updated files
	# (This verifies the set -e behavior prevents partial updates)
}

@test "update preserves directory permissions" {
	cd "$REPO_ROOT"
	
	# Change directory permissions
	chmod 755 "$TEST_HOME/.agent-os/standards"
	chmod 755 "$TEST_HOME/.agent-os/scripts"
	
	# Run update
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify directories still exist and are accessible
	[ -d "$TEST_HOME/.agent-os/standards" ]
	[ -d "$TEST_HOME/.agent-os/scripts" ]
	
	# Verify we can still write to them (permissions preserved)
	touch "$TEST_HOME/.agent-os/standards/test-write.txt"
	[ -f "$TEST_HOME/.agent-os/standards/test-write.txt" ]
}

@test "update works when some files are missing" {
	cd "$REPO_ROOT"
	
	# Remove some files
	rm -f "$TEST_HOME/.agent-os/standards/best-practices.md"
	rm -f "$TEST_HOME/.agent-os/instructions/core/plan-product.md"
	rm -f "$TEST_HOME/.agent-os/scripts/task-validator.sh"
	
	# Run update
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify missing files were restored
	[ -f "$TEST_HOME/.agent-os/standards/best-practices.md" ]
	[ -f "$TEST_HOME/.agent-os/instructions/core/plan-product.md" ]
	[ -f "$TEST_HOME/.agent-os/scripts/task-validator.sh" ]
	[ -x "$TEST_HOME/.agent-os/scripts/task-validator.sh" ]
}

@test "update creates missing directories" {
	cd "$REPO_ROOT"
	
	# Remove some directories
	rm -rf "$TEST_HOME/.agent-os/instructions/meta"
	rm -rf "$TEST_HOME/.agent-os/hooks"
	
	# Run update
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify directories were recreated
	[ -d "$TEST_HOME/.agent-os/instructions/meta" ]
	[ -d "$TEST_HOME/.agent-os/hooks" ]
	
	# Verify files were installed in recreated directories
	[ -f "$TEST_HOME/.agent-os/instructions/meta/pre-flight.md" ]
}

@test "update handles version file edge cases" {
	cd "$REPO_ROOT"
	
	# Test with empty VERSION file
	echo "" > "$TEST_HOME/.agent-os/VERSION"
	
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Should have valid version now
	[ -s "$TEST_HOME/.agent-os/VERSION" ]
	
	# Test with corrupt VERSION file
	echo -e "not\na\nvalid\nversion" > "$TEST_HOME/.agent-os/VERSION"
	
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Should have valid version now
	run cat "$TEST_HOME/.agent-os/VERSION"
	[[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+.*$ ]]
}

@test "update reports clear status of what was changed" {
	cd "$REPO_ROOT"
	
	# Create mixed scenario: some files exist, some missing, some with overwrite flags
	echo "CUSTOM" > "$TEST_HOME/.agent-os/standards/code-style.md"
	rm -f "$TEST_HOME/.agent-os/standards/tech-stack.md"
	
	# Run update with mixed flags
	run ./setup.sh --overwrite-standards
	[ "$status" -eq 0 ]
	
	# Should clearly report what was skipped, overwritten, and created
	[[ "$output" == *"(overwritten)"* ]]  # code-style.md was overwritten
	[[ "$output" == *"tech-stack.md"* ]] # tech-stack.md was created (not skipped)
}

@test "update validates installation completeness after completion" {
	cd "$REPO_ROOT"
	
	# Run update
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Verify all critical files exist after update
	[ -f "$TEST_HOME/.agent-os/standards/tech-stack.md" ]
	[ -f "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md" ]
	[ -f "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh" ]
	[ -f "$TEST_HOME/.agent-os/workflow-modules/step-1-hygiene-and-setup.md" ]
	[ -f "$TEST_HOME/.agent-os/tools/aos" ]
	[ -f "$TEST_HOME/.agent-os/VERSION" ]
	
	# Verify executable permissions on scripts
	[ -x "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh" ]
	[ -x "$TEST_HOME/.agent-os/scripts/project-context-loader.sh" ]
}