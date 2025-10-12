# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-10-12-stop-hook-context-#98/spec.md

> Created: 2025-10-12
> Version: 1.0.0

## Technical Requirements

### Context Extraction Functions

All required helper functions already exist in sourced libraries:

- **`get_current_branch()`** - `hooks/lib/git-utils.sh:23-30`
  - Returns current git branch name
  - Handles error cases (not-a-git-repo, unknown)

- **`extract_github_issue(source)`** - `hooks/lib/git-utils.sh:136-152`
  - Extracts issue number from branch name or commits
  - Supports patterns: `feature-#123`, `#123-feature`, `123-feature`
  - Returns empty string if no issue found

- **`detect_current_spec()`** - `hooks/lib/workflow-detector.sh:156-169`
  - Finds most recent spec in `.agent-os/specs/`
  - Returns basename like "2025-10-12-feature-name-#98"
  - Returns empty if no specs found

### Message Generation Enhancement

**Current implementation:** `hooks/stop-hook.sh:190-210`

The `generate_stop_message()` function needs modification to:
1. Call git context functions (already sourced at lines 18-29)
2. Build context lines conditionally
3. Generate smart commit message suggestions
4. Insert context into message template

### Performance Requirements

- **Target latency**: < 50ms added to existing message generation
- **No external dependencies**: Git commands only, no GitHub CLI
- **Graceful degradation**: Empty strings when context unavailable
- **Rate limiting preserved**: Existing 5-minute TTL still applies

## Approach Options

### Option A: Inline Context Extraction (Selected)

Extract context directly in `generate_stop_message()` function.

**Pros:**
- Simple, straightforward implementation
- No new functions needed
- Easy to test and debug
- Minimal code changes

**Cons:**
- Slightly longer function body
- Context extraction happens on every call (but rate-limited anyway)

### Option B: Separate Context Builder Function

Create new `build_commit_context()` function that returns structured data.

**Pros:**
- Cleaner separation of concerns
- Easier to unit test context extraction
- Reusable if other hooks need context

**Cons:**
- More complex implementation
- Additional function adds indirection
- Over-engineering for current need

**Rationale:** Option A is selected for simplicity. The context extraction is straightforward and only used in one place. The existing rate limiting (5-minute TTL) means performance impact is negligible. If other hooks need similar context in the future, we can refactor to Option B.

## Implementation Details

### Context Lines Construction

```bash
# Extract context
local current_branch=""
local issue_num=""
local spec_folder=""

if is_git_repo "$project_root"; then
  current_branch=$(git -C "$project_root" branch --show-current 2>/dev/null || echo "")

  if [ -n "$current_branch" ]; then
    issue_num=$(cd "$project_root" && extract_github_issue "branch")
  fi

  if [ -d "$project_root/.agent-os/specs" ]; then
    spec_folder=$(cd "$project_root" && detect_current_spec)
  fi
fi

# Build context lines
local context_lines=""
if [ -n "$current_branch" ]; then
  context_lines="${context_lines}Branch: $current_branch\n"
fi
if [ -n "$issue_num" ]; then
  context_lines="${context_lines}GitHub Issue: #$issue_num\n"
fi
if [ -n "$spec_folder" ]; then
  context_lines="${context_lines}Active Spec: $spec_folder\n"
fi
```

### Commit Message Suggestion Logic

```bash
# Generate smart commit message suggestion
local commit_suggestion=""
if [ -n "$issue_num" ]; then
  # With issue number
  commit_suggestion="  git commit -m \"feat: describe changes #${issue_num}\""
else
  # Without issue number (fallback)
  commit_suggestion="  git commit -m \"describe your work\""
fi
```

### Message Template Integration

Insert context lines after "Project:" line and before "Detected X files..." line.

Insert suggested commit as new section after file count and before "Next steps:".

## External Dependencies

No new external dependencies required. All functionality uses:
- **Existing git commands** - Already used throughout stop-hook
- **Sourced helper functions** - Already loaded from lib/ directory
- **Bash string manipulation** - Standard bash features

## Error Handling

### Missing Git Repository
- `is_git_repo()` check prevents execution in non-git directories
- Already handled by existing stop-hook logic

### Branch Name Edge Cases
- Detached HEAD: `get_current_branch()` returns "unknown"
- No branches: Empty string returned, gracefully skipped

### Issue Number Patterns
- Multiple patterns supported by `extract_github_issue()`
- No issue found: Empty string, suggestion shows generic message

### Missing Spec Folder
- `.agent-os/specs` doesn't exist: Directory check fails, skipped
- No specs in folder: `detect_current_spec()` returns empty string

All error cases result in graceful degradation - context lines simply omitted from message.

## Testing Strategy

### Unit Tests Required

1. **Branch extraction** - Test `get_current_branch()` with various repo states
2. **Issue parsing** - Test all supported branch naming patterns
3. **Spec detection** - Test with/without specs, multiple specs
4. **Message generation** - Test complete message with all context variations

### Integration Tests Required

1. **Stop-hook with context** - Full hook execution with branch/issue/spec
2. **Stop-hook without context** - Verify graceful fallback
3. **Performance measurement** - Ensure < 50ms added latency

### Test File Locations

- `tests/test-stop-hook-context.sh` - Unit tests for context extraction
- `tests/integration/test-stop-hook-full.sh` - Integration test (if needed)
