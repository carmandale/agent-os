# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-10-12-stop-hook-context-#98/spec.md

> Created: 2025-10-12
> Version: 1.0.0

## Test Coverage

### Unit Tests

**Context Extraction Functions**
- Test `extract_github_issue("branch")` with pattern: `feature-#123-description`
- Test `extract_github_issue("branch")` with pattern: `123-feature-name`
- Test `extract_github_issue("branch")` with pattern: `#123-feature`
- Test `extract_github_issue("branch")` with no issue number (returns empty)
- Test `get_current_branch()` in normal repository
- Test `get_current_branch()` in detached HEAD state
- Test `get_current_branch()` in non-git directory
- Test `detect_current_spec()` with single spec folder
- Test `detect_current_spec()` with multiple spec folders (returns most recent)
- Test `detect_current_spec()` with no spec folders (returns empty)

**Message Generation**
- Test `generate_stop_message()` with all context available (branch, issue, spec)
- Test `generate_stop_message()` with only branch available
- Test `generate_stop_message()` with only issue available
- Test `generate_stop_message()` with no context (graceful fallback)
- Test commit message suggestion with issue number
- Test commit message suggestion without issue number
- Verify context lines formatting (newlines, spacing)

### Integration Tests

**Stop-Hook Execution**
- Test stop-hook triggers with uncommitted changes on feature branch with issue
- Test stop-hook message includes branch name
- Test stop-hook message includes GitHub issue number
- Test stop-hook message includes active spec folder
- Test stop-hook message includes suggested commit format
- Test stop-hook rate limiting still functions (5-minute TTL)
- Test stop-hook suppression still works (AGENT_OS_HOOKS_QUIET=true)

**Performance Tests**
- Measure message generation latency with context extraction
- Verify total added time is < 50ms
- Test with large number of spec folders (performance doesn't degrade)

### Edge Case Tests

**Branch Naming Variations**
- Branch with multiple # symbols: `feature-#123-#456-name` (should extract first)
- Branch with issue at end: `feature-name-#123`
- Branch with issue in middle: `feature-#123-more-stuff`
- Branch without issue: `feature-branch` (empty issue, generic suggestion)
- Main/master branch: (empty issue, generic suggestion)

**Repository States**
- Not a git repository: stop-hook exits early (existing behavior)
- Git repo without .agent-os: no spec context shown
- Git repo with .agent-os but no specs: no spec context shown
- Detached HEAD state: shows "(detached)" or "unknown", no issue

**Error Conditions**
- Permission denied reading .agent-os/specs: graceful failure, no spec shown
- Invalid branch name characters: handled by git command
- Very long branch names: truncation if needed (test output formatting)

## Mocking Requirements

### File System Mocking
- **Mock .agent-os/specs/ directory** - Create temporary test directories with date-prefixed folders
- **Mock git repository** - Use temporary git repos for testing branch operations
- **Mock stop-hook environment** - Set project_root to test directory

### Git Command Mocking
- **Mock `git branch --show-current`** - Return controlled branch names for testing
- **Mock `git status --porcelain`** - Trigger stop-hook conditions
- **Mock `is_git_repo()`** - Control git repository detection

### Time-Based Mocking
- **Mock file timestamps** - Test "most recent spec" detection with controlled mtimes
- **Mock rate limiting** - Test TTL expiration without waiting 5 minutes

## Test Execution

### Running Tests

```bash
# Unit tests
bats tests/test-stop-hook-context.sh

# Integration tests (if created)
bash tests/integration/test-stop-hook-full.sh

# Performance tests
bash tests/performance/test-stop-hook-latency.sh
```

### Success Criteria

- All unit tests pass (100%)
- All integration tests pass (100%)
- Performance tests show < 50ms added latency
- Edge cases handled gracefully (no errors or crashes)
- Existing stop-hook functionality unchanged (regression tests pass)

## Test Maintenance

### When to Update Tests

- Any change to message format
- New branch naming patterns added
- Changes to context extraction logic
- Performance optimization changes

### Test Data

Store test data in `tests/fixtures/stop-hook-context/`:
- Sample branch names
- Mock spec folder structures
- Expected message outputs
