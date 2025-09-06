#!/usr/bin/env bash
# Helper functions for verify-installation tests
# Provides utilities for mock setup, validation, and common test patterns

# Create complete mock Agent OS installation
create_mock_installation() {
	local mock_home="$1"
	local mock_agent_os="${mock_home}/.agent-os"
	local mock_claude="${mock_home}/.claude"
	
	# Create directory structure
	mkdir -p "${mock_agent_os}/"{hooks,instructions,standards,scripts,tools,cache,logs}
	mkdir -p "${mock_claude}/"{commands,agents}
	
	# Create core instruction files
	cat > "${mock_agent_os}/instructions/plan-product.md" <<-'EOF'
		# Plan Product Instruction
		This is a mock instruction file for testing.
	EOF
	
	cat > "${mock_agent_os}/instructions/create-spec.md" <<-'EOF'
		# Create Spec Instruction  
		This is a mock instruction file for testing.
	EOF
	
	cat > "${mock_agent_os}/instructions/execute-tasks.md" <<-'EOF'
		# Execute Tasks Instruction
		This is a mock instruction file for testing.
	EOF
	
	# Create standards files
	cat > "${mock_agent_os}/standards/tech-stack.md" <<-'EOF'
		# Tech Stack Standards
		Mock tech stack standards for testing.
	EOF
	
	cat > "${mock_agent_os}/standards/code-style.md" <<-'EOF'
		# Code Style Standards
		Mock code style standards for testing.
	EOF
	
	# Create hook files
	cat > "${mock_agent_os}/hooks/post-hook.sh" <<-'EOF'
		#!/bin/bash
		# Mock post hook for testing
		echo "Post hook executed"
	EOF
	chmod +x "${mock_agent_os}/hooks/post-hook.sh"
	
	cat > "${mock_agent_os}/hooks/pre-hook.sh" <<-'EOF'
		#!/bin/bash
		# Mock pre hook for testing
		echo "Pre hook executed"
	EOF
	chmod +x "${mock_agent_os}/hooks/pre-hook.sh"
	
	# Create Claude Code configuration
	cat > "${mock_claude}/settings.json" <<-'EOF'
		{
			"hooks": {
				"postToolUse": ["~/.agent-os/hooks/post-hook.sh"],
				"userPromptSubmit": ["~/.agent-os/hooks/pre-hook.sh"]
			}
		}
	EOF
	
	# Create Claude commands
	cat > "${mock_claude}/commands/plan-product.md" <<-'EOF'
		# Plan Product Command
		Mock command file for testing.
	EOF
	
	# Create Claude agents
	cat > "${mock_claude}/agents/context-fetcher.md" <<-'EOF'
		---
		name: context-fetcher
		description: Mock agent for testing
		---
		Mock agent content.
	EOF
	
	# Create aos command
	cat > "${mock_agent_os}/tools/aos" <<-'EOF'
		#!/bin/bash
		# Mock aos command for testing
		case "$1" in
			"status")
				echo "Agent OS Status: OK"
				echo "Version: 4.0.0"
				;;
			"update")
				echo "Agent OS is up to date"
				;;
			*)
				echo "aos version 4.0.0"
				;;
		esac
	EOF
	chmod +x "${mock_agent_os}/tools/aos"
	
	# Create version file
	echo "4.0.0" > "${mock_agent_os}/VERSION"
}

# Create broken installation for testing failure scenarios
create_broken_installation() {
	local mock_home="$1"
	local break_type="$2"
	
	# First create a complete installation
	create_mock_installation "$mock_home"
	
	local mock_agent_os="${mock_home}/.agent-os"
	local mock_claude="${mock_home}/.claude"
	
	case "$break_type" in
		"missing_directory")
			rm -rf "${mock_agent_os}/hooks"
			;;
		"missing_file")
			rm "${mock_agent_os}/instructions/plan-product.md"
			;;
		"invalid_json")
			echo "invalid json {" > "${mock_claude}/settings.json"
			;;
		"missing_hook_file")
			rm "${mock_agent_os}/hooks/post-hook.sh"
			;;
		"non_executable_hook")
			chmod -x "${mock_agent_os}/hooks/pre-hook.sh"
			;;
		"missing_aos")
			rm "${mock_agent_os}/tools/aos"
			;;
		"wrong_permissions")
			chmod 444 "${mock_agent_os}"
			;;
	esac
}

# Validate that a mock installation is complete
validate_mock_installation() {
	local mock_home="$1"
	local mock_agent_os="${mock_home}/.agent-os"
	local mock_claude="${mock_home}/.claude"
	
	# Check directories exist
	[[ -d "${mock_agent_os}" ]] || return 1
	[[ -d "${mock_claude}" ]] || return 1
	
	# Check critical files exist
	[[ -f "${mock_agent_os}/instructions/plan-product.md" ]] || return 1
	[[ -f "${mock_claude}/settings.json" ]] || return 1
	[[ -x "${mock_agent_os}/tools/aos" ]] || return 1
	
	return 0
}

# Create minimal installation for quick tests
create_minimal_installation() {
	local mock_home="$1"
	local mock_agent_os="${mock_home}/.agent-os"
	local mock_claude="${mock_home}/.claude"
	
	mkdir -p "${mock_agent_os}" "${mock_claude}"
	echo '{}' > "${mock_claude}/settings.json"
	echo "4.0.0" > "${mock_agent_os}/VERSION"
}

# Test helper to check if command exists in PATH
command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# Test helper to validate JSON content
is_valid_json() {
	local file="$1"
	python3 -c "import json; json.load(open('$file'))" 2>/dev/null
}

# Test helper to count files in directory
count_files() {
	local dir="$1"
	local pattern="$2"
	
	if [[ -d "$dir" ]]; then
		find "$dir" -name "$pattern" -type f | wc -l
	else
		echo 0
	fi
}

# Test helper to check file permissions
check_executable() {
	local file="$1"
	[[ -x "$file" ]]
}