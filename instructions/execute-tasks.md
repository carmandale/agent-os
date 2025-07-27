---
description: Task Execution Rules for Agent OS
globs:
alwaysApply: false
version: 1.2.0
lastUpdated: 2025-07-26
encoding: UTF-8
---

# Task Execution Rules

<ai_meta>
  <parsing_rules>
    - Process XML blocks first for structured data
    - Execute instructions in sequential order
    - Use templates as exact patterns
    - Request missing data rather than assuming
  </parsing_rules>
  <file_conventions>
    - encoding: UTF-8
    - line_endings: LF
    - indent: 2 spaces
    - markdown_headers: no indentation
  </file_conventions>
</ai_meta>

## Overview

<purpose>
  - Execute spec tasks systematically
  - Follow TDD development workflow
  - Ensure quality through testing and review
</purpose>

<context>
  - Part of Agent OS framework
  - Executed after spec planning is complete
  - Follows tasks defined in spec tasks.md
</context>

<prerequisites>
  - Spec documentation exists in @.agent-os/specs/
  - Tasks defined in spec's tasks.md
  - Development environment configured
  - Git repository initialized
</prerequisites>

<process_flow>

<step number="0" name="workspace_hygiene_check">

### Step 0: Workspace Hygiene Check

<step_metadata>
  <purpose>ensure clean workspace before starting any work</purpose>
  <blocks>execution if workspace is dirty</blocks>
</step_metadata>

<hygiene_checklist>
  <git_status>
    <check>git status --porcelain</check>
    <requirement>empty output (clean working directory)</requirement>
  </git_status>
  <open_prs>
    <check>any PRs ready for merge?</check>
    <action>prompt user to merge first</action>
  </open_prs>
  <open_issues>
    <check>any completed issues need closing?</check>
    <action>prompt user to close first</action>
  </open_issues>
  <current_branch>
    <check>appropriate for new work</check>
    <action>suggest switching to main if needed</action>
  </current_branch>
</hygiene_checklist>

<hygiene_prompt>
  🧹 **Workspace Hygiene Check**
  
  Before starting work, let me verify our workspace is clean:
  
  - Git status: [CLEAN/DIRTY]
  - Open PRs: [NONE/READY_FOR_MERGE]
  - Open issues: [NONE/NEED_CLOSING]
  - Current branch: [APPROPRIATE/NEEDS_SWITCH]
  
  [IF_NOT_CLEAN]
  ⚠️ **Workspace needs cleanup before proceeding:**
  
  1. [SPECIFIC_ACTIONS_NEEDED]
  2. [SPECIFIC_ACTIONS_NEEDED]
  
  Please clean up the workspace first, then restart this command.
  
  [IF_CLEAN]
  ✅ **Workspace is clean and ready for work!**
</hygiene_prompt>

<instructions>
  ACTION: Check all hygiene criteria before proceeding
  BLOCK: If any criteria fail, stop execution
  GUIDE: Provide specific cleanup actions needed
  PROCEED: Only when workspace is completely clean
</instructions>

</step>

<step number="1" name="github_issue_verification">

### Step 1: GitHub Issue Verification

<step_metadata>
  <requires>github issue before any work</requires>
  <purpose>ensure work is tracked and traceable</purpose>
</step_metadata>

<issue_check>
  <check>Does the spec folder name contain a GitHub issue number?</check>
  <if_no_issue>
    - ERROR: "Cannot proceed without GitHub issue. Please create an issue and update spec folder name."
    - STOP: Execution until issue is created
  </if_no_issue>
  <if_has_issue>
    - EXTRACT: Issue number from folder name
    - STORE: Issue number for commit messages
    - PROCEED: To task assignment
  </if_has_issue>
</issue_check>

<instructions>
  ACTION: Verify GitHub issue exists before any work
  REQUIRE: Issue number in spec folder name
  STOP: If no issue found
  STORE: Issue number for later use
</instructions>

</step>

