#!/bin/bash
# Roadmap Synchronization Library
# Functions for keeping roadmap.md synchronized with completed specs and tasks

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" >&2
}

log_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

# ============================================================================
# Roadmap Structure Validation
# ============================================================================

validate_roadmap_format() {
    local roadmap_file="$1"
    
    if [[ ! -f "$roadmap_file" ]]; then
        log_error "Roadmap file not found: $roadmap_file"
        return 1
    fi
    
    # Check for required sections
    if ! grep -q "^# .*Roadmap" "$roadmap_file"; then
        log_error "Missing roadmap header"
        return 1
    fi
    
    if ! grep -q "^> Last Updated:" "$roadmap_file"; then
        log_error "Missing Last Updated metadata"
        return 1
    fi
    
    if ! grep -q "^> Version:" "$roadmap_file"; then
        log_error "Missing Version metadata"
        return 1
    fi
    
    return 0
}

# ============================================================================
# Roadmap Parsing Functions
# ============================================================================

parse_roadmap_structure() {
    local roadmap_file="$1"
    
    if ! validate_roadmap_format "$roadmap_file"; then
        return 1
    fi
    
    # Extract phase information
    local phases
    phases=$(grep -E "^## Phase [0-9]+:" "$roadmap_file" || true)
    
    if [[ -z "$phases" ]]; then
        log_warning "No phases found in roadmap"
        echo ""
        return 0
    fi
    
    echo "$phases"
    return 0
}

extract_roadmap_tasks() {
    local roadmap_file="$1"
    local phase_name="$2"
    
    if ! validate_roadmap_format "$roadmap_file"; then
        return 1
    fi
    
    # Use sed to extract the phase section, then grep for tasks
    local phase_section
    phase_section=$(sed -n "/^## $phase_name:/,/^## /p" "$roadmap_file" | sed '$d')
    
    # Extract task lines from the phase section
    echo "$phase_section" | grep -E "^- \[[x ]\]" || true
    return 0
}

# ============================================================================
# Spec Completion Detection
# ============================================================================

analyze_spec_tasks() {
    local tasks_file="$1"
    
    if [[ ! -f "$tasks_file" ]]; then
        log_error "Tasks file not found: $tasks_file"
        return 1
    fi
    
    # Count completed vs total tasks
    local total_tasks
    local completed_tasks
    
    total_tasks=$(grep -c "^- \[" "$tasks_file" 2>/dev/null || echo "0")
    completed_tasks=$(grep -c "^- \[x\]" "$tasks_file" 2>/dev/null || echo "0")
    
    if [[ "$total_tasks" -eq 0 ]]; then
        echo "unknown"
        return 0
    fi
    
    # Check if all tasks are completed
    if [[ "$completed_tasks" -eq "$total_tasks" ]]; then
        echo "complete"
    elif [[ "$completed_tasks" -gt 0 ]]; then
        echo "in-progress"
    else
        echo "not-started"
    fi
    
    return 0
}

