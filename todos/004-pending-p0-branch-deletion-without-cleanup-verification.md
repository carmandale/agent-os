---
status: completed
priority: p0
issue_id: "004"
tags: [code-review, data-integrity, pr-101, error-recovery]
dependencies: ["003"]
completed_date: 2025-10-16
---

# Branch Deletion Without Cleanup Verification

## Problem Statement

The merge command deletes the remote branch immediately during the merge operation, regardless of whether worktree cleanup will succeed. When cleanup fails, users are left with an orphaned worktree, no remote branch to push to, and no clear recovery path.

**Severity:** CRITICAL - Data Recovery Risk
**Impact:** Users lose ability to push additional commits or fixes after merge

## Findings

- Discovered during data-integrity-guardian review of PR #101
- Location: `scripts/workflow-merge.sh:427-428, 640-652`
- Branch deletion happens via `--delete-branch` flag during merge
- Cleanup failure leaves worktree pointing to deleted remote branch
- No recovery mechanism if cleanup fails after successful merge
- Creates confusion about how to extract local work

### Vulnerable Code Flow
```bash
execute_merge() {
    # Line 418-428: Branch deleted immediately
    local merge_command
    if [[ "$AUTO_MERGE" == "true" ]]; then
        merge_command="gh pr merge \"$PR_NUMBER\" --auto --$MERGE_STRATEGY"
    else
        merge_command="gh pr merge \"$PR_NUMBER\" --$MERGE_STRATEGY --delete-branch"
        #                                                              ^^^^^^^^^^^^^^
        #                                                      PROBLEM: Deletes immediately
    fi

    if execute_command "$merge_command"; then
        print_success "PR #$PR_NUMBER merged successfully"
        return 0
    fi
}

main() {
    # ...
    execute_merge || exit 1  # ← Branch deleted here if successful

    # Later: attempt cleanup
    detect_worktree
    if [[ "$AUTO_MERGE" != "true" ]]; then
        cleanup_worktree  # ← If this fails, branch already gone!
    fi
}
```

### Failure Scenario Timeline

**Time T0:** PR ready to merge, user in worktree
```bash
$ cd .worktrees/feature-bugfix-#456
$ /merge 456
```

**Time T1:** Merge succeeds
```bash
✅ PR #456 merged successfully
```

**Time T2:** GitHub deletes branch
```bash
✅ Remote branch 'feature/bugfix-#456' deleted automatically
```

**Time T3:** Cleanup attempts
```bash
🔄 Detecting worktree...
🔄 Cleaning up worktree...
```

**Time T4:** Cleanup fails (permission error, file locks, etc.)
```bash
❌ ERROR: Permission denied: cannot remove worktree
```

**Time T5:** User is stuck
- PR merged on GitHub ✓
- Remote branch deleted ✓
- Worktree still exists ✗
- Can't push to deleted branch ✗
- No documented recovery path ✗

### Real-World Failure Modes

**Scenario 1: Permission Issues**
```bash
# IDE has files locked in worktree
$ /merge 123
✅ Merged
❌ Error: cannot remove worktree (files in use)
# Branch gone, worktree stuck
```

**Scenario 2: Filesystem Issues**
```bash
# Disk full during cleanup
$ /merge 123
✅ Merged
❌ Error: No space left on device
# Branch gone, can't complete cleanup
```

**Scenario 3: Race Condition**
```bash
# Another process modifies worktree during cleanup
$ /merge 123
✅ Merged
❌ Error: worktree modified during operation
# Branch gone, inconsistent state
```

### Recovery Complexity

**Current manual recovery steps:**
```bash
# User must figure this out on their own:
1. cd <main-repo>                    # Navigate away
2. git fetch origin                  # Update refs
3. git branch -D feature/bugfix      # Delete local branch
4. git worktree remove --force <path> # Force remove worktree
5. git worktree prune                # Clean up refs
```

**Problems with manual recovery:**
- Requires git expertise
- Not documented in error message
- Risk of data loss if done wrong
- Time-consuming to diagnose

## Proposed Solutions

### Option 1: Conditional Branch Deletion (Recommended)
- **Pros**: Preserves branch for recovery, clear error path, safer
- **Cons**: Adds complexity to cleanup flow
- **Effort**: Medium (1 hour)
- **Risk**: Low - More robust than current

**Implementation:**
```bash
# Track merge success separately
MERGE_SUCCEEDED=false
BRANCH_NAME=""

execute_merge() {
    print_section "Executing Merge"

    # Get branch name for later deletion
    BRANCH_NAME=$(gh pr view "$PR_NUMBER" --json headRefName --jq '.headRefName')

    # Merge WITHOUT automatic branch deletion
    local merge_cmd
    if [[ "$AUTO_MERGE" == "true" ]]; then
        merge_cmd="gh pr merge \"$PR_NUMBER\" --auto --$MERGE_STRATEGY"
    else
        # Remove --delete-branch flag
        merge_cmd="gh pr merge \"$PR_NUMBER\" --$MERGE_STRATEGY"
    fi

    if execute_command "$merge_cmd"; then
        print_success "PR #$PR_NUMBER merged successfully"
        MERGE_SUCCEEDED=true
        return 0
    else
        print_error "Merge failed"
        return 1
    fi
}

cleanup_after_merge() {
    if [[ "$MERGE_SUCCEEDED" != "true" ]]; then
        return 0  # Nothing to clean up
    fi

    # If not in worktree, safe to delete immediately
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

delete_remote_branch() {
    if [[ -z "$BRANCH_NAME" ]]; then
        print_warning "Branch name unknown, cannot delete"
        return 1
    fi

    print_step "Deleting remote branch: $BRANCH_NAME"

    if execute_command "gh api -X DELETE \"repos/:owner/:repo/git/refs/heads/$BRANCH_NAME\""; then
        print_success "Remote branch deleted"
        return 0
    else
        print_warning "Could not delete remote branch"
        print_info "Manual deletion: gh api -X DELETE \"repos/:owner/:repo/git/refs/heads/$BRANCH_NAME\""
        return 1
    fi
}

main() {
    # ... validation ...

    execute_merge || exit 1

    detect_worktree

    if [[ "$AUTO_MERGE" != "true" ]]; then
        cleanup_after_merge || {
            # Non-fatal: PR merged, cleanup partial
            print_section "Merge Completed with Warnings"
            print_warning "PR merged successfully but cleanup incomplete"
            exit 2  # Warning exit code
        }
    fi

    generate_summary
    exit 0
}
```

