#!/bin/bash
#
# context-validator.sh
# Agent OS Context Clarity Validation System
#
# Validates that files are in their correct contexts and references resolve properly
# across the three-context Agent OS architecture:
# - Source Context: Repository files
# - Install Context: ~/.agent-os/ files  
# - Project Context: .agent-os/ files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global validation state
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

# Print colored output
print_status() {
	local color=$1
	local message=$2
	echo -e "${color}${message}${NC}"
}

print_error() {
	print_status "$RED" "❌ ERROR: $1"
	((VALIDATION_ERRORS++))
}

print_warning() {
	print_status "$YELLOW" "⚠️  WARNING: $1"
	((VALIDATION_WARNINGS++))
}

print_success() {
	print_status "$GREEN" "✅ $1"
}

print_info() {
	print_status "$BLUE" "ℹ️  $1"
}

# Get script directory (source context)
get_source_context() {
	echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
}

# Get install context
get_install_context() {
	echo "$HOME/.agent-os"
}

# Get project context (if in a project)
get_project_context() {
	local current_dir="$(pwd)"
	while [[ "$current_dir" != "/" ]]; do
		if [[ -d "$current_dir/.agent-os" ]]; then
			echo "$current_dir/.agent-os"
			return 0
		fi
		current_dir="$(dirname "$current_dir")"
	done
	return 1
}

# Validate that a context directory exists and has expected structure
validate_context_structure() {
	local context_type=$1
	local context_path=$2
	
	print_info "Validating $context_type context structure: $context_path"
	
	if [[ ! -d "$context_path" ]]; then
		print_error "$context_type context directory not found: $context_path"
		return 1
	fi
	
	case "$context_type" in
		"source")
			validate_source_context_structure "$context_path"
			;;
		"install")
			validate_install_context_structure "$context_path"
			;;
		"project")
			validate_project_context_structure "$context_path"
			;;
	esac
}

# Validate source context (repository) structure
validate_source_context_structure() {
	local source_path=$1
	
	# Expected directories in source context
	local expected_dirs=(
		"standards"
		"instructions"
		"instructions/core"
		"instructions/meta"
		"scripts"
		"workflow-modules"
		"tools"
		"commands"
		"claude-code/agents"
		"hooks"
	)
	
	for dir in "${expected_dirs[@]}"; do
		if [[ -d "$source_path/$dir" ]]; then
			print_success "Source directory exists: $dir"
		else
			print_warning "Source directory missing: $dir"
		fi
	done
	
	# Expected key files
	local expected_files=(
		"VERSION"
		"setup.sh"
		"setup-claude-code.sh"
		"standards/tech-stack.md"
		"standards/code-style.md"
		"standards/best-practices.md"
		"instructions/core/execute-tasks.md"
		"tools/aos"
	)
	
	for file in "${expected_files[@]}"; do
		if [[ -f "$source_path/$file" ]]; then
			print_success "Source file exists: $file"
		else
			print_error "Source file missing: $file"
		fi
	done
}

# Validate install context (~/.agent-os) structure
validate_install_context_structure() {
	local install_path=$1
	
	# Expected directories in install context
	local expected_dirs=(
		"standards"
		"instructions"
		"instructions/core"
		"instructions/meta"
		"scripts"
		"workflow-modules"
		"tools"
	)
	
	for dir in "${expected_dirs[@]}"; do
		if [[ -d "$install_path/$dir" ]]; then
			print_success "Install directory exists: $dir"
		else
			print_error "Install directory missing: $dir (Agent OS may not be properly installed)"
		fi
	done
	
	# Validate VERSION file and content
	if [[ -f "$install_path/VERSION" ]]; then
		local version=$(cat "$install_path/VERSION")
		if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
			print_success "Install VERSION file valid: $version"
		else
			print_error "Install VERSION file invalid format: $version"
		fi
	else
		print_error "Install VERSION file missing"
	fi
	
	# Check for deprecated files that should be cleaned up
	if [[ -f "$install_path/.version" ]]; then
		print_warning "Deprecated .version file found (should be VERSION)"
	fi
}

# Validate project context (.agent-os) structure
validate_project_context_structure() {
	local project_path=$1
	
	print_info "Project context found: $project_path"
	
	# Project context may have any subset of Agent OS structure
	# Common project files
	local project_files=(
		"product/mission.md"
		"product/roadmap.md"
		"product/decisions.md"
		"product/tech-stack.md"
		"product/code-style.md"
		"product/dev-best-practices.md"
	)
	
	local found_files=0
	for file in "${project_files[@]}"; do
		if [[ -f "$project_path/$file" ]]; then
			print_success "Project file exists: $file"
			((found_files++))
		fi
	done
	
	if [[ $found_files -eq 0 ]]; then
		print_warning "Project context exists but contains no standard Agent OS files"
	fi
}

# Validate file reference patterns
validate_file_references() {
	local context_type=$1
	local context_path=$2
	
	print_info "Validating file references in $context_type context"
	
	# Find all markdown files and check for reference patterns
	if [[ -d "$context_path" ]]; then
		while IFS= read -r -d '' file; do
			validate_references_in_file "$file" "$context_type" "$context_path"
		done < <(find "$context_path" -name "*.md" -print0 2>/dev/null)
	fi
}

