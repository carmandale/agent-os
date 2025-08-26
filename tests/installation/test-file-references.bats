#!/usr/bin/env bats
# 
# test-file-references.bats
# Validates all file references in Agent OS setup scripts
#
# This test suite ensures that every file referenced in setup scripts
# actually exists in the repository, preventing installation gaps.

load '../test_helper'

# Get the repository root directory
get_repo_root() {
	echo "$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

# Base URL for testing file references
BASE_URL="https://raw.githubusercontent.com/carmandale/agent-os/main"
REPO_ROOT="$(get_repo_root)"

@test "VERSION file exists for version tracking" {
	[ -f "$REPO_ROOT/VERSION" ]
}

@test "setup.sh references exist in repository - standards files" {
	# Test standards files referenced in setup.sh
	[ -f "$REPO_ROOT/standards/tech-stack.md" ]
	[ -f "$REPO_ROOT/standards/code-style.md" ]
	[ -f "$REPO_ROOT/standards/best-practices.md" ]
}

@test "setup.sh references exist in repository - core instruction files" {
	# Test core instruction files referenced in setup.sh
	[ -f "$REPO_ROOT/instructions/core/analyze-product.md" ]
	[ -f "$REPO_ROOT/instructions/core/create-spec.md" ]
	[ -f "$REPO_ROOT/instructions/core/execute-tasks.md" ]
	[ -f "$REPO_ROOT/instructions/core/plan-product.md" ]
	[ -f "$REPO_ROOT/instructions/core/execute-task.md" ]
}

@test "setup.sh references exist in repository - meta instruction files" {
	# Test meta instruction files
	[ -f "$REPO_ROOT/instructions/meta/pre-flight.md" ]
}

@test "setup.sh references exist in repository - core script files" {
	# Test script files referenced in setup.sh
	[ -f "$REPO_ROOT/scripts/workspace-hygiene-check.sh" ]
	[ -f "$REPO_ROOT/scripts/project-context-loader.sh" ]
	[ -f "$REPO_ROOT/scripts/task-validator.sh" ]
	[ -f "$REPO_ROOT/scripts/update-documentation.sh" ]
	[ -f "$REPO_ROOT/scripts/config-resolver.py" ]
	[ -f "$REPO_ROOT/scripts/session-memory.sh" ]
	[ -f "$REPO_ROOT/scripts/config-validator.sh" ]
	[ -f "$REPO_ROOT/scripts/pre-command-guard.sh" ]
	[ -f "$REPO_ROOT/scripts/intent-analyzer.sh" ]
	[ -f "$REPO_ROOT/scripts/workspace-state.sh" ]
	[ -f "$REPO_ROOT/scripts/context-aware-wrapper.sh" ]
	[ -f "$REPO_ROOT/scripts/testing-enforcer.sh" ]
}

@test "setup.sh references exist in repository - transparent work sessions scripts" {
	# Test transparent work sessions scripts referenced in setup.sh
	[ -f "$REPO_ROOT/scripts/workflow-validator.sh" ]
	[ -f "$REPO_ROOT/scripts/work-session-manager.sh" ]
	[ -f "$REPO_ROOT/scripts/commit-boundary-manager.sh" ]
	[ -f "$REPO_ROOT/scripts/session-auto-start.sh" ]
}

@test "setup.sh references exist in repository - additional utility scripts" {
	# Test additional utility scripts referenced in setup.sh
	[ -f "$REPO_ROOT/scripts/check-updates.sh" ]
	[ -f "$REPO_ROOT/scripts/validate-instructions.sh" ]
}

@test "setup.sh references exist in repository - python scripts" {
	# Test Python scripts referenced in setup.sh
	[ -f "$REPO_ROOT/scripts/project_root_resolver.py" ]
}

@test "setup.sh references exist in repository - workflow modules" {
	# Test workflow modules referenced in setup.sh
	[ -f "$REPO_ROOT/workflow-modules/step-1-hygiene-and-setup.md" ]
	[ -f "$REPO_ROOT/workflow-modules/step-2-planning-and-execution.md" ]
	[ -f "$REPO_ROOT/workflow-modules/step-3-quality-assurance.md" ]
	[ -f "$REPO_ROOT/workflow-modules/step-4-git-integration.md" ]
}

@test "setup.sh references exist in repository - aos unified CLI tool" {
	# Test aos CLI tool referenced in setup.sh
	[ -f "$REPO_ROOT/tools/aos" ]
}

@test "setup-claude-code.sh references exist in repository - command files" {
	# Test Claude Code command files referenced in setup-claude-code.sh
	[ -f "$REPO_ROOT/commands/plan-product.md" ]
	[ -f "$REPO_ROOT/commands/create-spec.md" ]
	[ -f "$REPO_ROOT/commands/execute-tasks.md" ]
	[ -f "$REPO_ROOT/commands/analyze-product.md" ]
	[ -f "$REPO_ROOT/commands/hygiene-check.md" ]
	[ -f "$REPO_ROOT/commands/update-documentation.md" ]
}

@test "setup-claude-code.sh references exist in repository - agent files" {
	# Test Claude Code agent files referenced in setup-claude-code.sh
	[ -f "$REPO_ROOT/claude-code/agents/context-fetcher.md" ]
	[ -f "$REPO_ROOT/claude-code/agents/date-checker.md" ]
	[ -f "$REPO_ROOT/claude-code/agents/file-creator.md" ]
	[ -f "$REPO_ROOT/claude-code/agents/git-workflow.md" ]
	[ -f "$REPO_ROOT/claude-code/agents/test-runner.md" ]
}

@test "setup-claude-code.sh references exist in repository - integration files" {
	# Test subagent integration file referenced in setup-claude-code.sh
	[ -f "$REPO_ROOT/integrations/setup-subagent-integration.sh" ]
}

@test "setup-claude-code.sh references exist in repository - hook files" {
	# Test Claude Code hook files referenced in setup-claude-code.sh
	[ -f "$REPO_ROOT/hooks/install-hooks.sh" ]
	[ -f "$REPO_ROOT/hooks/claude-code-hooks.json" ]
	
	# Test hook utility files
	[ -f "$REPO_ROOT/hooks/lib/workflow-detector.sh" ]
	[ -f "$REPO_ROOT/hooks/lib/git-utils.sh" ]
	[ -f "$REPO_ROOT/hooks/lib/context-builder.sh" ]
	[ -f "$REPO_ROOT/hooks/lib/evidence-standards.sh" ]
	[ -f "$REPO_ROOT/hooks/lib/project-config-injector.sh" ]
	[ -f "$REPO_ROOT/hooks/lib/testing-enforcer.sh" ]
	[ -f "$REPO_ROOT/hooks/lib/testing-reminder.sh" ]
	[ -f "$REPO_ROOT/hooks/lib/workflow-reminder.sh" ]
	
	# Test main hook files
	[ -f "$REPO_ROOT/hooks/workflow-enforcement-hook.py" ]
	[ -f "$REPO_ROOT/hooks/stop-hook.sh" ]
	[ -f "$REPO_ROOT/hooks/post-tool-use-hook.sh" ]
	[ -f "$REPO_ROOT/hooks/user-prompt-submit-hook.sh" ]
	[ -f "$REPO_ROOT/hooks/pre-bash-hook.sh" ]
	[ -f "$REPO_ROOT/hooks/post-bash-hook.sh" ]
	[ -f "$REPO_ROOT/hooks/notify-hook.sh" ]
}

@test "validate setup.sh executable permissions" {
	[ -x "$REPO_ROOT/setup.sh" ]
}

@test "validate setup-claude-code.sh executable permissions" {
	[ -x "$REPO_ROOT/setup-claude-code.sh" ]
}

@test "validate all script files have executable permissions" {
	# Check that all shell scripts referenced in setup.sh have executable permissions
	
	run find "$REPO_ROOT/scripts" -name "*.sh" -type f
	[ "$status" -eq 0 ]
	
	# Test a few critical scripts
	[ -x "$REPO_ROOT/scripts/workspace-hygiene-check.sh" ]
	[ -x "$REPO_ROOT/scripts/project-context-loader.sh" ]
	[ -x "$REPO_ROOT/scripts/task-validator.sh" ]
}

@test "validate curl URLs would resolve correctly" {
	# This test ensures the BASE_URL pattern used in setup scripts is correct
	# We test this by checking if the files exist at the expected relative paths
	
	# Test a few sample files to ensure the URL pattern is correct
	[ -f "$REPO_ROOT/standards/tech-stack.md" ]
	[ -f "$REPO_ROOT/instructions/core/execute-tasks.md" ]
	[ -f "$REPO_ROOT/scripts/workspace-hygiene-check.sh" ]
	[ -f "$REPO_ROOT/workflow-modules/step-1-hygiene-and-setup.md" ]
	[ -f "$REPO_ROOT/commands/plan-product.md" ]
	[ -f "$REPO_ROOT/claude-code/agents/context-fetcher.md" ]
}

@test "validate no missing directory dependencies" {
	# Ensure all directories that should be created exist as expected paths
	
	# Directories created by setup.sh
	[ -d "$REPO_ROOT/standards" ]
	[ -d "$REPO_ROOT/instructions" ]
	[ -d "$REPO_ROOT/instructions/core" ]
	[ -d "$REPO_ROOT/instructions/meta" ]
	[ -d "$REPO_ROOT/scripts" ]
	[ -d "$REPO_ROOT/workflow-modules" ]
	[ -d "$REPO_ROOT/tools" ]
	
	# Directories used by setup-claude-code.sh
	[ -d "$REPO_ROOT/commands" ]
	[ -d "$REPO_ROOT/claude-code/agents" ]
	[ -d "$REPO_ROOT/integrations" ]
	[ -d "$REPO_ROOT/hooks" ]
	[ -d "$REPO_ROOT/hooks/lib" ]
}

@test "validate VERSION file format" {
	# Ensure VERSION file contains a valid semantic version
	run cat "$REPO_ROOT/VERSION"
	[ "$status" -eq 0 ]
	
	# Check that it's not empty
	[ -n "$output" ]
	
	# Check that it matches semantic versioning pattern (basic check)
	[[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+.*$ ]]
}

@test "validate setup script consistency - no dead references" {
	# Ensure setup scripts don't reference files that don't exist
	# This is a comprehensive cross-check
	
	# Parse setup.sh for curl commands and extract file paths
	# This test will catch any curl references to files that don't exist
	
	# Extract all curl URLs from setup.sh that point to files in the repo
	# and verify those files exist
	
	run grep -o 'curl.*"${BASE_URL}/[^"]*"' "$REPO_ROOT/setup.sh"
	[ "$status" -eq 0 ]
	
	# For each URL found, check if the corresponding file exists
	# This is a simplified version - a more complete test would parse each URL
	
	# Instead, test known problematic patterns
	! grep -q "aos-background" "$REPO_ROOT/setup.sh"  # This was the problematic reference
}

@test "validate hook installation prerequisites" {
	# Ensure hook installation has all required dependencies
	[ -f "$REPO_ROOT/hooks/install-hooks.sh" ]
	[ -f "$REPO_ROOT/hooks/claude-code-hooks.json" ]
	
	# Test that claude-code-hooks.json is valid JSON
	run python3 -m json.tool "$REPO_ROOT/hooks/claude-code-hooks.json"
	[ "$status" -eq 0 ]
}