<step number="1.5" name="codebase_reality_check">

### Step 1.5: Codebase Reality Check

<step_metadata>
  <purpose>verify tasks match actual codebase state</purpose>
  <prevents>implementing already-completed features</prevents>
  <blocks>execution if major discrepancies found</blocks>
</step_metadata>

<reality_check_process>
  <task_validation>
    <check>scan tasks.md for inconsistent states</check>
    <flag>main tasks unchecked with all subtasks checked</flag>
    <flag>tasks claiming "not implemented" for existing code</flag>
  </task_validation>
  <implementation_detection>
    <check>scan codebase for files mentioned in tasks</check>
    <verify>if implementation files already exist</verify>
    <assess>implementation completeness vs task claims</assess>
  </implementation_detection>
  <git_history_check>
    <check>git log --oneline --since="1 week ago" .</check>
    <assess>recent commits related to current tasks</assess>
  </git_history_check>
</reality_check_process>

<inconsistency_detection>
  <red_flags>
    <main_task_unchecked_with_all_subtasks_done>
      ERROR: Task inconsistency detected
      - Main task: "[ ] Feature X" 
      - Subtasks: All marked "[x]"
      - ACTION: Flag for user review before proceeding
    </main_task_unchecked_with_all_subtasks_done>
    <implementation_already_exists>
      ERROR: Implementation mismatch detected
      - Task claims: "Not implemented"
      - Codebase shows: [FILE_PATH] with [LINE_COUNT] lines
      - ACTION: Verify task accuracy before proceeding
    </implementation_already_exists>
    <recent_commits_contradict_tasks>
      WARNING: Recent commits suggest different progress
      - Tasks show: [TASK_STATUS]
      - Git history shows: [RECENT_COMMIT_SUMMARY]
      - ACTION: Reconcile before proceeding
    </recent_commits_contradict_tasks>
  </red_flags>
</inconsistency_detection>

<reality_check_prompt>
  🔍 **Codebase Reality Check**
  
  Before executing tasks, let me verify the current state matches the task list:
  
  **Task Consistency**: [PASS ✅ / ISSUES_FOUND ⚠️]
  **Implementation Status**: [MATCHES_TASKS ✅ / DISCREPANCIES_FOUND ⚠️]
  **Recent Git Activity**: [CONSISTENT ✅ / CONFLICTING ⚠️]
  
  [IF_ISSUES_FOUND]
  ⚠️ **Discrepancies Detected:**
  
  1. [SPECIFIC_ISSUE_1]
  2. [SPECIFIC_ISSUE_2]
  
  **This suggests the task list may not reflect the current codebase state.**
  
  **Recommended actions:**
  - Review and update task status to match actual implementation
  - Mark completed features as "[x]" in tasks.md
  - Verify which tasks actually need work
  
  Should I proceed with task reconciliation? (yes/no)
  
  [IF_CLEAN]
  ✅ **Reality check passed - tasks align with codebase state**
</reality_check_prompt>

<blocking_criteria>
  <critical_inconsistencies>
    <block_if>major implementation already exists but task shows "not started"</block_if>
    <block_if>all subtasks complete but main task unchecked</block_if>
    <block_if>tasks reference non-existent files or outdated structure</block_if>
  </critical_inconsistencies>
  <user_approval_required>
    <scenario>when discrepancies detected</scenario>
    <options>["reconcile_tasks", "proceed_anyway", "abort_execution"]</options>
  </user_approval_required>
</blocking_criteria>

<instructions>
  ACTION: Perform comprehensive reality check before task execution
  DETECT: Task inconsistencies and implementation mismatches
  BLOCK: Execution on critical discrepancies requiring user input
  RECONCILE: Task status with actual codebase state when needed
</instructions>

</step>

<step number="2" name="task_assignment">

### Step 2: Task Assignment

<step_metadata>
  <inputs>
    - spec_srd_reference: file path
    - specific_tasks: array[string] (optional)
  </inputs>
  <default>next uncompleted parent task</default>
