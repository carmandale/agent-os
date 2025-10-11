#!/bin/bash

# workflow-status.sh
# Check Agent OS workflow health and identify issues that need attention

# Note: We don't use 'set -e' because we want to collect all workflow issues
# and return a meaningful exit code at the end, rather than exiting early

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
VERBOSE=false
FIX_SUGGESTIONS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
		--verbose)
			VERBOSE=true
			shift
			;;
		--fix-suggestions)
			FIX_SUGGESTIONS=true
			shift
			;;
		*)
			echo "Unknown option: $1"
			exit 1
			;;
	esac
done

# Helper functions
print_status() {
	case "$1" in
		"success") echo -e "${GREEN}✅ $2${NC}" ;;
		"warning") echo -e "${YELLOW}⚠️  $2${NC}" ;;
		"error") echo -e "${RED}❌ $2${NC}" ;;
		"info") echo -e "${BLUE}ℹ️  $2${NC}" ;;
		"check") echo -e "${CYAN}🔍 $2${NC}" ;;
		*) echo "$2" ;;
	esac
}

print_section() {
	echo ""
	echo -e "${CYAN}$1${NC}"
	echo "$(printf '=%.0s' $(seq 1 ${#1}))"
}

# Issue counters
CRITICAL_ISSUES=0
WARNINGS=0
FIXES=()

# Function to add fix suggestion
add_fix() {
	if [ "$FIX_SUGGESTIONS" = true ]; then
		FIXES+=("$1")
	fi
}

# Check git status
check_git_status() {
	print_section "Git Status"
	
	# Check if in git repo
	if ! git rev-parse --git-dir >/dev/null 2>&1; then
		print_status "error" "Not in a git repository"
		((CRITICAL_ISSUES++))
		return
	fi
	
	# Check for uncommitted changes
	if [ -n "$(git status --porcelain)" ]; then
		local changes=$(git status --porcelain | wc -l | tr -d ' ')
		print_status "error" "Uncommitted changes: $changes files"
		((CRITICAL_ISSUES++))
		add_fix "git add -A && git commit -m \"feat: [description] #[issue]\""
		
		if [ "$VERBOSE" = true ]; then
			echo "   Modified files:"
			git status --porcelain | sed 's/^/   /'
		fi
	else
		print_status "success" "Working tree clean"
	fi
	
	# Check current branch
	local current_branch=$(git branch --show-current)
	if [ "$current_branch" != "main" ]; then
		print_status "warning" "Not on main branch (currently on: $current_branch)"
		((WARNINGS++))
		add_fix "git checkout main"
	else
		print_status "success" "On main branch"
	fi
	
	# Check if ahead/behind remote
	if git remote get-url origin >/dev/null 2>&1; then
		git fetch >/dev/null 2>&1 || true
		local ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
		local behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")
		
		if [ "$ahead" -gt 0 ]; then
			print_status "warning" "Ahead of remote by $ahead commits"
			((WARNINGS++))
			add_fix "git push origin $(git branch --show-current)"
		fi
		
		if [ "$behind" -gt 0 ]; then
			print_status "warning" "Behind remote by $behind commits"  
			((WARNINGS++))
			add_fix "git pull origin $(git branch --show-current)"
		fi
		
		if [ "$ahead" -eq 0 ] && [ "$behind" -eq 0 ]; then
			print_status "success" "Synchronized with remote"
		fi
	fi
}

# Check documentation status
check_documentation() {
	print_section "Documentation Status"
	
	# Check if update-documentation script exists
	if [ ! -f "$HOME/.agent-os/scripts/update-documentation.sh" ]; then
		print_status "error" "update-documentation script not found"
		((CRITICAL_ISSUES++))
		return
	fi
	
	# Run documentation check
	local doc_result
	if doc_result=$("$HOME/.agent-os/scripts/update-documentation.sh" --dry-run 2>&1); then
		if echo "$doc_result" | grep -q "No changes detected"; then
			print_status "success" "Documentation up to date"
		else
			print_status "warning" "Documentation drift detected"
			((WARNINGS++))
			add_fix "/update-documentation"
			
			if [ "$VERBOSE" = true ]; then
				echo "   Issues found:"
				echo "$doc_result" | grep -E "^-|^#" | sed 's/^/   /'
			fi
		fi
	else
		print_status "warning" "Documentation check had issues"
		((WARNINGS++))
	fi
	
	# Check CHANGELOG.md specifically
	if [ -f "CHANGELOG.md" ]; then
		local recent_commits=$(git log --oneline --since="7 days ago" | wc -l | tr -d ' ')
		local changelog_updates=$(git log --oneline --since="7 days ago" -- CHANGELOG.md | wc -l | tr -d ' ')
		
		if [ "$recent_commits" -gt 0 ] && [ "$changelog_updates" -eq 0 ]; then
			print_status "warning" "CHANGELOG.md not updated recently ($recent_commits recent commits)"
			((WARNINGS++))
			add_fix "Update CHANGELOG.md with recent work"
		else
			print_status "success" "CHANGELOG.md current"
		fi
	else
		print_status "warning" "CHANGELOG.md not found"
		((WARNINGS++))
	fi
}

