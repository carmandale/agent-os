# Step 4: Git Integration and Completion

## Git Workflow (Step 9)

**Commit Process:**
- **Message Format:** Conventional commits with issue reference
- **Examples:**
  - `feat: implement user authentication #123`
  - `fix: resolve login validation bug #123`  
  - `test: add auth integration tests #123`
- **Requirement:** Every commit MUST reference the GitHub issue

**Push and Pull Request:**
- **Target:** Spec branch (derived from folder name)
- **Remote:** origin
- **PR Title:** Descriptive title matching functionality
- **PR Description:** Use template with issue link

**PR Template:**
```markdown
## Summary
[BRIEF_DESCRIPTION_OF_CHANGES]

**Fixes #[ISSUE_NUMBER]**

## Changes Made
- [CHANGE_1]
- [CHANGE_2]

## Testing  
- [TEST_COVERAGE]
- All tests passing ✓

## Issue Status
- [ ] Update issue with progress
- [ ] Close issue when PR is merged
```

## Roadmap Progress Check (Step 10)

**Update Criteria:**
- Spec fully implements roadmap feature
- All related tasks completed  
- Tests passing
- **Caution:** Only mark complete if absolutely certain

**Actions:**
1. Review @.agent-os/product/roadmap.md for related items
2. Evaluate if current spec completes roadmap goals
3. Update roadmap items if applicable
4. Verify certainty before marking complete

## Completion Notification (Step 11)

**System Sound:** Play completion notification
- **Command:** `afplay /System/Library/Sounds/Glass.aiff`
- **Purpose:** Alert user that task implementation is complete

## Completion Summary (Step 12)

**Summary Template:**
```markdown
## 🎉 WORK FULLY INTEGRATED AND COMPLETE

**Status**: All development work finished and ready for team use
**Integration State**: Code committed, PR ready, workspace clean

## ✅ What's been implemented
1. **[FEATURE_1]** - [ONE_SENTENCE_DESCRIPTION] 
2. **[FEATURE_2]** - [ONE_SENTENCE_DESCRIPTION]

## ✅ Quality Checks
- **Linting**: [PASSED/NOT_APPLICABLE]
- **TypeScript**: [PASSED/NOT_APPLICABLE]  
- **Unit Tests**: [X/Y passed]
- **Playwright Tests**: [PASSED/NOT_APPLICABLE]

## 📦 Integration Status
- **Pull Request**: [GITHUB_PR_URL] - [READY_FOR_MERGE/MERGED]
- **Branch Status**: [ON_MAIN/CLEANED_UP]
- **Issue Tracking**: #[ISSUE_NUMBER] - [UPDATED/CLOSED] 
- **Workspace**: Clean and ready for next work

## 🚀 NEXT STEPS
✅ **This work is completely finished and integrated**
- All code changes are committed and pushed
- Pull request is ready for review/merged
- Related issues are updated/closed
- Workspace is clean and on main branch
- Team can immediately build upon this work

**Ready for**: New feature development, next phase work, or additional tasks
```

## Autonomous Preparation for Merge (Step 13)

**Complete Validation Workflow:**
1. **Subagent Analysis:** Use senior-software-engineer, qa-test-engineer, code-refactoring-expert for comprehensive review
2. **Comprehensive Testing:** 100% pass rate on all tests (unit, integration, Playwright)  
3. **Functionality Validation:** End-to-end validation of all features
4. **PR Optimization:** Clear description, no conflicts, all GitHub checks passing

**BLOCKING:** Display "READY TO MERGE" message and wait for user approval:
```
🚨🛑 WORKFLOW COMPLETE - MERGE APPROVAL REQUIRED 🛑🚨

✅ Code implemented and validated
✅ Subagent expert review completed  
✅ All tests passing
✅ PR optimized and conflict-free

Type "merge" to complete workflow
```

## Execute Approved Merge (Step 14)

**Merge Execution (only after user types "merge"):**
1. **Merge PR:** `gh pr merge [PR_NUMBER] --merge --delete-branch`
2. **Close Issues:** Auto-close via "Fixes #123" in PR  
3. **Branch Cleanup:** Switch to main, pull latest
4. **Final Verification:** Clean git status, no open PRs, issues closed

**Success Message:**
```
🎉 **AGENT OS WORKFLOW COMPLETE!** 🎉

✅ **Merge Successful:**
- PR #[PR_NUMBER] merged to main
- Issue #[ISSUE_NUMBER] automatically closed  
- Feature branch deleted
- Workspace cleaned and reset

🚀 **Ready for next feature!**
```

## Workflow Completion Standards

**CRITICAL:** Work is NOT complete until ALL steps (9-14) are executed.
- **Technical completion** (code works) ≠ **Professional completion** (integrated)
- **Professional development** requires complete git integration workflow
- **Team collaboration** requires proper PR and issue management