</step_metadata>

<task_selection>
  <explicit>user specifies exact task(s)</explicit>
  <implicit>find next uncompleted task in tasks.md</implicit>
</task_selection>

<instructions>
  ACTION: Identify task(s) to execute
  DEFAULT: Select next uncompleted parent task if not specified
  CONFIRM: Task selection with user
</instructions>

</step>

<step number="2" name="context_analysis">

### Step 2: Context Analysis

<step_metadata>
  <reads>
    - spec SRD file
- spec tasks.md
- all files in spec sub-specs/ folder
    - @.agent-os/product/mission.md
  </reads>
  <purpose>complete understanding of requirements</purpose>
</step_metadata>

<context_gathering>
  <spec_level>
    - requirements from SRD
    - technical specs
    - test specifications
  </spec_level>
  <product_level>
    - overall mission alignment
    - technical standards
    - best practices
  </product_level>
</context_gathering>

<instructions>
  ACTION: Read all spec documentation thoroughly
  ANALYZE: Requirements and specifications for current task
  UNDERSTAND: How task fits into overall spec goals
</instructions>

</step>

<step number="3" name="implementation_planning">

### Step 3: Implementation Planning

<step_metadata>
  <creates>execution plan</creates>
  <requires>user approval</requires>
</step_metadata>

<plan_structure>
  <format>numbered list with sub-bullets</format>
  <includes>
    - all subtasks from tasks.md
    - implementation approach
    - dependencies to install
    - test strategy
  </includes>
</plan_structure>

<plan_template>
  ## Implementation Plan for [TASK_NAME]

  1. **[MAJOR_STEP_1]**
     - [SPECIFIC_ACTION]
     - [SPECIFIC_ACTION]

  2. **[MAJOR_STEP_2]**
     - [SPECIFIC_ACTION]
     - [SPECIFIC_ACTION]

  **Dependencies to Install:**
  - [LIBRARY_NAME] - [PURPOSE]

  **Test Strategy:**
  - [TEST_APPROACH]
</plan_template>

<approval_request>
  I've prepared the above implementation plan.
  Please review and confirm before I proceed with execution.
</approval_request>

<instructions>
  ACTION: Create detailed execution plan
  DISPLAY: Plan to user for review
  WAIT: For explicit approval before proceeding
  BLOCK: Do not proceed without affirmative permission
</instructions>

</step>

<step number="4" name="development_server_check">

### Step 4: Check for Development Server

<step_metadata>
  <checks>running development server</checks>
  <prevents>port conflicts</prevents>
</step_metadata>

<server_check_flow>
  <if_running>
    ASK user to shut down
    WAIT for response
  </if_running>
  <if_not_running>
    PROCEED immediately
  </if_not_running>
</server_check_flow>

<user_prompt>
  A development server is currently running.
  Should I shut it down before proceeding? (yes/no)
</user_prompt>

<instructions>
  ACTION: Check for running local development server
  CONDITIONAL: Ask permission only if server is running
  PROCEED: Immediately if no server detected
</instructions>

</step>

<step number="5" name="git_branch_management">

### Step 5: Git Branch Management

<step_metadata>
  <manages>git branches</manages>
  <ensures>proper isolation</ensures>
</step_metadata>

<branch_naming>
  <source>spec folder name</source>
  <format>exclude date prefix</format>
  <example>
    - folder: 2025-03-15-password-reset
    - branch: password-reset
  </example>
</branch_naming>

<branch_logic>
  <case_a>
    <condition>current branch matches spec name</condition>
    <action>PROCEED immediately</action>
  </case_a>
  <case_b>
    <condition>current branch is main/staging/review</condition>
    <action>CREATE new branch and PROCEED</action>
  </case_b>
  <case_c>
    <condition>current branch is different feature</condition>
    <action>ASK permission to create new branch</action>
  </case_c>
</branch_logic>

