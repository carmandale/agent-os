# Technical Specification: Merge Command

> **Spec:** 2025-10-13-merge-command-#100
> **Last Updated:** 2025-10-13

## Architecture Overview

### Command Structure

**Location:** `commands/workflow-merge.md` (markdown command file)
**Script:** `scripts/workflow-merge.sh` (main execution logic)
**Libraries:** Leverage existing `workflow-status.sh`, `workflow-complete.sh` patterns

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    /merge Command Entry                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              1. PR Inference Engine                          │
│  • Parse conversation history for PR mentions                │
│  • Check current branch against GitHub PRs                   │
│  • Extract issue number from branch name                     │
│  • Return most recent PR if multiple found                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              2. User Confirmation                            │
│  • Display: "Merge PR #XX: [title]?"                        │
│  • Show branch, author, status summary                       │
│  • Await user approval                                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              3. Pre-Merge Validator                          │
│  • Check CI/CD status via gh pr checks                       │
│  • Verify review approval via gh pr view                     │
│  • Check for merge conflicts                                 │
│  • Validate branch protection rules                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              4. Review Feedback Analyzer                     │
│  • Query CodeRabbit comments via GitHub API                  │
│  • Query Codex comments if applicable                        │
│  • Categorize: critical vs suggestions                       │
│  • Present to user with context                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              5. Merge Executor                               │
│  • Execute: gh pr merge --merge --delete-branch              │
│  • Verify merge commit on main                               │
│  • Handle merge queue scenarios                              │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              6. Worktree Cleanup                             │
│  • Detect if in worktree                                     │
│  • Return to main repository                                 │
│  • Fetch and pull latest                                     │
│  • Verify merge present locally                              │
│  • Remove worktree: git worktree remove                      │
│  • Prune metadata: git worktree prune                        │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. PR Inference Engine

**Function:** `infer_pr_number()`

**Logic:**
```bash
infer_pr_number() {
	local pr_number=""

	# Priority 1: Explicit argument
	if [[ -n "$1" ]]; then
		pr_number="$1"
		return 0
	fi

	# Priority 2: Current branch
	local branch=$(git branch --show-current)
	pr_number=$(gh pr list --head "$branch" --json number --jq '.[0].number')
	if [[ -n "$pr_number" ]]; then
		return 0
	fi

	# Priority 3: Extract issue from branch name
	if [[ $branch =~ issue-([0-9]+) ]] || \
	   [[ $branch =~ ^([0-9]+)- ]] || \
	   [[ $branch =~ (feature|bugfix|hotfix)-([0-9]+) ]]; then
		local issue="${BASH_REMATCH[1]}"
		pr_number=$(gh pr list --search "$issue" --json number --jq '.[0].number')
		if [[ -n "$pr_number" ]]; then
			return 0
		fi
	fi

	# Priority 4: Most recent PR from conversation (future: AI context parsing)

	echo "❌ Could not infer PR number. Please specify: /merge <pr_number>"
	return 1
}
```

**Dependencies:**
- `gh pr list` - GitHub CLI
- `git branch --show-current` - Git

### 2. Pre-Merge Validator

**Function:** `validate_merge_readiness(pr_number)`

**Checks:**
```bash
validate_merge_readiness() {
	local pr_number="$1"
	local errors=()

	# Check 1: Review Status
	local review_decision=$(gh pr view "$pr_number" --json reviewDecision --jq '.reviewDecision')
	if [[ "$review_decision" != "APPROVED" ]] && [[ "$review_decision" != "REVIEW_REQUIRED" ]]; then
		errors+=("Review required: $review_decision")
	fi

	# Check 2: Merge Conflicts
	local mergeable=$(gh pr view "$pr_number" --json mergeable --jq '.mergeable')
	if [[ "$mergeable" != "MERGEABLE" ]]; then
		errors+=("Merge conflicts detected")
	fi

	# Check 3: CI Checks
	local check_status=$(gh pr checks "$pr_number" --json state --jq '.[] | select(.state != "SUCCESS") | .name')
	if [[ -n "$check_status" ]]; then
		errors+=("Failing checks: $check_status")
	fi

	# Check 4: Branch Protection
	local merge_state=$(gh pr view "$pr_number" --json mergeStateStatus --jq '.mergeStateStatus')
	if [[ "$merge_state" == "BLOCKED" ]]; then
		errors+=("Branch protection rules not satisfied")
	fi

	if [[ ${#errors[@]} -gt 0 ]]; then
		echo "❌ Pre-merge validation failed:"
		printf '  • %s\n' "${errors[@]}"
		return 1
	fi

	echo "✅ All pre-merge checks passed"
	return 0
}
```

