# GitHub CLI and Git Worktree Integration Research

> Research Date: 2025-10-11
> Purpose: workflow-status command development for Agent OS
> Status: Complete

## Summary

This document provides comprehensive technical documentation for integrating GitHub CLI (`gh`) with git worktrees to display worktree status with associated GitHub issues and pull requests. This research supports the Agent OS workflow-status command implementation.

## 1. GitHub CLI JSON Output Capabilities

### 1.1 Available JSON Fields

#### Pull Requests (`gh pr list --json`)

Complete list of available fields:
```
additions, assignees, author, autoMergeRequest, baseRefName, baseRefOid, body,
changedFiles, closed, closedAt, closingIssuesReferences, comments, commits,
createdAt, deletions, files, fullDatabaseId, headRefName, headRefOid,
headRepository, headRepositoryOwner, id, isCrossRepository, isDraft, labels,
latestReviews, maintainerCanModify, mergeCommit, mergeStateStatus, mergeable,
mergedAt, mergedBy, milestone, number, potentialMergeCommit, projectCards,
projectItems, reactionGroups, reviewDecision, reviewRequests, reviews, state,
statusCheckRollup, title, updatedAt, url
```

**Key fields for workflow-status:**
- `headRefName`: Branch name of the PR
- `number`: PR number
- `title`: PR title
- `state`: PR state (OPEN, CLOSED, MERGED)
- `closingIssuesReferences`: Linked issues that this PR closes

#### Issues (`gh issue list --json`)

Complete list of available fields:
```
assignees, author, body, closed, closedAt, closedByPullRequestsReferences,
comments, createdAt, id, isPinned, labels, milestone, number, projectCards,
projectItems, reactionGroups, state, stateReason, title, updatedAt, url
```

**Key fields for workflow-status:**
- `number`: Issue number
- `title`: Issue title
- `state`: Issue state (OPEN, CLOSED)
- `closedByPullRequestsReferences`: PRs that closed this issue

### 1.2 Command Usage Patterns

#### Discover Available Fields

To see all available fields for any command:
```bash
gh pr list --json
gh issue list --json
```

This will error and display the complete list of field names.

#### Basic JSON Query

```bash
# Get specific fields for all PRs
gh pr list --json number,headRefName,title,state,closingIssuesReferences

# Get specific fields for all issues
gh issue list --json number,title,state,closedByPullRequestsReferences

# Limit results
gh pr list --limit 10 --json number,title,state

# Include all states (open, closed, merged)
gh pr list --state all --json number,headRefName,state
```

#### Filter by Branch

```bash
# Filter PRs by head branch (the source branch)
gh pr list --head "feature/my-branch" --json number,title,state

# Filter PRs by base branch (the target branch)
gh pr list --base "main" --json number,title,state

# Note: The --head flag does NOT support "owner:branch" syntax
# Use just the branch name: "my-branch"
```

#### View Current Branch PR

```bash
# Without arguments, shows PR for current branch
gh pr view

# With JSON output
gh pr view --json number,title,state,closingIssuesReferences
```

### 1.3 Example JSON Output

**Pull Request with Issue References:**
```json
{
  "closingIssuesReferences": [
    {
      "id": "I_kwDOPTKvPs7IUp1G",
      "number": 87,
      "repository": {
        "id": "R_kgDOPTKvPg",
        "name": "agent-os",
        "owner": {
          "id": "MDQ6VXNlcjIzNDg4MTk=",
          "login": "carmandale"
        }
      },
      "url": "https://github.com/carmandale/agent-os/issues/87"
    }
  ],
  "headRefName": "remove-optional-prompts-make-mandatory-#87",
  "number": 88,
  "state": "MERGED",
  "title": "Make subagents and hooks mandatory"
}
```

**Issue with Empty PR References:**
```json
{
  "closedByPullRequestsReferences": [],
  "number": 95,
  "state": "OPEN",
  "title": "Overhaul Installation System"
}
```

## 2. GitHub GraphQL API for Batch Queries

### 2.1 Why Use GraphQL

**Performance Benefits:**
- One complex GraphQL query can replace 5-10 separate REST API calls
- Reduce API rate limit consumption by 80%+
- Fetch exactly what you need with field selection
- Support for pagination with cursors

