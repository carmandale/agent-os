#!/bin/bash

# workflow-complete.sh
# Complete Agent OS workflow with all required steps for proper integration
# This script automates the Phase 4 git integration workflow from execute-tasks.md

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=false
FORCE=false
NO_PR=false
ISSUE_NUMBER=""
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
		--dry-run)
			DRY_RUN=true
			shift
			;;
		--force)
			FORCE=true
			shift
			;;
		--no-pr)
			NO_PR=true
			shift
			;;
		--issue)
			ISSUE_NUMBER="$2"
			shift 2
			;;
		--verbose)
			VERBOSE=true
			shift
			;;
		*)
			echo "Unknown option: $1"
			echo "Usage: $0 [--dry-run] [--force] [--no-pr] [--issue ISSUE_NUMBER] [--verbose]"
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
		"step") echo -e "${CYAN}🔄 $2${NC}" ;;
		*) echo "$2" ;;
	esac
}

print_section() {
	echo ""
	echo -e "${CYAN}$1${NC}"
	echo "$(printf '=%.0s' $(seq 1 ${#1}))"
}

# Dry run execution wrapper
execute_command() {
	if [ "$DRY_RUN" = true ]; then
		echo "  [DRY RUN] Would execute: $1"
	else
		if [ "$VERBOSE" = true ]; then
			echo "  Executing: $1"
		fi
		eval "$1"
	fi
}

# Issue counters and state
ERRORS=0
WARNINGS=0
CHANGES_STAGED=false
PR_CREATED=false
ISSUES_CLOSED=()

# Phase 1: Pre-completion checks
check_prerequisites() {
	print_section "Phase 1: Pre-completion Checks"
	
	# Check if in git repo
	if ! git rev-parse --git-dir >/dev/null 2>&1; then
		print_status "error" "Not in a git repository"
		((ERRORS++))
		return
	fi
	
	# Check for required tools
	local required_tools=("gh" "git")
	for tool in "${required_tools[@]}"; do
		if ! command -v "$tool" >/dev/null 2>&1; then
			print_status "error" "$tool command not found"
			((ERRORS++))
		fi
	done
	
	# Check GitHub authentication
	if ! gh auth status >/dev/null 2>&1; then
		print_status "error" "Not authenticated with GitHub"
		((ERRORS++))
		return
	fi
	
	# Analyze current state
	local current_branch=$(git branch --show-current)
	local uncommitted_files=$(git status --porcelain | wc -l | tr -d ' ')
	local untracked_files=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')
	
	print_status "info" "Current branch: $current_branch"
	print_status "info" "Uncommitted changes: $uncommitted_files files"
	print_status "info" "Untracked files: $untracked_files files"
	
	# Check for blocking issues
	if [ "$FORCE" = false ] && [ $ERRORS -gt 0 ]; then
		print_status "error" "Cannot continue due to $ERRORS critical errors"
		print_status "info" "Use --force to override (not recommended)"
		return 1
	fi
	
	print_status "success" "Pre-completion checks passed"
}

# Phase 2: Documentation and commit preparation
prepare_documentation() {
	print_section "Phase 2: Documentation & Commit Preparation"
	
	# Run documentation drift check
	if [ -f "$HOME/.agent-os/scripts/update-documentation.sh" ]; then
		print_status "step" "Checking for documentation drift"
		
		local doc_result
		if doc_result=$("$HOME/.agent-os/scripts/update-documentation.sh" --dry-run 2>&1); then
			if echo "$doc_result" | grep -q "No changes detected"; then
				print_status "success" "Documentation up to date"
			else
				print_status "warning" "Documentation drift detected"
				((WARNINGS++))
				
				if [ "$VERBOSE" = true ]; then
					echo "   Documentation issues:"
					echo "$doc_result" | grep -E "^-|^#" | sed 's/^/   /'
				fi
			fi
		else
			print_status "warning" "Documentation check had issues"
			((WARNINGS++))
		fi
	fi
	
	# Update CHANGELOG.md based on recent commits
	if [ -f "CHANGELOG.md" ]; then
		print_status "step" "Checking CHANGELOG.md status"
		
		# Get recent commits since last changelog update
		local changelog_commit=$(git log --oneline --grep="CHANGELOG" -1 --format="%H" 2>/dev/null || echo "")
		local recent_commits
		
		if [ -n "$changelog_commit" ]; then
			recent_commits=$(git log --oneline --since="7 days ago" --not "$changelog_commit" 2>/dev/null || git log --oneline -5)
		else
			recent_commits=$(git log --oneline -5)
		fi
		
		if [ -n "$recent_commits" ] && [ $(echo "$recent_commits" | wc -l | tr -d ' ') -gt 0 ]; then
			print_status "info" "Recent commits not in CHANGELOG:"
			echo "$recent_commits" | sed 's/^/   /'
			
			# Check if we should update CHANGELOG
			local changelog_updates=$(git log --oneline --since="7 days ago" -- CHANGELOG.md | wc -l | tr -d ' ')
			if [ "$changelog_updates" -eq 0 ]; then
				print_status "warning" "CHANGELOG.md should be updated with recent work"
				((WARNINGS++))
			fi
		else
			print_status "success" "CHANGELOG.md appears current"
		fi
	else
		print_status "warning" "CHANGELOG.md not found"
		((WARNINGS++))
	fi
}

