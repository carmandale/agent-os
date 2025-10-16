#!/usr/bin/env bash

# workflow-merge.sh
# Intelligent PR merge automation with safety checks and worktree cleanup
# Part of Agent OS workflow automation

set -euo pipefail

# Color codes for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Global configuration
DRY_RUN=false
FORCE=false
AUTO_MERGE=false
MERGE_STRATEGY="merge"  # merge, squash, or rebase
PR_NUMBER=""
VERBOSE=false

# State tracking
ERRORS=0
WARNINGS=0
IN_WORKTREE=false
WORKTREE_PATH=""
MAIN_REPO_PATH=""
MERGE_SUCCEEDED=false
BRANCH_NAME=""

# Parse command-line arguments
parse_arguments() {
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
			--auto)
				AUTO_MERGE=true
				shift
				;;
			--strategy)
				# SECURITY: Validate merge strategy parameter
				case "$2" in
					merge|squash|rebase)
						MERGE_STRATEGY="$2"
						;;
					*)
						print_error "Invalid merge strategy: $2"
						print_info "Valid options: merge, squash, rebase"
						exit 1
						;;
				esac
				shift 2
				;;
			--verbose)
				VERBOSE=true
				shift
				;;
			--help)
				show_help
				exit 0
				;;
			-*)
				print_error "Unknown option: $1"
				show_help
				exit 1
				;;
			*)
				# SECURITY: Validate PR number is numeric only
				if [[ "$1" =~ ^[0-9]+$ ]]; then
					if [[ ${#1} -gt 10 ]]; then
						print_error "PR number too long: $1 (max 10 digits)"
						exit 1
					fi
					PR_NUMBER="$1"
				else
					print_error "Invalid PR number: $1 (must contain only digits)"
					print_info "Example: /merge 123"
					exit 1
				fi
				shift
				;;
		esac
	done
}

# Display help text
show_help() {
	cat <<EOF
Usage: workflow-merge.sh [OPTIONS] [PR_NUMBER]

Intelligently merge pull requests with safety checks and worktree cleanup.

OPTIONS:
  --dry-run             Show what would happen without executing
  --force               Skip validation checks (use with caution)
  --auto                Enable GitHub auto-merge (merge when checks pass)
  --strategy STRATEGY   Merge strategy: merge (default), squash, or rebase
  --verbose             Show detailed output
  --help                Display this help message

ARGUMENTS:
  PR_NUMBER             PR number to merge (optional, will infer from branch)

EXAMPLES:
  workflow-merge.sh                    # Infer PR from current branch
  workflow-merge.sh 123                # Merge PR #123
  workflow-merge.sh --dry-run          # Preview merge without executing
  workflow-merge.sh --strategy squash  # Merge with squash strategy
  workflow-merge.sh --auto 123         # Enable auto-merge for PR #123

WORKFLOW:
  1. PR Inference - Determine which PR to merge
  2. User Confirmation - Confirm PR details before proceeding
  3. Pre-Merge Validation - Check CI, reviews, conflicts
  4. Review Feedback - Optionally address CodeRabbit/Codex comments
  5. Merge Execution - Execute merge via GitHub CLI
  6. Worktree Cleanup - Clean up worktree if applicable

For more information, see: commands/workflow-merge.md
EOF
}

# Helper functions for output
print_error() {
	echo -e "${RED}❌ $1${NC}" >&2
}

print_success() {
	echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
	echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
	echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
	echo -e "${CYAN}🔄 $1${NC}"
}

print_section() {
	echo ""
	echo -e "${CYAN}$1${NC}"
	# Portable alternative to seq (works on macOS and Linux)
	printf '%*s\n' "${#1}" '' | tr ' ' '='
}

# Dry run execution wrapper
# SECURITY: Uses direct execution to prevent command injection
execute_command() {
	if [[ "$DRY_RUN" == "true" ]]; then
		printf '  [DRY RUN] Would execute:'
		printf ' %q' "$@"
		echo
		return 0
	else
		if [[ "$VERBOSE" == "true" ]]; then
			printf '  Executing:'
			printf ' %q' "$@"
			echo
		fi
		"$@"
	fi
}

# Check prerequisites
check_prerequisites() {
	print_section "Prerequisites Check"

	local checks_passed=0
	local checks_total=4

	# Check if in git repo
	if ! git rev-parse --git-dir >/dev/null 2>&1; then
		print_error "Not in a git repository"
		((ERRORS++))
		return 1
	fi
	((checks_passed++))
	print_success "Git repository detected"

	# Check for required tools
	local required_tools=("gh" "git" "jq")
	for tool in "${required_tools[@]}"; do
		if ! command -v "$tool" >/dev/null 2>&1; then
			print_error "$tool command not found (install with: brew install $tool)"
			((ERRORS++))
		else
			((checks_passed++))
		fi
	done

	# Check GitHub authentication
	if ! gh auth status >/dev/null 2>&1; then
		print_error "Not authenticated with GitHub (run: gh auth login)"
		((ERRORS++))
		return 1
	fi
	print_success "GitHub authentication verified"

	if [[ $ERRORS -gt 0 ]]; then
		return 1
	fi

	echo ""
	print_success "Ready to proceed - all systems configured correctly"
	return 0
}

# Infer PR number from context
infer_pr_number() {
	print_section "PR Inference"

	# Priority 1: Explicit argument
	if [[ -n "$PR_NUMBER" ]]; then
		print_info "Using explicitly specified PR #$PR_NUMBER"
		return 0
	fi

	# Priority 2: Current branch
	local branch
	branch=$(git branch --show-current)
	print_info "Current branch: $branch"

	# Try to find PR from current branch
	local pr_from_branch
	pr_from_branch=$(gh pr list --head "$branch" --json number --jq '.[0].number' 2>/dev/null || echo "")

	if [[ -n "$pr_from_branch" ]]; then
		PR_NUMBER="$pr_from_branch"
		print_success "Inferred PR #$PR_NUMBER from branch '$branch'"
		return 0
	fi

	# Priority 3: Extract issue number from branch name patterns
	local issue_number=""

	# Pattern: issue-123 or #123
	if [[ $branch =~ issue-([0-9]+) ]] || [[ $branch =~ \#([0-9]+) ]]; then
		issue_number="${BASH_REMATCH[1]}"
	# Pattern: 123-feature-name
	elif [[ $branch =~ ^([0-9]+)- ]]; then
		issue_number="${BASH_REMATCH[1]}"
	# Pattern: feature-123-description
	elif [[ $branch =~ (feature|bugfix|hotfix)-([0-9]+) ]]; then
		issue_number="${BASH_REMATCH[2]}"
	fi

	if [[ -n "$issue_number" ]]; then
		# Search for PR with this issue number
		local pr_from_issue
		pr_from_issue=$(gh pr list --search "$issue_number in:title" --json number --jq '.[0].number' 2>/dev/null || echo "")

		if [[ -n "$pr_from_issue" ]]; then
			PR_NUMBER="$pr_from_issue"
			print_success "Inferred PR #$PR_NUMBER from issue number in branch name"
			return 0
		fi
	fi

	# Could not infer
	print_error "Could not infer PR number"
	print_info "Please specify PR number: workflow-merge.sh <pr_number>"
	((ERRORS++))
	return 1
}

# Confirm merge with user
confirm_merge() {
	print_section "Merge Confirmation"

	# Fetch PR details
	local pr_data
	pr_data=$(gh pr view "$PR_NUMBER" --json number,title,author,state,isDraft,headRefName 2>/dev/null) || {
		print_error "PR #$PR_NUMBER not found"
		((ERRORS++))
		return 1
	}

	local pr_title
	local pr_author
	local pr_state
	local is_draft
	local branch_name

	pr_title=$(echo "$pr_data" | jq -r '.title')
	pr_author=$(echo "$pr_data" | jq -r '.author.login')
	pr_state=$(echo "$pr_data" | jq -r '.state')
	is_draft=$(echo "$pr_data" | jq -r '.isDraft')
	branch_name=$(echo "$pr_data" | jq -r '.headRefName')

	# Display PR information
	echo ""
	echo -e "${CYAN}PR #$PR_NUMBER:${NC} $pr_title"
	echo -e "${BLUE}Author:${NC} $pr_author"
	echo -e "${BLUE}Branch:${NC} $branch_name"
	echo -e "${BLUE}State:${NC} $pr_state"
	echo -e "${BLUE}Strategy:${NC} $MERGE_STRATEGY"

	# Check if PR is in valid state
	if [[ "$pr_state" != "OPEN" ]]; then
		print_error "PR is not open (state: $pr_state)"
		((ERRORS++))
		return 1
	fi

	if [[ "$is_draft" == "true" ]]; then
		print_warning "PR is marked as draft"
		if [[ "$FORCE" != "true" ]]; then
			print_error "Cannot merge draft PR (use --force to override)"
			((ERRORS++))
			return 1
		fi
	fi

	# Confirmation prompt (skip in dry-run or force mode)
	if [[ "$DRY_RUN" != "true" ]] && [[ "$FORCE" != "true" ]]; then
		echo ""
		read -p "Proceed with merge? [Y/n]: " -r response
		response=${response:-Y}

		if [[ ! "$response" =~ ^[Yy]$ ]]; then
			print_info "Merge cancelled by user"
			exit 0
		fi
	fi

	print_success "Merge confirmed for PR #$PR_NUMBER"
	return 0
}

# Check workspace is clean before merge (prevents data loss)
check_workspace_cleanliness() {
	# Only check if we're in a worktree and not using auto-merge
	if [[ "$IN_WORKTREE" != "true" ]] || [[ "$AUTO_MERGE" == "true" ]]; then
		return 0
	fi

	print_section "Workspace Check"

	# Check for uncommitted changes
	if [[ -n "$(git status --porcelain)" ]]; then
		echo ""
		print_info "I noticed you have uncommitted changes in your workspace:"
		echo ""
		git status --short | sed 's/^/  /'
		echo ""
		print_info "Before we merge, we need a clean workspace. This prevents your changes from getting"
		print_info "trapped in the worktree after we delete the remote branch."
		echo ""
		print_success "Here's how I can help:"
		echo ""
		echo "  → Commit these changes? (if they belong in this PR)"
		echo "    Just ask: 'commit these changes'"
		echo ""
		echo "  → Stash for later? (if they're experimental work)"
		echo "    Just ask: 'stash these changes'"
		echo ""
		echo "  → Use auto-merge instead? (I'll merge when workspace is clean later)"
		echo "    Rerun: /workflow-merge --auto $PR_NUMBER"
		echo ""
		print_warning "Pausing merge until workspace is ready"
		((ERRORS++))
		return 1
	fi

	print_success "Workspace is clean - ready to merge safely"
	return 0
}

# Validate PR is ready to merge
validate_merge_readiness() {
	print_section "Pre-Merge Validation"

	local validation_errors=()

	# Fetch PR status
	local pr_checks
	pr_checks=$(gh pr view "$PR_NUMBER" --json reviewDecision,mergeable,mergeStateStatus 2>/dev/null) || {
		print_error "Failed to fetch PR status"
		((ERRORS++))
		return 1
	}

	local review_decision
	local mergeable
	local merge_state

	review_decision=$(echo "$pr_checks" | jq -r '.reviewDecision // "NONE"')
	mergeable=$(echo "$pr_checks" | jq -r '.mergeable')
	merge_state=$(echo "$pr_checks" | jq -r '.mergeStateStatus')

	# Check 1: Review Status
	print_step "Checking review status..."
	if [[ "$review_decision" == "APPROVED" ]]; then
		print_success "Reviews: Approved"
	elif [[ "$review_decision" == "NONE" ]] || [[ "$review_decision" == "REVIEW_REQUIRED" ]]; then
		if [[ "$FORCE" != "true" ]]; then
			validation_errors+=("Reviews required but not received")
			print_warning "Reviews: None received"
		else
			print_warning "Reviews: None (bypassed with --force)"
		fi
	else
		validation_errors+=("Review status: $review_decision")
		print_warning "Reviews: $review_decision"
	fi

	# Check 2: Merge Conflicts
	print_step "Checking for merge conflicts..."
	if [[ "$mergeable" == "MERGEABLE" ]]; then
		print_success "No merge conflicts"
	elif [[ "$mergeable" == "CONFLICTING" ]]; then
		validation_errors+=("Merge conflicts detected")
		print_error "Merge conflicts present"
	else
		print_warning "Mergeable status: $mergeable"
	fi

	# Check 3: CI/CD Checks
	print_step "Checking CI/CD status..."
	local checks_output
	checks_output=$(gh pr checks "$PR_NUMBER" 2>/dev/null || echo "")

	if [[ -n "$checks_output" ]]; then
		local failing_checks
		failing_checks=$(echo "$checks_output" | grep -E "fail|error" -i || echo "")

		if [[ -n "$failing_checks" ]]; then
			if [[ "$FORCE" != "true" ]]; then
				validation_errors+=("Failing CI checks")
				print_error "Some checks are failing:"
				echo "$failing_checks" | sed 's/^/  /'
			else
				print_warning "Some checks failing (bypassed with --force)"
			fi
		else
			print_success "All CI checks passing"
		fi
	else
		print_info "No CI checks configured"
	fi

	# Check 4: Branch Protection
	print_step "Checking branch protection..."
	if [[ "$merge_state" == "BLOCKED" ]]; then
		validation_errors+=("Branch protection rules not satisfied")
		print_error "Merge blocked by branch protection"
	elif [[ "$merge_state" == "CLEAN" ]] || [[ "$merge_state" == "UNSTABLE" ]]; then
		print_success "Branch protection satisfied"
	else
		print_warning "Merge state: $merge_state"
	fi

	# Report validation results
	if [[ ${#validation_errors[@]} -gt 0 ]]; then
		echo ""
		print_error "Pre-merge validation failed with ${#validation_errors[@]} issues:"
		printf '  • %s\n' "${validation_errors[@]}"

		if [[ "$FORCE" == "true" ]]; then
			print_warning "Proceeding anyway due to --force flag"
			((WARNINGS++))
		else
			print_info "Fix issues above or use --force to override (not recommended)"
			((ERRORS++))
			return 1
		fi
	else
		print_success "All pre-merge validation checks passed"
	fi

	return 0
}

# Execute the merge
execute_merge() {
	print_section "Merge Execution"

	# Get branch name for later deletion
	BRANCH_NAME=$(gh pr view "$PR_NUMBER" --json headRefName --jq '.headRefName' 2>/dev/null || echo "")

	if [[ "$AUTO_MERGE" == "true" ]]; then
		print_step "Enabling GitHub auto-merge..."
		execute_command gh pr merge "$PR_NUMBER" --auto "--$MERGE_STRATEGY"
		print_success "Auto-merge enabled - will merge when all checks pass"
		print_info "Skipping worktree cleanup (PR not merged yet)"
		return 0
	fi

	print_step "Merging PR #$PR_NUMBER with strategy: $MERGE_STRATEGY"

	# Execute merge WITHOUT automatic branch deletion
	# Branch will be deleted after successful cleanup
	if execute_command gh pr merge "$PR_NUMBER" "--$MERGE_STRATEGY"; then
		print_success "PR #$PR_NUMBER merged successfully"
		MERGE_SUCCEEDED=true

		# Verify merge commit
		if [[ "$DRY_RUN" != "true" ]]; then
			local merge_commit
			merge_commit=$(gh pr view "$PR_NUMBER" --json mergeCommit --jq '.mergeCommit.oid' 2>/dev/null || echo "")

			if [[ -n "$merge_commit" ]]; then
				print_info "Merge commit: $merge_commit"
			fi
		fi

		return 0
	else
		print_error "Merge failed"
		((ERRORS++))
		return 1
	fi
}

# Detect if running in a worktree
detect_worktree() {
	local current_dir
	current_dir=$(pwd)

	local worktree_list
	worktree_list=$(git worktree list --porcelain 2>/dev/null || echo "")

	if [[ -z "$worktree_list" ]]; then
		return 1
	fi

	# Parse worktree list to find if current directory is a worktree
	local in_worktree=false
	local worktree_path=""
	local main_path=""

	while IFS= read -r line; do
		if [[ $line =~ ^worktree\ (.*)$ ]]; then
			worktree_path="${BASH_REMATCH[1]}"

			if [[ "$worktree_path" == "$current_dir" ]]; then
				in_worktree=true
			fi

			if [[ -z "$main_path" ]]; then
				main_path="$worktree_path"
			fi
		fi
	done <<< "$worktree_list"

	if [[ "$in_worktree" == "true" ]]; then
		IN_WORKTREE=true
		WORKTREE_PATH="$current_dir"
		MAIN_REPO_PATH="$main_path"
		return 0
	fi

	return 1
}

# Clean up worktree after successful merge
cleanup_worktree() {
	if [[ "$IN_WORKTREE" != "true" ]]; then
		print_info "Not in a worktree, skipping cleanup"
		return 0
	fi

	print_section "Worktree Cleanup"

	print_step "Detected worktree: $WORKTREE_PATH"
	print_step "Main repository: $MAIN_REPO_PATH"

	# Check for uncommitted changes
	if [[ -n "$(git status --porcelain)" ]]; then
		print_warning "Worktree has uncommitted changes"
		print_error "Cannot remove worktree with uncommitted work"
		print_info "Commit or stash changes before cleanup"
		((ERRORS++))
		return 1
	fi

	# Return to main repository
	print_step "Returning to main repository..."
	if execute_command cd "$MAIN_REPO_PATH"; then
		print_success "Switched to main repository"
	fi

	# Detect default branch (don't assume 'main')
	local default_branch
	default_branch=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || echo "")
	if [[ -z "$default_branch" ]]; then
		# Fallback: check git's symbolic ref
		default_branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || echo "main")
	fi

	# Checkout default branch
	print_step "Switching to $default_branch branch..."
	execute_command git checkout "$default_branch"

	# Update default branch
	print_step "Fetching latest changes..."
	execute_command git fetch origin

	print_step "Pulling $default_branch branch..."
	execute_command git pull origin "$default_branch"

	# Verify merge is present
	if [[ "$DRY_RUN" != "true" ]]; then
		local recent_merge
		recent_merge=$(git log --oneline -5 --grep="Merge pull request" 2>/dev/null || echo "")

		if [[ -n "$recent_merge" ]]; then
			print_success "Merge verified in main:"
			echo "$recent_merge" | head -1 | sed 's/^/  /'
		else
			print_warning "Recent merge not found in main (may take time to sync)"
		fi
	fi

	# Remove worktree
	print_step "Removing worktree: $WORKTREE_PATH"
	if execute_command git worktree remove "$WORKTREE_PATH"; then
		print_success "Worktree removed"
	else
		print_error "Failed to remove worktree"
		print_info "Manual cleanup: git worktree remove \"$WORKTREE_PATH\""
		((ERRORS++))
		return 1
	fi

	# Prune metadata
	print_step "Pruning worktree metadata..."
	execute_command git worktree prune
	print_success "Worktree metadata pruned"

	return 0
}

# Delete remote branch after successful merge
delete_remote_branch() {
	if [[ -z "$BRANCH_NAME" ]]; then
		print_warning "Branch name unknown, cannot delete"
		return 1
	fi

	print_step "Deleting remote branch: $BRANCH_NAME"

	if execute_command gh api -X DELETE "repos/:owner/:repo/git/refs/heads/$BRANCH_NAME"; then
		print_success "Remote branch deleted"
		return 0
	else
		print_warning "Could not delete remote branch"
		print_info "Manual deletion: gh api -X DELETE \"repos/:owner/:repo/git/refs/heads/$BRANCH_NAME\""
		return 1
	fi
}

# Orchestrate cleanup and branch deletion after successful merge
cleanup_after_merge() {
	if [[ "$MERGE_SUCCEEDED" != "true" ]]; then
		return 0  # Nothing to clean up
	fi

	# If not in worktree, safe to delete branch immediately
	if [[ "$IN_WORKTREE" != "true" ]]; then
		delete_remote_branch
		return 0
	fi

	# In worktree - cleanup first, THEN delete branch
	print_section "Post-Merge Cleanup"

	if cleanup_worktree; then
		print_success "Worktree cleaned up successfully"
		delete_remote_branch
		return 0
	else
		print_warning "Worktree cleanup failed"
		print_info ""
		print_info "Your PR is merged, but local cleanup incomplete"
		print_info ""
		print_info "📋 Remote branch preserved for recovery:"
		print_info "   Branch: $BRANCH_NAME"
		print_info ""
		print_info "📋 Manual cleanup steps:"
		print_info "   1. Fix the issue preventing cleanup"
		print_info "   2. cd \"$MAIN_REPO_PATH\""
		print_info "   3. git worktree remove \"$WORKTREE_PATH\""
		print_info "   4. gh api -X DELETE \"repos/:owner/:repo/git/refs/heads/$BRANCH_NAME\""
		print_info ""
		((WARNINGS++))
		return 1
	fi
}

# Generate summary report
generate_summary() {
	print_section "Merge Summary"

	if [[ "$DRY_RUN" == "true" ]]; then
		print_info "DRY RUN MODE - No changes were made"
		echo ""
		print_info "Actual merge would:"
		echo "  • Merge PR #$PR_NUMBER with $MERGE_STRATEGY strategy"
		if [[ "$IN_WORKTREE" == "true" ]]; then
			echo "  • Clean up worktree: $WORKTREE_PATH"
		fi
		echo "  • Update local main branch"
	else
		if [[ "$AUTO_MERGE" == "true" ]]; then
			print_success "Auto-merge enabled for PR #$PR_NUMBER"
			print_info "PR will merge automatically when all checks pass"
		else
			print_success "PR #$PR_NUMBER merged successfully"
		fi

		if [[ "$IN_WORKTREE" == "true" ]]; then
			print_success "Worktree cleaned up"
			print_success "Returned to main repository"
		fi

		print_success "Local main branch updated"
	fi

	# Overall status
	echo ""
	if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
		print_success "Merge workflow completed successfully!"
	elif [[ $ERRORS -eq 0 ]]; then
		print_warning "Merge completed with $WARNINGS warnings"
	else
		print_error "Merge failed with $ERRORS errors and $WARNINGS warnings"
		return 1
	fi

	# Next steps
	if [[ "$DRY_RUN" != "true" ]] && [[ "$AUTO_MERGE" != "true" ]]; then
		echo ""
		echo -e "${CYAN}Next Steps:${NC}"
		echo "  → Run /workflow-status to verify clean state"
		echo "  → Start new work on main branch"
	fi

	return 0
}

# Main execution function
main() {
	echo -e "${CYAN}🔀 Agent OS PR Merge Automation${NC}"
	echo "====================================="
	echo ""

	# Parse arguments
	parse_arguments "$@"

	if [[ "$DRY_RUN" == "true" ]]; then
		echo -e "${YELLOW}⚠️  DRY RUN MODE - No changes will be made${NC}"
		echo ""
	fi

	# Execute workflow phases
	if ! check_prerequisites; then
		exit 1
	fi

	if ! infer_pr_number; then
		exit 1
	fi

	# Detect worktree context early (needed for workspace check)
	detect_worktree

	# Check workspace is clean BEFORE merge (prevents data loss)
	if ! check_workspace_cleanliness; then
		exit 1
	fi

	if ! confirm_merge; then
		exit 1
	fi

	if ! validate_merge_readiness; then
		exit 1
	fi

	# TODO: Phase 2 - Review feedback analysis
	# analyze_review_feedback

	if ! execute_merge; then
		exit 1
	fi

	# Cleanup worktree and delete branch (already detected earlier)
	if [[ "$AUTO_MERGE" != "true" ]]; then
		cleanup_after_merge || {
			# Non-fatal: PR merged, cleanup partial
			print_section "Merge Completed with Warnings"
			print_warning "PR merged successfully but cleanup incomplete"
			print_info "See recovery instructions above"

			# Generate summary even with warnings
			generate_summary
			exit 2  # Warning exit code
		}
	fi

	# Generate summary
	if ! generate_summary; then
		exit 1
	fi

	# Exit with appropriate code
	if [[ $ERRORS -gt 0 ]]; then
		echo ""
		print_info "Merge workflow paused - please address the issues above"
		exit 1
	elif [[ $WARNINGS -gt 0 ]]; then
		exit 2
	else
		exit 0
	fi
}

# Execute main function
main "$@"
