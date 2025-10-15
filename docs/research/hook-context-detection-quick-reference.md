# Hook Context Detection - Quick Reference

> Quick reference for implementing context detection in Agent OS hooks
>
> **See Also:** [Full Best Practices Documentation](./hook-context-detection-best-practices.md)

## Fast Git Commands (All <20ms)

### Branch Detection
```bash
# Get current branch name (recommended)
git rev-parse --abbrev-ref HEAD  # Returns "HEAD" in detached state

# Alternative (errors in detached state)
git symbolic-ref --short HEAD
```

### Workspace State
```bash
# Check for uncommitted changes
git status --porcelain  # Empty = clean, non-empty = dirty

# With branch tracking info
git status --porcelain --branch  # Shows ahead/behind counts
```

### Branch Tracking
```bash
# Get upstream tracking info
git for-each-ref --format='%(refname:short) %(upstream:short) %(upstream:track)' refs/heads
```

### Issue Correlation
```bash
# Extract issue number from branch name
branch=$(git rev-parse --abbrev-ref HEAD)
issue=$(echo "$branch" | grep -oE '#[0-9]+' | tr -d '#')

# Find issue references in recent commits
git log --oneline --grep="#" -10
```

## GitHub CLI Commands (Slow: 350-665ms)

### PR Status
```bash
# List open PRs with JSON output
gh pr list --json number,headRefName,state,title

# Get PR for current branch
gh pr status

# View specific PR
gh pr view 101 --json number,headRefName,title
```

### Issue Status
```bash
# List open issues
gh issue list --json number,title,state

# Get issues for current user
gh issue status
```

### Performance Tip
**Always cache GitHub CLI results with 5-10 second TTL!**

```bash
CACHE_FILE="${HOME}/.agent-os/cache/gh-prs.json"
TTL=5  # seconds

if [[ -f "$CACHE_FILE" ]] && [[ $(($(date +%s) - $(stat -f %m "$CACHE_FILE"))) -lt $TTL ]]; then
  cat "$CACHE_FILE"
else
  gh pr list --json number | tee "$CACHE_FILE"
fi
```

## Shell Script Patterns

### Standard Hook Header
```bash
#!/usr/bin/env bash

# Read Claude Code hook payload
payload="$(cat)"

# Check for required tools
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found; skipping hook" >&2
    exit 0  # Always exit 0 in hooks
fi

# Parse payload
tool_name="$(jq -r '.hookMetadata.toolName // empty' <<<"$payload")"

# Early exit if not relevant
if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

# ... hook logic ...

# Always exit 0 - never block
exit 0
```

### Error Handling
```bash
# For internal utility scripts
set -euo pipefail

# For hooks - NO SET -E (must never fail)
# Check and degrade gracefully instead:
if ! result=$(risky_command 2>&1); then
  echo "Warning: command failed" >&2
  result="default_value"
fi
```

### Performance Testing
```bash
# Time a command
time git status --porcelain

# Get millisecond timing
start=$(date +%s%3N)
git status --porcelain >/dev/null
end=$(date +%s%3N)
echo "$((end - start))ms"
```

### Cross-Platform Compatibility
```bash
# Get file modification time
stat_mtime() {
  if stat -f %m "$1" >/dev/null 2>&1; then
    stat -f %m "$1"  # macOS
  else
    stat -c %Y "$1"  # Linux
  fi
}
```

## Common Patterns

### Detect Workspace State
```bash
# Complete workspace check (~35ms)
detect_state() {
  local branch=$(git rev-parse --abbrev-ref HEAD)
  local dirty=false
  [[ -n "$(git status --porcelain)" ]] && dirty=true

  local ahead=0
  local tracking=$(git status --porcelain --branch | head -1)
  [[ "$tracking" =~ \[ahead\ ([0-9]+)\] ]] && ahead="${BASH_REMATCH[1]}"

  echo "{\"branch\":\"$branch\",\"dirty\":$dirty,\"ahead\":$ahead}"
}
```