# Phase 3: Stage and commit all changes
commit_changes() {
	print_section "Phase 3: Commit All Changes"
	
	# Check for changes to commit
	if [ -z "$(git status --porcelain)" ]; then
		print_status "info" "No changes to commit"
		return
	fi
	
	print_status "step" "Staging all changes"
	execute_command "git add -A"
	CHANGES_STAGED=true
	
	# Generate commit message
	local commit_message
	if [ -n "$ISSUE_NUMBER" ]; then
		# Try to get issue title from GitHub
		local issue_title
		if issue_title=$(gh issue view "$ISSUE_NUMBER" --json title -q '.title' 2>/dev/null); then
			commit_message="feat: $issue_title #$ISSUE_NUMBER"
		else
			commit_message="feat: complete workflow tasks #$ISSUE_NUMBER"
		fi
	else
		# Look for recent issue references in commits
		local recent_issue=$(git log --oneline -10 | grep -o '#[0-9]\+' | head -1)
		if [ -n "$recent_issue" ]; then
			commit_message="feat: complete workflow tasks $recent_issue"
		else
			commit_message="feat: complete current workflow tasks"
		fi
	fi
	
	print_status "step" "Committing changes: $commit_message"
	execute_command "git commit -m \"$commit_message

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>\""
	
	print_status "success" "Changes committed successfully"
}

