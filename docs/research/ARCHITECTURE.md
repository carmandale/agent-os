# workflow-status Architecture and Data Flow

> Visual guide to GitHub CLI + Worktree integration

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    workflow-status Command                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐     ┌──────────────┐     ┌────────────┐ │
│  │  Git Repo    │────▶│  PR/Issue    │────▶│  Display   │ │
│  │  Worktrees   │     │  Mapping     │     │  Results   │ │
│  └──────────────┘     └──────────────┘     └────────────┘ │
│         │                     │                    │        │
│         ▼                     ▼                    ▼        │
│  git worktree         gh pr list           formatted       │
│  list --porcelain     + caching            output          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow Diagram

```
┌──────────────────┐
│  1. Check        │
│  Prerequisites   │──── git repo? gh CLI? authenticated?
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│  2. Fetch PR     │────▶│  Cache Layer     │
│  Data from       │     │  TTL: 5 minutes  │
│  GitHub          │◀────│  ~/.agent-os/    │
└────────┬─────────┘     └──────────────────┘
         │                      │
         │                      │ cache miss
         │                      ▼
         │              gh pr list --state all
         │              --limit 1000
         │              --json number,headRefName,...
         │
         ▼
┌──────────────────┐
│  3. Build PR     │
│  Index (in-mem)  │──── Hash Map: branch_name -> pr_info
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│  4. Parse        │────▶│  For Each        │
│  Worktrees       │     │  Worktree:       │
└──────────────────┘     └────────┬─────────┘
         │                        │
         │                        ▼
         │              ┌──────────────────┐
         │              │ Extract:         │
         │              │ - Path           │
         │              │ - Branch name    │
         │              │ - HEAD SHA       │
         │              │ - Status         │
         │              └────────┬─────────┘
         │                        │
         ▼                        ▼
git worktree list      ┌──────────────────┐
--porcelain            │ Parse issue #    │
                       │ from branch name │
                       └────────┬─────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │ Lookup PR in     │
                       │ index (O(1))     │
                       └────────┬─────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │  5. Display      │
                       │  Results         │
                       └──────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │ Worktree: /path  │
                       │ Branch: main     │
                       │ PR: #88 (MERGED) │
                       │ Issues: #87      │
                       └──────────────────┘
```

## Component Breakdown

### 1. Prerequisites Check

```bash
check_prerequisites()
├── git rev-parse --git-dir        # In git repo?
├── command -v gh                  # gh CLI installed?
└── gh auth status                 # Authenticated?
```

**Result:** Pass/Fail → Exit if fail

### 2. PR Data Layer

```bash
fetch_pr_data()
├── get_cache_file()               # ~/.agent-os/cache/pr_cache_*.json
├── is_cache_fresh(TTL=300s)       # Check age
│   ├── YES → cat cache_file       # Use cached data
│   └── NO  → gh pr list           # Fetch fresh
│       ├── --state all
│       ├── --limit 1000
│       ├── --json fields...
│       └── save to cache
└── return pr_data (JSON array)
```

**Result:** JSON array of PRs

```json
[
  {
    "number": 88,
    "headRefName": "feature-#42",
    "title": "Add feature",
    "state": "MERGED",
    "closingIssuesReferences": [
      {"number": 42, "url": "..."}
    ]
  },
  ...
]
```

### 3. PR Index Builder

```bash
build_pr_index(pr_data)
├── for each PR in pr_data:
│   ├── extract headRefName
│   ├── extract pr info
│   └── branch_to_pr[headRefName] = pr_info
└── return index
```

**Result:** Hash map (associative array)

```
branch_to_pr = {
  "feature-#42": "88\tMERGED\tAdd feature\t42",
  "fix-bug-123": "89\tOPEN\tFix bug\t",
  ...
}
```

**Lookup Complexity:** O(1)

### 4. Worktree Parser

```bash
parse_worktrees(pr_data)
├── git worktree list --porcelain
│   │
│   ├── Line: "worktree /path/to/repo"     → worktree_path
│   ├── Line: "HEAD abc123..."             → head_sha
│   ├── Line: "branch refs/heads/main"     → branch_name
│   ├── Line: ""                           → END OF RECORD
│   │   └── process_worktree()
│   │
│   └── Repeat for next worktree
│
└── for each worktree:
    ├── parse_issue_from_branch(branch_name)
    │   └── Extract #42 from "feature-#42-description"
    │
    ├── lookup PR in branch_to_pr index
    │   └── pr_info = branch_to_pr[branch_name]
    │
    └── display_worktree_status()
```

**Result:** Parsed worktree records

### 5. Display Formatter

```bash
display_worktree_status()
├── Print worktree path
├── Print branch name
├── Print HEAD SHA (short)
├── If issue # parsed from branch:
│   └── Print "Issue: #42 (from branch)"
├── If PR found in index:
│   ├── Print PR number and state
│   ├── If verbose: Print PR title
│   └── Print linked issues
└── If no PR found:
    └── Print "PR: None found"
```

**Output Example:**

```
Worktree: /Users/dalecarman/Projects/agent-os
  Branch: feature-#42-add-feature
  Commit: abc123d
  Issue: #42 (inferred from branch name)
  PR: #88 (MERGED)
  Title: Add feature X to system
  Closes Issues: #42, #87
```

## Performance Analysis

### Time Complexity

| Operation | Complexity | Duration | Notes |
|-----------|------------|----------|-------|
| Check cache | O(1) | <1ms | File stat |
| Fetch PRs (cache miss) | O(n) | 1-2s | n = total PRs |
| Build index | O(n) | 10-50ms | n = total PRs |
| Parse worktrees | O(m) | 5-10ms per | m = worktrees |
| Lookup PR in index | O(1) | <1ms | Hash lookup |
| Display results | O(m) | 5-10ms per | m = worktrees |