**API Calls:**
- `gh pr view --json reviewDecision,mergeable,mergeStateStatus`
- `gh pr checks`

### 3. Review Feedback Analyzer

**Function:** `analyze_review_feedback(pr_number)`

**Logic:**
```bash
analyze_review_feedback() {
	local pr_number="$1"
	local repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

	# Fetch CodeRabbit comments
	local coderabbit_comments=$(gh api "repos/$repo/pulls/$pr_number/comments" \
		--jq '.[] | select(.user.login == "coderabbitai") | {path: .path, body: .body}')

	# Fetch Codex comments (if applicable)
	local codex_comments=$(gh api "repos/$repo/pulls/$pr_number/comments" \
		--jq '.[] | select(.user.login == "codex-bot") | {path: .path, body: .body}')

	# Parse and categorize
	if [[ -n "$coderabbit_comments" ]] || [[ -n "$codex_comments" ]]; then
		echo "🤖 Review feedback detected:"
		echo "$coderabbit_comments" | jq -r '.path + ": " + .body'
		echo "$codex_comments" | jq -r '.path + ": " + .body'

		# Prompt user
		read -p "Address review feedback before merging? [Y/n]: " response
		if [[ "$response" =~ ^[Yy]$ ]] || [[ -z "$response" ]]; then
			return 2  # Signal to address feedback
		fi
	fi

	return 0
}
```

**Dependencies:**
- `gh api repos/{owner}/{repo}/pulls/{pr}/comments`
- `jq` for JSON parsing

### 4. Merge Executor

**Function:** `execute_merge(pr_number)`

**Logic:**
```bash
execute_merge() {
	local pr_number="$1"
	local strategy="${MERGE_STRATEGY:-merge}"  # merge, squash, or rebase

	echo "🔄 Merging PR #$pr_number..."

	# Execute merge
	if gh pr merge "$pr_number" "--$strategy" --delete-branch; then
		echo "✅ PR #$pr_number merged successfully"

		# Verify merge commit
		local merge_commit=$(gh pr view "$pr_number" --json mergeCommit --jq '.mergeCommit.oid')
		if [[ -n "$merge_commit" ]]; then
			echo "  Merge commit: $merge_commit"
			return 0
		else
			echo "⚠️  Warning: Could not verify merge commit"
			return 1
		fi
	else
		echo "❌ Merge failed"
		return 1
	fi
}
```

**Options:**
- `--merge` (default): Create merge commit
- `--squash`: Squash commits
- `--rebase`: Rebase and merge
- `--delete-branch`: Remove remote branch after merge

### 5. Worktree Cleanup

**Function:** `cleanup_worktree()`

**Logic:**
```bash
cleanup_worktree() {
	# Detect if in worktree
	local current_dir=$(pwd)
	local worktree_info=$(git worktree list --porcelain | grep -A 2 "^worktree $current_dir")

	if [[ -z "$worktree_info" ]]; then
		echo "ℹ️  Not in a worktree, skipping cleanup"
		return 0
	fi

	echo "🧹 Cleaning up worktree..."

	# Extract worktree path
	local worktree_path=$(echo "$worktree_info" | head -1 | cut -d ' ' -f 2)
	local main_repo=$(git worktree list --porcelain | grep "^worktree" | head -1 | cut -d ' ' -f 2)

	# Return to main repository
	cd "$main_repo" || return 1
	echo "  Returned to main repository: $main_repo"

	# Update main branch
	git checkout main
	git fetch origin
	git pull origin main
	echo "  ✅ Main branch updated"

	# Verify merge is present
	local merge_commit=$(git log --oneline -1 --grep="Merge pull request")
	if [[ -z "$merge_commit" ]]; then
		echo "  ⚠️  Warning: Recent merge not found in main"
	else
		echo "  ✅ Merge verified: $merge_commit"
	fi

	# Remove worktree
	if git worktree remove "$worktree_path"; then
		echo "  ✅ Worktree removed: $worktree_path"
	else
		echo "  ❌ Failed to remove worktree (may need manual cleanup)"
		return 1
	fi

	# Prune metadata
	git worktree prune
	echo "  ✅ Worktree metadata pruned"

	return 0
}
```

