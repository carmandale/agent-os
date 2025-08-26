#!/bin/bash
#
# validate-references.sh
# Agent OS Reference Resolution Validator
#
# Validates that all Agent OS file references resolve correctly across all contexts
# Tests @ references (file includes) and ! references (script execution)

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
TOTAL_REFERENCES=0
VALID_REFERENCES=0

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
	((VALID_REFERENCES++))
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

# Find all Agent OS reference patterns in a file
find_references_in_file() {
	local file=$1
	local reference_type=$2
	
	case "$reference_type" in
		"install")
			# Find @~/.agent-os/ references
			grep -n "@~/.agent-os/" "$file" 2>/dev/null | while IFS=':' read -r line_num match; do
				local ref_path=$(echo "$match" | sed -E 's/.*@~\/\.agent-os\/([^[:space:])\]]+).*/\1/')
				echo "$line_num:@~/.agent-os/$ref_path"
				((TOTAL_REFERENCES++))
			done
			;;
		"project")
			# Find @.agent-os/ references
			grep -n "@\.agent-os/" "$file" 2>/dev/null | while IFS=':' read -r line_num match; do
				local ref_path=$(echo "$match" | sed -E 's/.*@\.agent-os\/([^[:space:])\]]+).*/\1/')
				echo "$line_num:@.agent-os/$ref_path"
				((TOTAL_REFERENCES++))
			done
			;;
		"script")
			# Find !~/.agent-os/scripts/ references
			grep -n "!~/.agent-os/scripts/" "$file" 2>/dev/null | while IFS=':' read -r line_num match; do
				local ref_path=$(echo "$match" | sed -E 's/.*!~\/\.agent-os\/scripts\/([^[:space:])\]]+).*/\1/')
				echo "$line_num:!~/.agent-os/scripts/$ref_path"
				((TOTAL_REFERENCES++))
			done
			;;
		"all")
			# Find all types
			{
				find_references_in_file "$file" "install"
				find_references_in_file "$file" "project"  
				find_references_in_file "$file" "script"
			}
			;;
	esac
}

# Validate a specific reference
validate_reference() {
	local reference=$1
	local source_file=$2
	local line_number=$3
	
	((TOTAL_REFERENCES++))
	
	case "$reference" in
		"@~/.agent-os/"*)
			# Install context reference
			validate_install_reference "$reference" "$source_file" "$line_number"
			;;
		"@.agent-os/"*)
			# Project context reference
			validate_project_reference "$reference" "$source_file" "$line_number"
			;;
		"!~/.agent-os/scripts/"*)
			# Script execution reference
			validate_script_reference "$reference" "$source_file" "$line_number"
			;;
		*)
			print_warning "Unknown reference type: $reference in $source_file:$line_number"
			;;
	esac
}

# Validate install context reference
validate_install_reference() {
	local reference=$1
	local source_file=$2
	local line_number=$3
	
	# Extract path from reference
	local ref_path="${reference#@}"
	local expanded_path="${ref_path/#\~/$HOME}"
	
	if [[ -f "$expanded_path" ]]; then
		print_success "Install reference valid: $reference ($source_file:$line_number)"
	elif [[ -d "$expanded_path" ]]; then
		print_success "Install directory reference valid: $reference ($source_file:$line_number)"
	else
		print_error "Install reference broken: $reference -> $expanded_path ($source_file:$line_number)"
		return 1
	fi
}

# Validate project context reference
validate_project_reference() {
	local reference=$1
	local source_file=$2
	local line_number=$3
	
	# Extract path from reference  
	local ref_path="${reference#@.agent-os/}"
	
	# Try to resolve in project context first
	if project_context=$(get_project_context); then
		local project_file="$project_context/$ref_path"
		if [[ -f "$project_file" ]]; then
			print_success "Project reference valid: $reference -> $project_file ($source_file:$line_number)"
			return 0
		elif [[ -d "$project_file" ]]; then
			print_success "Project directory reference valid: $reference -> $project_file ($source_file:$line_number)"
			return 0
		fi
	fi
	
	# Fall back to install context
	local install_context=$(get_install_context)
	local install_file="$install_context/$ref_path"
	if [[ -f "$install_file" ]]; then
		print_success "Project reference (fallback to install): $reference -> $install_file ($source_file:$line_number)"
		return 0
	elif [[ -d "$install_file" ]]; then
		print_success "Project directory reference (fallback to install): $reference -> $install_file ($source_file:$line_number)"
		return 0
	fi
	
	# Check if it might be a source context reference when run from source
	local source_context=$(get_source_context)
	local source_file_path="$source_context/$ref_path"
	if [[ -f "$source_file_path" ]]; then
		print_warning "Project reference found in source context (may work after installation): $reference ($source_file:$line_number)"
		return 0
	fi
	
	print_error "Project reference broken: $reference (checked project and install contexts) ($source_file:$line_number)"
	return 1
}

