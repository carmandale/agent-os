# Implementation Tasks: Merge Command

> **Spec:** 2025-10-13-merge-command-#100
> **Last Updated:** 2025-10-13
> **Status:** Ready for Implementation

## Task Organization

Tasks are organized into 4 phases matching the spec's implementation phases. Each task follows TDD: write tests first, implement feature, verify tests pass.

**Size Legend:**
- `XS` < 1 hour
- `S` 1-2 hours
- `M` 2-4 hours
- `L` 4-8 hours
- `XL` > 8 hours

---

## Phase 1: Core Merge Automation (MVP)

**Goal:** Basic merge with safety checks
**Estimated Time:** 6-8 hours

### Setup and Infrastructure

- [ ] **Task 1.1:** Create command file `commands/workflow-merge.md` `S`
	- [ ] Write YAML frontmatter with allowed tools
	- [ ] Add description and argument hints
	- [ ] Define context section with git/PR status
	- [ ] Add task section calling workflow-merge.sh script
	- **Tests:** None (markdown definition)
	- **Acceptance:** Command file follows Agent OS patterns from workflow-status.md

- [ ] **Task 1.2:** Create main script `scripts/workflow-merge.sh` `M`
	- [ ] Create file with proper shebang and permissions
	- [ ] Add script header comments
	- [ ] Define global variables and constants
	- [ ] Add color codes for terminal output
	- [ ] Create main() function skeleton
	- **Tests:** Script passes `bash -n` syntax check
	- **Acceptance:** Script structure matches workflow-complete.sh:1-50

- [ ] **Task 1.3:** Add merge command to installer `setup-claude-code.sh` `XS`
	- [ ] Add `workflow-merge` to command installation loop
	- [ ] Add curl command to fetch from GitHub
	- [ ] Handle existing file with --overwrite flag
	- **Tests:** Installation script runs without errors
	- **Acceptance:** Command installs to ~/.claude/commands/ during setup

### PR Inference Engine

- [ ] **Task 1.4:** Write PR inference tests `M`
	- [ ] Write test: infer from explicit argument
	- [ ] Write test: infer from current branch
	- [ ] Write test: infer from issue pattern in branch
	- [ ] Write test: fail gracefully when cannot infer
	- [ ] Write test: explicit argument takes priority
	- **File:** `tests/unit/test-pr-inference.bats`
	- **Acceptance:** All 5 tests defined and failing (red)

- [ ] **Task 1.5:** Implement PR inference function `M`
	- [ ] Create `infer_pr_number()` function
	- [ ] Implement explicit argument handling
	- [ ] Add current branch check via `gh pr list --head`
	- [ ] Add issue extraction from branch name (regex patterns)
	- [ ] Add error message for inference failure
	- **Tests:** Run tests/unit/test-pr-inference.bats
	- **Acceptance:** All PR inference tests pass (green)

### User Confirmation

- [ ] **Task 1.6:** Write confirmation prompt tests `S`
	- [ ] Write test: displays PR number and title
	- [ ] Write test: shows PR metadata (author, status)
	- [ ] Write test: accepts Y/yes confirmation
	- [ ] Write test: rejects N/no confirmation
	- **File:** `tests/unit/test-confirmation.bats`
	- **Acceptance:** All 4 tests defined and failing

- [ ] **Task 1.7:** Implement confirmation prompt `S`
	- [ ] Create `confirm_merge()` function
	- [ ] Fetch PR details via `gh pr view --json`
	- [ ] Display formatted PR information
	- [ ] Implement user input handling (Y/n)
	- [ ] Return appropriate exit codes
	- **Tests:** Run tests/unit/test-confirmation.bats
	- **Acceptance:** All confirmation tests pass

### Pre-Merge Validation

- [ ] **Task 1.8:** Write validation tests `L`
	- [ ] Write test: validation passes with approved PR
	- [ ] Write test: fails with failing CI
	- [ ] Write test: fails with merge conflicts
	- [ ] Write test: fails with missing approval
	- [ ] Write test: fails with blocked branch protection
	- [ ] Create mock functions for gh commands
	- **File:** `tests/unit/test-validation.bats`
	- **Acceptance:** All 5 validation tests defined and failing

