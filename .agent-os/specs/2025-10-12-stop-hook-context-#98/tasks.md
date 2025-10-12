# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-10-12-stop-hook-context-#98/spec.md

> Created: 2025-10-12
> Status: Ready for Implementation

## Tasks

- [ ] 1. Create Test Infrastructure
  - [ ] 1.1 Write unit tests for context extraction functions (extract_github_issue, get_current_branch, detect_current_spec)
  - [ ] 1.2 Create test fixtures directory with sample branch names and spec structures
  - [ ] 1.3 Write tests for message generation with all context variations
  - [ ] 1.4 Write tests for graceful fallback when context unavailable
  - [ ] 1.5 Verify all tests fail initially (TDD approach)

- [ ] 2. Implement Context Extraction in generate_stop_message()
  - [ ] 2.1 Write tests for branch name extraction in stop-hook context
  - [ ] 2.2 Add current_branch variable and call get_current_branch() in generate_stop_message()
  - [ ] 2.3 Write tests for issue number extraction from branch
  - [ ] 2.4 Add issue_num variable and call extract_github_issue("branch")
  - [ ] 2.5 Write tests for spec folder detection
  - [ ] 2.6 Add spec_folder variable and call detect_current_spec()
  - [ ] 2.7 Verify all context extraction tests pass

- [ ] 3. Build Context Lines String
  - [ ] 3.1 Write tests for context lines formatting with all context present
  - [ ] 3.2 Implement conditional context_lines string builder
  - [ ] 3.3 Write tests for context lines with partial context (branch only, issue only)
  - [ ] 3.4 Add branch line if current_branch not empty
  - [ ] 3.5 Add issue line if issue_num not empty
  - [ ] 3.6 Add spec line if spec_folder not empty
  - [ ] 3.7 Verify context formatting tests pass

- [ ] 4. Generate Smart Commit Suggestions
  - [ ] 4.1 Write tests for commit suggestion with issue number
  - [ ] 4.2 Implement commit_suggestion logic with issue number
  - [ ] 4.3 Write tests for commit suggestion without issue number (fallback)
  - [ ] 4.4 Add fallback for generic suggestion when no issue
  - [ ] 4.5 Verify commit suggestion tests pass

- [ ] 5. Update Message Template
  - [ ] 5.1 Write tests for complete message format with context
  - [ ] 5.2 Insert context_lines after "Project:" line in message template
  - [ ] 5.3 Add "Suggested commit:" section with commit_suggestion
  - [ ] 5.4 Update "Next steps" to reference suggested commit
  - [ ] 5.5 Verify complete message template tests pass

- [ ] 6. Integration Testing and Performance Validation
  - [ ] 6.1 Create integration test that triggers stop-hook with feature branch
  - [ ] 6.2 Verify stop-hook message includes branch, issue, and spec context
  - [ ] 6.3 Test stop-hook on branch without issue (verify graceful fallback)
  - [ ] 6.4 Test stop-hook in non-Agent OS project (verify no spec shown)
  - [ ] 6.5 Measure message generation latency (verify < 50ms added)
  - [ ] 6.6 Test rate limiting still functions (5-minute TTL)
  - [ ] 6.7 Test suppression still works (AGENT_OS_HOOKS_QUIET=true)
  - [ ] 6.8 Verify all integration tests pass

- [ ] 7. Edge Case Testing
  - [ ] 7.1 Write tests for various branch naming patterns (#123, 123-, #123-desc)
  - [ ] 7.2 Test detached HEAD state
  - [ ] 7.3 Test main/master branch (no issue extraction)
  - [ ] 7.4 Test multiple spec folders (verify most recent selected)
  - [ ] 7.5 Test missing .agent-os/specs directory
  - [ ] 7.6 Verify all edge case tests pass

- [ ] 8. Documentation and Cleanup
  - [ ] 8.1 Update comments in stop-hook.sh explaining new context extraction
  - [ ] 8.2 Add inline documentation for context_lines construction
  - [ ] 8.3 Document supported branch naming patterns in comments
  - [ ] 8.4 Update stop-hook.sh header with feature description
  - [ ] 8.5 Verify all tests still pass after documentation changes
