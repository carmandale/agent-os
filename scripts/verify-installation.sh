#!/usr/bin/env bash
# Agent OS Installation Verification Script
# Validates installation integrity, component functionality, and configuration correctness
#
# Usage:
#   ./scripts/verify-installation.sh [OPTIONS]
#
# Options:
#   --quick         Quick verification mode (< 5 seconds)
#   --full          Full comprehensive verification (< 30 seconds) [default]
#   --hooks-only    Validate only Claude Code hooks
#   --verbose       Show detailed output
#   --help          Show this help message
#
# Exit codes:
#   0 - Success (all checks passed)
#   1 - Critical failures (installation broken)  
#   2 - Warnings (installation works but has issues)
#   3 - Script error (invalid arguments or internal error)
#
# Author: Agent OS Team
# Issue: #92

set -euo pipefail

# Script configuration
readonly SCRIPT_VERSION="1.0.0"
readonly AGENT_OS_DIR="${HOME}/.agent-os"
readonly CLAUDE_DIR="${HOME}/.claude"

# Color codes for output formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Global variables
VERBOSE=false
MODE="full"
EXIT_CODE=0

# Utility functions
log_info() {
	echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
	echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $*"
	if [[ $EXIT_CODE -eq 0 ]]; then
		EXIT_CODE=2
	fi
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $*"
	EXIT_CODE=1
}

log_verbose() {
	if [[ "$VERBOSE" == true ]]; then
		echo -e "${BLUE}[VERBOSE]${NC} $*"
	fi
}

show_help() {
	cat <<-EOF
		${BOLD}Agent OS Installation Verification Script${NC}
		
		Validates Agent OS installation integrity, component functionality, and configuration correctness.
		
		${BOLD}Usage:${NC}
		  ./scripts/verify-installation.sh [OPTIONS]
		
		${BOLD}Options:${NC}
		  --quick         Quick verification mode (< 5 seconds)
		  --full          Full comprehensive verification (< 30 seconds) [default]
		  --hooks-only    Validate only Claude Code hooks
		  --verbose       Show detailed output
		  --help          Show this help message
		
		${BOLD}Exit codes:${NC}
		  0 - Success (all checks passed)
		  1 - Critical failures (installation broken)
		  2 - Warnings (installation works but has issues)
		  3 - Script error (invalid arguments or internal error)
		
		${BOLD}Examples:${NC}
		  ./scripts/verify-installation.sh --quick
		  ./scripts/verify-installation.sh --full --verbose
		  ./scripts/verify-installation.sh --hooks-only
	EOF
}

# Core verification functions
validate_directory_structure() {
	log_verbose "Validating Agent OS directory structure..."
	
	# Check main .agent-os directory
	if [[ ! -d "$AGENT_OS_DIR" ]]; then
		log_error "Agent OS directory not found: $AGENT_OS_DIR"
		log_error "Run 'curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash' to install"
		return 1
	fi
	
	# Check directory permissions
	if [[ ! -r "$AGENT_OS_DIR" || ! -w "$AGENT_OS_DIR" ]]; then
		log_error "Agent OS directory has incorrect permissions: $AGENT_OS_DIR"
		log_error "Run 'chmod 755 $AGENT_OS_DIR' to fix"
		return 1
	fi
	
	# Check required subdirectories
	local required_dirs=(
		"hooks"
		"instructions" 
		"standards"
		"scripts"
		"tools"
	)
	
	for dir in "${required_dirs[@]}"; do
		local full_path="${AGENT_OS_DIR}/${dir}"
		if [[ ! -d "$full_path" ]]; then
			log_error "Required directory missing: $full_path"
			return 1
		fi
		log_verbose "✓ Directory exists: $dir"
	done
	
	log_success "Directory structure validation passed"
	return 0
}

