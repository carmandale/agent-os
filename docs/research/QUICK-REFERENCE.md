# GitHub CLI + Worktree Quick Reference Card

> For Agent OS workflow-status command development

## Essential Commands

### GitHub CLI

```bash
# Get all PR fields available
gh pr list --json

# Get all issue fields available
gh issue list --json

# Fetch PRs with key fields (recommended)
gh pr list --state all --limit 1000 \
  --json number,headRefName,title,state,closingIssuesReferences

# Filter by branch
gh pr list --head "feature-branch" --json number,title

# Current branch PR
gh pr view --json number,title,state

# GraphQL query (faster for batch operations)
gh api graphql -f query='query { ... }'
```

### Git Worktree

```bash
# List worktrees (human-readable)
git worktree list

# List worktrees (machine-readable)
git worktree list --porcelain

# Example porcelain output:
# worktree /path/to/repo
# HEAD abc123...
# branch refs/heads/main
#
# (empty line = end of record)
```

## Key JSON Fields

### Pull Requests
```json
{
  "number": 88,
  "headRefName": "feature-branch",
  "title": "Add feature",
  "state": "OPEN",  // OPEN, CLOSED, MERGED
  "closingIssuesReferences": [
    {"number": 42, "url": "..."}
  ]
}
```

### Issues
```json
{
  "number": 42,
  "title": "Fix bug",
  "state": "OPEN",  // OPEN, CLOSED
  "closedByPullRequestsReferences": [
    {"number": 88}
  ]
}
```

## Common Patterns

### Parse Issue from Branch Name

```bash
# Pattern: feature-#42-description
echo "feature-#42-description" | grep -oE '#[0-9]+' | sed 's/#//'
# Output: 42

# Pattern: 42-feature-name
echo "42-feature-name" | grep -oE '^[0-9]+'
# Output: 42

# Bash function
parse_issue_from_branch() {
  local branch="$1"
  if [[ "$branch" =~ \#([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$branch" =~ ^([0-9]+)- ]]; then
    echo "${BASH_REMATCH[1]}"
  fi
}
```

### Parse Worktree Porcelain Format

```bash
git worktree list --porcelain | while IFS= read -r line; do
  if [[ -z "$line" ]]; then
    # End of record - process worktree
    echo "Worktree: $worktree_path, Branch: $branch_name"
    worktree_path=""
    branch_name=""
  elif [[ "$line" =~ ^worktree\ (.+)$ ]]; then
    worktree_path="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^branch\ refs/heads/(.+)$ ]]; then
    branch_name="${BASH_REMATCH[1]}"
  fi
done
```

### Build PR Index for Fast Lookup

```bash
# Fetch once
pr_data=$(gh pr list --state all --limit 1000 --json number,headRefName)

# Build hash map: branch -> PR number
declare -A branch_to_pr
while read -r pr; do
  branch=$(echo "$pr" | jq -r '.headRefName')
  number=$(echo "$pr" | jq -r '.number')
  branch_to_pr["$branch"]="$number"
done < <(echo "$pr_data" | jq -c '.[]')

# Lookup (O(1))
pr_number="${branch_to_pr[$branch_name]}"
```

## Performance Tips

### 1. Cache PR Data (5-min TTL)

```bash
CACHE_FILE="$HOME/.agent-os/cache/pr_cache.json"
CACHE_TTL=300  # 5 minutes

if [[ -f "$CACHE_FILE" ]]; then
  age=$(($(date +%s) - $(stat -f %m "$CACHE_FILE")))
  if [[ $age -lt $CACHE_TTL ]]; then
    pr_data=$(cat "$CACHE_FILE")
  fi
fi

# Fetch if not cached
if [[ -z "$pr_data" ]]; then
  pr_data=$(gh pr list --state all --limit 1000 --json ...)
  echo "$pr_data" > "$CACHE_FILE"
fi
```

### 2. Use GraphQL for Multiple Queries

```bash
# Single query replaces 10+ REST calls
gh api graphql --paginate -f query='
query($endCursor: String) {
  repository(owner: "owner", name: "repo") {
    pullRequests(first: 100, after: $endCursor) {
      nodes {
        number
        headRefName
        closingIssuesReferences(first: 10) {
          nodes { number }
        }
      }
      pageInfo { hasNextPage endCursor }
    }
  }
}
'
```

### 3. Batch Processing

```bash
# Fetch all PRs ONCE
pr_data=$(gh pr list --state all --limit 1000 --json ...)

# Build index ONCE
declare -A branch_to_pr
# ... populate index ...

# Lookup many times (O(1) each)
for worktree in $worktrees; do
  pr_number="${branch_to_pr[$branch_name]}"
done
```

## Error Handling

```bash
# Check prerequisites
if ! git rev-parse --git-dir &>/dev/null; then
  echo "Error: Not in git repo"
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI not installed"
  echo "Install: https://cli.github.com"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "Error: Not authenticated"
  echo "Run: gh auth login"
  exit 1
fi

# Handle API failures
if ! pr_data=$(gh pr list ... 2>&1); then
  echo "Warning: Failed to fetch PR data"
  echo "Continuing with limited info..."
  pr_data="[]"
fi
```

## Testing

```bash
# Test with mock data
test_workflow_status() {
  # Mock git worktree
  git() {
    if [[ "$1" == "worktree" ]]; then
      cat <<EOF
worktree /tmp/test
HEAD abc123
branch refs/heads/feature-#42
EOF
    fi
  }

  # Mock gh cli
  gh() {
    if [[ "$1" == "pr" ]]; then
      echo '[{"number": 10, "headRefName": "feature-#42"}]'
    fi
  }

  export -f git gh
  workflow_status
}
```

## Complete Example

See: `/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/agent-os/scripts/workflow-status-example.sh`

```bash
# Run example
./scripts/workflow-status-example.sh --verbose

# Expected output:
# ℹ Fetching PR data...
# ✓ Fetched 46 PRs
#
# Worktree: /path/to/repo
#   Branch: feature-#42
#   Commit: abc123d
#   Issue: #42 (from branch name)
#   PR: #88 (MERGED)
#   Closes Issues: #87
```

## Cheat Sheet

| Task | Command |
|------|---------|
| List PRs with issues | `gh pr list --json number,headRefName,closingIssuesReferences` |
| PR for branch | `gh pr list --head "branch"` |
| Current branch PR | `gh pr view` |
| List worktrees | `git worktree list --porcelain` |
| Parse issue # | `grep -oE '#[0-9]+' \| sed 's/#//'` |
| GraphQL query | `gh api graphql -f query='...'` |
| Check rate limit | `gh api rate_limit` |

## Resources

- Full docs: `docs/research/github-cli-worktree-integration.md`
- Example: `scripts/workflow-status-example.sh`
- Summary: `docs/research/SUMMARY.md`
