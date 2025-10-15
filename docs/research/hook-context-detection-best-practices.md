# Hook Context Detection Best Practices

> Research Documentation for Agent OS
>
> **Focus Areas:**
> - Fast Git operations for detecting active branches and work state
> - GitHub CLI patterns for issue/PR status checking
> - Shell scripting patterns for robust context detection
> - Performance considerations for hook scripts (target <100ms)
> - Error handling and graceful degradation in hook systems
>
> **Research Date:** 2025-10-15
> **Environment:** Git 2.50.1, GitHub CLI 2.81.0, Bash 3.2+

## Executive Summary

This document provides comprehensive guidance for implementing robust, performant context detection in shell-based hook systems. Based on analysis of Agent OS's existing implementation and industry best practices, the key principles are:

1. **Performance First**: All Git operations should complete in <20ms; total hook execution <100ms
2. **Graceful Degradation**: Hooks should never block; they observe and suggest, never enforce
3. **Error Resilience**: Use `set -euo pipefail` with proper trap handlers
4. **Context Caching**: Cache expensive operations (GitHub CLI calls) with TTL invalidation

## Fast Git Operations for Context Detection

### Branch Detection

**Recommended Command:**
```bash
git rev-parse --abbrev-ref HEAD
```

**Performance:** ~7ms (tested)

**Characteristics:**
- Works in all Git states (normal, detached HEAD, empty repo)
- Returns "HEAD" in detached HEAD state (graceful)
- Most portable across Git versions (since 1.6.3)

**Alternative:**
```bash
git symbolic-ref --short HEAD
```

**Performance:** ~8ms (tested)

**Characteristics:**
- Exits with error in detached HEAD state (strict)
- More explicit about symbolic references
- Requires Git 1.7.10+

**Decision:** Use `git rev-parse --abbrev-ref HEAD` for hook systems due to graceful behavior in edge cases.

### Working Directory State Detection

**Recommended Command:**
```bash
git status --porcelain
```

**Performance:** ~12ms (tested)

**Output Format:**
```
XY PATH
XY ORIG_PATH -> PATH
```

Where:
- X = status of staging area
- Y = status of working tree
- Empty output = clean workspace

**With Branch Information:**
```bash
git status --porcelain --branch
```

**Output:**
```
## branch...origin/branch [ahead 2]
?? untracked-file
 M modified-file
```

**Key Flags:**
- `--porcelain`: Machine-readable format, stable across Git versions
- `--porcelain=v2`: More detailed format (use for advanced cases)
- `--branch`: Include branch and tracking info
- `-z`: Null-terminated output (use for filenames with spaces)
- `--untracked-files=no`: Skip untracked files (faster for large repos)

### Branch Tracking Information

**Show upstream tracking:**
```bash
git for-each-ref --format='%(refname:short) %(upstream:short) %(upstream:track)' refs/heads
```

**Output:**
```
main origin/main [ahead 2]
feature/branch origin/feature/branch
local-branch
```

**Performance:** ~15ms for 10 branches

**Use Case:** Detect unpushed work or diverged branches.

### Commit History Analysis

**Recent commits with issue references:**
```bash
git log --oneline --grep="#" -n 10
```

**Performance:** ~20ms

**Use Case:** Correlate branch with GitHub issues.

**Commits on current branch since divergence:**
```bash
git log main..HEAD --oneline
```

**Performance:** ~15ms

**Use Case:** Understand scope of current work.

## GitHub CLI Patterns

### Performance Characteristics

GitHub CLI operations are **significantly slower** than Git operations:

- `gh pr list`: ~460ms
- `gh issue list`: ~665ms

**Implication:** GitHub CLI calls must be cached or made optional in hooks.

### PR Status Checking

**List open PRs:**
```bash
gh pr list --json number,headRefName,state,title --limit 10
```

**Output:**
```json
[
  {
    "headRefName": "feature/branch",
    "number": 101,
    "state": "OPEN",
    "title": "feat: implement feature"
  }
]
```

**Check PR for current branch:**
```bash
gh pr status
```

**Output:**
```
Current branch
  #101  feat: implement feature [feature/branch]
   - Checks passing
```

**View specific PR:**
```bash
gh pr view 101 --json number,headRefName,baseRefName,title,state,reviews
```

### Issue Status Checking

**List open issues:**
```bash
gh issue list --json number,title,state --limit 10
```

**Check issues for current user:**
```bash
gh issue status
```

**Output:**
```
Relevant issues in owner/repo

Issues assigned to you
  #100  feat: add feature

Issues mentioning you
  #98   fix: resolve bug

Issues opened by you
  #95   chore: update deps
```

