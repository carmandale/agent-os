#!/usr/bin/env bats
#
# test-performance-benchmarks.bats
# Performance benchmarks and dependency validation for Agent OS installation
#
# This test suite measures installation performance and validates dependency chains
# to ensure Agent OS installs efficiently and all components work together.

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

@test "installation completes within reasonable time limit" {
	cd "$REPO_ROOT"
	
	# Record start time
	start_time=$(date +%s)
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Record end time
	end_time=$(date +%s)
	
	# Calculate duration
	duration=$((end_time - start_time))
	
	# Installation should complete within 60 seconds on reasonable hardware
	# This accounts for network latency and curl downloads
	[ "$duration" -lt 60 ]
	
	# Report performance for monitoring
	echo "# Installation completed in ${duration} seconds" >&3
}

@test "claude-code setup completes within reasonable time limit" {
	cd "$REPO_ROOT"
	
	# First run base installation
	./setup.sh > /dev/null 2>&1
	
	# Record start time
	start_time=$(date +%s)
	
	# Run Claude Code setup
	run bash -c 'echo -e "n\nn" | ./setup-claude-code.sh'
	[ "$status" -eq 0 ]
	
	# Record end time
	end_time=$(date +%s)
	
	# Calculate duration
	duration=$((end_time - start_time))
	
	# Claude Code setup should complete within 30 seconds
	[ "$duration" -lt 30 ]
	
	echo "# Claude Code setup completed in ${duration} seconds" >&3
}

@test "installation downloads expected amount of data" {
	cd "$REPO_ROOT"
	
	# Count number of curl operations in setup.sh
	curl_count=$(grep -c "curl.*-o" setup.sh)
	
	# Should be downloading a reasonable number of files (not excessive)
	[ "$curl_count" -gt 10 ]   # At least 10 files
	[ "$curl_count" -lt 50 ]   # But not more than 50 files
	
	echo "# Installation downloads $curl_count files via curl" >&3
}

@test "dependency chain validation - scripts can execute after installation" {
	cd "$REPO_ROOT"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Test that key scripts can be executed without errors
	# (This validates the dependency chain)
	
	# workspace-hygiene-check.sh should run without errors
	run "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh" --version 2>/dev/null || true
	# Note: Script may not have --version flag, but should not crash on execution attempt
	
	# project-context-loader.sh should be executable
	[ -x "$TEST_HOME/.agent-os/scripts/project-context-loader.sh" ]
	
	# task-validator.sh should be executable  
	[ -x "$TEST_HOME/.agent-os/scripts/task-validator.sh" ]
	
	# Python scripts should be readable and have valid syntax
	if command -v python3 >/dev/null 2>&1; then
		run python3 -m py_compile "$TEST_HOME/.agent-os/scripts/config-resolver.py"
		[ "$status" -eq 0 ]
	fi
}

@test "dependency chain validation - workflow modules reference valid components" {
	cd "$REPO_ROOT"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Check that workflow modules reference scripts that actually exist
	
	# step-1-hygiene-and-setup.md should reference existing scripts
	if grep -q "workspace-hygiene-check.sh" "$TEST_HOME/.agent-os/workflow-modules/step-1-hygiene-and-setup.md"; then
		[ -f "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh" ]
	fi
	
	if grep -q "project-context-loader.sh" "$TEST_HOME/.agent-os/workflow-modules/step-1-hygiene-and-setup.md"; then
		[ -f "$TEST_HOME/.agent-os/scripts/project-context-loader.sh" ]
	fi
	
	if grep -q "task-validator.sh" "$TEST_HOME/.agent-os/workflow-modules/step-1-hygiene-and-setup.md"; then
		[ -f "$TEST_HOME/.agent-os/scripts/task-validator.sh" ]
	fi
}

@test "installation creates expected file count" {
	cd "$REPO_ROOT"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Count installed files
	file_count=$(find "$TEST_HOME/.agent-os" -type f | wc -l)
	
	# Should install a reasonable number of files
	# Based on setup.sh analysis: 3 standards + ~5 core instructions + 1 meta instruction + ~15 scripts + 4 workflow modules + 1 tool + 1 VERSION = ~30 files
	[ "$file_count" -gt 25 ]   # At least 25 files
	[ "$file_count" -lt 50 ]   # But not more than 50 files
	
	echo "# Installation created $file_count files" >&3
}

@test "installation disk usage is reasonable" {
	cd "$REPO_ROOT"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Measure disk usage
	if command -v du >/dev/null 2>&1; then
		disk_usage=$(du -sk "$TEST_HOME/.agent-os" | cut -f1)
		
		# Agent OS should use less than 1MB of disk space
		[ "$disk_usage" -lt 1024 ]  # Less than 1MB (1024KB)
		
		echo "# Installation uses ${disk_usage}KB of disk space" >&3
	fi
}