**Safety Checks:**
- Verify merge commit exists before cleanup
- Check for uncommitted changes in worktree
- Validate main branch updated successfully

## Data Flow

```
User Input → PR Inference → Confirmation
                               ↓
                         Validation
                               ↓
                    [If Issues Detected]
                               ↓
                      Review Feedback
                               ↓
                    [User Addresses]
                               ↓
                         Re-validate
                               ↓
                    [All Checks Pass]
                               ↓
                        Merge Execute
                               ↓
                    [If in Worktree]
                               ↓
                      Worktree Cleanup
                               ↓
                      Success Report
```

## Error Handling

### Error Categories

1. **User Input Errors**
   - Invalid PR number
   - PR not found
   - Ambiguous inference
   - **Action:** Clear error message, suggest correction

2. **Validation Failures**
   - Failing CI checks
   - Missing approvals
   - Merge conflicts
   - **Action:** Display specific issues, suggest fixes, exit gracefully

3. **Merge Failures**
   - GitHub API errors
   - Permission denied
   - Network issues
   - **Action:** Report error, provide manual merge command

4. **Cleanup Failures**
   - Worktree removal blocked
   - Uncommitted changes
   - Git operation failed
   - **Action:** Leave worktree intact, provide manual cleanup instructions

### Rollback Strategy

- Merge operations are atomic (GitHub handles)
- Worktree cleanup only after verified merge
- No destructive operations before validation passes

## Performance Considerations

### Expected Timings
- PR inference: <1 second
- Pre-merge validation: 2-3 seconds (GitHub API calls)
- Review feedback analysis: 1-2 seconds
- Merge execution: 2-5 seconds
- Worktree cleanup: 3-5 seconds

**Total:** 10-20 seconds for complete workflow

### Optimization Strategies
- Cache PR data for 30 seconds to reduce API calls
- Parallel validation checks where possible
- Use `--cached` flags for GitHub CLI when available

## Security Considerations

### Authentication
- Relies on `gh auth status` for GitHub authentication
- No credential storage or management
- Uses existing GitHub CLI session

### Permissions
- Respects repository branch protection rules
- Cannot bypass required reviews
- Admin override only with explicit `--admin` flag

### Data Privacy
- No sensitive data logged to files
- PR content stays in GitHub
- Local git operations only

## Testing Strategy

### Unit Tests
- PR inference logic with mock branches
- Validation checks with mock API responses
- Worktree detection logic

### Integration Tests
- Full workflow on test repository
- Mock PR with passing/failing checks
- Worktree creation and cleanup cycle

### Manual Testing Scenarios
1. Happy path: Clean merge from worktree
2. Failing checks: Validation blocks merge
3. Review feedback: CodeRabbit comments detected
4. Merge conflicts: User notified, merge blocked
5. Not in worktree: Cleanup skipped gracefully

## Dependencies

### Required
- `gh` (GitHub CLI) v2.0+
- `git` v2.17+ (for `git worktree remove`)
- `jq` for JSON parsing
- Bash 4.0+ for associative arrays

### Optional
- CodeRabbit integration (automatic)
- Codex integration (automatic)

## Installation

Command installed via `setup-claude-code.sh`:

```bash
curl -s -o "$HOME/.claude/commands/workflow-merge.md" \
	"https://raw.githubusercontent.com/carmandale/agent-os/main/commands/workflow-merge.md"
```

Script installed during Agent OS setup:

```bash
curl -s -o "$HOME/.agent-os/scripts/workflow-merge.sh" \
	"https://raw.githubusercontent.com/carmandale/agent-os/main/scripts/workflow-merge.sh"
chmod +x "$HOME/.agent-os/scripts/workflow-merge.sh"
```

## Configuration Options

### Environment Variables
- `MERGE_STRATEGY` - Default merge strategy (merge/squash/rebase)
- `AGENT_OS_AUTO_MERGE` - Enable auto-merge by default (true/false)
- `SKIP_REVIEW_FEEDBACK` - Skip review feedback analysis (true/false)

### User Preferences
Can be set in `~/.agent-os/config` (future):
```bash
merge.strategy=merge
merge.auto-cleanup=true
merge.confirm-always=true
```

## Future Enhancements

### Phase 5+ Features
- AI-powered conflict resolution suggestions
- Automatic changelog generation on merge
- Integration with project management tools (Jira, Linear)
- Merge queue support for high-traffic repositories
- Team notification integration (Slack, Discord)
- Merge metrics and analytics tracking