# Check GitHub integration
check_github_status() {
	print_section "GitHub Integration"
	
	# Check if gh CLI is available
	if ! command -v gh >/dev/null 2>&1; then
		print_status "error" "GitHub CLI (gh) not installed"
		((CRITICAL_ISSUES++))
		return
	fi
	
	# Check authentication
	if ! gh auth status >/dev/null 2>&1; then
		print_status "error" "Not authenticated with GitHub"
		((CRITICAL_ISSUES++))
		add_fix "gh auth login"
		return
	fi
	
	# Check for open PRs
	local open_prs
	if open_prs=$(gh pr list --state open --json number,title 2>/dev/null); then
		local pr_count=$(echo "$open_prs" | jq length 2>/dev/null || echo "0")
		
		if [ "$pr_count" -gt 0 ]; then
			print_status "warning" "Open PRs need attention: $pr_count"
			((WARNINGS++))
			add_fix "gh pr list --state open"
			
			if [ "$VERBOSE" = true ] && [ "$pr_count" -le 5 ]; then
				echo "   Open PRs:"
				echo "$open_prs" | jq -r '.[] | "   #\(.number): \(.title)"' 2>/dev/null || echo "   (Unable to parse PR list)"
			fi
		else
			print_status "success" "No open PRs"
		fi
	fi
	
	# Check for issues that might need closing
	local recent_issues
	if recent_issues=$(gh issue list --state open --limit 10 --json number,title 2>/dev/null); then
		local issue_count=$(echo "$recent_issues" | jq length 2>/dev/null || echo "0")
		
		if [ "$issue_count" -gt 0 ]; then
			print_status "info" "Open issues to review: $issue_count"
			
			if [ "$VERBOSE" = true ] && [ "$issue_count" -le 5 ]; then
				echo "   Recent open issues:"
				echo "$recent_issues" | jq -r '.[] | "   #\(.number): \(.title)"' 2>/dev/null || echo "   (Unable to parse issues)"
			fi
		fi
	fi
}

# Check Agent OS status
check_agent_os_status() {
	print_section "Agent OS Status"

	# Check if aos command exists (try command in PATH first, then direct executable path)
	local aos_cmd=""
	if command -v aos >/dev/null 2>&1; then
		aos_cmd="aos"
	elif [ -x "$HOME/.agent-os/tools/aos" ]; then
		aos_cmd="$HOME/.agent-os/tools/aos"
	fi

	if [ -n "$aos_cmd" ]; then
		# Run aos status and parse output
		local aos_output
		if aos_output=$($aos_cmd status 2>/dev/null); then
			if echo "$aos_output" | grep -q "All components current"; then
				print_status "success" "Agent OS components current"
			else
				print_status "warning" "Agent OS components need attention"
				((WARNINGS++))
				add_fix "aos status"
			fi

			if echo "$aos_output" | grep -q "Integrity OK"; then
				print_status "success" "Agent OS integrity OK"
			else
				print_status "warning" "Agent OS integrity issues"
				((WARNINGS++))
			fi
		else
			print_status "warning" "Could not check Agent OS status"
			((WARNINGS++))
		fi
	else
		print_status "warning" "aos command not found"
		((WARNINGS++))
	fi
}

# Main execution
main() {
	echo -e "${CYAN}🔍 Agent OS Workflow Status Check${NC}"
	echo "=================================="
	
	check_git_status
	check_documentation
	check_github_status
	check_agent_os_status
	
	# Summary
	print_section "Summary"
	
	if [ $CRITICAL_ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ]; then
		print_status "success" "Workflow is healthy - ready for new work!"
	elif [ $CRITICAL_ISSUES -eq 0 ]; then
		print_status "info" "Workflow mostly healthy with $WARNINGS minor issues"
	else
		print_status "error" "Workflow has $CRITICAL_ISSUES critical issues and $WARNINGS warnings"
	fi
	
	# Show fix suggestions if requested
	if [ "$FIX_SUGGESTIONS" = true ] && [ ${#FIXES[@]} -gt 0 ]; then
		echo ""
		echo -e "${YELLOW}🔧 Suggested Fixes:${NC}"
		for fix in "${FIXES[@]}"; do
			echo "   → $fix"
		done
	fi
	
	# Exit with appropriate code
	if [ $CRITICAL_ISSUES -gt 0 ]; then
		exit 1
	elif [ $WARNINGS -gt 0 ]; then
		exit 2
	else
		exit 0
	fi
}

# Execute main function
main "$@"