**Batch Multiple Queries:**
- Use aliases to batch multiple queries in a single request
- Retrieve repository issues, labels, and comments in one call
- More efficient than sequential REST API calls

### 2.2 GraphQL Query Pattern

```bash
gh api graphql --paginate -f query='
query($endCursor: String) {
  repository(owner: "OWNER", name: "REPO") {
    pullRequests(first: 100, after: $endCursor) {
      nodes {
        number
        headRefName
        title
        state
        closingIssuesReferences(first: 10) {
          nodes {
            number
            title
          }
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
'
```

**Key Features:**
- `--paginate`: Automatically fetches all pages
- `$endCursor`: Variable for pagination
- `pageInfo`: Required for pagination to work
- `nodes`: Array of results

### 2.3 Real-World Example

The following query retrieves all PRs with their associated issues:

```bash
gh api graphql --paginate -f query='
query($endCursor: String) {
  repository(owner: "carmandale", name: "agent-os") {
    pullRequests(first: 50, after: $endCursor, orderBy: {field: CREATED_AT, direction: DESC}) {
      nodes {
        number
        headRefName
        title
        state
        closingIssuesReferences(first: 5) {
          nodes {
            number
            title
          }
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
'
```

This returns multiple JSON objects (one per page), which need to be parsed separately.

### 2.4 Performance Optimization Strategies

**1. Pagination:**
- Use `first: 100` for maximum batch size (GitHub limit)
- Always include `pageInfo` fields for `--paginate` to work
- Process pages as they arrive (streaming approach)

**2. Field Selection:**
- Only request fields you need
- Reduces response size by 80%+
- Faster parsing and lower memory usage

**3. Caching:**
- Cache PR/issue mapping for the session
- Use TTL (time-to-live) cache with reasonable expiry (5-15 minutes)
- Invalidate cache on git operations (push, checkout, etc.)

**4. Batching:**
- Fetch all PRs once at startup, not per-worktree
- Build in-memory index: `branch_name -> {pr_number, issue_numbers[]}`
- Lookup is O(1) instead of O(n) API calls

## 3. Git Worktree Porcelain Format

### 3.1 Format Specification

**Command:**
```bash
git worktree list --porcelain
```

**Format Rules:**
- One attribute per line
- Format: `label value` (space-separated)
- Boolean attributes: label only (no value)
- Empty line indicates end of record
- With `-z` flag: NUL-terminated instead of newlines

### 3.2 Available Attributes

- `worktree <path>`: Path to the worktree (always first attribute)
- `HEAD <commit-sha>`: Current commit SHA
- `branch <ref>`: Full ref name (e.g., `refs/heads/main`)
- `bare`: Boolean flag (present if bare repository)
- `detached`: Boolean flag (present if HEAD is detached)
- `locked [reason]`: Boolean or with reason
- `prunable [reason]`: Boolean or with reason

### 3.3 Example Output

```
worktree /Users/dalecarman/Projects/agent-os
HEAD b43836dea907dcdb507feaca91d151f265afdfac
branch refs/heads/main

worktree /Users/dalecarman/Projects/agent-os-feature-42
HEAD 1234abc1234abc1234abc1234abc1234abc1234a
branch refs/heads/feature/fix-issue-#42-description

worktree /Users/dalecarman/Projects/agent-os-detached
HEAD 5678def5678def5678def5678def5678def5678d
detached

worktree /Users/dalecarman/Projects/agent-os-locked
HEAD 9abc0129abc0129abc0129abc0129abc0129abc
branch refs/heads/locked-branch
locked reason: in progress work
```

### 3.4 Parsing Algorithm

```bash
#!/bin/bash

parse_worktrees() {
  local worktree_path=""
  local head_sha=""
  local branch_ref=""
  local is_detached=false
  local is_locked=false
  local lock_reason=""

  while IFS= read -r line; do
    if [[ -z "$line" ]]; then
      # End of record - process worktree
      if [[ -n "$worktree_path" ]]; then
        process_worktree "$worktree_path" "$branch_ref" "$head_sha" "$is_detached"
      fi

      # Reset for next record
      worktree_path=""
      head_sha=""
      branch_ref=""
      is_detached=false
      is_locked=false
      lock_reason=""
    elif [[ "$line" =~ ^worktree\ (.+)$ ]]; then
      worktree_path="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^HEAD\ (.+)$ ]]; then
      head_sha="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^branch\ (.+)$ ]]; then
      branch_ref="${BASH_REMATCH[1]}"
    elif [[ "$line" == "detached" ]]; then
      is_detached=true
    elif [[ "$line" =~ ^locked($|\ (.+)$) ]]; then
      is_locked=true
      lock_reason="${BASH_REMATCH[2]}"
    fi
  done < <(git worktree list --porcelain)
}
```

