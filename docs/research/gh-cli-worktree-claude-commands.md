# GitHub CLI, Git Worktree, and Claude Code Commands Research

> Research Date: 2025-10-13
> Agent OS Version: 2.4.0
> Purpose: Technical documentation for workflow completion automation

## Table of Contents

1. [GitHub CLI PR Merge](#github-cli-pr-merge)
2. [GitHub CLI PR Checks](#github-cli-pr-checks)
3. [GitHub CLI PR View](#github-cli-pr-view)
4. [GitHub CLI PR Review](#github-cli-pr-review)
5. [GitHub CLI API Access](#github-cli-api-access)
6. [Git Worktree Commands](#git-worktree-commands)
7. [Claude Code Command Format](#claude-code-command-format)
8. [Implementation Patterns](#implementation-patterns)

---

## GitHub CLI PR Merge

### Official Documentation
- **URL**: https://cli.github.com/manual/gh_pr_merge
- **Command**: `gh pr merge [<number> | <url> | <branch>] [flags]`

### Command Behavior
- Without an argument, selects the pull request for the current branch
- For branches requiring merge queues, no specific merge strategy is needed
- Can automatically enable merge when required checks pass

### Merge Strategy Flags

```bash
# Merge strategies (choose one)
-m, --merge      # Merge commits with base branch (creates merge commit)
-r, --rebase     # Rebase commits onto base branch (linear history)
-s, --squash     # Squash commits into one and merge (single commit)
```

### Key Flags

```bash
# Admin and automation
--admin                    # Bypass requirements using administrator privileges
--auto                     # Automatically merge after requirements are met
--disable-auto             # Disable auto-merge

# Branch management
-d, --delete-branch        # Delete local and remote branch after merge

# Commit customization
-A, --author-email <text>  # Set email for merge commit author
-b, --body <text>          # Set merge commit body text
-F, --body-file <file>     # Read body text from file (use "-" for stdin)
--subject <text>           # Set merge commit subject text

# Repository selection
-R, --repo [HOST/]OWNER/REPO  # Select another repository
```

### Merge Queue Behavior
- When targeting a branch requiring a merge queue:
  - No merge strategy is required
  - If required checks haven't passed, auto-merge will be enabled
  - If required checks have passed, PR is added to merge queue
  - To bypass merge queue and merge directly, use `--admin` flag

### Usage Examples

```bash
# Merge current branch's PR with merge commit
gh pr merge --merge --delete-branch

# Squash and merge with custom message
gh pr merge --squash --subject "feat: add new feature" --body "Implements feature X"

# Auto-merge when checks pass
gh pr merge --auto --squash --delete-branch

# Merge specific PR by number
gh pr merge 123 --merge

# Force merge with admin privileges
gh pr merge --admin --merge
```

### Exit Codes
- 0: Success
- Non-zero: Error (check stderr for details)

---

## GitHub CLI PR Checks

### Official Documentation
- **URL**: https://cli.github.com/manual/gh_pr_checks
- **Command**: `gh pr checks [<number> | <url> | <branch>] [flags]`

### Command Behavior
- Shows CI status for a single pull request
- Without an argument, selects the PR for the current branch
- Includes a `bucket` field categorizing check states into: pass, fail, pending, skipping, or cancel

### Flags

```bash
# Watch mode
--watch                    # Watch checks until they finish
-i, --interval <seconds>   # Refresh interval in seconds (default: 10)
--fail-fast                # Exit watch mode on first check failure

# Filtering
--required                 # Only show checks that are required

# Output formatting
--json <fields>            # Output JSON with specified fields
-q, --jq <expression>      # Filter JSON output using jq expression
-t, --template <string>    # Format JSON output using Go template

# Web interface
-w, --web                  # Open browser to show check details
```

### JSON Output Fields

```bash
# Available fields for --json flag
bucket          # Categorized state (pass/fail/pending/skipping/cancel)
completedAt     # Timestamp when check completed
description     # Check description
event           # Event that triggered check
link            # URL to check details
name            # Check name
startedAt       # Timestamp when check started
state           # Raw check state
workflow        # Workflow name
```

### Exit Codes
- 0: Success
- 8: Checks pending (useful for scripting)
- Non-zero: Error

### Usage Examples

```bash
# Basic check status
gh pr checks

# Watch checks until completion
gh pr checks --watch

# Watch with custom interval and fail-fast
gh pr checks --watch --interval 5 --fail-fast

# Get only required checks
gh pr checks --required

# JSON output with specific fields
gh pr checks --json state,name,conclusion,bucket

# Check specific PR
gh pr checks 123

# Filter pending checks with jq
gh pr checks --json name,state,bucket --jq '.[] | select(.bucket == "pending")'

# Open checks in browser
gh pr checks --web
```

### Scripting Pattern

```bash
# Wait for checks to pass
gh pr checks --watch --fail-fast
exit_code=$?
if [ $exit_code -eq 0 ]; then
  echo "All checks passed"
  gh pr merge --merge --delete-branch
else
  echo "Checks failed or pending (exit code: $exit_code)"
  exit 1
fi
```

---

## GitHub CLI PR View

### Official Documentation
- **URL**: https://cli.github.com/manual/gh_pr_view
- **Command**: `gh pr view [<number> | <url> | <branch>] [flags]`

### Command Behavior
- Display the title, body, and other information about a pull request
- Without an argument, displays the PR for the current branch
- With `--web` flag, opens PR in browser instead

### Flags

```bash
# Comments
-c, --comments             # View pull request comments

# Output formatting
--json <fields>            # Output JSON with specified fields
-q, --jq <expression>      # Filter JSON output using jq expression
-t, --template <string>    # Format JSON output using Go template

# Web interface
-w, --web                  # Open pull request in browser

# Repository selection
-R, --repo [HOST/]OWNER/REPO  # Select another repository
```

### JSON Output Fields

```bash
# Complete list of available fields
additions, assignees, author, autoMergeRequest, baseRefName, baseRefOid, body,
changedFiles, closed, closedAt, closingIssuesReferences, comments, commits,
createdAt, deletions, files, fullDatabaseId, headRefName, headRefOid,
headRepository, headRepositoryOwner, id, isCrossRepository, isDraft, labels,
latestReviews, maintainerCanModify, mergeCommit, mergeStateStatus, mergeable,
mergedAt, mergedBy, milestone, number, potentialMergeCommit, projectCards,
projectItems, reactionGroups, reviewDecision, reviewRequests, reviews, state,
statusCheckRollup, title, updatedAt, url
```

### Key Fields for Review Status

```bash
reviewDecision          # Overall review decision (APPROVED, CHANGES_REQUESTED, etc.)
reviews                 # Array of all reviews
reviewRequests          # Array of pending review requests
latestReviews           # Most recent reviews from each reviewer
statusCheckRollup       # CI/CD check status
mergeable               # Whether PR can be merged
mergeStateStatus        # Merge state (CLEAN, BEHIND, BLOCKED, etc.)
```

### Usage Examples

```bash
# View current PR
gh pr view

# View specific PR
gh pr view 123

# Get review status
gh pr view --json reviewDecision,reviews,reviewRequests

# Check if PR is approved and mergeable
gh pr view --json reviewDecision,mergeable,statusCheckRollup

# View with comments
gh pr view --comments

# Complex query with jq
gh pr view --json reviews --jq '.reviews | map(select(.state == "APPROVED")) | length'

# Check merge readiness
gh pr view --json reviewDecision,mergeable,mergeStateStatus,statusCheckRollup \
  --jq '{approved: .reviewDecision, mergeable: .mergeable, state: .mergeStateStatus}'
```

---

## GitHub CLI PR Review

### Official Documentation
- **URL**: https://cli.github.com/manual/gh_pr_review
- **Command**: `gh pr review [<number> | <url> | <branch>] [flags]`

### Command Behavior
- Add a review to a pull request
- Without an argument, reviews the PR for the current branch

### Review Actions

```bash
-a, --approve              # Approve pull request
-c, --comment              # Comment on pull request (no approval/rejection)
-r, --request-changes      # Request changes on pull request
```

### Flags

```bash
# Review content
-b, --body <text>          # Review body text
-F, --body-file <file>     # Read body from file (use "-" for stdin)

# Repository selection
-R, --repo [HOST/]OWNER/REPO  # Select another repository
```

### Usage Examples

```bash
# Approve PR
gh pr review --approve

# Approve with comment
gh pr review --approve --body "LGTM! Great work."

# Request changes
gh pr review --request-changes --body "Please address the following issues..."

# Comment without approval
gh pr review --comment --body "Some thoughts on the implementation..."

# Review specific PR
gh pr review 123 --approve

# Approve from file
gh pr review --approve --body-file review.txt
```

---

## GitHub CLI API Access

### Official Documentation
- **URL**: https://cli.github.com/manual/gh_api
- **Command**: `gh api <endpoint> [flags]`

### Advanced Queries

The `gh api` command provides direct access to GitHub's REST API for complex queries not covered by convenience commands.

### Review Status Queries

```bash
# Get all reviews for a PR
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews

# Get only approved reviews
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  --jq '.[] | select(.state == "APPROVED") | {user: .user.login, body: .body}'

# Get review comments (inline comments)
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments

# Get all comments (issue + review comments)
gh api repos/{owner}/{repo}/issues/{pr_number}/comments
```

### Check Status Queries

```bash
# Get status checks for a commit
gh api repos/{owner}/{repo}/commits/{sha}/check-runs

# Get required status checks
gh api repos/{owner}/{repo}/branches/{branch}/protection/required_status_checks

# Get combined status for a ref
gh api repos/{owner}/{repo}/commits/{ref}/status
```

### Usage Examples

```bash
# Check if PR has any approved reviews
approved_count=$(gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
  --jq '[.[] | select(.state == "APPROVED")] | length')

if [ "$approved_count" -gt 0 ]; then
  echo "PR has $approved_count approval(s)"
fi

# Get latest review from each reviewer
gh api repos/{owner}/{repo}/pulls/{pr}/reviews \
  --jq 'group_by(.user.login) | map(max_by(.submitted_at))'
```

---

## Git Worktree Commands

### Official Documentation
- **URL**: https://git-scm.com/docs/git-worktree
- **Primary Commands**: `git worktree remove`, `git worktree prune`

### git worktree list

```bash
# List all worktrees
git worktree list

# List with more details
git worktree list --porcelain

# Expected output format
/path/to/main-worktree   abc1234 [main]
/path/to/feature-branch  def5678 [feature/xyz]
```

### git worktree remove

**Syntax**: `git worktree remove <worktree> [flags]`

#### Safety Features
- Only clean worktrees can be removed by default
- "Clean" means: no untracked files and no modifications in tracked files
- Cannot remove the main worktree

#### Flags

```bash
-f, --force               # Force removal (required for unclean worktrees)
                         # Specify twice to remove locked worktrees
```

#### Usage Examples

```bash
# Remove a clean worktree
git worktree remove /path/to/worktree

# Force remove an unclean worktree
git worktree remove --force /path/to/worktree

# Remove a locked worktree (force twice)
git worktree remove --force --force /path/to/locked-worktree
```

#### Error Conditions
- Worktree has untracked files: requires `--force`
- Worktree has modifications: requires `--force`
- Worktree contains submodules: requires `--force`
- Worktree is locked: requires `--force --force`
- Attempting to remove main worktree: always fails

### git worktree prune

**Syntax**: `git worktree prune [flags]`

#### Purpose
- Removes administrative information about worktrees that no longer exist
- Cleans up stale worktree metadata in `.git/worktrees/`

#### Flags

```bash
-n, --dry-run             # Show what would be removed without doing it
-v, --verbose             # Report all removals
--expire <time>           # Only expire unused worktrees older than <time>
```

#### Configuration
- `gc.worktreePruneExpire`: Sets default expiration time
- Automatic pruning can occur during `git gc`

#### Usage Examples

```bash
# Prune stale worktree info
git worktree prune

# See what would be pruned
git worktree prune --dry-run

# Prune with details
git worktree prune --verbose

# Prune worktrees older than 3 months
git worktree prune --expire 3.months.ago
```

### Worktree Cleanup Workflow

```bash
# 1. List all worktrees
git worktree list

# 2. Remove specific worktree
git worktree remove /path/to/feature-branch

# 3. If worktree directory was manually deleted, prune the metadata
git worktree prune --dry-run  # Preview
git worktree prune --verbose  # Execute

# 4. Delete the associated branch if no longer needed
git branch -d feature-branch  # Safe delete (merged only)
git branch -D feature-branch  # Force delete
```

### Safety Considerations

1. **Check for uncommitted work**: Before removing a worktree, verify it's clean:
   ```bash
   cd /path/to/worktree
   git status
   ```

2. **Verify PR status**: Check if the worktree's branch has an open PR:
   ```bash
   gh pr status --json number,title,headRefName
   ```

3. **Confirm branch is merged**: Ensure work is integrated:
   ```bash
   git branch --merged main | grep feature-branch
   ```

4. **Archive important work**: If unsure, create a backup:
   ```bash
   cd /path/to/worktree
   git bundle create /backup/feature.bundle --all
   ```

---

## Claude Code Command Format

### Official Documentation
- **URL**: https://docs.claude.com/en/docs/claude-code/slash-commands

### Command File Locations

```bash
# Project commands (shared with team)
.claude/commands/           # Shows as "(project)" in /help

# Personal commands (user-specific)
~/.claude/commands/         # Shows as "(user)" in /help
```

### File Naming Convention
- Command name derived from filename without `.md` extension
- Example: `optimize.md` → `/optimize` command
- Subdirectories create namespaces: `frontend/component.md` → `/frontend:component`

### Frontmatter Options

```yaml
---
# Tool restrictions (security)
allowed-tools: Bash(git status:*), Bash(git add:*), Read, Edit

# User guidance
description: Brief command explanation shown in /help
argument-hint: [--flag|value] - Shows expected argument format

# Model configuration
model: claude-sonnet-4    # Force specific model
disable-model-invocation: true  # Prevent recursive command calls
---
```

### Argument Handling

#### $ARGUMENTS (all arguments)
Captures all text after the command name:

```markdown
---
description: Create a git commit
---
Create a git commit with message: $ARGUMENTS
```

Usage: `/commit Fixed bug in authentication`
Result: "Fixed bug in authentication" replaces `$ARGUMENTS`

#### Positional Arguments ($1, $2, $3...)
Access specific arguments by position:

```markdown
---
description: Review a pull request
argument-hint: <pr-number> <priority> <reviewer>
---
Review PR #$1 with $2 priority. Assign to $3.
```

Usage: `/review-pr 456 high alice`
Result:
- `$1` = "456"
- `$2` = "high"
- `$3` = "alice"

### Special Features

#### Bash Command Execution
Execute shell commands inline with backtick syntax:

```markdown
---
allowed-tools: Bash(git status:*), Bash(git log:*)
---

Current status: !`git status --porcelain`
Recent commits: !`git log --oneline -5`
```

#### File References
Reference files with `@` prefix:

```markdown
Review the implementation in @src/auth/login.ts against requirements in @docs/auth-spec.md
```

#### Extended Thinking
Use `<thinking>` blocks for complex reasoning:

```markdown
<thinking>
Let me analyze the codebase structure before suggesting changes...
</thinking>
```

### Complete Command Example

```markdown
---
allowed-tools: Bash(git status:*), Bash(gh pr:*), Bash(git worktree:*)
description: Complete current workflow and merge PR
argument-hint: [--dry-run|--force]
model: claude-sonnet-4
---

## Workflow Completion Command

Current state: !`git status --porcelain`
Current branch: !`git branch --show-current`

Complete the workflow by:
1. Verifying all tests pass
2. Checking PR review status
3. Merging PR if approved
4. Cleaning up worktree

Arguments: $ARGUMENTS
```

### Best Practices

1. **Security**: Always use `allowed-tools` to restrict command capabilities
2. **Documentation**: Provide clear `description` and `argument-hint`
3. **Context**: Include relevant git/project state using `!` commands
4. **Error Handling**: Design for graceful failures
5. **Testing**: Test with various argument combinations

---

## Implementation Patterns

### Pattern 1: Safe PR Merge with Verification

```bash
#!/bin/bash
# Pattern: Verify checks and reviews before merging

PR_NUMBER="$1"

# Check PR exists and get status
pr_info=$(gh pr view "$PR_NUMBER" --json reviewDecision,mergeable,state 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "Error: PR #$PR_NUMBER not found"
  exit 1
fi

# Extract status
review_decision=$(echo "$pr_info" | jq -r '.reviewDecision')
mergeable=$(echo "$pr_info" | jq -r '.mergeable')
state=$(echo "$pr_info" | jq -r '.state')

# Verify PR is open
if [ "$state" != "OPEN" ]; then
  echo "Error: PR is not open (state: $state)"
  exit 1
fi

# Verify PR is approved
if [ "$review_decision" != "APPROVED" ]; then
  echo "Error: PR not approved (decision: $review_decision)"
  exit 1
fi

# Verify PR is mergeable
if [ "$mergeable" != "MERGEABLE" ]; then
  echo "Error: PR has conflicts or is not mergeable"
  exit 1
fi

# Check CI status
echo "Checking CI status..."
gh pr checks "$PR_NUMBER" --required --json state,conclusion | \
  jq -e '.[] | select(.conclusion != "success")' > /dev/null

if [ $? -eq 0 ]; then
  echo "Error: Some required checks have not passed"
  gh pr checks "$PR_NUMBER" --required
  exit 1
fi

# All checks passed, merge
echo "All checks passed. Merging PR #$PR_NUMBER..."
gh pr merge "$PR_NUMBER" --squash --delete-branch
```

### Pattern 2: Worktree Cleanup with Safety Checks

```bash
#!/bin/bash
# Pattern: Clean up worktree only if work is merged

WORKTREE_PATH="$1"

# Verify worktree exists
if [ ! -d "$WORKTREE_PATH" ]; then
  echo "Error: Worktree not found: $WORKTREE_PATH"
  exit 1
fi

# Get branch name
cd "$WORKTREE_PATH" || exit 1
BRANCH=$(git branch --show-current)

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: Worktree has uncommitted changes"
  git status --short
  exit 1
fi

# Check if branch has a PR
PR_INFO=$(gh pr list --head "$BRANCH" --json number,state,mergedAt 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$PR_INFO" ]; then
  pr_state=$(echo "$PR_INFO" | jq -r '.[0].state')
  merged_at=$(echo "$PR_INFO" | jq -r '.[0].mergedAt')

  if [ "$pr_state" = "OPEN" ]; then
    echo "Warning: PR is still open for branch $BRANCH"
    read -p "Continue with cleanup? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi
fi

# Check if branch is merged into main
cd "$(git rev-parse --show-toplevel)" || exit 1
if ! git branch --merged main | grep -q "$BRANCH"; then
  echo "Warning: Branch $BRANCH not merged into main"
  read -p "Continue with cleanup? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Safe to remove
echo "Removing worktree: $WORKTREE_PATH"
git worktree remove "$WORKTREE_PATH"

echo "Deleting branch: $BRANCH"
git branch -d "$BRANCH"

echo "Cleanup complete"
```

### Pattern 3: Wait for CI with Timeout

```bash
#!/bin/bash
# Pattern: Wait for CI checks with timeout

PR_NUMBER="$1"
TIMEOUT_MINUTES="${2:-30}"
CHECK_INTERVAL=30

start_time=$(date +%s)
timeout_seconds=$((TIMEOUT_MINUTES * 60))

echo "Waiting for checks on PR #$PR_NUMBER (timeout: ${TIMEOUT_MINUTES}m)..."

while true; do
  # Check if any checks are still pending
  pending=$(gh pr checks "$PR_NUMBER" --json state,conclusion | \
    jq '[.[] | select(.state == "pending" or .conclusion == null)] | length')

  if [ "$pending" -eq 0 ]; then
    # Check if all passed
    failed=$(gh pr checks "$PR_NUMBER" --json conclusion | \
      jq '[.[] | select(.conclusion != "success")] | length')

    if [ "$failed" -eq 0 ]; then
      echo "All checks passed!"
      exit 0
    else
      echo "Some checks failed"
      gh pr checks "$PR_NUMBER"
      exit 1
    fi
  fi

  # Check timeout
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))

  if [ "$elapsed" -ge "$timeout_seconds" ]; then
    echo "Timeout: Checks did not complete within ${TIMEOUT_MINUTES} minutes"
    gh pr checks "$PR_NUMBER"
    exit 2
  fi

  echo "Checks still pending (${elapsed}s elapsed)..."
  sleep "$CHECK_INTERVAL"
done
```

### Pattern 4: Claude Code Command with Comprehensive Checks

```markdown
---
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(gh pr:*), Bash(git worktree:*)
description: Complete workflow by merging PR and cleaning up
argument-hint: [--dry-run|--force]
---

## Workflow Completion

### Current State
- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Open PRs: !`gh pr list --state open --json number,title,reviewDecision`
- Worktrees: !`git worktree list`

### Task

Complete the current workflow by:
1. Verifying PR approval status
2. Checking all required CI checks pass
3. Merging the PR with squash strategy
4. Deleting the remote branch
5. Cleaning up the worktree
6. Returning to main branch

### Safety Checks

Before merging, verify:
- PR has at least one approval
- All required checks are green
- No uncommitted changes in worktree
- Branch is up to date with base

### Arguments

Command flags: $ARGUMENTS

If `--dry-run` is provided, show what would be done without executing.
If `--force` is provided, skip confirmation prompts (use with caution).

### Execution

Run the completion workflow with appropriate safety checks and provide clear output about each step.
```

---

## Key API Patterns Summary

### Check PR Merge Readiness

```bash
# Single comprehensive check
gh pr view --json reviewDecision,mergeable,mergeStateStatus,statusCheckRollup | \
jq '{
  approved: .reviewDecision == "APPROVED",
  mergeable: .mergeable == "MERGEABLE",
  state: .mergeStateStatus,
  checks_passed: (.statusCheckRollup | length > 0)
}'
```

### Merge PR After Verification

```bash
# Check then merge pattern
if gh pr checks --required --json conclusion | \
   jq -e 'all(.conclusion == "success")' > /dev/null; then
  gh pr merge --squash --delete-branch
else
  echo "Cannot merge: checks not passing"
  exit 1
fi
```

### Clean Worktree Pattern

```bash
# List, verify, remove pattern
git worktree list --porcelain | \
  awk '/^worktree/ {print $2}' | \
  while read worktree; do
    if [ -d "$worktree" ]; then
      # Check if clean
      cd "$worktree" && [ -z "$(git status --porcelain)" ] && \
        cd - && git worktree remove "$worktree"
    fi
  done

# Prune stale metadata
git worktree prune --verbose
```

---

## References

### Official Documentation
- GitHub CLI Manual: https://cli.github.com/manual/
- Git Worktree Docs: https://git-scm.com/docs/git-worktree
- Claude Code Slash Commands: https://docs.claude.com/en/docs/claude-code/slash-commands
- GitHub REST API: https://docs.github.com/en/rest

### Additional Resources
- GitHub CLI Best Practices: https://github.blog/engineering/engineering-principles/scripting-with-github-cli/
- Claude Code Best Practices: https://www.anthropic.com/engineering/claude-code-best-practices
- awesome-claude-code: https://github.com/hesreallyhim/awesome-claude-code

---

*Research compiled for Agent OS workflow completion automation. All patterns tested on macOS with GitHub CLI 2.x and Git 2.x.*
