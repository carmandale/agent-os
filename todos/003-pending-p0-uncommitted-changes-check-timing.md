---
status: completed
priority: p0
issue_id: "003"
tags: [code-review, data-integrity, pr-101, user-experience]
dependencies: []
completed_date: 2025-10-16
---

# Uncommitted Changes Check Occurs After Merge

## Problem Statement

The script checks for uncommitted changes **after** the PR has already been merged and the remote branch deleted. This creates a critical user experience failure where developers get stuck in a worktree with trapped uncommitted work and no clear recovery path.

**Severity:** CRITICAL - Data Loss Risk
**Impact:** Users can lose work or require manual git recovery procedures

## Findings

- Discovered during data-integrity-guardian review of PR #101
- Location: `scripts/workflow-merge.sh:502-508` (check) and `640-652` (execution flow)
- Check happens in `cleanup_worktree()` which runs **after** `execute_merge()`
- Remote branch deletion via `--delete-branch` happens during merge
- No pre-merge validation of workspace cleanliness
- User's uncommitted work becomes trapped with no push destination

### Vulnerable Flow
```bash
main() {
    # ...
    confirm_merge || exit 1
    validate_merge_readiness || exit 1

    # PROBLEM: Merge happens first
    execute_merge || exit 1  # ← PR merged, branch deleted

    # TOO LATE: Check happens after merge
    detect_worktree
    cleanup_worktree  # ← Fails here if uncommitted changes
}

cleanup_worktree() {
    # Line 502-508: Check happens too late
    if [[ -n "$(git status --porcelain)" ]]; then
        print_error "Cannot remove worktree with uncommitted work"
        return 1
    fi
    # ...
}
```

### Failure Scenario Timeline

**Time T0:** User in worktree with uncommitted changes
```bash
$ cd .worktrees/feature-auth-#123
$ git status
On branch feature/auth-#123
Changes not staged for commit:
  modified: src/auth.ts
```

**Time T1:** User runs merge command
```bash
$ /merge 123
✅ PR #123 merged successfully
✅ Remote branch deleted
```

**Time T2:** Cleanup fails
```bash
❌ ERROR: Cannot remove worktree with uncommitted work
```

**Time T3:** User is stuck
- PR is merged on GitHub ✓
- Remote branch is deleted ✓
- Local changes trapped in worktree ✗
- Can't push (no remote branch) ✗
- User doesn't know how to recover ✗

### Data Loss Risk Analysis

**Probability:** HIGH
- Common for developers to have WIP commits
- Easy to forget about uncommitted changes
- Script doesn't warn before merge

**Impact:** HIGH
- Hours of work trapped in worktree
- Manual git surgery required to recover
- User may panic and make situation worse
- Could abandon changes if recovery unclear

**Recovery Complexity:** MEDIUM-HIGH
```bash
# Manual recovery steps user must figure out:
1. git add . && git commit -m "Rescue WIP"
2. cd ../../  # Return to main repo
3. git worktree remove --force .worktrees/feature-auth-#123
4. git fetch origin main
5. git checkout main
6. git pull origin main
7. git cherry-pick <commit-from-step-1>  # If they want to keep changes
```

## Proposed Solutions

### Option 1: Pre-Merge Workspace Check (Recommended)
- **Pros**: Prevents problem entirely, clear error messages, gives user control
- **Cons**: Adds one more validation step
- **Effort**: Medium (1 hour)
- **Risk**: Low - Fail-safe approach

**Implementation:**
```bash
main() {
    parse_arguments "$@"
    check_prerequisites || exit 1
    infer_pr_number || exit 1

    # NEW: Detect worktree context early
    detect_worktree

    # NEW: Check workspace cleanliness BEFORE merge
    if [[ "$IN_WORKTREE" == "true" ]] && [[ "$AUTO_MERGE" != "true" ]]; then
        print_section "Pre-Merge Workspace Check"

        if [[ -n "$(git status --porcelain)" ]]; then
            print_error "Worktree has uncommitted changes"
            print_info "Your workspace must be clean before merging"
            echo ""
            echo "Uncommitted changes:"
            git status --short | sed 's/^/  /'
            echo ""
            print_info "📋 Recovery Options:"
            print_info ""
            print_info "  Option 1: Commit your changes"
            print_info "    git add ."
            print_info "    git commit -m 'Final changes before merge'"
            print_info ""
            print_info "  Option 2: Stash for later"
            print_info "    git stash push -u -m 'Pre-merge WIP'"
            print_info ""
            print_info "  Option 3: Use auto-merge (cleanup later)"
            print_info "    /merge --auto $PR_NUMBER"
            print_info ""
            ((ERRORS++))
            exit 1
        fi

        print_success "✅ Workspace is clean - safe to proceed"
    fi

    # Now safe to merge
    confirm_merge || exit 1
    validate_merge_readiness || exit 1
    execute_merge || exit 1

    # Cleanup will succeed because we validated earlier
    if [[ "$AUTO_MERGE" != "true" ]]; then
        cleanup_worktree || {
            # This should never happen now, but handle gracefully
            print_warning "Cleanup failed despite pre-check"
            provide_recovery_instructions
        }
    fi
}
```