### 3.5 Extract Branch Name

```bash
# From full ref (refs/heads/main) to branch name (main)
branch_ref="refs/heads/feature/my-branch"
branch_name="${branch_ref#refs/heads/}"
echo "$branch_name"  # Output: feature/my-branch
```

## 4. Branch-to-Issue/PR Mapping Strategies

### 4.1 Pattern: Parse Issue Number from Branch Name

Many teams include issue numbers in branch names following patterns like:
- `feature-#42-description`
- `fix-issue-#123`
- `42-feature-name`
- `feature/ABC-123-description` (Jira style)

**Regex Patterns:**

```bash
# Extract #42 pattern
echo "fix-issue-#42-description" | grep -oE '#[0-9]+' | sed 's/#//'
# Output: 42

# Extract leading number pattern
echo "42-feature-name" | grep -oE '^[0-9]+'
# Output: 42

# Extract Jira-style pattern
echo "feature/ABC-123-description" | grep -oE '[A-Z]+-[0-9]+' | cut -d'-' -f2
# Output: 123

# Universal pattern (finds any #N or leading N)
parse_issue_from_branch() {
  local branch="$1"

  # Try #N pattern first
  if [[ "$branch" =~ \#([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi

  # Try leading N pattern
  if [[ "$branch" =~ ^([0-9]+)- ]]; then
    echo "${BASH_REMATCH[1]}"
    return 0
  fi

  return 1
}
```

### 4.2 Pattern: Query GitHub for Branch's PR

**Method 1: Filter by Head Branch**
```bash
# Get PR for specific branch
gh pr list --head "feature/my-branch" --json number,title,state,closingIssuesReferences

# Example result:
# [{"number": 42, "title": "Add feature", "state": "OPEN", "closingIssuesReferences": [{"number": 41}]}]
```

**Method 2: Build Complete PR Index**
```bash
# Fetch all PRs once and build index
gh pr list --state all --limit 1000 --json number,headRefName,title,state,closingIssuesReferences > pr_cache.json

# Then lookup in-memory or with jq
jq -r '.[] | select(.headRefName == "feature/my-branch") | .number' pr_cache.json
```

**Method 3: Use GraphQL for Batch Lookup**
```bash
# Single query for all PRs with issue references
gh api graphql --paginate -f query='...' | jq -s 'map(.data.repository.pullRequests.nodes) | flatten'
```

### 4.3 Pattern: Map Issues to PRs

**Issues → PRs (via closedByPullRequestsReferences):**
```bash
gh issue view 42 --json number,title,closedByPullRequestsReferences
```

**PRs → Issues (via closingIssuesReferences):**
```bash
gh pr view 88 --json number,title,closingIssuesReferences
```

### 4.4 Recommended Approach for workflow-status

**Efficient Multi-Worktree Strategy:**

1. **One-Time Fetch at Command Start:**
   ```bash
   # Fetch all PRs with issue references
   pr_data=$(gh pr list --state all --limit 1000 --json number,headRefName,title,state,closingIssuesReferences)
   ```

2. **Build In-Memory Index:**
   ```bash
   # Create associative array: branch_name -> pr_info
   declare -A branch_to_pr

   while read -r pr; do
     branch=$(echo "$pr" | jq -r '.headRefName')
     branch_to_pr["$branch"]="$pr"
   done < <(echo "$pr_data" | jq -c '.[]')
   ```