detect_completed_specs() {
    local specs_dir="${1:-.agent-os/specs}"
    local completed_specs=""
    
    if [[ ! -d "$specs_dir" ]]; then
        log_warning "Specs directory not found: $specs_dir"
        echo ""
        return 0
    fi
    
    # Check each spec directory
    for spec_dir in "$specs_dir"/*; do
        if [[ -d "$spec_dir" && -f "$spec_dir/tasks.md" ]]; then
            local status
            status=$(analyze_spec_tasks "$spec_dir/tasks.md")
            
            if [[ "$status" == "complete" ]]; then
                local spec_name
                spec_name=$(basename "$spec_dir")
                
                if [[ -n "$completed_specs" ]]; then
                    completed_specs+=$'\n'
                fi
                completed_specs+="$spec_name"
            fi
        fi
    done
    
    echo "$completed_specs"
    return 0
}

match_spec_to_roadmap() {
    local task_description="$1"
    
    # Simple keyword matching - convert to lowercase for comparison
    local desc_lower
    desc_lower=$(echo "$task_description" | tr '[:upper:]' '[:lower:]')
    
    # Extract key terms that might match spec names
    local keywords
    keywords=$(echo "$desc_lower" | sed -E 's/[^a-z0-9]+/ /g' | tr ' ' '\n' | grep -v '^$' | head -5)
    
    echo "$keywords"
    return 0
}

# ============================================================================
# Roadmap Update Functions
# ============================================================================

update_roadmap_status() {
    local roadmap_file="$1"
    local task_description="$2"
    local status="$3"
    
    if ! validate_roadmap_format "$roadmap_file"; then
        return 1
    fi
    
    # Create backup
    cp "$roadmap_file" "$roadmap_file.backup"
    
    # Determine the checkbox status
    local checkbox
    case "$status" in
        "completed"|"complete")
            checkbox="[x]"
            ;;
        "in-progress"|"progress")
            checkbox="[ ]"
            ;;
        "not-started"|"pending")
            checkbox="[ ]"
            ;;
        *)
            log_error "Invalid status: $status"
            return 1
            ;;
    esac
    
    # Update the task line
    local temp_file
    temp_file=$(mktemp)
    
    # Use sed to update the specific task
    sed "s/^- \[.*\] $task_description/- $checkbox $task_description/g" "$roadmap_file" > "$temp_file"
    
    # Check if any changes were made
    if diff "$roadmap_file" "$temp_file" >/dev/null 2>&1; then
        log_warning "No matching task found: $task_description"
        rm "$temp_file"
        return 1
    fi
    
    # Apply changes
    mv "$temp_file" "$roadmap_file"
    log_success "Updated task status: $task_description -> $status"
    
    return 0
}

update_phase_status() {
    local roadmap_file="$1"
    local phase_name="$2"
    
    if ! validate_roadmap_format "$roadmap_file"; then
        return 1
    fi
    
    # Get all tasks for this phase
    local phase_tasks
    phase_tasks=$(extract_roadmap_tasks "$roadmap_file" "$phase_name")
    
    if [[ -z "$phase_tasks" ]]; then
        log_warning "No tasks found for phase: $phase_name"
        return 1
    fi
    
    # Count completed vs total tasks
    local total_tasks
    local completed_tasks
    
    total_tasks=$(echo "$phase_tasks" | wc -l)
    completed_tasks=$(echo "$phase_tasks" | grep -c "^- \[x\]" || echo "0")
    
    # Determine phase status
    local phase_status
    if [[ "$completed_tasks" -eq "$total_tasks" ]]; then
        phase_status="✅ COMPLETE"
    elif [[ "$completed_tasks" -gt 0 ]]; then
        phase_status="🔄 IN PROGRESS"
    else
        phase_status="⏳ PLANNED"
    fi
    
    # Update phase header
    local temp_file
    temp_file=$(mktemp)
    
    sed -E "s/^(## $phase_name.*) \([^)]+\)/\1 ($phase_status)/g" "$roadmap_file" > "$temp_file"
    
    # Apply changes
    mv "$temp_file" "$roadmap_file"
    log_success "Updated phase status: $phase_name -> $phase_status"
    
    return 0
}

sync_roadmap_dates() {
    local roadmap_file="$1"
    
    if ! validate_roadmap_format "$roadmap_file"; then
        return 1
    fi
    
    # Create backup
    cp "$roadmap_file" "$roadmap_file.backup"
    
    # Update the last updated date
    local current_date
    current_date=$(date +%Y-%m-%d)
    
    local temp_file
    temp_file=$(mktemp)
    
    sed "s/^> Last Updated:.*/> Last Updated: $current_date/g" "$roadmap_file" > "$temp_file"
    
    # Apply changes
    mv "$temp_file" "$roadmap_file"
    log_success "Updated roadmap timestamp: $current_date"
    
    return 0
}

# ============================================================================
# Version Management
# ============================================================================

update_roadmap_version() {
    local roadmap_file="$1"
    local new_version="$2"
    
    if ! validate_roadmap_format "$roadmap_file"; then
        return 1
    fi
    
    # Create backup
    cp "$roadmap_file" "$roadmap_file.backup"
    
    # Update the version
    local temp_file
    temp_file=$(mktemp)
    
    sed "s/^> Version:.*/> Version: $new_version/g" "$roadmap_file" > "$temp_file"
    
    # Apply changes
    mv "$temp_file" "$roadmap_file"
    log_success "Updated roadmap version: $new_version"
    
    return 0
}

detect_version_milestones() {
    local specs_dir="${1:-.agent-os/specs}"
    local roadmap_file="${2:-.agent-os/product/roadmap.md}"
    
    if ! validate_roadmap_format "$roadmap_file"; then
        return 1
    fi
    
    # Parse roadmap to find completed phases
    local completed_phases=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^##\ (Phase\ [0-9]+:.*)\(✅\ COMPLETE\) ]]; then
            local phase_name="${BASH_REMATCH[1]}"
            if [[ -n "$completed_phases" ]]; then
                completed_phases+=$'\n'
            fi
            completed_phases+="$phase_name"
        fi
    done < "$roadmap_file"
    
    echo "$completed_phases"
    return 0
}

# ============================================================================
# Complete Roadmap Synchronization
# ============================================================================

full_roadmap_sync() {
    local roadmap_file="$1"
    local specs_dir="${2:-.agent-os/specs}"
    
    if ! validate_roadmap_format "$roadmap_file"; then
        return 1
    fi
    
    log_info "Starting full roadmap synchronization..."
    
    # Detect completed specs
    local completed_specs
    completed_specs=$(detect_completed_specs "$specs_dir")
    
    if [[ -n "$completed_specs" ]]; then
        log_info "Found completed specs:"
        echo "$completed_specs" | while read -r spec; do
            echo "  - $spec"
        done
    fi
    
    # Update timestamps
    sync_roadmap_dates "$roadmap_file"
    
    # Update phase statuses (simplified approach)
    local phases
    phases=$(parse_roadmap_structure "$roadmap_file")
    
    if [[ -n "$phases" ]]; then
        while IFS= read -r phase_line; do
            if [[ "$phase_line" =~ ^##\ (Phase\ [0-9]+) ]]; then
                local phase_num="${BASH_REMATCH[1]}"
                update_phase_status "$roadmap_file" "$phase_num" || true
            fi
        done <<< "$phases"
    fi
    
    log_success "Roadmap synchronization completed"
    return 0
}