- [ ] **Task 1.9:** Implement validation function `L`
	- [ ] Create `validate_merge_readiness()` function
	- [ ] Check review status via `gh pr view --json reviewDecision`
	- [ ] Check merge conflicts via `gh pr view --json mergeable`
	- [ ] Check CI status via `gh pr checks`
	- [ ] Check branch protection via `gh pr view --json mergeStateStatus`
	- [ ] Collect and display all validation errors
	- **Tests:** Run tests/unit/test-validation.bats
	- **Acceptance:** All validation tests pass

### Merge Execution

- [ ] **Task 1.10:** Write merge execution tests `M`
	- [ ] Write test: successful merge with default strategy
	- [ ] Write test: merge with squash strategy
	- [ ] Write test: merge with rebase strategy
	- [ ] Write test: merge failure handling
	- [ ] Write test: verify merge commit after merge
	- **File:** `tests/unit/test-merge-execution.bats`
	- **Acceptance:** All 5 tests defined and failing

- [ ] **Task 1.11:** Implement merge execution `M`
	- [ ] Create `execute_merge()` function
	- [ ] Support merge strategies (merge/squash/rebase)
	- [ ] Execute `gh pr merge --delete-branch`
	- [ ] Verify merge commit via `gh pr view --json mergeCommit`
	- [ ] Handle merge failures with clear errors
	- **Tests:** Run tests/unit/test-merge-execution.bats
	- **Acceptance:** All merge execution tests pass

### Main Workflow Integration

- [ ] **Task 1.12:** Write integration tests for Phase 1 `M`
	- [ ] Write test: complete workflow (infer → validate → merge)
	- [ ] Write test: workflow blocks on failing CI
	- [ ] Write test: explicit PR number works
	- [ ] Write test: handles PR not found
	- **File:** `tests/integration/test-merge-workflow-phase1.bats`
	- **Acceptance:** All 4 integration tests defined

- [ ] **Task 1.13:** Implement main workflow for Phase 1 `M`
	- [ ] Create `main()` function
	- [ ] Parse command-line arguments
	- [ ] Call infer_pr_number()
	- [ ] Call confirm_merge()
	- [ ] Call validate_merge_readiness()
	- [ ] Call execute_merge()
	- [ ] Update local main branch
	- [ ] Display success summary
	- **Tests:** Run tests/integration/test-merge-workflow-phase1.bats
	- **Acceptance:** Phase 1 integration tests pass

### Phase 1 Completion

- [ ] **Task 1.14:** Manual testing and bug fixes `M`
	- [ ] Test happy path on real repository
	- [ ] Test error scenarios (failing CI, conflicts)
	- [ ] Fix any discovered bugs
	- [ ] Update documentation for discovered issues
	- **Tests:** Manual test scenarios 1, 2, 4, 5 from tests.md
	- **Acceptance:** All Phase 1 manual tests pass

---

## Phase 2: Review Feedback Integration

**Goal:** Address review comments before merge
**Estimated Time:** 4-6 hours

### Review Feedback Detection

- [ ] **Task 2.1:** Write review feedback tests `M`
	- [ ] Write test: detect CodeRabbit comments
	- [ ] Write test: detect Codex comments
	- [ ] Write test: no feedback when no comments
	- [ ] Write test: categorize critical vs suggestions
	- [ ] Create mock GitHub API responses
	- **File:** `tests/unit/test-review-feedback.bats`
	- **Acceptance:** All 4 tests defined and failing

- [ ] **Task 2.2:** Implement review feedback analyzer `M`
	- [ ] Create `analyze_review_feedback()` function
	- [ ] Fetch PR comments via `gh api repos/.../pulls/.../comments`
	- [ ] Filter for CodeRabbit comments (user.login == "coderabbitai")
	- [ ] Filter for Codex comments (user.login == "codex-bot")
	- [ ] Parse and display comments by file
	- [ ] Categorize CRITICAL vs suggestion comments
	- **Tests:** Run tests/unit/test-review-feedback.bats
	- **Acceptance:** All review feedback tests pass

### User Interaction for Review Feedback