### Branch-Issue Correlation

**Strategy 1: Branch naming convention**
```bash
# Branch: feature/merge-command-#100
branch=$(git rev-parse --abbrev-ref HEAD)
issue_num=$(echo "$branch" | grep -oE '#[0-9]+' | tr -d '#')
```

**Strategy 2: Commit message parsing**
```bash
# Search recent commits for issue references
git log --oneline -10 | grep -oE '#[0-9]+' | head -1
```

**Strategy 3: GitHub CLI query**
```bash
# Get PRs for current branch
branch=$(git rev-parse --abbrev-ref HEAD)
gh pr list --json number,headRefName --jq ".[] | select(.headRefName == \"$branch\") | .number"
```

### Graceful GitHub CLI Degradation

**Pattern from workspace-state.sh:**
```bash
compute_open_prs() {
  # If skip or gh missing, report 0
  if [[ -n "$SKIP_GH" ]] || ! command -v gh >/dev/null 2>&1; then
    echo 0; return
  fi

  local out
  # Try with timeout if available
  if command -v timeout >/dev/null 2>&1; then
    out=$(timeout 0.8s gh pr list --json number 2>/dev/null || echo "[]")
  else
    out=$(gh pr list --json number 2>/dev/null || echo "[]")
  fi

  # Count PRs
  { printf "%s" "$out" | grep -o '"number"' 2>/dev/null || true; } | wc -l | tr -d ' '
}
```

**Key Principles:**
1. Make GitHub CLI optional (check if installed)
2. Use timeouts to prevent hangs
3. Provide sensible defaults (0 open PRs) on failure
4. Never exit non-zero on GitHub CLI failures

## Shell Scripting Best Practices

### Error Handling Fundamentals

**Standard header for hook scripts:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Optional: Set trap for cleanup
trap 'cleanup' EXIT ERR
```

**Flags explained:**
- `set -e`: Exit immediately if a command exits with non-zero status
- `set -u`: Treat unset variables as errors
- `set -o pipefail`: Pipeline fails if any command fails (not just the last)

**When to use in hooks:**
- **DO use** in internal utility scripts
- **DON'T use** in top-level hooks (they should never fail)
- **DO use** with trap handlers for cleanup

### Graceful Degradation Pattern

**From post-bash-hook.sh:**
```bash
# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found; skipping post-bash observation" >&2
    exit 0
fi

# Always exit 0 for hooks - never block
exit 0
```

**Principles:**
1. Check for required tools before use
2. Provide informative stderr messages
3. Exit 0 even on internal failures
4. Degrade gracefully (skip features, don't crash)

### Performance Optimization

**Fast command existence check:**
```bash
# Good: Uses hash table lookup
if command -v git >/dev/null 2>&1; then
    # ...
fi

# Avoid: Slower
if which git >/dev/null 2>&1; then
    # ...
fi
```

**Minimize subshells:**
```bash
# Slow: Multiple subshells
result=$(cat file | grep pattern | awk '{print $1}')

# Fast: Single pipeline
result=$(grep pattern file | awk '{print $1}')
```

**Use built-in commands:**
```bash
# Slow: External sed
echo "$text" | sed 's/foo/bar/'

# Fast: Parameter expansion
echo "${text//foo/bar}"
```

**Avoid loops for external commands:**
```bash
# Slow: Fork process for each file
for file in *.txt; do
    grep "pattern" "$file"
done

# Fast: Single grep invocation
grep "pattern" *.txt
```

### Caching Pattern

**From workspace-state.sh:**
```bash
CACHE_DIR="${HOME}/.agent-os/cache"
CACHE_FILE="${CACHE_DIR}/workspace-state.json"
TTL="${AGENT_OS_STATE_TTL:-5}"  # seconds

mkdir -p "$CACHE_DIR"

# Cross-platform stat for modification time
stat_mtime() {
  if stat -f %m "$1" >/dev/null 2>&1; then
    stat -f %m "$1"  # macOS
  else
    stat -c %Y "$1"  # Linux
  fi
}

now_ts() { date +%s; }

is_fresh() {
  [[ -f "$CACHE_FILE" ]] || return 1
  local ct=$(stat_mtime "$CACHE_FILE" 2>/dev/null || echo 0)
  local ts=$(now_ts)
  local age=$(( ts - ct ))
  [[ "$age" -lt "$TTL" ]]
}

if is_fresh; then
  cat "$CACHE_FILE"
  exit 0
fi