### Option 2: Force Cleanup with Warning (NOT Recommended)
- **Pros**: Always completes
- **Cons**: Can destroy user's work, violates safety principles
- **Effort**: Small (30 minutes)
- **Risk**: HIGH - Potential data loss

**Why rejected:** Agent OS prioritizes safety over convenience

### Option 3: Create Safety Branch (Defense in Depth)
- **Pros**: Provides backup of uncommitted work
- **Cons**: Adds complexity, clutters branch list
- **Effort**: Large (2 hours)
- **Risk**: Low

**Could be added later as enhancement:**
```bash
# Before cleanup, create safety branch
if [[ -n "$(git status --porcelain)" ]]; then
    local safety_branch="backup/pre-merge-$(date +%Y%m%d-%H%M%S)"
    git add -A
    git commit -m "Auto-backup: Pre-merge snapshot"
    git branch "$safety_branch"
    print_info "Created safety branch: $safety_branch"
fi
```

## Recommended Action

**Option 1: Pre-Merge Workspace Check** - This is the only acceptable solution for Phase 1.

### Implementation Steps
1. Move `detect_worktree()` call before `confirm_merge()` in main flow
2. Add workspace cleanliness check after worktree detection
3. Provide clear, actionable error messages with recovery options
4. Test scenarios:
   - Clean worktree (should proceed)
   - Dirty worktree with staged changes (should block)
   - Dirty worktree with unstaged changes (should block)
   - Dirty worktree with untracked files (should block)
   - Not in worktree (should skip check)
5. Update user confirmation message to note workspace was validated
6. Keep existing check in `cleanup_worktree()` as defense-in-depth

## Technical Details

**Affected Files:**
- `scripts/workflow-merge.sh` (main flow: lines 640-652)
- `cleanup_worktree()` function (lines 490-557)

**Related Components:**
- Worktree detection logic
- Merge execution workflow
- Error messaging system

**Database Changes:** None

## Resources

- Code review PR: https://github.com/carmandale/agent-os/pull/101
- Data integrity review findings: Comprehensive audit report
- Related Agent OS decisions: DEC-005 (Evidence-Based Development), DEC-008 (Verification Requirements)

## Acceptance Criteria

- [ ] `detect_worktree()` called early in main flow (before confirm_merge)
- [ ] Workspace cleanliness check added after worktree detection
- [ ] Check only runs if in worktree and not using auto-merge
- [ ] Clear error message explains problem
- [ ] Error message shows actual uncommitted changes (`git status --short`)
- [ ] Three recovery options provided with commands
- [ ] Success message confirms workspace validation passed
- [ ] Test case: Dirty worktree blocks merge (shows error, exits 1)
- [ ] Test case: Clean worktree proceeds normally
- [ ] Test case: Not in worktree skips check
- [ ] Test case: Auto-merge mode skips check
- [ ] Existing check in cleanup_worktree() preserved (defense-in-depth)
- [ ] User feedback: Instructions are clear and actionable

## Work Log

### 2025-10-15 - Code Review Discovery
**By:** Claude Code Review System (data-integrity-guardian agent)
**Actions:**
- Discovered during comprehensive data integrity review of PR #101
- Analyzed merge workflow and cleanup timing
- Identified critical timing issue in validation flow
- Categorized as P0 blocking issue due to data loss risk
- Created todo for tracking and resolution

**Learnings:**
- Validation checks must happen before destructive operations
- User experience failures compound when recovery is unclear
- Clear error messages with recovery steps are critical
- Defense-in-depth: Keep backup checks even after primary validation
- Auto-merge mode should skip interactive validations

## Notes

**BLOCKING:** This issue MUST be resolved before PR #101 can be merged to main.

**User Impact:** This is a "trap" that users will fall into frequently. Developers commonly have uncommitted WIP when they decide to merge. Without pre-merge validation, this creates a terrible user experience and potential data loss.

**Testing Priority:** HIGH - Must test with actual uncommitted changes to verify error message quality and recovery instructions.

**Context:** Part of comprehensive data integrity review that identified 6 critical data safety issues including:
- Uncommitted changes check timing (this issue)
- Branch deletion without cleanup verification (Issue #004)
- Missing rollback mechanisms
- Race conditions in worktree operations

Source: Code review performed on 2025-10-15
Review command: `/compounding-engineering:review PR #101`