### Option 2: Always Force Cleanup (NOT Recommended)
- **Pros**: Simpler logic, always completes
- **Cons**: Can lose uncommitted work, violates safety principles
- **Effort**: Small (30 minutes)
- **Risk**: HIGH - Data loss risk

**Why rejected:** Agent OS design principles prioritize safety over convenience

### Option 3: Manual Branch Deletion Only (Alternative)
- **Pros**: Complete user control, no surprises
- **Cons**: Requires extra manual step, UX regression
- **Effort**: Small (remove --delete-branch flag)
- **Risk**: Low

**Consideration:** Could be offered as a flag option (`--no-delete-branch`)

## Recommended Action

**Option 1: Conditional Branch Deletion** - This provides the best balance of automation and safety.

### Implementation Steps
1. Extract branch name before merge
2. Remove `--delete-branch` flag from merge command
3. Add `cleanup_after_merge()` function
4. Implement `delete_remote_branch()` helper
5. Add conditional logic:
   - Not in worktree → delete immediately
   - In worktree → cleanup first, then delete
   - Cleanup fails → preserve branch + provide instructions
6. Update error messaging with recovery steps
7. Track merge success separately from cleanup
8. Use exit code 2 for "success with warnings"

## Technical Details

**Affected Files:**
- `scripts/workflow-merge.sh` (execute_merge, main flow)

**New Functions:**
- `cleanup_after_merge()` - Orchestrates cleanup and branch deletion
- `delete_remote_branch()` - Handles branch deletion with error handling

**Related Components:**
- GitHub CLI API integration
- Worktree cleanup logic
- Error messaging system
- Exit code handling

**Database Changes:** None

## Resources

- Code review PR: https://github.com/carmandale/agent-os/pull/101
- Data integrity findings: Comprehensive audit report
- Related issue: Uncommitted changes check timing (Issue #003)
- GitHub API documentation: https://docs.github.com/en/rest/git/refs#delete-a-reference

## Acceptance Criteria

- [ ] `BRANCH_NAME` extracted before merge operation
- [ ] `--delete-branch` flag removed from merge command
- [ ] `cleanup_after_merge()` function created and called
- [ ] `delete_remote_branch()` helper function created
- [ ] Branch deletion skipped if not in worktree (deleted immediately)
- [ ] Branch deletion deferred if in worktree (after cleanup)
- [ ] Branch preserved if cleanup fails
- [ ] Clear recovery instructions provided when cleanup fails
- [ ] Exit code 0 for complete success
- [ ] Exit code 2 for success with warnings (merge succeeded, cleanup failed)
- [ ] Exit code 1 for failure (merge failed)
- [ ] Test scenarios:
  - [ ] Not in worktree: immediate branch deletion works
  - [ ] In worktree + clean: cleanup then delete works
  - [ ] In worktree + cleanup fails: branch preserved, instructions shown
  - [ ] Manual branch deletion command works (via gh api)
- [ ] User feedback: Recovery instructions are clear and actionable

## Work Log

### 2025-10-15 - Code Review Discovery
**By:** Claude Code Review System (data-integrity-guardian agent)
**Actions:**
- Discovered during comprehensive data integrity review of PR #101
- Analyzed merge and cleanup operation ordering
- Identified critical timing issue with branch deletion
- Categorized as P0 blocking issue due to recovery complexity
- Created todo for tracking and resolution

**Learnings:**
- Destructive operations should be last in the workflow
- Cleanup verification should precede permanent deletions
- Preserve recovery options when operations fail
- Clear error messages with specific recovery steps prevent user frustration
- Exit codes should communicate partial success states

## Notes

**BLOCKING:** This issue MUST be resolved before PR #101 can be merged to main.

**Dependency:** This issue is related to Issue #003 (uncommitted changes check). Together they form a comprehensive safety net:
- Issue #003: Prevents merge if workspace dirty (proactive)
- Issue #004: Handles cleanup failures gracefully (reactive)

**User Impact:** Without this fix, users experiencing cleanup failures have no documented path forward. This creates support burden and erodes trust in the tool.

**Testing Priority:** HIGH - Must test actual cleanup failures (file locks, permissions, disk space) to verify error messages and recovery instructions.

**Context:** Part of comprehensive data integrity review that identified 6 critical data safety issues. This is the second-highest priority after uncommitted changes validation.

Source: Code review performed on 2025-10-15
Review command: `/compounding-engineering:review PR #101`
