#!/bin/bash
# workflow-status-example.sh
# Example implementation of workflow-status command using GitHub CLI and git worktree
# Based on research: docs/research/github-cli-worktree-integration.md

set -euo pipefail

# Configuration
CACHE_DIR="${HOME}/.agent-os/cache"
CACHE_TTL=300  # 5 minutes
VERBOSE="${VERBOSE:-false}"

# Colors
GREEN="\033[32m"
BLUE="\033[34m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# Utility functions
log_info() {
	echo -e "${BLUE}ℹ${RESET} $*" >&2
}

log_success() {
	echo -e "${GREEN}✓${RESET} $*" >&2
}

log_warning() {
	echo -e "${YELLOW}⚠${RESET} $*" >&2
}

log_error() {
	echo -e "${RED}✗${RESET} $*" >&2
}

# Check prerequisites
check_prerequisites() {
	# Check if in git repo
	if ! git rev-parse --git-dir &>/dev/null; then
		log_error "Not in a git repository"
		return 1
	fi

	# Check if gh CLI is installed
	if ! command -v gh &>/dev/null; then
		log_error "GitHub CLI (gh) is not installed"
		echo "Install from: https://cli.github.com" >&2
		return 1
	fi

	# Check if authenticated
	if ! gh auth status &>/dev/null; then
		log_error "Not authenticated with GitHub"
		echo "Run: gh auth login" >&2
		return 1
	fi

	return 0
}

# Parse issue number from branch name
parse_issue_from_branch() {
	local branch="$1"

	# Try #N pattern first (e.g., feature-#42-description)
	if [[ "$branch" =~ \#([0-9]+) ]]; then
		echo "${BASH_REMATCH[1]}"
		return 0
	fi

	# Try leading N pattern (e.g., 42-feature-name)
	if [[ "$branch" =~ ^([0-9]+)- ]]; then
		echo "${BASH_REMATCH[1]}"
		return 0
	fi

	return 1
}

# Get cache file path for current repo
get_cache_file() {
	mkdir -p "$CACHE_DIR"

	local repo_path
	repo_path=$(git rev-parse --show-toplevel)

	# Create cache key from repo path
	local cache_key
	cache_key=$(echo "$repo_path" | md5sum | cut -d' ' -f1 2>/dev/null || echo "$repo_path" | md5 | cut -d' ' -f1)

	echo "${CACHE_DIR}/pr_cache_${cache_key}.json"
}

# Check if cache is fresh
is_cache_fresh() {
	local cache_file="$1"
	local cache_ttl="$2"

	if [[ ! -f "$cache_file" ]]; then
		return 1
	fi

	# Get file modification time (cross-platform)
	local file_mtime
	if [[ "$OSTYPE" == "darwin"* ]]; then
		file_mtime=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
	else
		file_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
	fi

	local current_time
	current_time=$(date +%s)

	local cache_age=$((current_time - file_mtime))

	[[ $cache_age -lt $cache_ttl ]]
}

# Fetch PR data with caching
fetch_pr_data() {
	local cache_file
	cache_file=$(get_cache_file)

	# Check if cache is fresh
	if is_cache_fresh "$cache_file" "$CACHE_TTL"; then
		log_info "Using cached PR data ($(find "$cache_file" -mmin -$((CACHE_TTL / 60)) 2>/dev/null && echo "fresh" || echo "stale"))"
		cat "$cache_file"
		return 0
	fi

	# Fetch fresh data
	log_info "Fetching pull request data from GitHub..."

	local pr_data
	if ! pr_data=$(gh pr list --state all --limit 1000 --json number,headRefName,title,state,closingIssuesReferences 2>&1); then
		log_warning "Failed to fetch PR data: $pr_data"
		log_warning "Continuing with limited information..."

		# Return empty array if fetch fails
		echo "[]"
		return 1
	fi

	# Save to cache
	echo "$pr_data" > "$cache_file"

	local pr_count
	pr_count=$(echo "$pr_data" | jq '. | length')
	log_success "Fetched $pr_count pull requests"

	echo "$pr_data"
}

# Build branch-to-PR index
build_pr_index() {
	local pr_data="$1"

	# Use jq to create a map of branch -> pr info
	echo "$pr_data" | jq -r '.[] | "\(.headRefName)\t\(.number)\t\(.state)\t\(.title)\t\([ .closingIssuesReferences[].number ] | join(","))"'
}

# Get PR info for branch
get_pr_for_branch() {
	local branch="$1"
	local pr_index="$2"

	# Lookup in index
	echo "$pr_index" | grep "^${branch}	" || true
}

# Format PR state with color
format_pr_state() {
	local state="$1"

	case "$state" in
		OPEN)
			echo -e "${GREEN}${state}${RESET}"
			;;
		MERGED)
			echo -e "${BLUE}${state}${RESET}"
			;;
		CLOSED)
			echo -e "${RED}${state}${RESET}"
			;;
		*)
			echo "$state"
			;;
	esac
}