3. **Lookup Per Worktree:**
   ```bash
   for worktree in $(git worktree list --porcelain); do
     # Parse worktree info
     branch_name="..."

     # Lookup PR (O(1) operation)
     pr_info="${branch_to_pr[$branch_name]}"

     if [[ -n "$pr_info" ]]; then
       pr_number=$(echo "$pr_info" | jq -r '.number')
       pr_state=$(echo "$pr_info" | jq -r '.state')
       issue_numbers=$(echo "$pr_info" | jq -r '.closingIssuesReferences[].number')
     fi
   done
   ```

**Performance:**
- Single API call for all PRs: ~1-2 seconds
- Parsing worktrees: ~100ms per worktree
- Lookups: O(1) per worktree
- Total: ~2 seconds for 50 worktrees

## 5. Performance Optimization Recommendations

### 5.1 Caching Strategy

**Session Cache:**
```bash
# Cache location
CACHE_DIR="${HOME}/.agent-os/cache"
CACHE_FILE="${CACHE_DIR}/pr_cache_$(git rev-parse --show-toplevel | md5).json"
CACHE_TTL=300  # 5 minutes

use_cached_or_fetch() {
  local cache_file="$1"
  local cache_ttl="$2"

  # Check if cache exists and is fresh
  if [[ -f "$cache_file" ]]; then
    local cache_age=$(( $(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file") ))

    if [[ $cache_age -lt $cache_ttl ]]; then
      cat "$cache_file"
      return 0
    fi
  fi

  # Fetch fresh data
  gh pr list --state all --limit 1000 --json number,headRefName,title,state,closingIssuesReferences | tee "$cache_file"
}
```

**Cache Invalidation Triggers:**
- `git push` (hook)
- `git checkout` (hook)
- Manual command: `workflow-status --refresh`

### 5.2 Parallel Processing

For repositories with many worktrees:

```bash
# Process worktrees in parallel
export -f process_worktree
git worktree list --porcelain | parallel -j4 --pipe process_worktree
```

### 5.3 Lazy Loading

```bash
# Only fetch PR/issue data if --verbose flag is used
if [[ "$VERBOSE" == "true" ]]; then
  fetch_pr_data
else
  # Show basic worktree info only
fi
```

### 5.4 Rate Limit Awareness

```bash
# Check rate limit before making requests
check_rate_limit() {
  local remaining=$(gh api rate_limit --jq '.resources.core.remaining')
  local reset=$(gh api rate_limit --jq '.resources.core.reset')

  if [[ $remaining -lt 10 ]]; then
    echo "Warning: Only $remaining API calls remaining"
    echo "Rate limit resets at $(date -r $reset)"
    return 1
  fi

  return 0
}
```

## 6. Implementation Pseudocode

### 6.1 Complete workflow-status Flow

```bash
#!/bin/bash

workflow_status() {
  # 1. Check if in git repo
  if ! git rev-parse --git-dir &>/dev/null; then
    echo "Error: Not in a git repository"
    return 1
  fi

  # 2. Fetch PR data (with caching)
  pr_data=$(use_cached_or_fetch "$CACHE_FILE" "$CACHE_TTL")

  # 3. Build branch-to-PR index
  declare -A branch_to_pr
  while read -r pr; do
    branch=$(echo "$pr" | jq -r '.headRefName')
    branch_to_pr["$branch"]="$pr"
  done < <(echo "$pr_data" | jq -c '.[]')

  # 4. Parse worktrees
  local current_worktree=""
  local current_branch=""
  local current_head=""

  while IFS= read -r line; do
    if [[ -z "$line" ]]; then
      # End of worktree record
      if [[ -n "$current_worktree" ]]; then
        display_worktree_status "$current_worktree" "$current_branch" "$current_head" "$branch_to_pr"
      fi

      # Reset
      current_worktree=""
      current_branch=""
      current_head=""
    elif [[ "$line" =~ ^worktree\ (.+)$ ]]; then
      current_worktree="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^HEAD\ (.+)$ ]]; then
      current_head="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^branch\ refs/heads/(.+)$ ]]; then
      current_branch="${BASH_REMATCH[1]}"
    fi
  done < <(git worktree list --porcelain)
}

display_worktree_status() {
  local worktree_path="$1"
  local branch_name="$2"
  local head_sha="$3"
  local -n pr_index="$4"

  echo "Worktree: $worktree_path"
  echo "  Branch: $branch_name"
  echo "  Commit: ${head_sha:0:7}"

  # Try to parse issue from branch name
  local issue_num=""
  if [[ "$branch_name" =~ \#([0-9]+) ]]; then
    issue_num="${BASH_REMATCH[1]}"
    echo "  Issue: #$issue_num (from branch name)"
  fi

  # Lookup PR
  local pr_info="${pr_index[$branch_name]}"
  if [[ -n "$pr_info" ]]; then
    local pr_number=$(echo "$pr_info" | jq -r '.number')
    local pr_state=$(echo "$pr_info" | jq -r '.state')
    local pr_title=$(echo "$pr_info" | jq -r '.title')

    echo "  PR: #$pr_number ($pr_state)"
    echo "  Title: $pr_title"

    # Show linked issues
    local issue_numbers=$(echo "$pr_info" | jq -r '.closingIssuesReferences[].number' | tr '\n' ', ' | sed 's/,$//')
    if [[ -n "$issue_numbers" ]]; then
      echo "  Closes Issues: $issue_numbers"
    fi
  else
    echo "  PR: None"
  fi

  echo ""
}
```