# Validate references in a specific file
validate_references_in_file() {
	local file=$1
	local context_type=$2
	local context_path=$3
	
	# Look for Agent OS reference patterns
	local reference_patterns=(
		"@~/.agent-os/"           # Install context references
		"@.agent-os/"             # Project context references
		"!~/.agent-os/scripts/"   # Script execution references
	)
	
	for pattern in "${reference_patterns[@]}"; do
		while IFS= read -r line; do
			# Extract the referenced path
			local ref_path=$(echo "$line" | sed -E "s/.*${pattern//\//\\\/}([^[:space:]]+).*/\1/")
			validate_reference_resolution "$pattern$ref_path" "$context_type"
		done < <(grep -n "$pattern" "$file" 2>/dev/null || true)
	done
}

# Validate that a reference can be resolved
validate_reference_resolution() {
	local reference=$1
	local source_context=$2
	
	case "$reference" in
		"@~/.agent-os/"*)
			# Install context reference
			local path="${reference#@}"
			local expanded_path="${path/#\~/$HOME}"
			if [[ -f "$expanded_path" ]]; then
				print_success "Install reference resolves: $reference"
			else
				print_error "Install reference broken: $reference -> $expanded_path"
			fi
			;;
		"@.agent-os/"*)
			# Project context reference  
			local project_context
			if project_context=$(get_project_context); then
				local path="${reference#@.agent-os/}"
				if [[ -f "$project_context/$path" ]]; then
					print_success "Project reference resolves: $reference"
				else
					print_warning "Project reference not found: $reference (may be inherited from install context)"
				fi
			else
				print_warning "Project reference found but no project context: $reference"
			fi
			;;
		"!~/.agent-os/scripts/"*)
			# Script execution reference
			local path="${reference#!}"
			local expanded_path="${path/#\~/$HOME}"
			if [[ -x "$expanded_path" ]]; then
				print_success "Script reference resolves and is executable: $reference"
			elif [[ -f "$expanded_path" ]]; then
				print_error "Script reference exists but not executable: $reference"
			else
				print_error "Script reference broken: $reference -> $expanded_path"
			fi
			;;
	esac
}

# Check for context violations (files in wrong places)
validate_context_violations() {
	print_info "Checking for context violations"
	
	local source_context=$(get_source_context)
	local install_context=$(get_install_context)
	
	# Check if source files accidentally copied to install context
	if [[ -d "$install_context" ]]; then
		# Look for files that should only be in source context
		local source_only_files=(
			"setup.sh"
			"setup-claude-code.sh"
			"CLAUDE.md"
			"README.md"
			"CHANGELOG.md"
			".git"
		)
		
		for file in "${source_only_files[@]}"; do
			if [[ -e "$install_context/$file" ]]; then
				print_error "Context violation: Source-only file found in install context: $file"
			fi
		done
		
		# Check for test files in install context (should only be in source)
		if [[ -d "$install_context/tests" ]]; then
			print_error "Context violation: Tests directory should not be in install context"
		fi
	fi
}

# Generate context summary report
generate_context_summary() {
	print_info "Context Summary Report"
	echo "========================"
	
	local source_context=$(get_source_context)
	local install_context=$(get_install_context)
	
	echo "Source Context: $source_context"
	echo "Install Context: $install_context"
	
	if project_context=$(get_project_context); then
		echo "Project Context: $project_context"
	else
		echo "Project Context: None (not in an Agent OS project)"
	fi
	
	echo ""
	echo "Validation Results:"
	echo "  Errors: $VALIDATION_ERRORS"
	echo "  Warnings: $VALIDATION_WARNINGS"
	
	if [[ $VALIDATION_ERRORS -eq 0 ]]; then
		print_success "All context validations passed!"
		return 0
	else
		print_error "Context validation failed with $VALIDATION_ERRORS errors"
		return 1
	fi
}

# Main validation function
main() {
	echo "🔍 Agent OS Context Validation System"
	echo "====================================="
	echo ""
	
	local source_context=$(get_source_context)
	local install_context=$(get_install_context)
	
	# Validate contexts exist and have proper structure
	validate_context_structure "source" "$source_context"
	validate_context_structure "install" "$install_context"
	
	# Validate project context if we're in one
	if project_context=$(get_project_context); then
		validate_context_structure "project" "$project_context"
	fi
	
	echo ""
	
	# Validate file references
	validate_file_references "source" "$source_context"
	validate_file_references "install" "$install_context"
	
	if project_context=$(get_project_context); then
		validate_file_references "project" "$project_context"
	fi
	
	echo ""
	
	# Check for context violations
	validate_context_violations
	
	echo ""
	
	# Generate summary
	generate_context_summary
}

# Show usage information
show_usage() {
	cat << EOF
Agent OS Context Validator

Usage: $0 [OPTIONS]

OPTIONS:
  -h, --help     Show this help message
  --source-only  Validate only source context
  --install-only Validate only install context
  --project-only Validate only project context

DESCRIPTION:
  Validates the Agent OS three-context architecture:
  
  Source Context:  Repository files (where you run this script)
  Install Context: ~/.agent-os/ files (global Agent OS installation)
  Project Context: .agent-os/ files (project-specific overrides)
  
  Ensures files are in correct locations and references resolve properly.

EXAMPLES:
  $0                    # Validate all contexts
  $0 --install-only     # Check only ~/.agent-os/ installation
  $0 --source-only      # Check only repository structure

EOF
}

# Parse command line arguments
case "${1:-}" in
	-h|--help)
		show_usage
		exit 0
		;;
	--source-only)
		validate_context_structure "source" "$(get_source_context)"
		;;
	--install-only)
		validate_context_structure "install" "$(get_install_context)"
		;;
	--project-only)
		if project_context=$(get_project_context); then
			validate_context_structure "project" "$project_context"
		else
			print_error "No project context found"
			exit 1
		fi
		;;
	"")
		main
		;;
	*)
		echo "Unknown option: $1"
		echo "Use --help for usage information"
		exit 1
		;;
esac