#!/bin/bash
# Agent OS Documentation Update Library
# Modular functions for documentation maintenance and updates

set -euo pipefail

# ============================================================================
# Global Variables
# ============================================================================

# Default configuration
MODE="${MODE:-dry-run}"
UPDATE_CHANGELOG="${UPDATE_CHANGELOG:-0}"
CREATE_MISSING="${CREATE_MISSING:-0}"
DEEP="${DEEP:-0}"
FIX_REFS="${FIX_REFS:-0}"
SYNC_ROADMAP="${SYNC_ROADMAP:-0}"
UPDATE_ALL="${UPDATE_ALL:-0}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Flag Parsing Module
# ============================================================================

parse_flags() {
    local args=("$@")
    
    # Reset flags
    MODE="dry-run"
    UPDATE_CHANGELOG=0
    CREATE_MISSING=0
    DEEP=0
    FIX_REFS=0
    SYNC_ROADMAP=0
    UPDATE_ALL=0
    
    for arg in "${args[@]}"; do
        case "$arg" in
            --dry-run)
                MODE="dry-run"
                ;;
            --update)
                MODE="update"
                ;;
            --changelog-only)
                UPDATE_CHANGELOG=1
                MODE="update"
                ;;
            --create-missing)
                CREATE_MISSING=1
                ;;
            --deep)
                DEEP=1
                ;;
            --fix-refs)
                FIX_REFS=1
                MODE="update"
                ;;
            --sync-roadmap)
                SYNC_ROADMAP=1
                MODE="update"
                ;;
            --all)
                UPDATE_ALL=1
                UPDATE_CHANGELOG=1
                CREATE_MISSING=1
                DEEP=1
                FIX_REFS=1
                SYNC_ROADMAP=1
                MODE="update"
                ;;
            --diff-only)
                MODE="diff-only"
                ;;
            *)
                log_error "Unknown flag: $arg"
                return 1
                ;;
        esac
    done
    
    # Export variables for other functions
    export MODE UPDATE_CHANGELOG CREATE_MISSING DEEP FIX_REFS SYNC_ROADMAP UPDATE_ALL
    
    # Return flag status for testing
    echo "MODE=$MODE UPDATE_CHANGELOG=$UPDATE_CHANGELOG FIX_REFS=$FIX_REFS SYNC_ROADMAP=$SYNC_ROADMAP UPDATE_ALL=$UPDATE_ALL"
}

# ============================================================================
# Discovery Module
# ============================================================================

discover_changes() {
    local changed
    changed=$(git diff --name-only HEAD 2>/dev/null || true)
    
    if [[ -z "$changed" ]]; then
        return 0
    fi
    
    echo "$changed"
}

discover_repository_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

# ============================================================================
# Analysis Module
# ============================================================================

analyze_documentation_health() {
    local health_issues=()
    
    # Check for issues without specs
    local issues_output
    issues_output=$(analyze_issues_without_specs)
    if [[ -n "$issues_output" ]]; then
        health_issues+=("$issues_output")
    fi
    
    # Check for recent PRs not in changelog
    local prs_output
    prs_output=$(analyze_recent_prs)
    if [[ -n "$prs_output" ]]; then
        health_issues+=("$prs_output")
    fi
    
    # Check changelog recency
    if ! check_changelog_recent; then
        health_issues+=("## CHANGELOG needs recent entries")
    fi
    
    # Output all health issues
    for issue in "${health_issues[@]}"; do
        echo "$issue"
    done
}