# Validate script execution reference
validate_script_reference() {
	local reference=$1
	local source_file=$2
	local line_number=$3
	
	# Extract path from reference
	local ref_path="${reference#!}"
	local expanded_path="${ref_path/#\~/$HOME}"
	
	if [[ -x "$expanded_path" ]]; then
		print_success "Script reference valid and executable: $reference ($source_file:$line_number)"
	elif [[ -f "$expanded_path" ]]; then
		print_error "Script reference exists but not executable: $reference -> $expanded_path ($source_file:$line_number)"
		return 1
	else
		print_error "Script reference broken: $reference -> $expanded_path ($source_file:$line_number)"
		return 1
	fi
}

# Validate references in all files in a directory
validate_references_in_directory() {
	local directory=$1
	local context_name=$2
	
	if [[ ! -d "$directory" ]]; then
		print_warning "$context_name context directory not found: $directory"
		return 0
	fi
	
	print_info "Validating references in $context_name context: $directory"
	
	local file_count=0
	local ref_count=0
	
	# Find all markdown files
	while IFS= read -r -d '' file; do
		((file_count++))
		
		# Find and validate each type of reference
		while IFS=':' read -r line_num reference; do
			if [[ -n "$reference" ]]; then
				((ref_count++))
				validate_reference "$reference" "$file" "$line_num"
			fi
		done < <(find_references_in_file "$file" "all")
		
	done < <(find "$directory" -name "*.md" -type f -print0 2>/dev/null)
	
	print_info "$context_name context: scanned $file_count files, found $ref_count references"
}

# Check for common reference patterns that might be problematic
validate_reference_patterns() {
	print_info "Checking for problematic reference patterns"
	
	local source_context=$(get_source_context)
	local install_context=$(get_install_context)
	
	# Look for references that might not work across contexts
	local problematic_patterns=(
		"@\.agent-os/product/"     # Project-specific references
		"@~/.agent-os/specs/"      # Specs should be project-specific
		"!~/.agent-os/tools/"      # Tools might not be in scripts directory
	)
	
	for pattern in "${problematic_patterns[@]}"; do
		print_info "Checking pattern: $pattern"
		
		# Search in source context
		if [[ -d "$source_context" ]]; then
			local matches=$(find "$source_context" -name "*.md" -type f -exec grep -l "$pattern" {} \; 2>/dev/null | wc -l)
			if [[ "$matches" -gt 0 ]]; then
				print_warning "Found $matches files using pattern '$pattern' (may need context-specific handling)"
			fi
		fi
	done
}

# Validate that reference syntax is correct
validate_reference_syntax() {
	print_info "Validating reference syntax patterns"
	
	local contexts=()
	contexts+=("$(get_source_context)")
	contexts+=("$(get_install_context)")
	
	if project_context=$(get_project_context); then
		contexts+=("$project_context")
	fi
	
	for context_path in "${contexts[@]}"; do
		if [[ ! -d "$context_path" ]]; then
			continue
		fi
		
		# Look for malformed references
		local malformed_patterns=(
			"@~/.agent-os[^/]"          # Missing slash after @~/.agent-os
			"@\.agent-os[^/]"           # Missing slash after @.agent-os  
			"@/.agent-os/"              # Wrong syntax (should be @.agent-os/)
			"!/.agent-os/"              # Wrong syntax (should be !~/.agent-os/)
		)
		
		for pattern in "${malformed_patterns[@]}"; do
			while IFS= read -r -d '' file; do
				if grep -q "$pattern" "$file" 2>/dev/null; then
					local matches=$(grep -n "$pattern" "$file" | head -3)
					print_error "Malformed reference syntax in $file:"
					echo "$matches" | while IFS=':' read -r line_num match; do
						echo "  Line $line_num: $match"
					done
				fi
			done < <(find "$context_path" -name "*.md" -type f -print0 2>/dev/null)
		done
	done
}

