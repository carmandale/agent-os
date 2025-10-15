# Test Specification: Merge Command

> **Spec:** 2025-10-13-merge-command-#100
> **Last Updated:** 2025-10-13

## Test Strategy

### Approach
- **TDD (Test-Driven Development):** Write tests before implementation
- **Unit Tests:** Test individual functions in isolation
- **Integration Tests:** Test complete workflow with mock GitHub responses
- **Manual Tests:** Verify real GitHub interaction and user experience

### Test Framework
- **Shell Testing:** BATS (Bash Automated Testing System)
- **Location:** `tests/test-workflow-merge.bats`
- **Mocks:** Mock `gh` commands for predictable testing

## Unit Tests

### 1. PR Inference Tests

**File:** `tests/unit/test-pr-inference.bats`

```bats
@test "infer PR from explicit argument" {
	run infer_pr_number 123
	assert_success
	assert_output "123"
}

@test "infer PR from current branch" {
	git checkout -b feature/auth-#456
	run infer_pr_number
	assert_success
	assert_output "456"
}

@test "infer PR from branch with issue pattern" {
	git checkout -b issue-789
	run infer_pr_number
	assert_success
	assert_output --partial "789"
}

@test "fail gracefully when PR cannot be inferred" {
	git checkout -b random-branch
	run infer_pr_number
	assert_failure
	assert_output --partial "Could not infer PR number"
}

@test "prioritize explicit argument over branch" {
	git checkout -b feature/auth-#456
	run infer_pr_number 999
	assert_success
	assert_output "999"
}
```

### 2. Validation Tests

**File:** `tests/unit/test-validation.bats`

```bats
@test "validation passes with approved PR" {
	mock_gh_pr_view_approved
	run validate_merge_readiness 123
	assert_success
	assert_output --partial "All pre-merge checks passed"
}

@test "validation fails with failing CI" {
	mock_gh_pr_checks_failing
	run validate_merge_readiness 123
	assert_failure
	assert_output --partial "Failing checks"
}

@test "validation fails with merge conflicts" {
	mock_gh_pr_view_conflicts
	run validate_merge_readiness 123
	assert_failure
	assert_output --partial "Merge conflicts detected"
}

@test "validation fails with missing approval" {
	mock_gh_pr_view_review_required
	run validate_merge_readiness 123
	assert_failure
	assert_output --partial "Review required"
}

@test "validation fails with blocked branch protection" {
	mock_gh_pr_view_blocked
	run validate_merge_readiness 123
	assert_failure
	assert_output --partial "Branch protection rules not satisfied"
}
```

### 3. Review Feedback Tests

**File:** `tests/unit/test-review-feedback.bats`

```bats
@test "detect CodeRabbit comments" {
	mock_gh_api_coderabbit_comments
	run analyze_review_feedback 123
	assert_success
	assert_output --partial "Review feedback detected"
	assert_output --partial "coderabbitai"
}

@test "detect Codex comments" {
	mock_gh_api_codex_comments
	run analyze_review_feedback 123
	assert_success
	assert_output --partial "Review feedback detected"
	assert_output --partial "codex-bot"
}

@test "no review feedback when no comments" {
	mock_gh_api_no_comments
	run analyze_review_feedback 123
	assert_success
	refute_output --partial "Review feedback detected"
}

@test "categorize critical vs suggestion comments" {
	mock_gh_api_mixed_comments
	run analyze_review_feedback 123
	assert_success
	assert_output --partial "CRITICAL"
	assert_output --partial "suggestion"
}
```

### 4. Merge Execution Tests

**File:** `tests/unit/test-merge-execution.bats`

```bats
@test "successful merge with default strategy" {
	mock_gh_pr_merge_success
	run execute_merge 123
	assert_success
	assert_output --partial "merged successfully"
}

@test "merge with squash strategy" {
	MERGE_STRATEGY=squash
	mock_gh_pr_merge_success
	run execute_merge 123
	assert_success
	assert_output --partial "merged successfully"
}

@test "merge with rebase strategy" {
	MERGE_STRATEGY=rebase
	mock_gh_pr_merge_success
	run execute_merge 123
	assert_success
	assert_output --partial "merged successfully"
}

@test "merge failure handling" {
	mock_gh_pr_merge_failure
	run execute_merge 123
	assert_failure
	assert_output --partial "Merge failed"
}

@test "verify merge commit after merge" {
	mock_gh_pr_merge_success
	run execute_merge 123
	assert_success
	assert_output --partial "Merge commit:"
}
```

### 5. Worktree Cleanup Tests

**File:** `tests/unit/test-worktree-cleanup.bats`