- [ ] **Task 2.3:** Write user interaction tests `S`
	- [ ] Write test: prompts user to address feedback
	- [ ] Write test: accepts Y to address feedback
	- [ ] Write test: accepts n to skip feedback
	- [ ] Write test: re-validates after addressing
	- **File:** `tests/unit/test-review-interaction.bats`
	- **Acceptance:** All 4 tests defined and failing

- [ ] **Task 2.4:** Implement review feedback interaction `S`
	- [ ] Add prompt: "Address review feedback before merging? [Y/n]:"
	- [ ] Handle user input (Y/n)
	- [ ] If Y: return signal to pause merge
	- [ ] If n: continue with merge
	- [ ] Add loop to re-check after user addresses
	- **Tests:** Run tests/unit/test-review-interaction.bats
	- **Acceptance:** All interaction tests pass

### Integration with Main Workflow

- [ ] **Task 2.5:** Integrate review feedback into workflow `M`
	- [ ] Add `analyze_review_feedback()` call after validation
	- [ ] Handle return code 2 (feedback needs addressing)
	- [ ] Add re-validation loop after feedback addressed
	- [ ] Update success path to include feedback check
	- **Tests:** Run tests/integration/test-merge-workflow.bats
	- **Acceptance:** Workflow handles review feedback correctly

### Phase 2 Completion

- [ ] **Task 2.6:** Manual testing with CodeRabbit `S`
	- [ ] Test on PR with CodeRabbit comments
	- [ ] Verify comments displayed correctly
	- [ ] Test addressing feedback workflow
	- [ ] Test skipping feedback workflow
	- **Tests:** Manual test scenario 3 from tests.md
	- **Acceptance:** CodeRabbit integration works end-to-end

---

## Phase 3: Worktree Management

**Goal:** Automatic cleanup after successful merge
**Estimated Time:** 3-4 hours

### Worktree Detection

- [ ] **Task 3.1:** Write worktree detection tests `M`
	- [ ] Write test: detect when in worktree
	- [ ] Write test: skip when not in worktree
	- [ ] Write test: extract worktree path correctly
	- [ ] Write test: identify main repository path
	- [ ] Create test fixtures with worktrees
	- **File:** `tests/unit/test-worktree-detection.bats`
	- **Acceptance:** All 4 tests defined and failing

- [ ] **Task 3.2:** Implement worktree detection `S`
	- [ ] Create `detect_worktree()` function
	- [ ] Use `git worktree list --porcelain` to check current dir
	- [ ] Extract worktree path if in worktree
	- [ ] Identify main repository path
	- [ ] Return appropriate status codes
	- **Tests:** Run tests/unit/test-worktree-detection.bats
	- **Acceptance:** All detection tests pass

### Worktree Cleanup

- [ ] **Task 3.3:** Write worktree cleanup tests `L`
	- [ ] Write test: return to main repository
	- [ ] Write test: update main branch
	- [ ] Write test: verify merge present locally
	- [ ] Write test: remove worktree successfully
	- [ ] Write test: prune worktree metadata
	- [ ] Write test: fail if uncommitted changes
	- **File:** `tests/unit/test-worktree-cleanup.bats`
	- **Acceptance:** All 6 tests defined and failing

- [ ] **Task 3.4:** Implement worktree cleanup `L`
	- [ ] Create `cleanup_worktree()` function
	- [ ] Change directory to main repository
	- [ ] Checkout main branch
	- [ ] Fetch and pull from origin
	- [ ] Verify merge commit present
	- [ ] Check for uncommitted changes in worktree
	- [ ] Remove worktree via `git worktree remove`
	- [ ] Prune metadata via `git worktree prune`
	- **Tests:** Run tests/unit/test-worktree-cleanup.bats
	- **Acceptance:** All cleanup tests pass

### Integration with Main Workflow

- [ ] **Task 3.5:** Integrate worktree cleanup into workflow `M`
	- [ ] Add `detect_worktree()` call after successful merge
	- [ ] Call `cleanup_worktree()` if in worktree
	- [ ] Skip cleanup if not in worktree (with info message)
	- [ ] Handle cleanup failures gracefully
	- [ ] Update success summary with cleanup status
	- **Tests:** Run tests/integration/test-merge-workflow.bats
	- **Acceptance:** Complete workflow includes worktree cleanup