# Compute fresh data...
```

**Key Principles:**
1. Cache expensive operations (GitHub CLI, complex Git queries)
2. Use TTL for cache invalidation (5-10 seconds for hooks)
3. Handle cross-platform differences (macOS vs Linux)
4. Atomic cache updates (write to temp, then move)

### JSON Output Pattern

**From workspace-state.sh:**
```bash
emit_json() {
  local dirty="$1" prs="$2"
  printf '{"dirty":%s,"open_prs":%s}\n' "$dirty" "$prs"
}

# Usage
dirty=$(compute_dirty)
prs=$(compute_open_prs)
emit_json "$dirty" "$prs" | tee "$CACHE_FILE" >/dev/null
emit_json "$dirty" "$prs"  # Output to stdout
```

**Use jq for parsing:**
```bash
payload="$(cat)"  # Read stdin

tool_name="$(jq -r '.hookMetadata.toolName // empty' <<<"$payload")"
cmd="$(jq -r '.tool_input.command // empty' <<<"$payload")"
exit_code="$(jq -r '.tool_response.exit_code // empty' <<<"$payload")"
```

## Context Detection Patterns

### Intent Classification

**From intent-analyzer.sh:**
```bash
classify_intent() {
  local text="$1"
  local L=$(echo "$text" | tr '[:upper:]' '[:lower:]')

  # Maintenance patterns
  local MAINT_PAT='\bfix\b.*\btests?\b|\baddress\b.*\bci\b|\bdebug\b|\bresolve\b.*\bconflict|\bfix\b.*\bbug'

  # New work patterns
  local NEW_PAT='\bimplement\b.*\bfeature\b|\bbuild\b.*\bnew\b|\bcreate\b.*\b(feature|component|system)\b'

  if grep -Eiq "$MAINT_PAT" <<< "$L"; then
    echo "MAINTENANCE"
  elif grep -Eiq "$NEW_PAT" <<< "$L"; then
    echo "NEW"
  else
    echo "AMBIGUOUS"
  fi
}
```

**Use Cases:**
- Determine if user is doing maintenance vs new work
- Decide whether to enforce clean workspace
- Provide context-appropriate suggestions

### Command Classification

**From pre-bash-hook.sh:**
```bash
classify_command() {
  local command="$1"

  # Server-related patterns
  if echo "$command" | grep -qE "(npm|yarn|pnpm) (run|start|serve|dev)"; then
    echo "server"
  # Test-related patterns
  elif echo "$command" | grep -qE "(npm|yarn) test|pytest|jest|vitest"; then
    echo "test"
  # Build-related patterns
  elif echo "$command" | grep -qE "(npm|yarn) build|webpack|vite build|make"; then
    echo "build"
  else
    echo "other"
  fi
}
```

**Use Cases:**
- Provide command-specific suggestions
- Track different types of development activity
- Detect long-running operations (servers, watchers)

### Workspace State Detection

**Complete pattern:**
```bash
detect_workspace_state() {
  local state='{}'

  # Branch information (fast: ~7ms)
  local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

  # Working tree state (fast: ~12ms)
  local dirty=false
  [[ -n "$(git status --porcelain 2>/dev/null)" ]] && dirty=true

  # Unpushed commits (fast: ~15ms)
  local ahead=0
  local behind=0
  local tracking=$(git status --porcelain --branch 2>/dev/null | head -1)
  if [[ "$tracking" =~ \[ahead\ ([0-9]+)\] ]]; then
    ahead="${BASH_REMATCH[1]}"
  fi
  if [[ "$tracking" =~ \[behind\ ([0-9]+)\] ]]; then
    behind="${BASH_REMATCH[1]}"
  fi

  # Issue correlation (fast: regex)
  local issue=""
  if [[ "$branch" =~ \#([0-9]+) ]]; then
    issue="${BASH_REMATCH[1]}"
  fi

  # Open PRs (cached: 0ms if fresh, 460ms if stale)
  local open_prs=$(get_cached_pr_count)

  # Output JSON
  jq -n \
    --arg branch "$branch" \
    --argjson dirty "$dirty" \
    --argjson ahead "$ahead" \
    --argjson behind "$behind" \
    --arg issue "$issue" \
    --argjson open_prs "$open_prs" \
    '{branch, dirty, ahead, behind, issue, open_prs}'
}
```

## Performance Benchmarks

### Git Operations (Agent OS repo, 2025-10-15)

| Operation | Command | Time |
|-----------|---------|------|
| Branch name | `git rev-parse --abbrev-ref HEAD` | 7ms |
| Symbolic ref | `git symbolic-ref --short HEAD` | 8ms |
| Status check | `git status --porcelain` | 12ms |
| Status with branch | `git status --porcelain --branch` | 13ms |
| Branch tracking | `git for-each-ref refs/heads` | 15ms |
| Recent commits | `git log --oneline -10` | 20ms |

**Total for comprehensive state check:** ~35ms (Git only)

### GitHub CLI Operations

| Operation | Command | Time |
|-----------|---------|------|
| List PRs | `gh pr list --json number` | 460ms |
| List issues | `gh issue list --json number` | 665ms |
| PR status | `gh pr status` | 350ms |
| Issue status | `gh issue status` | 500ms |

**Implication:** Must cache or make optional (adds 0-665ms)

### Target Performance

For hook scripts:
- **Git operations only:** <50ms (target: <100ms)
- **With cached GitHub data:** <60ms
- **With fresh GitHub data:** <750ms (acceptable if cached properly)

**Recommendation:**
- Run Git operations every time (fast)
- Cache GitHub CLI results with 5-10 second TTL
- Make GitHub CLI optional/skippable

## Error Handling Patterns

### Trap-Based Cleanup

```bash
#!/usr/bin/env bash
set -euo pipefail

cleanup() {
  local exit_code=$?
  # Perform cleanup
  rm -f "$TEMP_FILE"
  exit "$exit_code"
}

trap cleanup EXIT ERR INT TERM

# Script body
TEMP_FILE=$(mktemp)
# ... work with temp file
```

### Graceful Command Failure

```bash
# Pattern 1: Default on failure
result=$(command_that_might_fail 2>/dev/null || echo "default")

# Pattern 2: Check and handle
if command_that_might_fail 2>/dev/null; then
  # Success path
else
  # Failure path (still exit 0)
  echo "Command failed; continuing with defaults" >&2
fi

# Pattern 3: Try-catch simulation
if ! output=$(risky_command 2>&1); then
  echo "Warning: $output" >&2
  output="fallback"
fi
```

### Timeout Pattern

```bash
# Use timeout for external commands that might hang
if command -v timeout >/dev/null 2>&1; then
  output=$(timeout 1s gh pr list 2>/dev/null || echo "[]")
else
  # No timeout available; add manual timeout (advanced)
  output=$(gh pr list 2>/dev/null || echo "[]")
fi
```

## Integration Patterns

### Pre-Hook Pattern

**Purpose:** Observe command before execution

```bash
#!/usr/bin/env bash

# Read Claude Code hook payload
payload="$(cat)"

# Parse with jq
tool_name="$(jq -r '.hookMetadata.toolName // empty' <<<"$payload")"

# Early exit if not relevant
if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

# Extract command
cmd="$(jq -r '.tool_input.command // empty' <<<"$payload")"

# Classify intent
intent=$(classify_command "$cmd")

# Log observation
log_observation "pre" "$cmd" "$intent"

# Provide brief feedback (optional)
case "$intent" in
  "server") echo "🚀 Starting development server..." ;;
  "test")   echo "🧪 Running tests..." ;;