## 7. Best Practices

### 7.1 Error Handling

```bash
# Check if gh CLI is installed
if ! command -v gh &>/dev/null; then
  echo "Error: GitHub CLI (gh) is not installed"
  echo "Install from: https://cli.github.com"
  return 1
fi

# Check if authenticated
if ! gh auth status &>/dev/null; then
  echo "Error: Not authenticated with GitHub"
  echo "Run: gh auth login"
  return 1
fi

# Handle API failures gracefully
fetch_pr_data() {
  if ! pr_data=$(gh pr list --state all --limit 1000 --json number,headRefName 2>&1); then
    echo "Warning: Failed to fetch PR data from GitHub"
    echo "Error: $pr_data"
    echo "Continuing with limited information..."
    return 1
  fi

  echo "$pr_data"
}
```

### 7.2 User Experience

```bash
# Show progress for long operations
echo "Fetching pull request data..." >&2
pr_data=$(gh pr list --state all --limit 1000 --json ...)
echo "✓ Fetched $(echo "$pr_data" | jq '. | length') PRs" >&2

# Use colors for status
case "$pr_state" in
  OPEN)
    color="\033[32m"  # Green
    ;;
  MERGED)
    color="\033[34m"  # Blue
    ;;
  CLOSED)
    color="\033[31m"  # Red
    ;;
esac

echo -e "${color}PR: #$pr_number ($pr_state)\033[0m"
```

### 7.3 Testing

```bash
# Test with sample data
test_workflow_status() {
  # Mock git worktree output
  export -f git
  git() {
    if [[ "$1" == "worktree" && "$2" == "list" ]]; then
      cat <<EOF
worktree /tmp/test-repo
HEAD abc123
branch refs/heads/feature-#42-test

worktree /tmp/test-repo-2
HEAD def456
branch refs/heads/main
EOF
    fi
  }

  # Mock gh output
  export -f gh
  gh() {
    if [[ "$1" == "pr" && "$2" == "list" ]]; then
      cat <<EOF
[{"number": 10, "headRefName": "feature-#42-test", "state": "OPEN", "closingIssuesReferences": [{"number": 42}]}]
EOF
    fi
  }

  # Run workflow-status
  workflow_status
}
```

## 8. Example Implementation

See `/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/agent-os/scripts/workflow-status-example.sh` for a complete working implementation.

## 9. References

### Official Documentation
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [gh pr list](https://cli.github.com/manual/gh_pr_list)
- [gh issue list](https://cli.github.com/manual/gh_issue_list)
- [git worktree documentation](https://git-scm.com/docs/git-worktree)
- [GitHub GraphQL API](https://docs.github.com/en/graphql)

### Community Resources
- [Scripting with GitHub CLI](https://github.blog/engineering/engineering-principles/scripting-with-github-cli/)
- [GitHub CLI JSON Fields Discussion](https://github.com/cli/cli/discussions/5902)
- [Git Worktree Workflows](https://stackoverflow.com/questions/46102041/git-get-worktree-for-every-branch-in-seperate-folders-bash)

---

*This research was conducted for the Agent OS workflow-status command development. For questions or updates, see the Agent OS repository.*
