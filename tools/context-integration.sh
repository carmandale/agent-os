#!/bin/bash
#
# context-integration.sh
# Agent OS Context Validation Integration Hub
#
# Unified interface for all Agent OS context validation tools
# Orchestrates context validation, mapping, reference checking, and reporting

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global state
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0
TOTAL_CHECKS=0

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

print_header() {
	print_status "$PURPLE" "🔧 $1"
}

print_section() {
	print_status "$CYAN" "📋 $1"
}

# Get script directory
get_script_dir() {
	echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# Check if all required tools are available
check_tool_availability() {
	local script_dir=$(get_script_dir)
	local missing_tools=()
	
	# Required tools
	local tools=(
		"$script_dir/context-validator.sh"
		"$script_dir/generate-context-map.sh"
		"$script_dir/validate-references.sh"
		"$script_dir/check-file-contexts.py"
	)
	
	print_info "Checking tool availability..."
	
	for tool in "${tools[@]}"; do
		if [[ ! -f "$tool" ]]; then
			missing_tools+=("$(basename "$tool")")
			print_error "Required tool missing: $(basename "$tool")"
		elif [[ ! -x "$tool" ]]; then
			print_error "Tool not executable: $(basename "$tool")"
			missing_tools+=("$(basename "$tool")")
		else
			print_success "Tool available: $(basename "$tool")"
		fi
		((TOTAL_CHECKS++))
	done
	
	# Check Python availability for Python tool
	if ! command -v python3 &> /dev/null; then
		print_error "Python3 not available for check-file-contexts.py"
		missing_tools+=("python3")
	else
		print_success "Python3 available for advanced context analysis"
	fi
	((TOTAL_CHECKS++))
	
	if [[ ${#missing_tools[@]} -gt 0 ]]; then
		print_error "Missing tools: ${missing_tools[*]}"
		return 1
	fi
	
	return 0
}

# Run context structure validation
run_context_validation() {
	local script_dir=$(get_script_dir)
	local filter=$1
	
	print_section "Context Structure Validation"
	
	if [[ -n "$filter" ]]; then
		"$script_dir/context-validator.sh" "$filter"
	else
		"$script_dir/context-validator.sh"
	fi
	
	local exit_code=$?
	((TOTAL_CHECKS++))
	
	if [[ $exit_code -eq 0 ]]; then
		print_success "Context validation completed successfully"
	else
		print_error "Context validation failed with exit code $exit_code"
		((VALIDATION_ERRORS++))
	fi
	
	return $exit_code
}

# Run reference resolution validation
run_reference_validation() {
	local script_dir=$(get_script_dir)
	local args="$*"
	
	print_section "Reference Resolution Validation"
	
	if [[ -n "$args" ]]; then
		"$script_dir/validate-references.sh" $args
	else
		"$script_dir/validate-references.sh"
	fi
	
	local exit_code=$?
	((TOTAL_CHECKS++))
	
	if [[ $exit_code -eq 0 ]]; then
		print_success "Reference validation completed successfully"
	else
		print_error "Reference validation failed with exit code $exit_code"
		((VALIDATION_ERRORS++))
	fi
	
	return $exit_code
}

# Run advanced context analysis
run_advanced_analysis() {
	local script_dir=$(get_script_dir)
	local args="$*"
	
	print_section "Advanced Context Analysis"
	
	if [[ -n "$args" ]]; then
		python3 "$script_dir/check-file-contexts.py" $args
	else
		python3 "$script_dir/check-file-contexts.py" --validate-all
	fi
	
	local exit_code=$?
	((TOTAL_CHECKS++))
	
	if [[ $exit_code -eq 0 ]]; then
		print_success "Advanced analysis completed successfully"
	else
		print_error "Advanced analysis failed with exit code $exit_code"
		((VALIDATION_ERRORS++))
	fi
	
	return $exit_code
}

# Generate context documentation
generate_context_map() {
	local script_dir=$(get_script_dir)
	local output_file=${1:-"CONTEXT-MAP.md"}
	
	print_section "Context Documentation Generation"
	
	"$script_dir/generate-context-map.sh" "$output_file"
	
	local exit_code=$?
	((TOTAL_CHECKS++))
	
	if [[ $exit_code -eq 0 ]]; then
		print_success "Context documentation generated: $output_file"
	else
		print_error "Context documentation generation failed"
		((VALIDATION_ERRORS++))
	fi
	
	return $exit_code
}

# Run comprehensive validation suite
run_full_validation() {
	print_header "Agent OS Context Validation Suite"
	echo "=================================="
	echo ""
	
	local start_time=$(date +%s)
	
	# Tool availability check
	if ! check_tool_availability; then
		print_error "Tool availability check failed - cannot proceed"
		return 1
	fi
	
	echo ""
	
	# Context structure validation
	if ! run_context_validation; then
		print_warning "Context validation had issues but continuing..."
	fi
	
	echo ""
	
	# Reference resolution validation
	if ! run_reference_validation; then
		print_warning "Reference validation had issues but continuing..."
	fi
	
	echo ""
	
	# Advanced analysis
	if ! run_advanced_analysis; then
		print_warning "Advanced analysis had issues but continuing..."
	fi
	
	echo ""
	
	# Generate summary report
	generate_summary_report "$start_time"
}

# Run quick health check
run_health_check() {
	print_header "Agent OS Context Health Check"
	echo "=============================="
	echo ""
	
	local start_time=$(date +%s)
	
	# Quick tool check
	if ! check_tool_availability; then
		print_error "Health check failed - tools not available"
		return 1
	fi
	
	# Quick context validation (install only)
	print_section "Quick Context Check"
	run_context_validation "--install-only"
	
	echo ""
	
	# Generate quick summary
	print_section "Health Check Summary"
	local end_time=$(date +%s)
	local duration=$((end_time - start_time))
	
	echo ""
	echo "Health Check Results:"
	echo "  Total Checks: $TOTAL_CHECKS"
	echo "  Errors: $VALIDATION_ERRORS"
	echo "  Warnings: $VALIDATION_WARNINGS"
	echo "  Duration: ${duration}s"
	echo ""
	
	if [[ $VALIDATION_ERRORS -eq 0 ]]; then
		print_success "Agent OS context health check passed!"
		return 0
	else
		print_error "Agent OS context health check failed with $VALIDATION_ERRORS errors"
		return 1
	fi
}

# Generate comprehensive summary report
generate_summary_report() {
	local start_time=$1
	local end_time=$(date +%s)
	local duration=$((end_time - start_time))
	
	print_section "Validation Summary Report"
	echo "=========================="
	echo ""
	echo "Execution Summary:"
	echo "  Total Checks: $TOTAL_CHECKS"
	echo "  Errors: $VALIDATION_ERRORS"
	echo "  Warnings: $VALIDATION_WARNINGS"
	echo "  Duration: ${duration}s"
	echo "  Date: $(date '+%Y-%m-%d %H:%M:%S')"
	echo ""
	
	if [[ $VALIDATION_ERRORS -eq 0 ]]; then
		print_success "All Agent OS context validations passed!"
		echo ""
		print_info "Recommendations:"
		echo "  - Your Agent OS installation appears healthy"
		echo "  - All contexts are properly structured"
		echo "  - File references resolve correctly"
		echo "  - Consider running periodic health checks"
		return 0
	else
		print_error "Agent OS context validation failed with $VALIDATION_ERRORS errors"
		echo ""
		print_info "Next Steps:"
		echo "  1. Review error details above"
		echo "  2. Fix identified context issues"
		echo "  3. Re-run validation to confirm fixes"
		echo "  4. Check Agent OS documentation for troubleshooting"
		return 1
	fi
}

# Show usage information
show_usage() {
	cat << EOF
Agent OS Context Validation Integration Hub

Usage: $0 [COMMAND] [OPTIONS]

COMMANDS:
  validate     Run full context validation suite (default)
  health       Quick health check (install context only)
  map [FILE]   Generate context documentation map
  contexts     Validate context structures only
  references   Validate reference resolution only
  analysis     Run advanced context analysis only
  
VALIDATION OPTIONS:
  --source-only    Validate only source context
  --install-only   Validate only install context
  --project-only   Validate only project context
  --summary        Show only summary statistics

EXAMPLES:
  $0                          # Full validation suite
  $0 health                   # Quick health check
  $0 validate --install-only  # Validate install context only
  $0 map                      # Generate CONTEXT-MAP.md
  $0 map custom-map.md        # Generate custom filename
  $0 contexts --source-only   # Validate source context structure
  $0 references --summary     # Reference validation summary only

DESCRIPTION:
  Unified interface for Agent OS context validation tools:
  
  - Context structure validation (source/install/project)
  - Reference resolution verification (@~/.agent-os/, @.agent-os/, !)
  - Advanced context analysis with Python tools
  - Documentation generation with visual diagrams
  - Comprehensive reporting and troubleshooting
  
  This tool orchestrates all Agent OS context validation components
  and provides a single entry point for context quality assurance.

EOF
}

# Main execution function
main() {
	local command="${1:-validate}"
	
	case "$command" in
		validate|"")
			shift
			run_full_validation "$@"
			;;
		health)
			run_health_check
			;;
		map)
			shift
			generate_context_map "$@"
			;;
		contexts)
			shift
			run_context_validation "$@"
			;;
		references)
			shift
			run_reference_validation "$@"
			;;
		analysis)
			shift
			run_advanced_analysis "$@"
			;;
		-h|--help)
			show_usage
			exit 0
			;;
		*)
			echo "Unknown command: $command"
			echo "Use --help for usage information"
			exit 1
			;;
	esac
}

# Execute main function with all arguments
main "$@"