### Phase 3 Completion

- [ ] **Task 3.6:** Manual testing with worktrees `M`
	- [ ] Test merge from worktree (happy path)
	- [ ] Test merge from main repo (skip cleanup)
	- [ ] Test cleanup with uncommitted changes
	- [ ] Verify worktree fully removed
	- **Tests:** Manual test scenarios 1 and 4 from tests.md
	- **Acceptance:** Worktree cleanup works reliably

---

## Phase 4: Advanced Features & Polish

**Goal:** Production-ready with full safety and UX
**Estimated Time:** 4-6 hours

### Command-Line Flags

- [ ] **Task 4.1:** Implement --dry-run mode `M`
	- [ ] Parse --dry-run flag
	- [ ] Add DRY_RUN global variable
	- [ ] Wrap all mutating operations with DRY_RUN checks
	- [ ] Display "[DRY RUN]" prefix for actions
	- [ ] Show what would happen without executing
	- **Tests:** tests/integration/test-merge-workflow.bats (dry-run test)
	- **Acceptance:** Dry-run shows actions without executing

- [ ] **Task 4.2:** Implement --force mode `S`
	- [ ] Parse --force flag
	- [ ] Skip selected validation checks
	- [ ] Display warning: "⚠️ WARNING: Forcing merge"
	- [ ] Document which checks are skipped
	- **Tests:** tests/integration/test-merge-workflow.bats (force test)
	- **Acceptance:** Force mode bypasses validation with warning

- [ ] **Task 4.3:** Implement --auto mode `S`
	- [ ] Parse --auto flag
	- [ ] Use `gh pr merge --auto` instead of immediate merge
	- [ ] Display: "Enabled auto-merge (will merge when checks pass)"
	- [ ] Skip worktree cleanup (PR not merged yet)
	- **Tests:** Manual test with --auto flag
	- **Acceptance:** Auto-merge enabled on GitHub

- [ ] **Task 4.4:** Implement --strategy flag `XS`
	- [ ] Parse --strategy flag (merge/squash/rebase)
	- [ ] Set MERGE_STRATEGY variable
	- [ ] Display strategy in confirmation prompt
	- **Tests:** tests/unit/test-merge-execution.bats (strategy tests exist)
	- **Acceptance:** Strategy flag works as expected

### Error Handling & UX

- [ ] **Task 4.5:** Comprehensive error handling `M`
	- [ ] Add error handling for GitHub API failures
	- [ ] Handle network errors gracefully
	- [ ] Add recovery suggestions for each error type
	- [ ] Implement graceful degradation where possible
	- **Tests:** tests/edge-cases/test-merge-edge-cases.bats
	- **Acceptance:** All error scenarios handled gracefully

- [ ] **Task 4.6:** Terminal output polish `S`
	- [ ] Add color codes (green=success, red=error, yellow=warning)
	- [ ] Add emoji/icons for visual feedback
	- [ ] Implement progress indicators for long operations
	- [ ] Format output for readability
	- **Tests:** Visual inspection during manual testing
	- **Acceptance:** Output looks professional and informative

- [ ] **Task 4.7:** Add help text `XS`
	- [ ] Implement --help flag
	- [ ] Display usage information
	- [ ] Document all flags and options
	- [ ] Add examples
	- **Tests:** Run `workflow-merge.sh --help`
	- **Acceptance:** Help text is clear and comprehensive

### Documentation

- [ ] **Task 4.8:** Update CLAUDE.md `S`
	- [ ] Document /merge command usage
	- [ ] Add examples for common scenarios
	- [ ] Document flags and options
	- [ ] Add troubleshooting section
	- **Tests:** Review documentation for completeness
	- **Acceptance:** CLAUDE.md has complete /merge documentation

- [ ] **Task 4.9:** Inline code comments `M`
	- [ ] Add comments explaining PR inference logic
	- [ ] Document validation checks
	- [ ] Explain worktree cleanup steps
	- [ ] Add function headers with descriptions
	- **Tests:** Code review for comment quality
	- **Acceptance:** All major functions have clear comments

### Testing