# Generate reference summary report
generate_reference_summary() {
	print_info "Reference Validation Summary"
	echo "============================="
	echo ""
	echo "Total References Checked: $TOTAL_REFERENCES"
	echo "Valid References: $VALID_REFERENCES"
	echo "Invalid References: $VALIDATION_ERRORS"
	echo "Warnings: $VALIDATION_WARNINGS"
	echo ""
	
	if [[ $TOTAL_REFERENCES -eq 0 ]]; then
		print_warning "No references found to validate"
		return 0
	fi
	
	local success_rate=$((VALID_REFERENCES * 100 / TOTAL_REFERENCES))
	echo "Success Rate: $success_rate%"
	echo ""
	
	if [[ $VALIDATION_ERRORS -eq 0 ]]; then
		print_success "All references are valid!"
		return 0
	else
		print_error "Found $VALIDATION_ERRORS broken references"
		echo ""
		print_info "Recommendations:"
		echo "  1. Fix broken references by updating file paths"
		echo "  2. Ensure referenced files exist in correct contexts"
		echo "  3. Run 'tools/context-validator.sh' to check context structure"
		echo "  4. Consider using context-specific references (@.agent-os/ vs @~/.agent-os/)"
		return 1
	fi
}

# Main validation function
main() {
	echo "🔍 Agent OS Reference Validation System"
	echo "======================================="
	echo ""
	
	local source_context=$(get_source_context)
	local install_context=$(get_install_context)
	
	# Validate references in source context
	validate_references_in_directory "$source_context" "Source"
	
	echo ""
	
	# Validate references in install context
	validate_references_in_directory "$install_context" "Install"
	
	echo ""
	
	# Validate references in project context if available
	if project_context=$(get_project_context); then
		validate_references_in_directory "$project_context" "Project"
		echo ""
	else
		print_info "No project context found - skipping project reference validation"
		echo ""
	fi
	
	# Additional validation checks
	validate_reference_patterns
	echo ""
	
	validate_reference_syntax
	echo ""
	
	# Generate summary
	generate_reference_summary
}

# Show usage information
show_usage() {
	cat << EOF
Agent OS Reference Validator

Usage: $0 [OPTIONS] [PATH]

ARGUMENTS:
  PATH           Specific directory to validate (optional)

OPTIONS:
  -h, --help     Show this help message
  --install-only Validate only install context references
  --project-only Validate only project context references
  --source-only  Validate only source context references
  --summary      Show only summary statistics

DESCRIPTION:
  Validates Agent OS file references across all contexts:
  
  Reference Types:
    @~/.agent-os/file.md     - Install context references (always resolve to ~/.agent-os/)
    @.agent-os/file.md       - Project context references (project first, then install fallback)
    !~/.agent-os/scripts/... - Script execution references (must be executable)
  
  Checks that all referenced files exist and are accessible from their contexts.

EXAMPLES:
  $0                        # Validate all references in all contexts
  $0 --install-only         # Check only install context references
  $0 ~/.agent-os/           # Validate specific directory
  $0 --summary              # Show only statistics

EOF
}

# Parse command line arguments
SUMMARY_ONLY=false
CONTEXT_FILTER=""
TARGET_PATH=""

while [[ $# -gt 0 ]]; do
	case $1 in
		-h|--help)
			show_usage
			exit 0
			;;
		--install-only)
			CONTEXT_FILTER="install"
			shift
			;;
		--project-only)
			CONTEXT_FILTER="project"
			shift
			;;
		--source-only)
			CONTEXT_FILTER="source"
			shift
			;;
		--summary)
			SUMMARY_ONLY=true
			shift
			;;
		-*)
			echo "Unknown option: $1"
			echo "Use --help for usage information"
			exit 1
			;;
		*)
			TARGET_PATH="$1"
			shift
			;;
	esac
done

# Execute based on arguments
if [[ -n "$TARGET_PATH" ]]; then
	# Validate specific path
	validate_references_in_directory "$TARGET_PATH" "Specified"
	generate_reference_summary
elif [[ -n "$CONTEXT_FILTER" ]]; then
	# Validate specific context only
	case "$CONTEXT_FILTER" in
		"source")
			validate_references_in_directory "$(get_source_context)" "Source"
			;;
		"install")
			validate_references_in_directory "$(get_install_context)" "Install"
			;;
		"project")
			if project_context=$(get_project_context); then
				validate_references_in_directory "$project_context" "Project"
			else
				print_error "No project context found"
				exit 1
			fi
			;;
	esac
	generate_reference_summary
else
	# Full validation
	main
fi