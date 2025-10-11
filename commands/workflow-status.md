---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git worktree:*), Bash(gh issue:*), Bash(gh pr:*), Bash(aos status:*), Bash(~/.agent-os/scripts/workflow-status-wrapper.sh:*)
description: Check Agent OS workflow health and identify what needs attention before continuing work
argument-hint: [--verbose|--fix-suggestions]
---

## Context

- Current git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -5`

## Task

Check the current Agent OS workflow health and identify any issues that need attention before starting new work or completing current tasks.

### Workflow Health Report

!`~/.agent-os/scripts/workflow-status-wrapper.sh $ARGUMENTS`

## Available Modes

- **Normal Mode (default)**: Quick workflow health check showing critical issues
- **--verbose**: Detailed analysis with explanations and context
- **--fix-suggestions**: Include specific commands to fix identified issues

## What This Command Checks

### Critical Workflow Issues
- ❌ **Uncommitted Changes**: Files that need to be committed
- ❌ **Documentation Drift**: CHANGELOG.md or docs out of date  
- ❌ **Open Issues**: GitHub issues that should be closed
- ❌ **Incomplete PRs**: Pull requests needing attention
- ❌ **Branch Status**: Not on main branch or behind remote

### Workflow Health Indicators
- ✅ **Clean Git Status**: Working tree clean
- ✅ **Documentation Current**: No drift detected
- ✅ **Issues Synchronized**: All related issues properly tracked
- ✅ **On Main Branch**: Ready for new work
- ✅ **Agent OS Status**: All components current
- ✅ **Git Worktrees**: Active worktrees tracked with GitHub issue/PR status
- ⚠️ **Stale Worktrees**: Worktrees with closed issues/PRs or merged branches

## Usage Examples

```bash
# Quick health check
/workflow-status

# Detailed analysis
/workflow-status --verbose

# Get specific fix commands
/workflow-status --fix-suggestions
```

## Git Worktree Integration

The workflow-status command now tracks all git worktrees and their connection to GitHub issues and PRs:

### Worktree Status Indicators

- ✅ **Active Worktrees**: Connected to open GitHub issues or PRs
- ⚠️ **Stale Worktrees**: Connected to closed issues/PRs or merged branches
- ℹ️ **Informational**: Worktrees without GitHub associations

### Example Output

```
Git Worktrees
=============
✅ ../agent-os (main) - primary worktree
✅ ../issue-96 (issue-96-worktree-listing) - Issue #96: Add worktree listing (open)
⚠️  ../issue-88 (feature-88-hooks) - Issue #88: Claude hooks (closed) - consider cleanup
ℹ️  Found 3 worktrees (1 needs attention)
```

### Worktree Features

- **Automatic Detection**: Detects issue numbers from branch names (`issue-123`, `123-feature`, etc.)
- **GitHub Integration**: Fetches issue/PR status and titles using GitHub CLI
- **Performance Caching**: Caches GitHub API responses for 5 minutes
- **Cleanup Suggestions**: Recommends removing worktrees for closed issues/merged branches
- **Graceful Degradation**: Works without GitHub CLI, showing basic worktree info

## Notes

- Use this command before starting new features to ensure clean workspace
- Run after completing work to verify everything is properly integrated
- Integrates with existing Agent OS tools (aos status, update-documentation)
- Provides actionable next steps for any issues found
- Worktree tracking helps manage parallel development work streams