- [ ] **Task 4.10:** Write edge case tests `L`
	- [ ] Write test: multiple PRs from same branch
	- [ ] Write test: already merged PR
	- [ ] Write test: closed but not merged PR
	- [ ] Write test: PR with merge queue
	- [ ] Write test: network failure handling
	- [ ] Write test: GitHub API rate limit
	- **File:** `tests/edge-cases/test-merge-edge-cases.bats`
	- **Acceptance:** All edge case tests pass

- [ ] **Task 4.11:** Write performance tests `S`
	- [ ] Write test: PR inference < 2 seconds
	- [ ] Write test: validation < 5 seconds
	- [ ] Write test: complete workflow < 30 seconds
	- **File:** `tests/performance/test-merge-performance.bats`
	- **Acceptance:** All performance targets met

### Phase 4 Completion

- [ ] **Task 4.12:** Final manual testing `L`
	- [ ] Test all manual scenarios from tests.md
	- [ ] Test on multiple repositories
	- [ ] Test on macOS and Linux
	- [ ] Document any platform-specific issues
	- **Tests:** All 6 manual test scenarios from tests.md
	- **Acceptance:** All scenarios work correctly on both platforms

- [ ] **Task 4.13:** Code review and cleanup `M`
	- [ ] Review code for style consistency
	- [ ] Remove debug code and TODOs
	- [ ] Optimize performance where possible
	- [ ] Ensure error messages are helpful
	- **Tests:** Code review checklist from spec
	- **Acceptance:** Code passes all review criteria

---

## Final Integration

### PR Creation

- [ ] **Task 5.1:** Create pull request `M`
	- [ ] Commit all code changes
	- [ ] Run all tests one final time
	- [ ] Create PR with comprehensive description
	- [ ] Link to issue #100
	- [ ] Add test results to PR description
	- [ ] Request review
	- **Tests:** All tests pass in CI
	- **Acceptance:** PR ready for review

### Documentation Updates

- [ ] **Task 5.2:** Update roadmap `XS`
	- [ ] Mark /merge command as implemented
	- [ ] Update Phase 1 status if applicable
	- [ ] Document completion date
	- **File:** `.agent-os/product/roadmap.md`
	- **Acceptance:** Roadmap reflects /merge completion

- [ ] **Task 5.3:** Update README if needed `XS`
	- [ ] Add /merge to command list if not present
	- [ ] Update feature list
	- **File:** `README.md`
	- **Acceptance:** README mentions /merge command

### Deployment

- [ ] **Task 5.4:** Merge to main `XS`
	- [ ] Address any PR feedback
	- [ ] Get approval from reviewers
	- [ ] Merge PR to main
	- [ ] Verify deployment successful
	- **Tests:** Installation test after merge
	- **Acceptance:** /merge available after `setup-claude-code.sh`

---

## Task Summary

**Total Tasks:** 50 tasks across 4 phases plus final integration

**Time Estimate Breakdown:**
- Phase 1: 6-8 hours (MVP)
- Phase 2: 4-6 hours (Review Integration)
- Phase 3: 3-4 hours (Worktree Management)
- Phase 4: 4-6 hours (Polish)
- Final Integration: 2-3 hours
- **Total:** 19-27 hours

**Task Size Distribution:**
- XS: 8 tasks (~6 hours)
- S: 10 tasks (~15 hours)
- M: 25 tasks (~75 hours, but many parallel)
- L: 7 tasks (~42 hours)
- XL: 0 tasks

**Parallel Execution Opportunities:**
- Test writing tasks can be done in parallel with setup
- Unit tests for different components are independent
- Documentation tasks can be done concurrently with testing

## Notes

- **TDD Approach:** All feature tasks follow pattern: write test → implement → verify test passes
- **Dependencies:** Some tasks depend on prior tasks (marked with completion checkboxes)
- **Flexibility:** Task order within phases can be adjusted based on developer preference
- **Quality Gates:** Each phase has completion criteria that must be met before proceeding

## Progress Tracking

Update task checkboxes as work progresses. When a task is complete:
1. Check the box: `- [x]`
2. Update the "Last Updated" date at the top of this file
3. Commit the change with a meaningful message

Use `git grep "\- \[ \]" .agent-os/specs/2025-10-13-merge-command-#100/tasks.md` to count remaining tasks.