**Total Time:**
- **Cache Hit:** ~100ms for 10 worktrees
- **Cache Miss:** ~2-3s for 10 worktrees + 1000 PRs

### Space Complexity

| Component | Size | Notes |
|-----------|------|-------|
| PR data (JSON) | ~1-5MB | 1000 PRs with full details |
| PR index (hash map) | ~100KB | In-memory, branch -> info |
| Worktree data | ~10KB | Typically <100 worktrees |
| Cache file | ~1-5MB | On disk, TTL 5 minutes |

**Total Memory:** ~5-10MB peak

## Optimization Strategies

### 1. Caching (Implemented)

```
First call:  fetch PR data (2s) + process (100ms) = 2.1s
Second call: read cache (10ms) + process (100ms)  = 110ms

Speedup: 19x faster
```

**Trade-offs:**
- ✅ 95% faster for repeated calls
- ✅ Reduces API rate limit usage
- ⚠️ Data may be 0-5 minutes stale
- ⚠️ Cache invalidation needed on git operations

### 2. In-Memory Index (Implemented)

```
Without index: O(n*m) = 1000 PRs × 10 worktrees = 10,000 ops
With index:    O(n+m) = 1000 PRs + 10 worktrees = 1,010 ops

Speedup: 10x faster
```

**Trade-offs:**
- ✅ O(1) lookups vs O(n) linear search
- ✅ Negligible memory overhead
- ⚠️ Requires full PR list upfront

### 3. GraphQL Batching (Optional)

```
REST API:  10 sequential calls × 200ms = 2000ms
GraphQL:   1 batched query    × 300ms =  300ms

Speedup: 6.7x faster
```

**Trade-offs:**
- ✅ 80% fewer API calls
- ✅ Lower rate limit consumption
- ⚠️ More complex query syntax
- ⚠️ Harder to debug

### 4. Lazy Loading (Optional)

```
Without lazy: Always fetch PR data (2s)
With lazy:    Only fetch if --verbose flag

Speedup: Infinite for basic mode
```

**Trade-offs:**
- ✅ Instant results for basic worktree list
- ✅ Only pay cost when needed
- ⚠️ Two-tier user experience

## Error Handling Strategy

```
┌─────────────────┐
│  Prerequisites  │
│  Check Failed?  │
└────────┬────────┘
         │ YES
         ▼
    Exit with
    helpful error
    message
         │ NO
         ▼
┌─────────────────┐
│  API Call       │
│  Failed?        │
└────────┬────────┘
         │ YES
         ▼
    Continue with
    limited info
    (pr_data = [])
         │ NO
         ▼
┌─────────────────┐
│  Parse Error?   │
└────────┬────────┘
         │ YES
         ▼
    Skip record,
    continue with
    next worktree
         │ NO
         ▼
┌─────────────────┐
│  Success        │
└─────────────────┘
```

**Philosophy:** Graceful degradation over hard failures

## Alternative Architectures Considered

### Option A: Per-Worktree API Calls

```
for each worktree:
  gh pr list --head "$branch_name"
```

**Rejected:** O(m) API calls, very slow, rate limit issues

### Option B: SQLite Database

```
sqlite3 pr_cache.db "SELECT * FROM prs WHERE branch=?"
```

**Rejected:** Overkill for simple caching, adds dependency

### Option C: Real-time API (No Cache)

```
Always fetch fresh: gh pr list ...
```

**Rejected:** Too slow (2s every call), wastes API quota

### Selected: In-Memory Index + TTL Cache

**Why:**
- Fast: O(1) lookups with 5-min cache
- Simple: Pure bash, no external deps
- Scalable: Handles 1000s of PRs/worktrees
- Reliable: Graceful degradation on failures

## Testing Strategy

### Unit Tests

```bash
test_parse_issue_from_branch()
test_parse_worktree_porcelain()
test_build_pr_index()
test_cache_freshness()
```

### Integration Tests

```bash
test_with_mock_git()
test_with_mock_gh()
test_with_real_repo()
```

### Performance Tests

```bash
benchmark_pr_fetch()
benchmark_index_build()
benchmark_worktree_parse()
```

### Edge Cases

```bash
test_no_prs_found()
test_detached_head()
test_locked_worktree()
test_api_failure()
test_invalid_cache()
test_empty_repo()
```

## Future Enhancements

### Phase 1: Basic Worktree Status
- ✅ List worktrees
- ✅ Show branch names
- ✅ Map to PRs/issues
- ✅ Cache PR data

### Phase 2: Enhanced Details
- ⏳ Show worktree cleanliness (uncommitted changes)
- ⏳ Show ahead/behind status
- ⏳ Show PR review status
- ⏳ Show CI/CD status

### Phase 3: Interactive Features
- ⏳ Filter by status (open PRs only, etc.)
- ⏳ Sort by various criteria
- ⏳ Jump to worktree
- ⏳ Create new worktree from issue

### Phase 4: Integration
- ⏳ Integrate with workflow-complete
- ⏳ Integrate with workflow-hygiene
- ⏳ Dashboard view (TUI)

## Resources

- **Full Documentation:** `docs/research/github-cli-worktree-integration.md`
- **Quick Reference:** `docs/research/QUICK-REFERENCE.md`
- **Working Example:** `scripts/workflow-status-example.sh`
- **Summary:** `docs/research/SUMMARY.md`

---

*Architecture designed for the Agent OS workflow-status command. Focus on simplicity, performance, and reliability.*