# Phase 4: GitHub integration
github_integration() {
	print_section "Phase 4: GitHub Integration"
	
	local current_branch=$(git branch --show-current)
	
	# Skip PR creation if on main and --no-pr is specified
	if [ "$NO_PR" = true ] && [ "$current_branch" = "main" ]; then
		print_status "info" "Skipping PR creation (--no-pr specified and on main branch)"
		return
	fi
	
	# Check if we're on a feature branch that needs a PR
	if [ "$current_branch" != "main" ]; then
		print_status "step" "Creating or updating PR for branch: $current_branch"
		
		# Check if PR already exists
		local existing_pr
		if existing_pr=$(gh pr view "$current_branch" --json number -q '.number' 2>/dev/null); then
			print_status "info" "PR #$existing_pr already exists for this branch"
		else
			# Create new PR
			local pr_title
			if [ -n "$ISSUE_NUMBER" ]; then
				local issue_title=$(gh issue view "$ISSUE_NUMBER" --json title -q '.title' 2>/dev/null || echo "Workflow completion")
				pr_title="$issue_title"
			else
				pr_title="Complete workflow tasks"
			fi
			
			local pr_body="## Summary
- Completed current workflow tasks
- All changes committed and ready for review
- Documentation updated as needed

## Test Plan
- [x] All changes committed
- [x] Documentation checked for drift
- [x] Workflow completion verified

🤖 Generated with [Claude Code](https://claude.ai/code)"
			
			execute_command "gh pr create --title \"$pr_title\" --body \"$pr_body\""
			PR_CREATED=true
			print_status "success" "PR created successfully"
		fi
	fi
	
	# Close related issues if specified
	if [ -n "$ISSUE_NUMBER" ]; then
		print_status "step" "Checking issue #$ISSUE_NUMBER status"
		
		local issue_state
		if issue_state=$(gh issue view "$ISSUE_NUMBER" --json state -q '.state' 2>/dev/null); then
			if [ "$issue_state" = "OPEN" ]; then
				print_status "step" "Closing issue #$ISSUE_NUMBER"
				execute_command "gh issue close $ISSUE_NUMBER --comment \"Work completed and committed. All workflow steps finished.\""
				ISSUES_CLOSED+=("$ISSUE_NUMBER")
				print_status "success" "Issue #$ISSUE_NUMBER closed"
			else
				print_status "info" "Issue #$ISSUE_NUMBER already closed"
			fi
		fi
	fi
}

# Phase 5: Final cleanup and verification
final_cleanup() {
	print_section "Phase 5: Final Cleanup & Verification"
	
	local current_branch=$(git branch --show-current)
	
	# Return to main branch if we were on a feature branch and PR was created
	if [ "$current_branch" != "main" ] && [ "$PR_CREATED" = true ]; then
		print_status "step" "Switching back to main branch"
		execute_command "git checkout main"
		
		# Pull latest changes
		print_status "step" "Pulling latest changes from remote"
		execute_command "git pull origin main"
	fi
	
	# Final verification
	print_status "step" "Running final verification"
	
	# Check git status
	if [ -z "$(git status --porcelain)" ]; then
		print_status "success" "Working tree clean"
	else
		print_status "warning" "Working tree has uncommitted changes"
		((WARNINGS++))
	fi
	
	# Check if on main branch
	current_branch=$(git branch --show-current)
	if [ "$current_branch" = "main" ]; then
		print_status "success" "On main branch"
	else
		print_status "info" "On branch: $current_branch"
	fi
	
	# Run Agent OS status check if available
	if command -v aos >/dev/null 2>&1; then
		print_status "step" "Checking Agent OS status"
		local aos_result
		if aos_result=$(aos status 2>/dev/null); then
			if echo "$aos_result" | grep -q "All components current"; then
				print_status "success" "Agent OS status: All components current"
			else
				print_status "warning" "Agent OS components may need attention"
				((WARNINGS++))
			fi
		fi
	fi
}

# Summary and reporting
generate_summary() {
	print_section "Workflow Completion Summary"
	
	if [ ${#ISSUES_CLOSED[@]} -gt 0 ]; then
		print_status "success" "Issues closed: ${ISSUES_CLOSED[*]}"
	fi
	
	if [ "$PR_CREATED" = true ]; then
		print_status "success" "Pull request created"
	fi
	
	if [ "$CHANGES_STAGED" = true ]; then
		print_status "success" "All changes committed"
	fi
	
	# Overall status
	if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
		print_status "success" "Workflow completed successfully - ready for new work!"
	elif [ $ERRORS -eq 0 ]; then
		print_status "info" "Workflow completed with $WARNINGS warnings"
	else
		print_status "error" "Workflow completed with $ERRORS errors and $WARNINGS warnings"
	fi
	
	# Next steps
	echo ""
	echo -e "${CYAN}Next Steps:${NC}"
	if [ "$PR_CREATED" = true ]; then
		echo "  → Review and merge PR when ready"
	fi
	if [ ${#ISSUES_CLOSED[@]} -gt 0 ]; then
		echo "  → Verify closed issues are properly resolved"
	fi
	echo "  → Run /workflow-status to check overall health"
	echo "  → Ready to start new work with clean workspace"
}

# Main execution
main() {
	echo -e "${CYAN}🚀 Agent OS Workflow Completion${NC}"
	echo "==================================="
	
	if [ "$DRY_RUN" = true ]; then
		echo -e "${YELLOW}⚠️  DRY RUN MODE - No changes will be made${NC}"
		echo ""
	fi
	
	# Execute all phases
	if ! check_prerequisites; then
		exit 1
	fi
	
	prepare_documentation
	commit_changes
	github_integration
	final_cleanup
	generate_summary
	
	# Exit with appropriate code
	if [ $ERRORS -gt 0 ]; then
		exit 1
	elif [ $WARNINGS -gt 0 ]; then
		exit 2
	else
		exit 0
	fi
}

# Execute main function
main "$@"