esac

# Always exit 0 - never block
exit 0
```

### Post-Hook Pattern

**Purpose:** Observe command results and provide suggestions

```bash
#!/usr/bin/env bash

# Read payload
payload="$(cat)"

# Parse results
exit_code="$(jq -r '.tool_response.exit_code // empty' <<<"$payload")"
cmd="$(jq -r '.tool_input.command // empty' <<<"$payload")"

# Classify
intent=$(classify_command "$cmd")

# Log result
log_observation "post" "$cmd" "$intent" "$exit_code"

# Provide context-aware suggestions
if [ "$exit_code" = "0" ]; then
  case "$intent" in
    "test")
      echo "✅ Tests passed! Use 'aos dashboard' to see history."
      ;;
    "server")
      echo "🚀 Server running. Use 'aos dashboard' to monitor."
      ;;
  esac
else
  echo "❌ Command failed (exit $exit_code)"
  echo "💡 Check 'aos dashboard' for details."
fi

# Always exit 0
exit 0
```

### Context-Aware Enforcement Pattern

**Purpose:** Allow/block operations based on workspace state

```bash
#!/usr/bin/env bash
set -euo pipefail

# Get user intent
intent=$(classify_intent "$user_message")

# Get workspace state (cached)
state=$(get_workspace_state_cached)
dirty=$(echo "$state" | jq -r '.dirty')
open_prs=$(echo "$state" | jq -r '.open_prs')

