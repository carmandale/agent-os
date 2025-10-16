---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git branch:*), Bash(git worktree:*), Bash(git fetch:*), Bash(git pull:*), Bash(git checkout:*), Bash(gh pr:*), Bash(gh api:*), Bash(gh repo:*), Bash(grep:*), Bash(sed:*), Bash(~/.agent-os/scripts/workflow-merge.sh:*)
description: Intelligently merge pull requests with safety checks, review feedback integration, and worktree cleanup
argument-hint: [--dry-run|--force|--auto|--strategy merge|squash|rebase] [pr_number]
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Current worktree: !`git worktree list | grep "$(pwd)" || echo "Not in a worktree"`

## Task

Merge a pull request with comprehensive safety checks, optional review feedback resolution, and automatic worktree cleanup.

### Merge Pull Request

!`~/.agent-os/scripts/workflow-merge.sh $ARGUMENTS`

## What This Command Does

### PR Inference
- **Explicit Argument**: Use specified PR number (`/merge 123`)
- **Current Branch**: Infer from current branch via `gh pr list --head`
- **Branch Pattern**: Extract issue number from branch name patterns
- **Conversation Context**: (Future) Parse recent conversation for PR mentions

### Pre-Merge Validation
- ✅ **CI/CD Checks**: Verify all checks passing
- ✅ **Review Approval**: Check required approvals received
- ✅ **Merge Conflicts**: Ensure no conflicts with target branch
- ✅ **Branch Protection**: Validate protection rules satisfied

### Review Feedback Integration
- 🤖 **CodeRabbit Comments**: Detect and display automated review feedback
- 🤖 **Codex Comments**: Detect and display Codex review feedback
- 📝 **User Interaction**: Option to address feedback before merging

### Merge Execution
- 🔀 **Safe Merge**: Execute merge via `gh pr merge` with strategy
- 🏷️ **Branch Cleanup**: Automatically delete merged branch
- 🔄 **Local Update**: Update local main branch after merge

### Worktree Cleanup (If Applicable)
- 🧹 **Auto-Detection**: Detect if running in a worktree
- 🏠 **Return to Main**: Navigate back to main repository
- 🔄 **Update Main**: Fetch and pull latest changes
- ✅ **Verify Merge**: Confirm merge present in main
- 🗑️ **Remove Worktree**: Safely remove worktree directory
- 🔧 **Prune Metadata**: Clean up git worktree metadata

## Command Flags

### Execution Modes
- **--dry-run**: Show what would happen without executing
- **--force**: Skip validation checks (use with caution)
- **--auto**: Enable GitHub auto-merge (merge when checks pass)

### Merge Strategies
- **--strategy merge**: Create merge commit (default)
- **--strategy squash**: Squash commits before merging
- **--strategy rebase**: Rebase and merge

## Usage Examples

```bash
# Merge PR inferred from current branch
/merge

# Merge specific PR
/merge 123

# Preview merge without executing
/merge --dry-run

# Merge with squash strategy
/merge --strategy squash

# Enable auto-merge for PR
/merge --auto 123

# Force merge (skip validation)
/merge --force 123
```

## Safety Features

### Validation Checks
- Blocks merge if CI failing
- Requires approval if branch protection enabled
- Detects merge conflicts before attempting merge
- Validates branch protection rules

### User Confirmations
- Confirms PR number before proceeding
- Prompts for review feedback resolution
- Shows clear summary of what will happen

### Error Handling
- Clear error messages with recovery suggestions
- Graceful degradation on network issues
- Preserves worktree if merge fails
- Rollback-safe operations

## Workflow Integration

This command integrates with Agent OS workflows:

1. **After `/execute-tasks`**: When feature implementation complete
2. **With `/workflow-complete`**: Part of complete workflow automation
3. **Manual PR Creation**: After pushing feature branch
4. **Review Response**: After addressing review feedback

## Example Workflow

```bash
# 1. Complete feature in worktree
cd .worktrees/feature-name-#123

# 2. Create PR (via /workflow-complete or manually)
gh pr create --title "feat: add feature" --body "..."

# 3. Wait for CI and reviews...

# 4. Merge PR with automatic cleanup
/merge

# Result: PR merged, worktree cleaned up, back on main branch
```

## Notes

- Uses GitHub CLI (`gh`) for all GitHub operations
- Respects repository branch protection rules
- CodeRabbit/Codex integration is automatic
- Worktree cleanup only runs if in a worktree
- All operations are safe and reversible before merge
- Dry-run mode available for preview
