---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(gh issue:*), Bash(gh pr:*), Bash(aos status:*), Bash(~/.agent-os/scripts/workflow-status.sh:*)
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

!`~/.agent-os/scripts/workflow-status.sh $ARGUMENTS`

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

## Usage Examples

```bash
# Quick health check
/workflow-status

# Detailed analysis
/workflow-status --verbose

# Get specific fix commands
/workflow-status --fix-suggestions
```

## Notes

- Use this command before starting new features to ensure clean workspace
- Run after completing work to verify everything is properly integrated
- Integrates with existing Agent OS tools (aos status, update-documentation)
- Provides actionable next steps for any issues found