case "$intent" in
  MAINTENANCE)
    # Always allow maintenance work
    echo "ALLOW"
    exit 0
    ;;
  NEW)
    # Require clean workspace for new work
    if [[ "$dirty" == "true" || "$open_prs" -gt 0 ]]; then
      echo "BLOCK: New work requires clean workspace"
      exit 1
    else
      echo "ALLOW"
      exit 0
    fi
    ;;
  AMBIGUOUS)
    # Default: suggest clarification
    echo "BLOCK: Please clarify intent (maintenance or new work)"
    exit 1
    ;;
esac
```

## Testing Strategies

### Manual Testing

```bash
# Test branch detection
git rev-parse --abbrev-ref HEAD
git symbolic-ref --short HEAD

# Test workspace state
git status --porcelain
git status --porcelain --branch

# Test GitHub CLI
gh pr list --json number,headRefName
gh issue list --json number,title

# Test performance
time git status --porcelain
time gh pr list --json number
```

### Automated Testing

```bash
#!/usr/bin/env bash
# test-context-detection.sh

test_branch_detection() {
  local branch=$(git rev-parse --abbrev-ref HEAD)
  [[ -n "$branch" ]] || { echo "FAIL: Empty branch"; exit 1; }
  echo "PASS: Branch = $branch"
}

test_workspace_state() {
  local output=$(git status --porcelain)
  echo "PASS: Status check works"
}

test_performance() {
  local start=$(date +%s%3N)
  git status --porcelain >/dev/null
  local end=$(date +%s%3N)
  local duration=$((end - start))

  if [[ $duration -lt 100 ]]; then
    echo "PASS: Performance = ${duration}ms"
  else
    echo "WARN: Slow performance = ${duration}ms"
  fi
}

test_branch_detection
test_workspace_state
test_performance
```

## Edge Cases and Considerations

### Detached HEAD State

**Detection:**
```bash
branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch" == "HEAD" ]]; then
  echo "In detached HEAD state"
  # Get commit SHA instead
  commit=$(git rev-parse HEAD)
  echo "Current commit: $commit"
fi
```

### Empty Repository

**Detection:**
```bash
if ! git rev-parse HEAD >/dev/null 2>&1; then
  echo "Empty repository (no commits)"
fi
```

### Submodules

**Impact:** Git operations may be slower in repos with submodules

**Mitigation:**
```bash
# Skip submodule status checks
git status --porcelain --ignore-submodules
```

### Large Repositories

**Impact:** `git status` can be slow (>100ms) in very large repos

**Mitigations:**
1. Use `--untracked-files=no` to skip untracked file scanning
2. Enable Git's untracked cache: `git config core.untrackedCache true`
3. Enable fsmonitor for even faster status: `git config core.fsmonitor true`

### Sparse Checkouts

**Impact:** Working tree doesn't reflect full repository

**Consideration:** Context detection still works, but may not reflect full state

### Worktrees

**Detection:**
```bash
# Check if in a worktree
git rev-parse --git-dir  # Returns .git/worktrees/NAME if in worktree

# List all worktrees
git worktree list
```

## References

### Official Documentation

- [Git Status Documentation](https://git-scm.com/docs/git-status)
- [Git Rev-Parse Documentation](https://git-scm.com/docs/git-rev-parse)
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [Bash Scripting Best Practices](https://mywiki.wooledge.org/BashGuide)

### Agent OS Implementation Files

- `/hooks/pre-bash-hook.sh` - Command observation before execution
- `/hooks/post-bash-hook.sh` - Command observation after execution
- `/scripts/intent-analyzer.sh` - User intent classification
- `/scripts/workspace-state.sh` - Cached workspace state with TTL
- `/scripts/context-aware-wrapper.sh` - Intent-based operation gating

### Performance Testing

All performance benchmarks conducted on:
- **System:** macOS 15.1 (Darwin 25.1.0)
- **Git Version:** 2.50.1
- **GitHub CLI Version:** 2.81.0
- **Repository:** Agent OS (moderate size, ~100 commits)
- **Date:** 2025-10-15

### Key Takeaways

1. **Git operations are fast** (7-20ms) - use freely in hooks
2. **GitHub CLI is slow** (350-665ms) - must cache with 5-10s TTL
3. **Use `set -euo pipefail`** for internal scripts, not top-level hooks
4. **Always exit 0 in hooks** - graceful degradation is mandatory
5. **Cache expensive operations** - workspace state, GitHub data
6. **Provide sensible defaults** - 0 open PRs, clean workspace on tool failure
7. **Test performance** - target <100ms for hook execution
8. **Handle edge cases** - detached HEAD, empty repo, large repos

---

**Document Status:** Complete
**Last Updated:** 2025-10-15
**Maintainer:** Agent OS Core Team
