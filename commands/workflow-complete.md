---
allowed-tools: Bash(git status:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(git branch:*), Bash(gh issue:*), Bash(gh pr:*), Bash(aos status:*), Bash(~/.agent-os/scripts/workflow-complete.sh:*), Bash(~/.agent-os/scripts/update-documentation.sh:*)
description: Complete current Agent OS workflow by ensuring all steps are properly finished and integrated
argument-hint: [--dry-run|--force|--no-pr|--issue ISSUE_NUMBER]
---

## Context

- Current git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Open PRs: !`gh pr list --state open --limit 3`
- Recent commits: !`git log --oneline -3`

## Task

Complete the current Agent OS workflow by executing all required steps to properly finish and integrate work. This command ensures nothing is forgotten and all Agent OS standards are met.

### Workflow Completion Process

!`~/.agent-os/scripts/workflow-complete.sh $ARGUMENTS`

## What This Command Does

### Phase 1: Pre-completion Checks
1. **Analyze current state** - Identify uncommitted changes, current branch, related issues
2. **Validate workspace** - Ensure no blocking issues or conflicts
3. **Check documentation** - Run `/update-documentation --dry-run` to detect drift

### Phase 2: Documentation & Commits
4. **Update CHANGELOG.md** - Add entries for recent work based on commits
5. **Commit all changes** - Stage and commit with proper conventional commit messages
6. **Update issue references** - Ensure commits reference relevant GitHub issues

### Phase 3: GitHub Integration
7. **Create/update PR** - Generate PR with comprehensive description and evidence
8. **Link issues** - Ensure PR properly links to related GitHub issues
9. **Update roadmap** - Mark completed roadmap items if applicable

### Phase 4: Final Integration
10. **Close issues** - Mark completed GitHub issues as closed with resolution summary
11. **Clean workspace** - Return to main branch with clean working tree
12. **Final verification** - Confirm all workflow steps completed successfully

## Available Options

- **--dry-run**: Preview all actions without making any changes
- **--force**: Override safety checks and warnings (use with caution)
- **--no-pr**: Skip PR creation if work should be committed directly to main
- **--issue ISSUE_NUMBER**: Explicitly specify which issue this work addresses

## Usage Examples

```bash
# Complete workflow with all safety checks
/workflow-complete

# Preview what would be done without executing
/workflow-complete --dry-run

# Complete workflow for specific issue
/workflow-complete --issue 123

# Force completion even with warnings
/workflow-complete --force

# Complete without creating PR (direct to main)
/workflow-complete --no-pr
```

## Success Criteria

This command is successful when:
- ✅ All changes committed with proper messages
- ✅ CHANGELOG.md updated with recent work
- ✅ Documentation drift resolved
- ✅ PR created with evidence and proper description
- ✅ Related GitHub issues updated/closed
- ✅ Workspace clean and on main branch
- ✅ Ready for new feature development

## Integration

This command integrates with existing Agent OS tools:
- Uses `/update-documentation` for drift detection
- Leverages `aos status` for system health checks
- Follows Agent OS git workflow patterns
- Respects existing workflow enforcement hooks
- Maintains compatibility with work sessions

## Notes

- This command implements the complete Agent OS workflow from step-4-git-integration.md
- Designed to prevent workflow abandonment and ensure professional development practices
- Can be used at any point to "catch up" on missed workflow steps
- Provides clear success/failure feedback with actionable next steps