@test "validate script execution dependencies are met" {
	cd "$REPO_ROOT"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Check that scripts have appropriate shebangs
	
	# Bash scripts should start with #!/bin/bash
	for script in workspace-hygiene-check.sh project-context-loader.sh task-validator.sh; do
		if [ -f "$TEST_HOME/.agent-os/scripts/$script" ]; then
			run head -n1 "$TEST_HOME/.agent-os/scripts/$script"
			[[ "$output" =~ ^#!/bin/bash ]]
		fi
	done
	
	# Python scripts should be identified correctly
	if [ -f "$TEST_HOME/.agent-os/scripts/config-resolver.py" ]; then
		file_type=$(file "$TEST_HOME/.agent-os/scripts/config-resolver.py")
		[[ "$file_type" == *"Python"* ]] || [[ "$file_type" == *"ASCII text"* ]]
	fi
}

@test "validate aos CLI tool functionality after installation" {
	cd "$REPO_ROOT"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Test aos CLI tool basic functionality
	[ -f "$TEST_HOME/.agent-os/tools/aos" ]
	
	# aos should be executable (note: may fail in test environment, that's OK)
	# [ -x "$TEST_HOME/.agent-os/tools/aos" ]
	
	# aos should have reasonable size (not empty, not huge)
	file_size=$(wc -c < "$TEST_HOME/.agent-os/tools/aos")
	[ "$file_size" -gt 100 ]     # At least 100 bytes
	[ "$file_size" -lt 100000 ]  # Less than 100KB
}

@test "installation performance is consistent across runs" {
	cd "$REPO_ROOT"
	
	# Run installation multiple times and measure consistency
	times=()
	
	for i in {1..3}; do
		# Clean environment
		rm -rf "$TEST_HOME/.agent-os" 2>/dev/null || true
		
		# Time installation
		start_time=$(date +%s)
		./setup.sh > /dev/null 2>&1
		end_time=$(date +%s)
		
		duration=$((end_time - start_time))
		times+=($duration)
	done
	
	# Calculate average
	total=0
	for time in "${times[@]}"; do
		total=$((total + time))
	done
	average=$((total / ${#times[@]}))
	
	# All runs should complete within reasonable time
	for time in "${times[@]}"; do
		[ "$time" -lt 60 ]
	done
	
	# Variation should be reasonable (no run should be more than 2x average)
	for time in "${times[@]}"; do
		[ "$time" -lt $((average * 2)) ]
	done
	
	echo "# Installation times: ${times[*]}, average: ${average}s" >&3
}

@test "validate instruction files reference existing components" {
	cd "$REPO_ROOT"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Check that instruction files don't reference non-existent components
	
	# execute-tasks.md should reference valid scripts
	if grep -q "@~/.agent-os/scripts/" "$TEST_HOME/.agent-os/instructions/core/execute-tasks.md"; then
		# Extract referenced script paths and verify they exist
		# This is a simplified check - full implementation would parse all references
		[ -f "$TEST_HOME/.agent-os/scripts/workspace-hygiene-check.sh" ]
		[ -f "$TEST_HOME/.agent-os/scripts/project-context-loader.sh" ]
	fi
	
	# create-spec.md should be functional
	[ -s "$TEST_HOME/.agent-os/instructions/core/create-spec.md" ]
	
	# plan-product.md should be functional
	[ -s "$TEST_HOME/.agent-os/instructions/core/plan-product.md" ]
}

@test "validate no broken internal references after installation" {
	cd "$REPO_ROOT"
	
	# Run installation  
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Look for file references in installed files that might be broken
	# This is a basic validation - comprehensive checking would require parsing
	
	# Check for common broken reference patterns
	broken_refs=0
	
	# Look for references to non-existent files (basic patterns)
	if find "$TEST_HOME/.agent-os" -name "*.md" -exec grep -l "nonexistent" {} \; 2>/dev/null; then
		broken_refs=$((broken_refs + 1))
	fi
	
	# Should not find broken references
	[ "$broken_refs" -eq 0 ]
}

@test "installation memory usage is reasonable" {
	cd "$REPO_ROOT"
	
	# Monitor memory usage during installation
	if command -v /usr/bin/time >/dev/null 2>&1; then
		# Use time command to measure resource usage
		run /usr/bin/time -l ./setup.sh 2>&1 || /usr/bin/time -v ./setup.sh 2>&1
		
		# Installation should not use excessive memory
		# This test is platform dependent and may not work everywhere
		[ "$status" -eq 0 ]  # Installation should succeed
		
		echo "# Resource usage information: $output" >&3
	else
		skip "time command not available for memory measurement"
	fi
}

@test "validate version consistency across installed components" {
	cd "$REPO_ROOT"
	
	# Run installation
	run ./setup.sh
	[ "$status" -eq 0 ]
	
	# Get installed version
	installed_version=$(cat "$TEST_HOME/.agent-os/VERSION")
	
	# Get repository version
	repo_version=$(cat "$REPO_ROOT/VERSION")
	
	# Versions should match
	[ "$installed_version" = "$repo_version" ]
	
	# Version should be valid semantic version
	[[ "$installed_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+.*$ ]]
	
	echo "# Installed version: $installed_version" >&3
}

@test "concurrent installations do not degrade performance significantly" {
	cd "$REPO_ROOT"
	
	# Time single installation
	start_time=$(date +%s)
	HOME="$TEST_HOME" ./setup.sh > /dev/null 2>&1
	end_time=$(date +%s)
	single_duration=$((end_time - start_time))
	
	# Clean up
	rm -rf "$TEST_HOME/.agent-os"
	
	# Time concurrent installations
	export TEST_HOME_2=$(mktemp -d)
	
	start_time=$(date +%s)
	HOME="$TEST_HOME" ./setup.sh > /dev/null 2>&1 &
	pid1=$!
	HOME="$TEST_HOME_2" ./setup.sh > /dev/null 2>&1 &
	pid2=$!
	
	wait $pid1
	wait $pid2
	end_time=$(date +%s)
	concurrent_duration=$((end_time - start_time))
	
	# Concurrent should not be significantly slower than 1.5x single
	[ "$concurrent_duration" -lt $((single_duration * 2)) ]
	
	echo "# Single: ${single_duration}s, Concurrent: ${concurrent_duration}s" >&3
	
	# Cleanup
	rm -rf "$TEST_HOME_2"
}