validate_file_integrity() {
	log_verbose "Validating file integrity..."
	
	# Check core instruction files
	local required_instructions=(
		"plan-product.md"
		"create-spec.md"  
		"execute-tasks.md"
	)
	
	for file in "${required_instructions[@]}"; do
		local full_path="${AGENT_OS_DIR}/instructions/core/${file}"
		if [[ ! -f "$full_path" ]]; then
			log_error "Required instruction file missing: $file"
			return 1
		fi
		
		# Check file is not empty and not a 404 error
		if [[ ! -s "$full_path" ]] || grep -q "404.*Not Found" "$full_path" 2>/dev/null; then
			log_error "Instruction file is empty or corrupted: $file"
			log_error "Run setup script to reinstall"
			return 1
		fi
		log_verbose "✓ Instruction file valid: $file"
	done
	
	# Check standards files
	local required_standards=(
		"tech-stack.md"
		"code-style.md"
		"best-practices.md"
	)
	
	for file in "${required_standards[@]}"; do
		local full_path="${AGENT_OS_DIR}/standards/${file}"
		if [[ ! -f "$full_path" ]]; then
			log_warning "Standard file missing (optional): $file"
		else
			log_verbose "✓ Standard file exists: $file"
		fi
	done
	
	# Check executable permissions on hooks
	if [[ -d "${AGENT_OS_DIR}/hooks" ]]; then
		local hook_files
		hook_files=$(find "${AGENT_OS_DIR}/hooks" -name "*.sh" -type f 2>/dev/null || true)
		for hook_file in $hook_files; do
			if [[ ! -x "$hook_file" ]]; then
				log_error "Hook file not executable: $(basename "$hook_file")"
				log_error "Run 'chmod +x $hook_file' to fix"
				return 1
			fi
			log_verbose "✓ Hook file executable: $(basename "$hook_file")"
		done
	fi
	
	log_success "File integrity validation passed"
	return 0
}