### Classify Command Intent
```bash
classify_command() {
  local cmd="$1"
  if echo "$cmd" | grep -qE "(npm|yarn) (start|dev|serve)"; then
    echo "server"
  elif echo "$cmd" | grep -qE "(npm|yarn) test|pytest|jest"; then
    echo "test"
  elif echo "$cmd" | grep -qE "(npm|yarn) build|webpack|vite"; then
    echo "build"
  else
    echo "other"
  fi
}
```

### Classify User Intent
```bash
classify_intent() {
  local text="$1"
  local lower=$(echo "$text" | tr '[:upper:]' '[:lower:]')

  if echo "$lower" | grep -qE '\bfix\b|\bdebug\b|\bresolve\b'; then
    echo "MAINTENANCE"
  elif echo "$lower" | grep -qE '\bimplement\b|\bbuild\b.*\bnew\b|\bcreate\b'; then
    echo "NEW"
  else
    echo "AMBIGUOUS"
  fi
}
```

### Cache with TTL
```bash
CACHE_DIR="${HOME}/.agent-os/cache"
CACHE_FILE="${CACHE_DIR}/data.json"
TTL=5  # seconds

mkdir -p "$CACHE_DIR"

is_fresh() {
  [[ ! -f "$CACHE_FILE" ]] && return 1
  local age=$(($(date +%s) - $(stat_mtime "$CACHE_FILE")))
  [[ "$age" -lt "$TTL" ]]
}

if is_fresh; then
  cat "$CACHE_FILE"
else
  compute_data | tee "$CACHE_FILE"
fi
```

## Performance Targets

| Operation | Target | Acceptable | Slow |
|-----------|--------|------------|------|
| Git status | <20ms | <50ms | >100ms |
| GitHub CLI (cached) | <10ms | <20ms | >50ms |
| GitHub CLI (fresh) | <500ms | <750ms | >1000ms |
| Total hook execution | <50ms | <100ms | >200ms |

## Common Mistakes to Avoid

1. ❌ **Using `set -e` in top-level hooks** - Hooks must never fail
2. ❌ **Making uncached GitHub CLI calls** - Too slow for hooks
3. ❌ **Exiting non-zero from hooks** - Breaks Claude Code workflow
4. ❌ **Not checking if tools exist** - May run in minimal environments
5. ❌ **Using subshells unnecessarily** - Impacts performance
6. ❌ **Not handling edge cases** - Detached HEAD, empty repo, etc.

## Checklist for New Hooks

- [ ] Reads Claude Code payload from stdin with `payload="$(cat)"`
- [ ] Checks for required tools (jq, git, gh) with graceful fallback
- [ ] Exits early if not relevant tool (e.g., `if [ "$tool_name" != "Bash" ]`)
- [ ] Uses only fast Git operations (<20ms each)
- [ ] Caches slow operations (GitHub CLI) with TTL
- [ ] Handles errors gracefully (no `set -e` at top level)
- [ ] Always exits 0, never blocks execution
- [ ] Provides brief, helpful output (<3 lines)
- [ ] Tested for performance (<100ms total execution)
- [ ] Handles edge cases (detached HEAD, no git repo, etc.)

## Testing Commands

```bash
# Test branch detection
git rev-parse --abbrev-ref HEAD

# Test workspace state
git status --porcelain

# Test GitHub CLI
gh pr list --json number

# Test hook performance
time bash hooks/pre-bash-hook.sh < test-payload.json

# Profile hook execution
bash -x hooks/pre-bash-hook.sh < test-payload.json 2>&1 | grep -E '^\+'
```

## Resources

- **Full Documentation:** [hook-context-detection-best-practices.md](./hook-context-detection-best-practices.md)
- **Agent OS Hooks:** `/hooks/*.sh`
- **Utility Scripts:** `/scripts/*.sh`
- **Git Documentation:** https://git-scm.com/docs
- **GitHub CLI Manual:** https://cli.github.com/manual/

---

**Last Updated:** 2025-10-15