<case_c_prompt>
  Current branch: [CURRENT_BRANCH]
  This spec needs branch: [SPEC_BRANCH]

  May I create a new branch for this spec? (yes/no)
</case_c_prompt>

<instructions>
  ACTION: Check current git branch
  EVALUATE: Which case applies
  EXECUTE: Appropriate branch action
  WAIT: Only for case C approval
</instructions>

</step>

<step number="6" name="development_execution">

### Step 6: Development Execution

<step_metadata>
  <follows>approved implementation plan</follows>
  <adheres_to>all spec standards</adheres_to>
  <includes>optional linting during development</includes>
</step_metadata>

<execution_standards>
  <follow_exactly>
    - approved implementation plan
    - spec specifications
    - @.agent-os/product/code-style.md
    - @.agent-os/product/dev-best-practices.md
  </follow_exactly>
  <approach>test-driven development (TDD)</approach>
</execution_standards>

<tdd_workflow>
  1. Write failing tests first
  2. Implement minimal code to pass
  3. Refactor while keeping tests green
  4. Repeat for each feature
</tdd_workflow>

<linting_during_development>
  <condition>if linting tools detected</condition>
  <check_for>
    - ESLint config (JavaScript/TypeScript)
    - Prettier config
    - TypeScript compiler (tsconfig.json)
    - Ruff config (Python)
  </check_for>
  <optional_run>
    - Run linting to catch issues early
    - Fix obvious formatting issues
    - Report but don't block on linting errors (save blocking for Step 8)
  </optional_run>
</linting_during_development>

