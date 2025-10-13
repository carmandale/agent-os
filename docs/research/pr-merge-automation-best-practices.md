# PR Merge Automation Best Practices - Research Summary

> Research Date: 2025-10-13
> Focus: Safe merge workflows, CI/CD integration, worktree cleanup, Git safety protocols

## Executive Summary

This document consolidates best practices for building automated PR merge commands based on research from official documentation, popular CLI tools (GitHub CLI, GitLab CLI), and industry standards. Key themes include confirmation patterns, pre-merge validation, status check verification, worktree cleanup, and error recovery.

---

## 1. Safe Merge Workflows

### Confirmation Patterns

**Severity-Based Confirmation Levels** (Source: [CLI Guidelines](https://clig.dev/))

- **Mild changes**: May not need confirmation (e.g., single file deletion)
- **Moderate changes**: Usually prompt for confirmation (e.g., directory deletion, remote operations)
- **Severe changes**: Require explicit confirmation (e.g., full application deletion)

**Best Practices**:
- Use uppercase for default option: `Y/n` means Y is default
- For dangerous operations, make confirmation deliberately difficult:
  - Ask user to type the full name of what they're deleting
  - Provide `--confirm="name-of-thing"` flag for scripting
- Provide `--no-prompt` or `--no-interactive` flags for automation
- Implement `--dry-run` flag to preview changes without executing

**Example Pattern**:
```bash
# Interactive confirmation
read -p "Merge PR #123 into main? (Y/n): " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || exit 0

# Script-friendly flags
git-merge-tool --auto --no-prompt
git-merge-tool --dry-run  # Preview only
```

### GitHub CLI (`gh`) Approach

**Command**: `gh pr merge`

**Key Features**:
- `--auto`: Automatically merge when requirements met
- `--match-head-commit <SHA>`: Ensures specific commit matches before merge
- `--admin`: Bypass merge requirements (use with caution)
- `-d`, `--delete-branch`: Clean up branch after merge

**Merge Strategies**:
- `--merge`: Standard merge commit
- `--rebase`: Rebase commits onto base branch
- `--squash`: Squash all commits into single commit

**Documentation**: https://cli.github.com/manual/gh_pr_merge

### GitLab CLI (`glab`) Approach

**Auto-merge Safety**:
- Cancels auto-merge if new commits are added (ensures review)
- Cancels if target branch updated and only fast-forward merges allowed
- Enforces project merge requirements (approvals, resolved threads, successful pipeline)

**Bypass for Automation**:
- Service accounts can be designated to bypass approval policies
- All bypass events are fully audited

**Documentation**: https://docs.gitlab.com/user/project/merge_requests/auto_merge/

---

## 2. Code Review Integration

### Approval Requirements

**GitHub Approach**:
```bash
# Check PR status including reviews
gh pr view --json reviewDecision,statusCheckRollup

# Approve PR
gh pr review --approve

# Request changes
gh pr review --request-changes -b "Reason for changes"
```

**Key Considerations**:
- Parse review comments from API
- Require minimum number of approvals (configurable)
- Check for "changes requested" status
- Verify no pending review threads

**Automation Tools**:
- **reviewdog**: Parses linter output and posts review comments ([GitHub](https://github.com/reviewdog/reviewdog))
- **CodeRabbit**: AI-powered review with CLI commands ([Docs](https://docs.coderabbit.ai/guides/commands))

### Best Practices

1. **Verify approval status before merge**:
   ```bash
   review_decision=$(gh pr view "$PR_NUMBER" --json reviewDecision -q .reviewDecision)
   if [[ "$review_decision" != "APPROVED" ]]; then
       echo "Error: PR not approved"
       exit 1
   fi
   ```

2. **Check for blocking comments**:
   - Parse comment threads
   - Identify unresolved conversations
   - Block merge if critical issues remain

3. **Support review bypass for special cases**:
   - Emergency hotfixes (with audit logging)
   - Automated dependency updates
   - Documentation-only changes

---

## 3. CI/CD Status Verification

### GitHub Actions Integration

**Command**: `gh pr checks`

**Key Features**:
- `--watch`: Monitor checks until completion
- `--required`: Show only required checks
- Exit code 8 if checks still pending

**Pre-Merge Validation**:
```bash
# Check all required status checks
gh pr checks "$PR_NUMBER" --required

# Wait for checks to complete
gh pr checks "$PR_NUMBER" --watch

# Verify all checks passed
status=$(gh pr view "$PR_NUMBER" --json statusCheckRollup -q '.statusCheckRollup[].state')
if echo "$status" | grep -q "FAILURE\|ERROR"; then
    echo "Error: Some checks failed"
    exit 1
fi
```

**Documentation**: https://cli.github.com/manual/gh_pr_checks

### Branch Protection Requirements

**Required Status Checks** (Source: [GitHub Docs](https://docs.github.com/articles/about-status-checks)):
- Configure "Require status checks to pass before merging"
- Select specific checks to require
- Enable "Require branches to be up to date before merging"
- Apply rules to administrators too

**Best Practices**:
1. **Always verify latest commit**:
   - Status checks must pass on most recent commit SHA
   - Prevents merging outdated code

2. **Handle merge queue scenarios**:
   - Check for merge queue requirements
   - Ensure workflows include `merge_group` event trigger

3. **Implement timeout handling**:
   - Don't wait indefinitely for checks
   - Configure reasonable timeout (e.g., 30 minutes)
   - Provide clear error messages on timeout

### Auto-Merge Pattern

```bash
# Enable auto-merge (merges when checks pass)
gh pr merge "$PR_NUMBER" --auto --squash

# Disable auto-merge
gh pr merge "$PR_NUMBER" --disable-auto
```

**When to Use**:
- Long-running CI pipelines
- Multiple reviewers across time zones
- Automated dependency updates

**Documentation**: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request

---

## 4. Worktree Cleanup Best Practices

### Modern Approach (Git 2.17+)

**Primary Command**: `git worktree remove`

```bash
# Remove clean worktree
git worktree remove /path/to/worktree

# Force remove worktree with uncommitted changes
git worktree remove --force /path/to/worktree
```

**Documentation**: https://git-scm.com/docs/git-worktree

### Prune Stale Worktrees

**Command**: `git worktree prune`

```bash
# Prune stale worktrees (manual)
git worktree prune

# Preview what would be pruned
git worktree prune --dry-run

# Prune with verbose output
git worktree prune --verbose

# Prune worktrees older than specific time
git worktree prune --expire 3.weeks.ago
```

**When to Prune**:
- After manually deleting worktree directory
- Cleanup disconnected worktree metadata
- Automatic cleanup based on `gc.worktreePruneExpire`

### Safety Considerations

1. **Check worktree status first**:
   ```bash
   git worktree list
   ```

2. **Locked worktrees cannot be pruned**:
   ```bash
   git worktree unlock /path/to/worktree
   ```

3. **Avoid disconnected state**:
   - Always use `git worktree remove` instead of manual deletion
   - Disconnected worktrees can cause incorrect `git rev-list` results

### Recommended Cleanup Workflow

```bash
# After successful PR merge
after_merge_cleanup() {
    local worktree_path="$1"

    # 1. Remove worktree
    if git worktree remove "$worktree_path" 2>/dev/null; then
        echo "Worktree removed: $worktree_path"
    else
        echo "Warning: Could not remove worktree cleanly"
        git worktree remove --force "$worktree_path"
    fi

    # 2. Prune stale references
    git worktree prune --verbose

    # 3. Delete remote branch
    git push origin --delete "$branch_name"

    # 4. Delete local branch
    git branch -D "$branch_name"
}
```

---

## 5. Git Safety Protocols

### Force Push Protection

**Branch Protection Rules** (Source: [GitHub Docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)):

- GitHub blocks force pushes on protected branches by default
- GitLab protects default branch automatically
- Configure protection for main, master, develop, release branches

### Safe Force Push Alternative

**Use `--force-with-lease` instead of `--force`**:

```bash
# Dangerous: overwrites any remote changes
git push --force

# Safer: checks if remote changed since last fetch
git push --force-with-lease
```

**How it works** (Source: [Git Tower](https://www.git-tower.com/blog/force-push-in-git/)):
- Verifies remote branch hasn't been updated since last fetch
- Rejects push if remote has new commits
- Prevents accidental overwrite of teammate's work

**Documentation**: https://git-scm.com/docs/git-push

### Preventing Accidental Main Branch Merges

**Best Practices**:

1. **Verify target branch before merge**:
   ```bash
   base_branch=$(gh pr view "$PR_NUMBER" --json baseRefName -q .baseRefName)
   if [[ "$base_branch" == "main" ]] && [[ "$allow_main_merge" != "true" ]]; then
       read -p "WARNING: Merging to main. Continue? (y/N): " confirm
       [[ "$confirm" =~ ^[Yy]$ ]] || exit 0
   fi
   ```

2. **Require explicit flag for protected branches**:
   ```bash
   merge-tool --allow-main-merge
   ```

3. **Implement branch protection rules**:
   - Require pull request reviews
   - Require status checks
   - Restrict who can push
   - Block force pushes

### Error Prevention Checklist

Before merge:
- [ ] Verify working directory is clean
- [ ] Confirm on correct branch
- [ ] Check for uncommitted changes
- [ ] Verify remote is up to date
- [ ] Validate PR number/branch name
- [ ] Confirm target branch is correct
- [ ] Check all status checks passed
- [ ] Verify required approvals present

---

## 6. User Experience Patterns for CLI Merge Commands

### Standard Flag Conventions

**Common Flags** (Source: [CLI Guidelines](https://clig.dev/)):

- `-f, --force`: Bypass confirmations (use sparingly)
- `--dry-run`: Preview without executing
- `--no-prompt`: Disable interactive prompts
- `-y, --yes`: Auto-confirm all prompts
- `-v, --verbose`: Detailed output
- `-q, --quiet`: Minimal output

### Interactive Mode Pattern

```bash
# When command run without full arguments, prompt for input
merge-pr() {
    local pr_number="${1:-}"

    if [[ -z "$pr_number" ]]; then
        # Interactive mode
        echo "Available PRs:"
        gh pr list
        read -p "Enter PR number: " pr_number
    fi

    # Continue with merge...
}
```

### Progress Display

**Best Practices** (Source: [Evil Martians](https://evilmartians.com/chronicles/cli-ux-best-practices-3-patterns-for-improving-progress-displays)):

1. **Show what's happening**:
   ```bash
   echo "Checking PR status..."
   echo "Verifying CI checks..."
   echo "Merging pull request..."
   echo "Cleaning up worktree..."
   ```

2. **Use spinners for long operations**:
   - Show progress for operations >1 second
   - Indicate what's happening
   - Allow Ctrl-C interruption

3. **Provide clear completion messages**:
   ```bash
   echo "✓ PR #123 merged successfully"
   echo "✓ Branch feature-xyz deleted"
   echo "✓ Worktree cleaned up"
   echo ""
   echo "Next steps:"
   echo "  git checkout main"
   echo "  git pull"
   ```

### Error Message Guidelines

**Key Principles** (Source: [CLI Guidelines](https://clig.dev/)):

1. **Catch errors and rewrite for humans**:
   ```bash
   # Bad
   Error: ref HEAD is not a symbolic ref

   # Good
   Error: Unable to merge. Your working directory has uncommitted changes.
   Run 'git status' to see what needs to be committed or stashed.
   ```

2. **Put most important information at end**:
   - Users read bottom of terminal first
   - Error details should be easily visible

3. **Use color intentionally**:
   - Red for errors
   - Yellow for warnings
   - Green for success
   - No color for info

4. **Provide actionable guidance**:
   ```bash
   Error: PR #123 has failing checks

   Failed checks:
   - lint (1 error)
   - test (3 failures)

   View details: gh pr checks 123
   ```

---

## 7. Error Handling and Rollback Strategies

### Undo Merge Strategies

**1. For Uncommitted Merges (Conflicts)**:
```bash
# Abort merge in progress
git merge --abort
```

**2. For Local Merges (Not Pushed)**:
```bash
# Reset to before merge (destructive)
git reset --hard HEAD^

# Reset but keep uncommitted changes (safer)
git reset --merge HEAD^
```

**3. For Pushed Merges (On Remote)**:
```bash
# Revert merge commit (creates new commit)
git revert -m 1 <merge-commit-sha>

# The -m 1 option keeps parent side of merge
```

**Documentation**:
- https://www.git-tower.com/learn/git/faq/undo-git-merge
- https://graphite.dev/guides/how-to-revert-a-merge-in-git

### Rollback Decision Tree

```
Is merge committed?
├─ NO → Use 'git merge --abort'
└─ YES
    └─ Is merge pushed to remote?
        ├─ NO → Use 'git reset --merge HEAD^'
        └─ YES → Use 'git revert -m 1 <sha>'
```

### Error Recovery Patterns

**1. Handle merge conflicts**:
```bash
if ! git merge feature-branch; then
    echo "Error: Merge conflicts detected"
    echo "Conflicts in:"
    git diff --name-only --diff-filter=U
    echo ""
    echo "Resolve conflicts and run: git merge --continue"
    echo "Or abort merge with: git merge --abort"
    exit 1
fi
```

**2. Validate state before operation**:
```bash
# Check for clean working directory
if ! git diff-index --quiet HEAD --; then
    echo "Error: Working directory has uncommitted changes"
    echo "Commit or stash changes before merging"
    exit 1
fi
```

**3. Implement transaction-style operations**:
```bash
merge_with_rollback() {
    # Save current state
    local original_branch=$(git rev-parse --abbrev-ref HEAD)
    local original_sha=$(git rev-parse HEAD)

    # Attempt merge
    if ! git merge "$1"; then
        echo "Error: Merge failed, rolling back..."
        git merge --abort
        git checkout "$original_branch"
        return 1
    fi

    # Verify merge success
    if ! run_post_merge_tests; then
        echo "Error: Post-merge tests failed, rolling back..."
        git reset --hard "$original_sha"
        return 1
    fi

    return 0
}
```

### Conflict Resolution Strategies

**Best Practices**:

1. **Detect conflicts early**:
   ```bash
   # Check if merge would conflict before attempting
   git merge --no-commit --no-ff "$branch"
   if [ $? -ne 0 ]; then
       echo "Warning: Merge will have conflicts"
       git merge --abort
   fi
   ```

2. **Provide clear conflict information**:
   - List conflicting files
   - Show conflict markers
   - Suggest resolution tools (merge tool, manual edit)

3. **Preserve conflict state**:
   - Don't auto-resolve conflicts
   - Let user decide resolution strategy
   - Provide clear exit path (abort option)

---

## 8. Implementation Recommendations

### Comprehensive Pre-Merge Checklist

```bash
pre_merge_validation() {
    local pr_number="$1"
    local errors=()

    # 1. Verify PR exists and is open
    if ! gh pr view "$pr_number" &>/dev/null; then
        errors+=("PR #$pr_number not found")
    fi

    # 2. Check PR status
    local state=$(gh pr view "$pr_number" --json state -q .state)
    if [[ "$state" != "OPEN" ]]; then
        errors+=("PR is not open (state: $state)")
    fi

    # 3. Verify CI checks passed
    if ! gh pr checks "$pr_number" --required 2>/dev/null; then
        errors+=("Required CI checks have not passed")
    fi

    # 4. Check review approvals
    local review_decision=$(gh pr view "$pr_number" --json reviewDecision -q .reviewDecision)
    if [[ "$review_decision" != "APPROVED" ]]; then
        errors+=("PR not approved (decision: $review_decision)")
    fi

    # 5. Verify branch is up to date
    local mergeable=$(gh pr view "$pr_number" --json mergeable -q .mergeable)
    if [[ "$mergeable" == "CONFLICTING" ]]; then
        errors+=("PR has merge conflicts")
    fi

    # 6. Check working directory is clean
    if ! git diff-index --quiet HEAD --; then
        errors+=("Working directory has uncommitted changes")
    fi

    # Report errors
    if [ ${#errors[@]} -gt 0 ]; then
        echo "Pre-merge validation failed:"
        printf "  - %s\n" "${errors[@]}"
        return 1
    fi

    return 0
}
```

### Safe Merge Implementation

```bash
safe_merge_pr() {
    local pr_number="$1"
    local merge_strategy="${2:-squash}"  # squash, merge, rebase
    local auto_delete_branch="${3:-true}"

    # Pre-merge validation
    echo "Validating PR #$pr_number..."
    if ! pre_merge_validation "$pr_number"; then
        return 1
    fi

    # Confirmation prompt
    local pr_title=$(gh pr view "$pr_number" --json title -q .title)
    local base_branch=$(gh pr view "$pr_number" --json baseRefName -q .baseRefName)
    echo ""
    echo "Ready to merge:"
    echo "  PR #$pr_number: $pr_title"
    echo "  Strategy: $merge_strategy"
    echo "  Target: $base_branch"

    if [[ "$base_branch" == "main" ]] || [[ "$base_branch" == "master" ]]; then
        echo "  ⚠️  WARNING: Merging to protected branch"
    fi

    read -p "Proceed with merge? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Merge cancelled"
        return 0
    fi

    # Perform merge
    echo "Merging PR #$pr_number..."
    local merge_flags="--$merge_strategy"
    [[ "$auto_delete_branch" == "true" ]] && merge_flags="$merge_flags --delete-branch"

    if gh pr merge "$pr_number" $merge_flags; then
        echo "✓ PR #$pr_number merged successfully"

        # Cleanup worktree if applicable
        local branch_name=$(gh pr view "$pr_number" --json headRefName -q .headRefName)
        cleanup_worktree "$branch_name"

        return 0
    else
        echo "✗ Failed to merge PR #$pr_number"
        return 1
    fi
}
```

### Worktree-Aware Merge

```bash
cleanup_worktree() {
    local branch_name="$1"

    # Check if branch has associated worktree
    local worktree_path=$(git worktree list --porcelain | grep -A2 "branch refs/heads/$branch_name" | grep "worktree" | cut -d' ' -f2)

    if [[ -n "$worktree_path" ]]; then
        echo "Cleaning up worktree: $worktree_path"

        if git worktree remove "$worktree_path" 2>/dev/null; then
            echo "✓ Worktree removed"
        else
            echo "⚠️  Could not remove worktree cleanly, forcing..."
            git worktree remove --force "$worktree_path"
        fi

        # Prune stale worktree references
        git worktree prune --verbose
    fi
}
```

---

## 9. Key Takeaways

### Must-Have Features

1. **Pre-merge validation**:
   - CI status checks
   - Review approvals
   - Merge conflicts detection
   - Branch up-to-date verification

2. **Safety mechanisms**:
   - Confirmation prompts for destructive operations
   - Protected branch warnings
   - Dry-run mode
   - Rollback capabilities

3. **User experience**:
   - Clear progress indicators
   - Actionable error messages
   - Suggested next steps
   - Script-friendly flags

4. **Worktree management**:
   - Automatic cleanup after merge
   - Stale worktree pruning
   - Safe removal with fallback

5. **Git safety**:
   - Use `--force-with-lease` never `--force`
   - Branch protection awareness
   - Transaction-style operations with rollback

### Recommended Flags

```bash
merge-pr [OPTIONS] <pr-number>

Required:
  pr-number          Pull request number to merge

Options:
  -s, --strategy     Merge strategy: squash|merge|rebase (default: squash)
  -d, --delete       Delete branch after merge (default: true)
  -f, --force        Force merge (bypass confirmations)
  -y, --yes          Auto-confirm prompts
  --no-checks        Skip CI status verification (dangerous)
  --dry-run          Preview without executing
  --verbose          Detailed output
  --quiet            Minimal output

Safety:
  --require-reviews  Require PR approvals (default: true)
  --allow-conflicts  Allow merge despite conflicts
  --keep-worktree    Don't cleanup worktree after merge
```

### Anti-Patterns to Avoid

1. **Don't skip validation checks** - Always verify CI and reviews
2. **Don't use `--force` without confirmation** - Use `--force-with-lease`
3. **Don't merge to main without warnings** - Protected branches need extra care
4. **Don't leave orphaned worktrees** - Always cleanup after merge
5. **Don't assume merge success** - Validate and provide rollback
6. **Don't hide error details** - Show full context for debugging
7. **Don't bypass branch protection** - Respect repository rules

---

## 10. Reference Links

### Official Documentation

**GitHub CLI**:
- Main documentation: https://cli.github.com/manual/
- PR merge: https://cli.github.com/manual/gh_pr_merge
- PR checks: https://cli.github.com/manual/gh_pr_checks
- PR review: https://cli.github.com/manual/gh_pr_review

**GitLab CLI**:
- Main documentation: https://docs.gitlab.com/editor_extensions/gitlab_cli/
- Auto-merge: https://docs.gitlab.com/user/project/merge_requests/auto_merge/
- Merge requests: https://docs.gitlab.com/user/project/merge_requests/

**Git**:
- git-merge: https://git-scm.com/docs/git-merge
- git-worktree: https://git-scm.com/docs/git-worktree
- git-push: https://git-scm.com/docs/git-push

**GitHub Docs**:
- About status checks: https://docs.github.com/articles/about-status-checks
- Branch protection: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
- Auto-merge: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request

### Best Practice Guides

- CLI Guidelines: https://clig.dev/
- CLI UX patterns: https://lucasfcosta.com/2022/06/01/ux-patterns-cli-tools.html
- Evil Martians CLI UX: https://evilmartians.com/chronicles/cli-ux-best-practices-3-patterns-for-improving-progress-displays
- Graphite Git guides: https://graphite.dev/guides/

### Tools and Resources

- reviewdog (code review automation): https://github.com/reviewdog/reviewdog
- Git Tower guides: https://www.git-tower.com/learn/git/
- Stack Overflow discussions on merge automation

---

## Appendix: Example Implementations

### Minimal Safe Merge

```bash
#!/usr/bin/env bash
set -euo pipefail

merge_pr() {
    local pr="$1"

    # Validate
    gh pr checks "$pr" || { echo "Checks failed"; exit 1; }

    # Confirm
    read -p "Merge PR #$pr? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0

    # Merge
    gh pr merge "$pr" --squash --delete-branch
}

merge_pr "$1"
```

### Production-Ready Merge

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuration
DEFAULT_STRATEGY="squash"
REQUIRE_APPROVALS=true
AUTO_DELETE_BRANCH=true
CLEANUP_WORKTREE=true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() { echo -e "${RED}✗ $*${NC}" >&2; }
success() { echo -e "${GREEN}✓ $*${NC}"; }
warning() { echo -e "${YELLOW}⚠ $*${NC}"; }
info() { echo "$*"; }

validate_pr() {
    local pr="$1"
    local errors=()

    # Check PR exists
    if ! gh pr view "$pr" &>/dev/null; then
        errors+=("PR #$pr not found")
    fi

    # Check status
    local state=$(gh pr view "$pr" --json state -q .state)
    [[ "$state" != "OPEN" ]] && errors+=("PR not open")

    # Check CI
    if ! gh pr checks "$pr" --required &>/dev/null; then
        errors+=("CI checks failed")
    fi

    # Check approvals
    if [[ "$REQUIRE_APPROVALS" == "true" ]]; then
        local decision=$(gh pr view "$pr" --json reviewDecision -q .reviewDecision)
        [[ "$decision" != "APPROVED" ]] && errors+=("PR not approved")
    fi

    # Report errors
    if [ ${#errors[@]} -gt 0 ]; then
        error "Validation failed:"
        printf "  - %s\n" "${errors[@]}"
        return 1
    fi

    return 0
}

merge_pr() {
    local pr="$1"
    local strategy="${2:-$DEFAULT_STRATEGY}"

    info "Validating PR #$pr..."
    validate_pr "$pr" || return 1

    local title=$(gh pr view "$pr" --json title -q .title)
    local base=$(gh pr view "$pr" --json baseRefName -q .baseRefName)

    echo ""
    info "Ready to merge:"
    info "  PR: #$pr - $title"
    info "  Strategy: $strategy"
    info "  Target: $base"

    [[ "$base" =~ ^(main|master)$ ]] && warning "  Merging to protected branch"

    read -p "Proceed? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { info "Cancelled"; return 0; }

    local flags="--$strategy"
    [[ "$AUTO_DELETE_BRANCH" == "true" ]] && flags="$flags --delete-branch"

    if gh pr merge "$pr" $flags; then
        success "PR #$pr merged successfully"

        if [[ "$CLEANUP_WORKTREE" == "true" ]]; then
            local branch=$(gh pr view "$pr" --json headRefName -q .headRefName)
            cleanup_worktree "$branch"
        fi

        return 0
    else
        error "Failed to merge PR #$pr"
        return 1
    fi
}

cleanup_worktree() {
    local branch="$1"
    local path=$(git worktree list --porcelain | grep -A2 "branch refs/heads/$branch" | grep "worktree" | cut -d' ' -f2)

    if [[ -n "$path" ]]; then
        info "Cleaning up worktree: $path"
        git worktree remove "$path" 2>/dev/null || git worktree remove --force "$path"
        git worktree prune
        success "Worktree cleaned up"
    fi
}

# Main
if [[ $# -lt 1 ]]; then
    error "Usage: $0 <pr-number> [strategy]"
    exit 1
fi

merge_pr "$@"
```

---

**Research compiled by**: Claude Code (Anthropic)
**Date**: 2025-10-13
**Agent OS Version**: 2.4.0