```bats
@test "detect when in worktree" {
	create_test_worktree
	cd_to_worktree
	run cleanup_worktree
	assert_success
	assert_output --partial "Cleaning up worktree"
}

@test "skip cleanup when not in worktree" {
	cd_to_main_repo
	run cleanup_worktree
	assert_success
	assert_output --partial "Not in a worktree"
}

@test "return to main repository during cleanup" {
	create_test_worktree
	cd_to_worktree
	run cleanup_worktree
	assert_success
	assert_equal "$(pwd)" "$MAIN_REPO_PATH"
}

@test "update main branch during cleanup" {
	create_test_worktree
	cd_to_worktree
	run cleanup_worktree
	assert_success
	assert_output --partial "Main branch updated"
}

@test "remove worktree after verification" {
	create_test_worktree
	cd_to_worktree
	run cleanup_worktree
	assert_success
	assert_output --partial "Worktree removed"
	refute_directory_exists "$WORKTREE_PATH"
}

@test "prune worktree metadata" {
	create_test_worktree
	cd_to_worktree
	run cleanup_worktree
	assert_success
	assert_output --partial "Worktree metadata pruned"
}

@test "fail gracefully if worktree has uncommitted changes" {
	create_test_worktree
	cd_to_worktree
	touch uncommitted.txt
	run cleanup_worktree
	assert_failure
	assert_output --partial "uncommitted changes"
}
```

## Integration Tests

### Full Workflow Tests

**File:** `tests/integration/test-merge-workflow.bats`

```bats
@test "complete workflow: infer → validate → merge → cleanup" {
	# Setup: Create PR in worktree
	create_test_pr_in_worktree 123

	# Execute: Run merge command
	run workflow-merge.sh

	# Assert: All steps completed
	assert_success
	assert_output --partial "Merge PR #123?"
	assert_output --partial "All pre-merge checks passed"
	assert_output --partial "merged successfully"
	assert_output --partial "Worktree removed"
}

@test "workflow with review feedback" {
	create_test_pr_with_coderabbit_comments 456
	mock_user_input "Y"  # User confirms addressing feedback

	run workflow-merge.sh

	assert_success
	assert_output --partial "Review feedback detected"
	assert_output --partial "Address review feedback"
}

@test "workflow blocks on failing CI" {
	create_test_pr_with_failing_ci 789

	run workflow-merge.sh

	assert_failure
	assert_output --partial "Failing checks"
	assert_output --partial "Cannot merge"
}

@test "dry-run mode shows actions without executing" {
	create_test_pr 123

	run workflow-merge.sh --dry-run

	assert_success
	assert_output --partial "[DRY RUN]"
	assert_output --partial "Would merge PR #123"
	refute_output --partial "merged successfully"  # Should not actually merge
}

@test "force mode skips validation checks" {
	create_test_pr_with_failing_ci 123

	run workflow-merge.sh --force

	assert_success
	assert_output --partial "⚠️  WARNING: Forcing merge"
	assert_output --partial "merged successfully"
}
```

## Edge Case Tests

**File:** `tests/edge-cases/test-merge-edge-cases.bats`

```bats
@test "handle multiple PRs from same branch" {
	create_multiple_prs_same_branch

	run workflow-merge.sh

	assert_failure
	assert_output --partial "Multiple PRs found"
	assert_output --partial "Please specify"
}

@test "handle already merged PR" {
	create_merged_pr 123

	run workflow-merge.sh 123

	assert_failure
	assert_output --partial "PR already merged"
}

@test "handle closed but not merged PR" {
	create_closed_pr 123

	run workflow-merge.sh 123

	assert_failure
	assert_output --partial "PR is closed"
}

@test "handle PR with merge queue" {
	create_pr_in_merge_queue 123

	run workflow-merge.sh 123

	assert_success
	assert_output --partial "Added to merge queue"
}

@test "handle network failure gracefully" {
	mock_network_failure

	run workflow-merge.sh 123

	assert_failure
	assert_output --partial "Network error"
	assert_output --partial "Try again"
}

@test "handle GitHub API rate limit" {
	mock_api_rate_limit

	run workflow-merge.sh 123

	assert_failure
	assert_output --partial "Rate limit exceeded"
	assert_output --partial "Wait"
}
```

## Manual Test Scenarios

### Scenario 1: Happy Path (Green PR in Worktree)

**Setup:**
1. Create feature branch with issue number: `git checkout -b feature/merge-cmd-#100`
2. Create worktree: `git worktree add .worktrees/merge-cmd-#100 feature/merge-cmd-#100`
3. Create test PR on GitHub with passing CI
4. Navigate to worktree: `cd .worktrees/merge-cmd-#100`

**Execute:**
```bash
/merge
```

**Expected:**
- ✅ Infers PR #100 from branch
- ✅ Displays: "Merge PR #100: Add merge command?"
- ✅ Shows PR details (author, checks, reviews)
- ✅ All validation checks pass
- ✅ Executes merge successfully
- ✅ Returns to main repository
- ✅ Updates main branch
- ✅ Removes worktree
- ✅ Displays success summary

### Scenario 2: Failing CI Checks

**Setup:**
1. Create PR with intentionally failing tests
2. Navigate to worktree

**Execute:**
```bash
/merge
```

**Expected:**
- ✅ Infers PR correctly
- ✅ Validation detects failing checks
- ❌ Blocks merge with clear error message
- ✅ Lists specific failing checks
- ✅ Suggests fixes: "Fix failing tests before merging"
- ✅ Does not execute merge