analyze_issues_without_specs() {
    local issues_without_specs=()
    
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        return 0
    fi
    
    # Get open issues
    local open_issues
    open_issues=$(gh issue list --state open --json number,title 2>/dev/null || echo "[]")
    
    if [[ "$open_issues" != "[]" ]]; then
        # Parse issue numbers using jq if available
        if command -v jq &> /dev/null; then
            while IFS= read -r issue_num; do
                if [[ ! -d ".agent-os/specs/"*"-#${issue_num}" ]]; then
                    issues_without_specs+=("$issue_num")
                fi
            done < <(echo "$open_issues" | jq -r '.[].number')
        fi
    fi
    
    if [[ ${#issues_without_specs[@]} -gt 0 ]]; then
        echo "## Issues without specs:"
        printf -- '- Issue #%s\n' "${issues_without_specs[@]}"
    fi
}

analyze_recent_prs() {
    if ! command -v gh &> /dev/null; then
        return 0
    fi
    
    local recent_prs
    recent_prs=$(gh pr list --state merged --limit 5 --json number,title,mergedAt 2>/dev/null || echo "[]")
    
    if [[ "$recent_prs" != "[]" && -f CHANGELOG.md ]]; then
        if command -v jq &> /dev/null; then
            local undocumented_prs=()
            while IFS= read -r pr_num; do
                if ! grep -q "#${pr_num}" CHANGELOG.md 2>/dev/null; then
                    undocumented_prs+=("$pr_num")
                fi
            done < <(echo "$recent_prs" | jq -r '.[].number')
            
            if [[ ${#undocumented_prs[@]} -gt 0 ]]; then
                echo "## Recent PRs not in CHANGELOG:"
                printf -- '- PR #%s\n' "${undocumented_prs[@]}"
            fi
        fi
    fi
}

check_changelog_recent() {
    if [[ ! -f CHANGELOG.md ]]; then
        return 1
    fi
    
    # Check for dates within last 30 days
    local thirty_days_ago
    thirty_days_ago=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d 2>/dev/null || echo "2024-01-01")
    
    if grep -E "^## [0-9]{4}-[0-9]{2}-[0-9]{2}" CHANGELOG.md | head -5 | grep -qE "$(date +%Y-%m)"; then
        return 0
    fi
    
    return 1
}

# ============================================================================
# Reporting Module
# ============================================================================

generate_report() {
    local section_title="$1"
    local content="$2"
    local summary="${3:-}"
    
    echo "# $section_title"
    
    if [[ -n "$content" ]]; then
        echo "$content" | sed 's/^/- /'
    else
        echo "No changes detected."
    fi
    
    if [[ -n "$summary" ]]; then
        echo ""
        echo "$summary"
    fi
}

generate_proposals() {
    local changed="$1"
    local proposals=()
    
    # Determine what needs updating based on changes
    local needs_changelog=0
    local needs_readme=0
    local needs_docs=0
    local needs_product=0
    
    # Check if code changes require CHANGELOG update
    if echo "$changed" | grep -qE "^(scripts/|tools/|setup\.sh|setup-claude-code\.sh|setup-cursor\.sh|hooks/|instructions/|workflow-modules/)"; then
        needs_changelog=1
    fi
    
    # Check if any non-doc change should update CHANGELOG
    if echo "$changed" | grep -vqE "^(docs/|\.agent-os/product/|\.github/|CHANGELOG\.md$|README\.md$|CLAUDE\.md$)"; then
        needs_changelog=1
    fi
    
    # Check if README needs update
    if echo "$changed" | grep -qE "^(tools/|setup\.sh|commands/)"; then
        needs_readme=1
    fi
    
    # Check if documentation needs update
    if echo "$changed" | grep -qE "^(instructions/|workflow-modules/|hooks/)"; then
        needs_docs=1
    fi
    
    # Check if product documentation needs update
    if echo "$changed" | grep -qE "^(\.agent-os/product/|instructions/core/)"; then
        needs_product=1
    fi
    
    # Build proposals list
    [[ $needs_changelog -eq 1 ]] && proposals+=("CHANGELOG.md")
    [[ $needs_readme -eq 1 ]] && proposals+=("README.md" "CLAUDE.md")
    [[ $needs_docs -eq 1 ]] && proposals+=("docs/*")
    [[ $needs_product -eq 1 ]] && proposals+=(".agent-os/product/{roadmap.md,decisions.md}")
    
    # Additional checks
    if ! check_changelog_recent; then
        if [[ $needs_changelog -eq 0 ]]; then
            proposals+=("CHANGELOG.md (no recent entries)")
        fi
    fi
    
    # Output proposals
    if [[ ${#proposals[@]} -gt 0 ]]; then
        printf -- '%s\n' "${proposals[@]}" | sort -u
    fi
}

# ============================================================================
# Validation Module
# ============================================================================

validate_environment() {
    local missing_commands=()
    
    # Check for required commands
    if ! command -v git &> /dev/null; then
        missing_commands+=("git")
    fi
    
    if ! command -v gh &> /dev/null; then
        log_info "Note: gh CLI not available - GitHub integration disabled"
    fi
    
    if ! command -v jq &> /dev/null; then
        log_info "Note: jq not available - JSON parsing may be limited"
    fi
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        return 1
    fi
    
    return 0
}

validate_repository() {
    if ! git rev-parse --git-dir &> /dev/null; then
        log_error "Not in a git repository"
        return 1
    fi
    
    return 0
}

# ============================================================================
# Utility Functions
# ============================================================================

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

is_dry_run() {
    [[ "$MODE" == "dry-run" ]]
}

is_update_mode() {
    [[ "$MODE" == "update" ]]
}

is_diff_only_mode() {
    [[ "$MODE" == "diff-only" ]]
}

# ============================================================================
# CHANGELOG Auto-Update Module
# ============================================================================

analyze_git_commits() {
    local since=""
    local format="simple"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --since=*)
                since="${1#*=}"
                shift
                ;;
            --format=*)
                format="${1#*=}"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # Build git log command
    local git_cmd="git log --oneline"
    if [[ -n "$since" ]]; then
        git_cmd="$git_cmd --since='$since'"
    fi
    
    # Get commits
    local commits
    commits=$(eval "$git_cmd" 2>/dev/null || true)
    
    if [[ -z "$commits" ]]; then
        return 0
    fi
    
    # Process commits based on format
    if [[ "$format" == "detailed" ]]; then
        # Include commit body and metadata
        git_cmd="git log --format='%h|%s|%b|%an|%ad' --date=iso"
        if [[ -n "$since" ]]; then
            git_cmd="$git_cmd --since='$since'"
        fi
        eval "$git_cmd" 2>/dev/null || true
    else
        echo "$commits"
    fi
}

categorize_commit() {
    local commit_msg="$1"
    
    # Extract type from conventional commit format
    if [[ "$commit_msg" =~ ^(feat|feature)[\(:] ]]; then
        echo "Added"
    elif [[ "$commit_msg" =~ ^fix[\(:] ]]; then
        echo "Fixed"
    elif [[ "$commit_msg" =~ ^(docs|doc)[\(:] ]]; then
        echo "Changed"
    elif [[ "$commit_msg" =~ ^(style|refactor)[\(:] ]]; then
        echo "Changed"
    elif [[ "$commit_msg" =~ ^(test|tests)[\(:] ]]; then
        echo "Changed"
    elif [[ "$commit_msg" =~ ^(chore|build|ci)[\(:] ]]; then
        echo "Changed"
    elif [[ "$commit_msg" =~ ^(breaking|BREAKING)[\(:] ]]; then
        echo "Changed"
    elif [[ "$commit_msg" =~ ^(perf|performance)[\(:] ]]; then
        echo "Changed"
    else
        echo "Changed"
    fi
}

fetch_pr_data() {
    local merged=false
    local limit=10
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --merged)
                merged=true
                shift
                ;;
            --limit=*)
                limit="${1#*=}"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        return 0
    fi
    
    # Build gh command
    local gh_cmd="gh pr list --json number,title,mergedAt,author,body --limit $limit"
    if [[ "$merged" == true ]]; then
        gh_cmd="$gh_cmd --state merged"
    fi
    
    # Execute and return PR data
    eval "$gh_cmd" 2>/dev/null || echo "[]"
}

format_pr_entry() {
    local pr_data="$1"
    local category="${2:-Added}"
    
    # Extract PR information using basic string manipulation
    # (avoiding jq dependency in core function)
    local pr_number
    local pr_title
    local pr_author
    
    pr_number=$(echo "$pr_data" | sed -n 's/.*"number": *\([0-9]*\).*/\1/p')
    pr_title=$(echo "$pr_data" | sed -n 's/.*"title": *"\([^"]*\)".*/\1/p')
    pr_author=$(echo "$pr_data" | sed -n 's/.*"login": *"\([^"]*\)".*/\1/p')
    
    if [[ -n "$pr_number" && -n "$pr_title" ]]; then
        echo "- **$pr_title** (#$pr_number) @$pr_author"
    fi
}

generate_changelog_entries() {
    local since=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --since=*)
                since="${1#*=}"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # Get commits
    local commits
    commits=$(analyze_git_commits --since="$since")
    
    if [[ -z "$commits" ]]; then
        return 0
    fi
    
    # Categorize commits
    declare -A categories
    categories["Added"]=""
    categories["Fixed"]=""
    categories["Changed"]=""
    
    while IFS= read -r commit; do
        if [[ -n "$commit" ]]; then
            # Extract commit message (after hash)
            local original_msg
            original_msg=$(echo "$commit" | cut -d' ' -f2-)
            
            local category
            category=$(categorize_commit "$original_msg")
            
            # Remove conventional commit prefix for display
            local commit_msg
            commit_msg=$(echo "$original_msg" | sed 's/^[^:]*: *//')
            
            # Only process recognized categories
            if [[ "$category" == "Added" || "$category" == "Fixed" || "$category" == "Changed" ]]; then
                if [[ -n "${categories[$category]:-}" ]]; then
                    categories[$category]+=$'\n'"- $commit_msg"
                else
                    categories[$category]="- $commit_msg"
                fi
            fi
        fi
    done <<< "$commits"
    
    # Output formatted sections
    for category in "Added" "Changed" "Fixed"; do
        if [[ -n "${categories[$category]:-}" ]]; then
            echo "### $category"
            echo "${categories[$category]}"
            echo ""
        fi
    done
}

format_changelog_date() {
    local input_date="$1"
    
    if [[ "$input_date" == "now" ]]; then
        date +%Y-%m-%d
    elif [[ "$input_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T ]]; then
        # ISO format - extract just the date part
        echo "$input_date" | cut -d'T' -f1
    elif [[ "$input_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        # Already in correct format
        echo "$input_date"
    else
        # Try to parse with date command
        date -d "$input_date" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d
    fi
}

backup_changelog() {
    if [[ -f "CHANGELOG.md" ]]; then
        cp "CHANGELOG.md" "CHANGELOG.md.backup"
        log_info "Created backup: CHANGELOG.md.backup"
        return 0
    else
        log_warning "No CHANGELOG.md found to backup"
        return 1
    fi
}

create_basic_changelog() {
    local changelog_file="${1:-CHANGELOG.md}"
    
    cat > "$changelog_file" <<'EOF'
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

EOF
}

extract_unreleased_entries() {
    local changelog_file="${1:-CHANGELOG.md}"
    
    if [[ ! -f "$changelog_file" ]]; then
        return 0
    fi
    
    # Extract content between [Unreleased] and next version section
    local in_unreleased=false
    local result=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^\#\#\ \[Unreleased\] ]]; then
            in_unreleased=true
            continue
        elif [[ "$line" =~ ^\#\# && "$in_unreleased" == true ]]; then
            # Found next version section, stop
            break
        elif [[ "$in_unreleased" == true && -n "$line" ]]; then
            # Add non-empty lines from unreleased section
            if [[ -n "$result" ]]; then
                result+=$'\n'
            fi
            result+="$line"
        fi
    done < "$changelog_file"
    
    echo "$result"
}

validate_changelog_format() {
    local changelog_file="$1"
    
    if [[ ! -f "$changelog_file" ]]; then
        log_error "Changelog file not found: $changelog_file"
        return 1
    fi
    
    # Check for basic Keep a Changelog structure
    if ! grep -q "# Changelog" "$changelog_file" && ! grep -q "# CHANGELOG" "$changelog_file"; then
        log_error "Missing changelog header"
        return 1
    fi
    
    if ! grep -q "## \[" "$changelog_file"; then
        log_error "Missing version sections"
        return 1
    fi
    
    return 0
}

update_changelog_file() {
    local new_entries="$1"
    local changelog_file="${2:-CHANGELOG.md}"
    
    if [[ -z "$new_entries" ]]; then
        log_warning "No new entries to add to changelog"
        return 0
    fi
    
    # Create backup
    backup_changelog
    
    # Check if changelog exists
    if [[ ! -f "$changelog_file" ]]; then
        log_info "Creating new CHANGELOG.md"
        create_basic_changelog "$changelog_file"
    fi
    
    # Check if [Unreleased] section exists
    if ! grep -q "^## \[Unreleased\]" "$changelog_file"; then
        log_info "Adding [Unreleased] section to existing changelog"
        # Add [Unreleased] section after main header
        local temp_file
        temp_file=$(mktemp)
        
        local header_done=false
        while IFS= read -r line; do
            echo "$line" >> "$temp_file"
            if [[ "$line" =~ ^#[[:space:]] && "$header_done" == false ]]; then
                header_done=true
                echo "" >> "$temp_file"
                echo "## [Unreleased]" >> "$temp_file"
                echo "" >> "$temp_file"
            fi
        done < "$changelog_file"
        
        # If no header found, just append
        if [[ "$header_done" == false ]]; then
            echo "" >> "$temp_file"
            echo "## [Unreleased]" >> "$temp_file"
            echo "" >> "$temp_file"
        fi
        
        mv "$temp_file" "$changelog_file"
    fi
    
    # Find the [Unreleased] section
    local temp_file
    temp_file=$(mktemp)
    
    # Read through file and insert new entries under [Unreleased]
    local in_unreleased=false
    local entries_added=false
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        # Check if we found the [Unreleased] section
        if [[ "$line" =~ ^\#\#\ \[Unreleased\] ]]; then
            in_unreleased=true
        elif [[ "$line" =~ ^\#\# && "$in_unreleased" == true ]]; then
            # Found next version section, insert entries before it
            if [[ "$entries_added" == false ]]; then
                echo "" >> "$temp_file"
                echo "$new_entries" >> "$temp_file"
                entries_added=true
            fi
            in_unreleased=false
        elif [[ "$in_unreleased" == true && "$line" =~ ^\#\#\# && "$entries_added" == false ]]; then
            # Found first subsection under [Unreleased], insert before it
            echo "" >> "$temp_file"
            echo "$new_entries" >> "$temp_file"
            echo "" >> "$temp_file"
            entries_added=true
        fi
    done < "$changelog_file"
    
    # If we never found a place to insert, add at end of [Unreleased]
    if [[ "$entries_added" == false ]]; then
        echo "" >> "$temp_file"
        echo "$new_entries" >> "$temp_file"
    fi
    
    # Replace original file
    mv "$temp_file" "$changelog_file"
    log_success "Updated $changelog_file with new entries"
}

preserve_manual_entries() {
    local new_entries="$1"
    local changelog_file="${2:-CHANGELOG.md}"
    
    if [[ ! -f "$changelog_file" ]]; then
        echo "$new_entries"
        return 0
    fi
    
    # Extract existing entries from [Unreleased] section
    local existing_entries
    existing_entries=$(extract_unreleased_entries "$changelog_file")
    
    if [[ -z "$existing_entries" ]]; then
        echo "$new_entries"
        return 0
    fi
    
    # Merge entries by category
    merge_changelog_sections "$existing_entries" "$new_entries"
}

merge_changelog_sections() {
    local existing="$1"
    local new="$2"
    
    # Simple merge approach - combine similar sections
    local merged=""
    
    # Parse both sets of entries and combine by category
    declare -A all_sections
    
    # Extract sections from existing entries
    local current_section=""
    local section_content=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^\#\#\#\ (.+) ]]; then
            # Save previous section
            if [[ -n "$current_section" && -n "$section_content" ]]; then
                all_sections["$current_section"]+="$section_content"$'\n'
            fi
            current_section="${BASH_REMATCH[1]}"
            section_content=""
        elif [[ -n "$current_section" && "$line" =~ ^- ]]; then
            section_content+="$line"$'\n'
        fi
    done <<< "$existing"
    
    # Save last section from existing
    if [[ -n "$current_section" && -n "$section_content" ]]; then
        all_sections["$current_section"]+="$section_content"
    fi
    
    # Add new entries
    current_section=""
    section_content=""
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^\#\#\#\ (.+) ]]; then
            # Save previous section
            if [[ -n "$current_section" && -n "$section_content" ]]; then
                all_sections["$current_section"]+="$section_content"$'\n'
            fi
            current_section="${BASH_REMATCH[1]}"
            section_content=""
        elif [[ -n "$current_section" && "$line" =~ ^- ]]; then
            section_content+="$line"$'\n'
        fi
    done <<< "$new"
    
    # Save last section from new
    if [[ -n "$current_section" && -n "$section_content" ]]; then
        all_sections["$current_section"]+="$section_content"
    fi
    
    # Output merged sections
    for category in "Added" "Changed" "Fixed"; do
        if [[ -n "${all_sections[$category]:-}" ]]; then
            merged+="### $category"$'\n'
            merged+="${all_sections[$category]}"$'\n'
        fi
    done
    
    echo "$merged" | sed '/^[[:space:]]*$/d'
}

detect_version_changes() {
    local since="${1:-1 day ago}"
    
    # Look for version-related files and tags
    local version_files=("VERSION" "version.txt" "package.json")
    local version_changes=""
    
    # Check for version file changes
    for file in "${version_files[@]}"; do
        if [[ -f "$file" ]] && git diff --name-only HEAD~1 2>/dev/null | grep -q "^$file$"; then
            local current_version
            if [[ "$file" == "VERSION" || "$file" == "version.txt" ]]; then
                current_version=$(cat "$file" 2>/dev/null | tr -d '\n')
            elif [[ "$file" == "package.json" ]]; then
                current_version=$(grep '"version"' "$file" | head -1 | sed 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            fi
            
            if [[ -n "$current_version" ]]; then
                version_changes="$current_version"
                break
            fi
        fi
    done
    
    # Check for recent tags if no version file changes
    if [[ -z "$version_changes" ]]; then
        local recent_tag
        recent_tag=$(git tag --sort=-creatordate --merged HEAD | head -1 2>/dev/null || true)
        if [[ -n "$recent_tag" ]]; then
            version_changes="$recent_tag"
        fi
    fi
    
    echo "$version_changes"
}

full_changelog_update() {
    local since="${1:-1 day ago}"
    local changelog_file="${2:-CHANGELOG.md}"
    
    # Validate environment
    validate_environment || return 1
    validate_repository || return 1
    
    # Generate new entries
    log_info "Analyzing commits since: $since"
    local new_entries
    new_entries=$(generate_changelog_entries --since="$since")
    
    if [[ -z "$new_entries" ]]; then
        log_info "No new entries to add to changelog"
        return 0
    fi
    
    # Preserve existing manual entries
    local merged_entries
    merged_entries=$(preserve_manual_entries "$new_entries" "$changelog_file")
    
    # Update the changelog file
    update_changelog_file "$merged_entries" "$changelog_file"
    
    # Validate the result
    if validate_changelog_format "$changelog_file"; then
        log_success "Successfully updated $changelog_file"
        return 0
    else
        log_error "Changelog validation failed after update"
        return 1
    fi
}

# ============================================================================
# Main Execution Function
# ============================================================================

main_execution() {
    local repo_root
    repo_root=$(discover_repository_root)
    cd "$repo_root"
    
    # Validate environment and repository
    validate_environment || return 1
    validate_repository || return 1
    
    # Discover changes
    local changed
    changed=$(discover_changes)
    
    # Generate discovery report
    generate_report "Discovery" "$changed"
    
    # Handle diff-only mode
    if is_diff_only_mode; then
        echo ""
        echo "# Git Diff Statistics"
        git --no-pager diff --stat HEAD
        return 0
    fi
    
    # Analyze documentation health
    local health_analysis
    health_analysis=$(analyze_documentation_health)
    
    # Generate proposals
    local proposals
    proposals=$(generate_proposals "$changed")
    
    # Output analysis results
    if [[ -n "$health_analysis" ]]; then
        echo ""
        echo "# Proposed Documentation Updates"
        echo "$health_analysis"
        
        if [[ -n "$proposals" ]]; then
            echo ""
            echo "$proposals" | sed 's/^/- /'
        fi
    else
        echo ""
        echo "# Proposed Documentation Updates"
        if [[ -n "$proposals" ]]; then
            echo "$proposals" | sed 's/^/- /'
        else
            echo "No documentation changes required."
        fi
    fi
    
    # Handle dry-run vs update modes
    if is_dry_run; then
        if [[ -n "$proposals" || -n "$health_analysis" ]]; then
            echo ""
            echo "Documentation updates required. Run without --dry-run to see details."
            return 2  # Exit code 2 indicates updates recommended
        fi
    elif is_update_mode; then
        log_info "Update mode enabled - would perform actual updates here"
        # TODO: Call update functions when implemented
    fi
    
    return 0
}