# Display worktree status
display_worktree_status() {
	local worktree_path="$1"
	local branch_name="$2"
	local head_sha="$3"
	local pr_index="$4"

	# Get relative path for display
	local relative_path
	relative_path=$(realpath --relative-to="$(pwd)" "$worktree_path" 2>/dev/null || echo "$worktree_path")

	echo ""
	echo "Worktree: $relative_path"
	echo "  Branch: $branch_name"
	echo "  Commit: ${head_sha:0:7}"

	# Try to parse issue from branch name
	local issue_num
	if issue_num=$(parse_issue_from_branch "$branch_name"); then
		echo "  Issue: #$issue_num (inferred from branch name)"
	fi

	# Lookup PR
	local pr_info
	pr_info=$(get_pr_for_branch "$branch_name" "$pr_index")

	if [[ -n "$pr_info" ]]; then
		# Parse PR info (tab-separated)
		IFS=$'\t' read -r _branch pr_number pr_state pr_title issue_numbers <<< "$pr_info"

		echo -n "  PR: #$pr_number ("
		format_pr_state "$pr_state"
		echo ")"

		if [[ "$VERBOSE" == "true" ]]; then
			echo "  Title: $pr_title"
		fi

		# Show linked issues
		if [[ -n "$issue_numbers" && "$issue_numbers" != "null" ]]; then
			echo "  Closes Issues: #${issue_numbers//,/, #}"
		fi
	else
		echo "  PR: None found"
	fi
}

# Parse and display all worktrees
parse_worktrees() {
	local pr_data="$1"

	# Build PR index
	log_info "Building PR index..."
	local pr_index
	pr_index=$(build_pr_index "$pr_data")

	# Parse worktrees
	local current_worktree=""
	local current_branch=""
	local current_head=""
	local worktree_count=0

	while IFS= read -r line; do
		if [[ -z "$line" ]]; then
			# End of worktree record
			if [[ -n "$current_worktree" ]]; then
				display_worktree_status "$current_worktree" "$current_branch" "$current_head" "$pr_index"
				((worktree_count++))
			fi

			# Reset
			current_worktree=""
			current_branch=""
			current_head=""
		elif [[ "$line" =~ ^worktree\ (.+)$ ]]; then
			current_worktree="${BASH_REMATCH[1]}"
		elif [[ "$line" =~ ^HEAD\ (.+)$ ]]; then
			current_head="${BASH_REMATCH[1]}"
		elif [[ "$line" =~ ^branch\ refs/heads/(.+)$ ]]; then
			current_branch="${BASH_REMATCH[1]}"
		elif [[ "$line" == "detached" ]]; then
			current_branch="(detached)"
		fi
	done < <(git worktree list --porcelain)

	# Handle last worktree if no trailing newline
	if [[ -n "$current_worktree" ]]; then
		display_worktree_status "$current_worktree" "$current_branch" "$current_head" "$pr_index"
		((worktree_count++))
	fi

	echo ""
	log_success "Total worktrees: $worktree_count"
}

# Clear cache
clear_cache() {
	local cache_file
	cache_file=$(get_cache_file)

	if [[ -f "$cache_file" ]]; then
		rm "$cache_file"
		log_success "Cache cleared"
	else
		log_info "No cache to clear"
	fi
}

# Main function
main() {
	# Parse arguments
	local force_refresh=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--refresh|-r)
				force_refresh=true
				shift
				;;
			--verbose|-v)
				VERBOSE=true
				shift
				;;
			--clear-cache)
				clear_cache
				exit 0
				;;
			--help|-h)
				cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Display status of git worktrees with associated GitHub issues and pull requests.

Options:
  --refresh, -r        Force refresh of cached PR data
  --verbose, -v        Show detailed information
  --clear-cache        Clear cached PR data
  --help, -h           Show this help message

Environment Variables:
  VERBOSE              Set to 'true' for verbose output

Example:
  $(basename "$0") --verbose
  VERBOSE=true $(basename "$0")

EOF
				exit 0
				;;
			*)
				log_error "Unknown option: $1"
				echo "Use --help for usage information" >&2
				exit 1
				;;
		esac
	done

	# Check prerequisites
	if ! check_prerequisites; then
		exit 1
	fi

	# Clear cache if force refresh
	if [[ "$force_refresh" == "true" ]]; then
		clear_cache
	fi

	# Fetch PR data
	local pr_data
	pr_data=$(fetch_pr_data)

	# Parse and display worktrees
	parse_worktrees "$pr_data"
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