### Scenario 3: CodeRabbit Review Feedback

**Setup:**
1. Create PR with CodeRabbit comments
2. Navigate to worktree

**Execute:**
```bash
/merge
```

**Expected:**
- ✅ Infers PR correctly
- ✅ Validation passes
- ✅ Detects CodeRabbit comments
- ✅ Displays: "🤖 Review feedback detected:"
- ✅ Lists comments by file
- ✅ Prompts: "Address review feedback before merging? [Y/n]:"
- ✅ If user types Y: Pauses merge, allows addressing
- ✅ If user types n: Proceeds with merge

### Scenario 4: Not in Worktree

**Setup:**
1. Stay in main repository
2. Create feature branch with PR

**Execute:**
```bash
/merge 123
```

**Expected:**
- ✅ Accepts explicit PR number
- ✅ Validation passes
- ✅ Executes merge
- ✅ Updates main branch
- ℹ️  Displays: "Not in a worktree, skipping cleanup"
- ✅ No worktree removal attempted

### Scenario 5: Merge Conflicts

**Setup:**
1. Create PR with merge conflicts
2. Navigate to worktree

**Execute:**
```bash
/merge
```

**Expected:**
- ✅ Infers PR correctly
- ❌ Validation detects conflicts
- ✅ Blocks merge with error: "Merge conflicts detected"
- ✅ Suggests: "Resolve conflicts before merging"
- ✅ Provides command: `git merge main`

### Scenario 6: Dry Run Mode

**Setup:**
1. Create valid PR in worktree

**Execute:**
```bash
/merge --dry-run
```

**Expected:**
- ✅ Infers PR correctly
- ✅ Shows all validation checks
- ✅ Displays: "[DRY RUN] Would merge PR #123"
- ✅ Shows what cleanup would happen
- ❌ Does not actually merge
- ❌ Does not remove worktree

## Performance Tests

**File:** `tests/performance/test-merge-performance.bats`

```bats
@test "PR inference completes within 2 seconds" {
	start_time=$(date +%s)
	run infer_pr_number
	end_time=$(date +%s)
	duration=$((end_time - start_time))
	assert_less_than "$duration" 2
}

@test "validation completes within 5 seconds" {
	start_time=$(date +%s)
	run validate_merge_readiness 123
	end_time=$(date +%s)
	duration=$((end_time - start_time))
	assert_less_than "$duration" 5
}

@test "complete workflow completes within 30 seconds" {
	start_time=$(date +%s)
	run workflow-merge.sh
	end_time=$(date +%s)
	duration=$((end_time - start_time))
	assert_less_than "$duration" 30
}
```

## Test Execution Commands

```bash
# Run all tests
bats tests/test-workflow-merge.bats

# Run unit tests only
bats tests/unit/

# Run integration tests
bats tests/integration/

# Run edge case tests
bats tests/edge-cases/

# Run specific test file
bats tests/unit/test-pr-inference.bats

# Run with verbose output
bats -t tests/test-workflow-merge.bats

# Generate test coverage report (requires bats-coverage)
bats tests/ --coverage
```

## Test Fixtures

**Location:** `tests/fixtures/workflow-merge/`

### Mock Functions

**File:** `tests/fixtures/workflow-merge/mocks.bash`

```bash
# Mock gh pr view for approved PR
mock_gh_pr_view_approved() {
	gh() {
		if [[ "$1" == "pr" && "$2" == "view" ]]; then
			echo '{"reviewDecision":"APPROVED","mergeable":"MERGEABLE","mergeStateStatus":"CLEAN"}'
		fi
	}
	export -f gh
}

# Mock gh pr checks for passing CI
mock_gh_pr_checks_passing() {
	gh() {
		if [[ "$1" == "pr" && "$2" == "checks" ]]; then
			echo '[{"name":"CI","state":"SUCCESS"}]'
		fi
	}
	export -f gh
}

# Mock gh api for CodeRabbit comments
mock_gh_api_coderabbit_comments() {
	gh() {
		if [[ "$1" == "api" ]]; then
			cat tests/fixtures/workflow-merge/coderabbit-comments.json
		fi
	}
	export -f gh
}
```

### Test Data

**File:** `tests/fixtures/workflow-merge/coderabbit-comments.json`

```json
[
	{
		"path": "scripts/workflow-merge.sh",
		"body": "Consider adding error handling for network failures",
		"user": {"login": "coderabbitai"}
	},
	{
		"path": "commands/workflow-merge.md",
		"body": "CRITICAL: Missing input validation",
		"user": {"login": "coderabbitai"}
	}
]
```

## Test Coverage Goals

- **Unit Tests:** 90%+ code coverage
- **Integration Tests:** All critical paths covered
- **Edge Cases:** All identified edge cases tested
- **Manual Tests:** All user-facing scenarios verified

## Test Maintenance

- Run tests before every commit
- Update tests when adding new features
- Review test failures immediately
- Keep mocks synchronized with real API responses