validate_claude_hooks() {
	log_verbose "Validating Claude Code hooks configuration..."
	
	# Check Claude settings file exists
	local settings_file="${CLAUDE_DIR}/settings.json"
	if [[ ! -f "$settings_file" ]]; then
		log_warning "Claude Code settings file not found: $settings_file"
		log_warning "Claude Code hooks may not be configured"
		return 0
	fi
	
	# Validate JSON syntax
	if ! python3 -c "import json; json.load(open('$settings_file'))" 2>/dev/null; then
		log_error "Claude Code settings file has invalid JSON syntax: $settings_file"
		return 1
	fi
	log_verbose "✓ Claude settings JSON is valid"
	
	# Check hook references point to existing files
	local hook_refs
	hook_refs=$(python3 -c "
import json
try:
    with open('$settings_file') as f:
        data = json.load(f)
    hooks = data.get('hooks', {})
    for hook_type, hook_list in hooks.items():
        if isinstance(hook_list, list):
            for hook in hook_list:
                if hook.startswith('~/'):
                    print(hook.replace('~', '$HOME'))
                else:
                    print(hook)
except Exception:
    pass
" 2>/dev/null || true)
	
	for hook_ref in $hook_refs; do
		if [[ -n "$hook_ref" && ! -f "$hook_ref" ]]; then
			log_error "Claude hook references missing file: $hook_ref"
			return 1
		elif [[ -n "$hook_ref" && ! -x "$hook_ref" ]]; then
			log_error "Claude hook references non-executable file: $hook_ref"
			return 1
		elif [[ -n "$hook_ref" ]]; then
			log_verbose "✓ Hook file exists and executable: $(basename "$hook_ref")"
		fi
	done
	
	log_success "Claude Code hooks validation passed"
	return 0
}

validate_cli_commands() {
	log_verbose "Validating CLI commands..."
	
	# Check aos command availability
	if ! command -v aos >/dev/null 2>&1; then
		local aos_path="${AGENT_OS_DIR}/tools/aos"
		if [[ ! -x "$aos_path" ]]; then
			log_error "aos command not found in PATH or at $aos_path"
			log_error "Add ~/.agent-os/tools to PATH or run setup script"
			return 1
		fi
		log_verbose "✓ aos command found at: $aos_path"
	else
		log_verbose "✓ aos command available in PATH"
	fi
	
	# Test aos basic functionality
	local aos_output
	if aos_output=$(aos status 2>/dev/null); then
		log_verbose "✓ aos status command works"
		if [[ "$VERBOSE" == true ]]; then
			echo "$aos_output" | head -3
		fi
	else
		log_warning "aos status command failed (may not be critical)"
	fi
	
	log_success "CLI commands validation passed"
	return 0
}

validate_git_integration() {
	log_verbose "Validating Git integration..."
	
	# Check git availability
	if ! command -v git >/dev/null 2>&1; then
		log_warning "git command not found - some Agent OS features may not work"
		log_warning "Install git for full functionality"
		return 0
	fi
	log_verbose "✓ git command available"
	
	# Check GitHub CLI (optional)
	if command -v gh >/dev/null 2>&1; then
		log_verbose "✓ GitHub CLI available"
		
		# Check if authenticated (don't fail if not)
		if gh auth status >/dev/null 2>&1; then
			log_verbose "✓ GitHub CLI authenticated"
		else
			log_verbose "? GitHub CLI not authenticated (run 'gh auth login')"
		fi
	else
		log_verbose "? GitHub CLI not found (install for full GitHub integration)"
	fi
	
	log_success "Git integration validation passed" 
	return 0
}

# Main execution functions
run_quick_verification() {
	log_info "Running quick verification..."
	
	# Only check critical components for speed
	validate_directory_structure || return 1
	
	# Basic file check (just core files)
	if [[ ! -f "${AGENT_OS_DIR}/instructions/plan-product.md" ]]; then
		log_error "Core instruction file missing"
		return 1
	fi
	
	# Basic Claude check
	if [[ -f "${CLAUDE_DIR}/settings.json" ]]; then
		if ! python3 -c "import json; json.load(open('${CLAUDE_DIR}/settings.json'))" 2>/dev/null; then
			log_error "Claude settings file corrupted"
			return 1
		fi
	fi
	
	log_success "Quick verification completed successfully"
	return 0
}

run_full_verification() {
	log_info "Running full verification..."
	
	validate_directory_structure || return 1
	validate_file_integrity || return 1
	validate_claude_hooks || return 1
	validate_cli_commands || return 1
	validate_git_integration || return 1
	
	log_success "Full verification completed successfully"
	return 0
}

run_hooks_only_verification() {
	log_info "Running Claude Code hooks verification..."
	
	validate_claude_hooks || return 1
	
	log_success "Hooks verification completed successfully" 
	return 0
}

# Argument parsing
parse_arguments() {
	while [[ $# -gt 0 ]]; do
		case $1 in
			--quick)
				MODE="quick"
				shift
				;;
			--full)
				MODE="full"
				shift
				;;
			--hooks-only)
				MODE="hooks-only"
				shift
				;;
			--verbose)
				VERBOSE=true
				shift
				;;
			--help|-h)
				show_help
				exit 0
				;;
			*)
				log_error "Invalid argument: $1"
				show_help
				exit 3
				;;
		esac
	done
}

# Main execution
main() {
	parse_arguments "$@"
	
	echo -e "${BOLD}Agent OS Installation Verification Script v${SCRIPT_VERSION}${NC}"
	echo "Mode: $MODE"
	echo ""
	
	case "$MODE" in
		"quick")
			run_quick_verification
			;;
		"full")  
			run_full_verification
			;;
		"hooks-only")
			run_hooks_only_verification
			;;
		*)
			log_error "Unknown mode: $MODE"
			exit 3
			;;
	esac
	
	echo ""
	if [[ $EXIT_CODE -eq 0 ]]; then
		log_success "Installation verification completed successfully!"
	elif [[ $EXIT_CODE -eq 2 ]]; then
		log_warning "Installation verification completed with warnings"
	else
		log_error "Installation verification failed!"
	fi
	
	exit $EXIT_CODE
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi