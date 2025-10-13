# Merge Command Specification

> **Issue:** #100
> **Created:** 2025-10-13
> **Status:** Planning
> **Size Estimate:** XL (32-46 hours)

## Overview

Create an intelligent `/merge` command for Agent OS that automates the complete PR merge workflow with safety checks, code review integration, and automatic worktree cleanup. The command should infer PR context from conversation, validate readiness for merge, address any review feedback, and clean up after successful integration.

## Problem Statement

### Current Workflow Pain Points

1. **Manual PR merge requires multiple manual steps:**
   - Checking PR status on GitHub
   - Reviewing CodeRabbit/Codex feedback
   - Addressing review comments
   - Verifying CI status
   - Manual merge execution
   - Worktree cleanup
   - Branch deletion

2. **Context switching between tools:**
   - AI conversation → GitHub web UI → Terminal → Back to AI
   - Lost context when reviewing feedback
   - Manual copy-paste of PR numbers

3. **Risk of premature merges:**
   - No systematic pre-merge validation
   - Easy to miss failing CI checks
   - Potential to merge with unresolved review comments

4. **Worktree management overhead:**
   - Orphaned worktrees after manual merges
   - Manual cleanup commands
   - Risk of deleting wrong worktree

### User Story

> "As a developer using Agent OS, when I've completed work on a feature branch in a worktree, I want to type `/merge` and have the system intelligently merge my PR after validating it's ready, addressing any review feedback, and cleaning up the worktree automatically."

## Proposed Solution

Create a `/merge` command that provides intelligent, context-aware PR merge automation with comprehensive safety checks and optional review feedback resolution.

### Command Syntax

```bash
/merge [pr_number]              # Merge specific PR
/merge                          # Infer PR from current branch/context
/merge --dry-run               # Show what would happen without executing
/merge --force                 # Skip some validation checks (with warnings)
/merge --auto                  # Enable GitHub auto-merge when checks pass
```

### High-Level Workflow

1. **PR Inference** - Infer PR from argument, branch name, or conversation context
2. **User Confirmation** - Display "Merge PR #XX?" for user approval
3. **Pre-Merge Validation** - Check CI status, reviews, conflicts, branch protection
4. **Review Feedback** - Detect and address CodeRabbit/Codex comments if present
5. **Merge Execution** - Execute merge via `gh pr merge` when green
6. **Worktree Cleanup** - If in worktree: return to main, verify merge, delete worktree

### Key Features

- **Context-aware PR inference** from conversation, branch, or explicit argument
- **User confirmation** before destructive operations
- **Comprehensive safety checks** (CI, reviews, conflicts)
- **Review feedback integration** with CodeRabbit/Codex
- **Automatic worktree cleanup** with verification
- **Graceful error handling** with recovery suggestions

## Success Metrics

### Quantitative
- **Time Savings:** Reduce merge workflow from 5-10 minutes to <1 minute
- **Error Reduction:** Decrease premature merges by 100% (validation prevents)
- **Adoption:** 80%+ of Agent OS users use `/merge` within 1 month
- **Worktree Cleanup:** Eliminate orphaned worktrees (currently a common issue)

### Qualitative
- Users report merge process feels "seamless"
- Reduced anxiety about merge safety
- Positive feedback on review feedback integration
- Perceived as "Agent OS magic"

## Implementation Phases

### Phase 1: Core Merge Automation (MVP)
**Goal:** Basic merge with safety checks
**Acceptance Criteria:**
- `/merge` infers PR from current branch
- User receives confirmation prompt before merge
- Validates PR is mergeable and checks pass
- Executes merge with `gh pr merge`
- Updates local main branch after merge

### Phase 2: Review Feedback Integration
**Goal:** Address review comments before merge
**Acceptance Criteria:**
- Detects unresolved review comments
- Displays critical issues requiring action
- Allows user to address issues before proceeding
- Re-checks review status after fixes

### Phase 3: Worktree Management
**Goal:** Automatic cleanup after successful merge
**Acceptance Criteria:**
- Detects when running in a worktree
- Returns to main repository after merge
- Safely removes worktree after verification
- Updates main branch with latest changes

### Phase 4: Advanced Features & Polish
**Goal:** Production-ready with full safety and UX
**Acceptance Criteria:**
- `--dry-run` shows actions without execution
- `--auto` enables GitHub auto-merge feature
- Clear error messages with recovery suggestions
- Beautiful terminal output with colors/icons

## References

### Internal References
- **Command patterns:** `commands/workflow-status.md`
- **Script patterns:** `scripts/workflow-complete.sh:428`
- **Git workflow:** `workflow-modules/step-4-git-integration.md:134`
- **Worktree detection:** `scripts/workflow-status.sh:282-365`
- **Installation pattern:** `setup-claude-code.sh:65-77`

### External References
- **GitHub CLI merge:** https://cli.github.com/manual/gh_pr_merge
- **GitHub CLI checks:** https://cli.github.com/manual/gh_pr_checks
- **GitHub CLI PR view:** https://cli.github.com/manual/gh_pr_view
- **Git worktree:** https://git-scm.com/docs/git-worktree
- **Branch protection:** https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches

### Research Documents
- **PR merge best practices:** `docs/research/pr-merge-automation-best-practices.md`
- **GitHub CLI patterns:** `docs/research/gh-cli-worktree-claude-commands.md`

### Related Work
- **Workflow completion:** #37 (Claude Code hooks implementation)
- **Worktree tracking:** #97 (Worktree listing feature)
- **Context awareness:** #98 (Stop-hook context enhancement)