<instructions>
  ACTION: Execute development plan systematically
  FOLLOW: All coding standards and specifications
  IMPLEMENT: TDD approach throughout
  MAINTAIN: Code quality at every step
  OPTIONAL: Run linting if configs detected (don't block)
</instructions>

</step>

<step number="7" name="task_status_updates">

### Step 7: Task Status Updates

<step_metadata>
  <updates>tasks.md file</updates>
  <timing>immediately after completion</timing>
</step_metadata>

<update_format>
  <completed>- [x] Task description</completed>
  <incomplete>- [ ] Task description</incomplete>
  <blocked>
    - [ ] Task description
    ⚠️ Blocking issue: [DESCRIPTION]
  </blocked>
</update_format>

<blocking_criteria>
  <attempts>maximum 3 different approaches</attempts>
  <action>document blocking issue</action>
  <emoji>⚠️</emoji>
</blocking_criteria>

<instructions>
  ACTION: Update tasks.md after each task completion
  MARK: [x] for completed items immediately
  DOCUMENT: Blocking issues with ⚠️ emoji
  LIMIT: 3 attempts before marking as blocked
</instructions>

</step>

<step number="8" name="quality_assurance_verification">

### Step 8: Quality Assurance Verification

<step_metadata>
  <runs>comprehensive quality checks</runs>
  <ensures>no regressions or quality issues</ensures>
  <blocks>execution if any checks fail</blocks>
</step_metadata>

<quality_checks>
  <linting_and_typing>
    <required>true</required>
    <javascript_typescript>
      <check>ESLint (if config exists)</check>
      <check>Prettier (if config exists)</check>
      <check>TypeScript compiler (if tsconfig.json exists)</check>
      <requirement>zero errors, zero warnings</requirement>
    </javascript_typescript>
    <python>
      <check>Ruff linting (if config exists)</check>
      <check>Type checking with mypy (if configured)</check>
      <requirement>zero errors, zero warnings</requirement>
    </python>
    <failure_action>STOP - fix all linting/typing issues before proceeding</failure_action>
  </linting_and_typing>
  
  <test_execution>
    <order>
      1. Verify new tests pass
      2. Run entire test suite  
      3. Run web UI tests (if web project)
    </order>
    <requirement>100% pass rate - NO EXCEPTIONS</requirement>
    <failure_action>STOP - all tests MUST pass before proceeding</failure_action>
  </test_execution>
  
  <web_ui_testing>
    <detection>
      <check>package.json contains React, Next.js, Vue, or Angular</check>
      <check>project has frontend components</check>
    </detection>
    <if_web_project>
      <playwright_check>
        <check>Does project have Playwright config?</check>
        <if_exists>run Playwright tests automatically</if_exists>
        <if_missing>prompt user about adding Playwright tests</if_missing>
      </playwright_check>
      <user_prompt>
        🎭 **Web UI Testing Detected**
        
        This appears to be a web frontend project. For comprehensive testing:
        
        **Playwright tests**: [FOUND/NOT_FOUND]
        
        [IF_NOT_FOUND]
        Should I help you set up Playwright tests for this UI work? 
        This ensures your frontend changes work correctly in browsers.
        
        Options:
        1. **yes** - Set up Playwright tests now
        2. **skip** - Continue without UI tests (not recommended)  
        3. **later** - Remind me to add Playwright tests in summary
        
        [IF_FOUND]  
        Running existing Playwright tests...
      </user_prompt>
    </if_web_project>
  </web_ui_testing>
</quality_checks>

<failure_handling>
  <critical_blocking>
    - Any test failures
    - Any linting errors
    - Any TypeScript errors
    - Any Playwright test failures (if running)
  </critical_blocking>
  <action>troubleshoot and fix immediately</action>
  <priority>MUST be resolved before proceeding to commits</priority>
  <no_exceptions>Never proceed with failing quality checks</no_exceptions>
</failure_handling>

<instructions>
  ACTION: Run all quality checks systematically
  REQUIRE: Perfect pass rate on all enabled checks
  BLOCK: Absolutely no proceeding with any failures
  DETECT: Web projects and offer Playwright setup
  FIX: All issues before moving to git workflow
</instructions>

</step>

<step number="9" name="git_workflow">

### Step 9: Git Workflow

<step_metadata>
  <creates>
    - git commit
    - github push
    - pull request
  </creates>
  <requires>issue number from step 1</requires>
</step_metadata>

<commit_process>
  <commit>
    <message>descriptive summary of changes with issue reference</message>
    <format>conventional commits with issue number</format>
    <examples>
      - feat: implement user authentication #123
      - fix: resolve login validation bug #123
      - test: add auth integration tests #123
    </examples>
    <requirement>every commit must reference the GitHub issue</requirement>
  </commit>
  <push>
    <target>spec branch</target>
    <remote>origin</remote>
  </push>
  <pull_request>
    <title>descriptive PR title</title>
    <description>functionality recap with issue link</description>
    <issue_link>must include "Fixes #123" or "Closes #123"</issue_link>
  </pull_request>
</commit_process>

<pr_template>
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
</pr_template>

<instructions>
  ACTION: Commit all changes with descriptive message and issue reference
  REQUIRE: Issue number in every commit message
  PUSH: To GitHub on spec branch
  CREATE: Pull request with issue link and status tracking
</instructions>

</step>

<step number="10" name="roadmap_progress_check">

### Step 10: Roadmap Progress Check

<step_metadata>
  <checks>@.agent-os/product/roadmap.md</checks>
  <updates>if spec completes roadmap item</updates>
</step_metadata>

<roadmap_criteria>
  <update_when>
    - spec fully implements roadmap feature
    - all related tasks completed
    - tests passing
  </update_when>
  <caution>only mark complete if absolutely certain</caution>
</roadmap_criteria>

<instructions>
  ACTION: Review roadmap.md for related items
  EVALUATE: If current spec completes roadmap goals
  UPDATE: Mark roadmap items complete if applicable
  VERIFY: Certainty before marking complete
</instructions>

</step>

<step number="11" name="completion_notification">

### Step 11: Task Completion Notification

<step_metadata>
  <plays>system sound</plays>
  <alerts>user of completion</alerts>
</step_metadata>

<notification_command>
  afplay /System/Library/Sounds/Glass.aiff
</notification_command>

<instructions>
  ACTION: Play completion sound
  PURPOSE: Alert user that task is complete
</instructions>

</step>

<step number="12" name="completion_summary">

### Step 12: Completion Summary

<step_metadata>
  <creates>summary message</creates>
  <format>structured with emojis</format>
  <includes>issue and PR links</includes>
</step_metadata>

<summary_template>
  ## ✅ What's been done

  1. **[FEATURE_1]** - [ONE_SENTENCE_DESCRIPTION]
  2. **[FEATURE_2]** - [ONE_SENTENCE_DESCRIPTION]

  ## ⚠️ Issues encountered

  [ONLY_IF_APPLICABLE]
  - **[ISSUE_1]** - [DESCRIPTION_AND_REASON]

  ## 👀 Ready to test in browser

  [ONLY_IF_APPLICABLE]
  1. [STEP_1_TO_TEST]
  2. [STEP_2_TO_TEST]

  ## 🎭 UI Testing Status

  [ONLY_IF_WEB_PROJECT]
  - **Playwright tests**: [PASSING/NOT_CONFIGURED/REMINDER_NEEDED]
  - **Browser testing**: [MANUAL_STEPS_IF_NO_PLAYWRIGHT]
  
  [IF_PLAYWRIGHT_REMINDER_NEEDED]
  💡 **Reminder**: Consider adding Playwright tests for more reliable UI testing

  ## ✅ Quality Checks

  - **Linting**: [PASSED/NOT_APPLICABLE] 
  - **TypeScript**: [PASSED/NOT_APPLICABLE]
  - **Unit Tests**: [X/Y passed]
  - **Playwright Tests**: [PASSED/NOT_APPLICABLE]

  ## 📦 Pull Request

  View PR: [GITHUB_PR_URL]
  
  ## 🔗 Issue Tracking

  - GitHub Issue: #[ISSUE_NUMBER] - [ISSUE_URL]
  - **Remember to update and close the issue when PR is merged**
</summary_template>

<summary_sections>
  <required>
    - functionality recap
    - quality checks status
    - pull request info
  </required>
  <conditional>
    - issues encountered (if any)
    - testing instructions (if testable in browser)
    - UI testing status (if web project)
    - Playwright reminder (if not configured)
  </conditional>
</summary_sections>

<instructions>
  ACTION: Create comprehensive summary
  INCLUDE: All required sections
  ADD: Conditional sections if applicable
  FORMAT: Use emoji headers for scannability
</instructions>

</step>

<step number="13" name="pr_and_issue_cleanup">

### Step 13: PR and Issue Cleanup

<step_metadata>
  <purpose>encourage proper cleanup of PRs and issues</purpose>
  <requires>user approval before executing</requires>
</step_metadata>

<cleanup_assessment>
  <check_pr_status>
    <verify>PR is mergeable</verify>
    <verify>all checks passing</verify>
    <verify>no conflicts</verify>
  </check_pr_status>
  <identify_linked_issues>
    <extract>issue numbers from PR description</extract>
    <verify>issues are ready to close</verify>
  </identify_linked_issues>
</cleanup_assessment>

<cleanup_proposal>
  ## Cleanup Time! 🧹

  Your PR is ready and all tests are passing. Following our best practices:

  **I recommend merging and cleaning up now to keep the workspace tidy:**
  - ✅ Merge PR #[PR_NUMBER]: [PR_TITLE]
  - ✅ Auto-close linked issue #[ISSUE_NUMBER]
  - ✅ Delete feature branch: [BRANCH_NAME]
  - ✅ Return to main branch
  - ✅ Pull latest changes
  - ✅ Verify clean workspace state

  **May I proceed with this cleanup? (yes/no)**

  ⚠️ *Skipping cleanup now means you'll need to handle it manually before starting new work.*
</cleanup_proposal>

<user_responses>
  <if_yes>
    PROCEED: Execute all cleanup actions
    CONTINUE: To Step 14 (Workspace Reset)
  </if_yes>
  <if_no>
    SKIP: Cleanup actions
    WARN: About manual cleanup requirement
    END: With reminder message
  </if_no>
</user_responses>

<instructions>
  ACTION: Assess PR and issue status
  PROPOSE: Complete cleanup with specific actions
  REQUEST: User approval before proceeding
  ENCOURAGE: Following best practices
</instructions>

</step>

<step number="14" name="workspace_reset">

### Step 14: Workspace Reset

<step_metadata>
  <executes>only if user approved Step 13</executes>
  <ensures>clean workspace for next work</ensures>
</step_metadata>

<cleanup_execution>
  <merge_pr>
    <command>gh pr merge [PR_NUMBER] --merge --delete-branch</command>
    <verify>merge successful</verify>
  </merge_pr>
  <close_issues>
    <auto_close>linked issues via "Fixes #123" in PR</auto_close>
    <verify>issues properly closed</verify>
  </close_issues>
  <branch_cleanup>
    <switch>git checkout main</switch>
    <pull>git pull origin main</pull>
    <verify>up to date with remote</verify>
  </branch_cleanup>
  <final_verification>
    <git_status>must be clean</git_status>
    <no_open_prs>from this work</no_open_prs>
    <issues_closed>related to this work</issues_closed>
  </final_verification>
</cleanup_execution>

<completion_messages>
  <if_success>
    ✅ **Cleanup Complete!**
    
    - PR merged successfully
    - Issues closed automatically  
    - Feature branch deleted
    - Workspace is clean and ready for next work!
    
    🚀 **Ready to start your next feature!**
  </if_success>
  <if_skipped>
    ⚠️ **Cleanup Skipped**
    
    Remember to complete these manually before starting new work:
    - Merge PR #[PR_NUMBER]
    - Close issue #[ISSUE_NUMBER] 
    - Clean up feature branch
    - Return to main branch
    
    💡 **Next time, let me handle the cleanup for you!**
  </if_skipped>
</completion_messages>

<instructions>
  ACTION: Execute approved cleanup systematically
  VERIFY: Each step completes successfully
  CONFIRM: Final workspace is completely clean
  MESSAGE: Clear status and next steps
</instructions>

</step>

</process_flow>

## Development Standards

<standards>
  <code_style>
    <follow>@.agent-os/product/code-style.md</follow>
    <enforce>strictly</enforce>
  </code_style>
  <best_practices>
    <follow>@.agent-os/product/dev-best-practices.md</follow>
    <apply>all directives</apply>
  </best_practices>
  <testing>
    <coverage>comprehensive</coverage>
    <approach>test-driven development</approach>
  </testing>
  <documentation>
    <commits>clear and descriptive</commits>
    <pull_requests>detailed descriptions</pull_requests>
  </documentation>
</standards>

## Error Handling

<error_protocols>
  <blocking_issues>
    - document in tasks.md
    - mark with ⚠️ emoji
    - include in summary
  </blocking_issues>
  <quality_failures>
    - fix before proceeding
    - never commit broken tests
    - never commit linting errors
    - never commit TypeScript errors
    - never commit failing Playwright tests
  </quality_failures>
  <technical_roadblocks>
    - attempt 3 approaches
    - document if unresolved
    - seek user input
  </technical_roadblocks>
</error_protocols>

<final_checklist>
  <verify>
    - [ ] Workspace hygiene verified (Step 0)
    - [ ] Task implementation complete
    - [ ] All quality checks passed (Step 8):
      - [ ] Linting: zero errors/warnings
      - [ ] TypeScript: zero errors (if applicable)
      - [ ] Unit tests: 100% passing
      - [ ] Playwright tests: passed (if web project)
    - [ ] tasks.md updated
    - [ ] Code committed and pushed
    - [ ] Pull request created
    - [ ] Roadmap checked/updated
    - [ ] Summary provided to user
    - [ ] Cleanup proposed and executed (Steps 13-14)
    - [ ] Workspace reset to clean state
  </verify>
</final_checklist>
