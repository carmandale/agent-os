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

<step number="1.2" name="project_memory_refresh">

### Step 1.2: Project Memory Refresh

<step_metadata>
  <purpose>prevent claude code amnesia about project configuration</purpose>
  <priority>critical</priority>
  <blocks>execution if project context cannot be loaded</blocks>
</step_metadata>

<memory_refresh_process>
  <required_files_check>
    <tech_stack>
      <file>@.agent-os/product/tech-stack.md</file>
      <purpose>package managers, ports, startup commands</purpose>
      <critical_sections>
        - Package Managers section
        - Development Environment section  
        - Startup Commands section
        - Environment Files section
      </critical_sections>
    </tech_stack>
    <mission>
      <file>@.agent-os/product/mission.md</file>
      <purpose>project goals and context</purpose>
    </mission>
    <environment_files>
      <frontend_env>.env.local</frontend_env>
      <backend_env>.env</backend_env>
      <purpose>port configuration and API URLs</purpose>
    </environment_files>
    <startup_script>
      <file>./start.sh</file>
      <purpose>how to start development servers</purpose>
    </startup_script>
  </required_files_check>
</memory_refresh_process>

<memory_refresh_prompt>
  🧠 **Project Memory Refresh**
  
  Before proceeding with any work, I'm refreshing my memory about this project:
  
  **Tech Stack**: [PACKAGE_MANAGERS_FROM_TECH_STACK]
  **Ports**: Frontend [FRONTEND_PORT], Backend [BACKEND_PORT]
  **Startup**: [STARTUP_METHOD_FROM_START_SH_OR_TECH_STACK]
  **Project Type**: [PROJECT_STRUCTURE_FROM_TECH_STACK]
  **Testing**: [E2E_TOOL_FROM_TECH_STACK]
  
  ✅ **Memory refreshed - I will maintain consistency with these settings**
</memory_refresh_prompt>

<amnesia_prevention_checks>
  <package_manager_verification>
    <python_check>
      <if_tech_stack_says_uv>NEVER use pip or create new venv</if_tech_stack_says_uv>
      <if_tech_stack_says_pip>NEVER use uv</if_tech_stack_says_pip>
      <always_check>requirements.txt vs pyproject.toml</always_check>
    </python_check>
    <javascript_check>
      <if_yarn_lock_exists>ALWAYS use yarn</if_yarn_lock_exists>
      <if_package_lock_exists>ALWAYS use npm</if_package_lock_exists>
      <never_mix>package managers within same project</never_mix>
    </javascript_check>
  </package_manager_verification>
  
  <port_consistency_check>
    <env_files_check>
      <frontend>verify .env.local has correct PORT</frontend>
      <backend>verify .env has correct API_PORT</backend>
    </env_files_check>
    <startup_scripts_check>
      <verify>start.sh reads ports from .env files</verify>
    </startup_scripts_check>
  </port_consistency_check>
  
  <project_structure_awareness>
    <monorepo_check>
      <if_monorepo>expect frontend/ and backend/ directories</if_monorepo>
      <if_separate>expect different repo structure</if_separate>
    </monorepo_check>
    <testing_awareness>
      <if_playwright_configured>expect playwright.config.js</if_playwright_configured>
      <if_no_e2e>remember to suggest Playwright setup</if_no_e2e>
    </testing_awareness>
  </project_structure_awareness>
</amnesia_prevention_checks>

<missing_files_handling>
  <if_tech_stack_missing>
    ERROR: "Cannot proceed without tech-stack.md. Run /plan-product first."
    STOP: Execution until project is properly initialized
  </if_tech_stack_missing>
  <if_env_files_missing>
    WARNING: "Environment files missing. Will create them during implementation."
    CONTINUE: But flag for creation
  </if_env_files_missing>
  <if_startup_script_missing>
    WARNING: "Startup script missing. Will create start.sh during implementation."
    CONTINUE: But flag for creation
  </if_startup_script_missing>
</missing_files_handling>

<instructions>
  ACTION: Read and internalize all project context files
  VERIFY: Package managers, ports, and startup commands
  PREVENT: Amnesia about fundamental project decisions
  BLOCK: Work if critical project context is missing
  MAINTAIN: Absolute consistency with documented choices
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
  <implemented_not_validated>
    - [ ] Task description
    🔍 Awaiting validation: [DESCRIPTION]
  </implemented_not_validated>
</update_format>

<completion_requirements>
  <never_mark_complete_without>
    - Frontend work: Browser validation complete
    - Backend work: API testing complete
    - Both: Functionality proven working
    - All: Step 8.5 validation passed
  </never_mark_complete_without>
  
  <validation_pending_status>
    <when>implementation done but validation not performed</when>
    <status>🔍 Awaiting validation</status>
    <action>proceed to Step 8.5 for validation</action>
  </validation_pending_status>
</completion_requirements>

<blocking_criteria>
  <attempts>maximum 3 different approaches</attempts>
  <action>document blocking issue</action>
  <emoji>⚠️</emoji>
  <validation_required>NEVER mark [x] without validation proof</validation_required>
</blocking_criteria>

<instructions>
  ACTION: Update tasks.md with accurate implementation status
  MARK: [x] ONLY after Step 8.5 validation proves functionality
  INTERMEDIATE: Use 🔍 Awaiting validation for implemented but unvalidated work
  DOCUMENT: Blocking issues with ⚠️ emoji
  PREVENT: False completion claims without proof
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
      <check>tech-stack.md mentions frontend framework</check>
    </detection>
    <if_web_project>
      <playwright_check>
        <check>Does project have Playwright config?</check>
        <if_exists>run Playwright tests automatically</if_exists>
        <if_missing>MANDATORY setup required for web projects</if_missing>
      </playwright_check>
      <user_prompt>
        🎭 **Web UI Testing Required**
        
        ⚠️ **This is a web frontend project - Playwright E2E testing is MANDATORY**
        
        **Playwright tests**: [FOUND/NOT_FOUND]
        
        [IF_NOT_FOUND]
        🚨 **Missing Critical Testing**: Web projects MUST have end-to-end testing to prevent UI regressions.
        
        **I will set up Playwright tests now** - this is required for quality assurance.
        
        Playwright setup includes:
        - Install @playwright/test
        - Create playwright.config.js  
        - Create tests/ directory with basic tests
        - Update package.json scripts
        
        [IF_FOUND]  
        ✅ Running existing Playwright tests...
      </user_prompt>
      <mandatory_setup>
        <if_no_playwright>
          <action>automatically set up Playwright</action>
          <no_skip_option>true</no_skip_option>
          <reasoning>web projects without E2E testing are incomplete</reasoning>
        </if_no_playwright>
      </mandatory_setup>
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

<step number="8.5" name="mandatory_functionality_validation">

### Step 8.5: Mandatory Functionality Validation

<step_metadata>
  <purpose>BLOCK completion until functionality is proven working</purpose>
  <priority>CRITICAL - NO EXCEPTIONS</priority>
  <blocks>git workflow until validation complete</blocks>
</step_metadata>

<validation_requirements>
  <frontend_work>
    <if_frontend_changes>
      <mandatory_browser_testing>true</mandatory_browser_testing>
      <playwright_execution>REQUIRED</playwright_execution>
      <manual_verification>REQUIRED if no Playwright</manual_verification>
    </if_frontend_changes>
    <validation_criteria>
      <visual_confirmation>see feature working in browser</visual_confirmation>
      <user_flow_testing>complete user workflows</user_flow_testing>
      <responsive_testing>test on different screen sizes</responsive_testing>
      <error_scenarios>test error conditions</error_scenarios>
    </validation_criteria>
  </frontend_work>
  
  <backend_work>
    <if_backend_changes>
      <api_testing>REQUIRED</api_testing>
      <endpoint_verification>REQUIRED</endpoint_verification>
      <integration_testing>REQUIRED</integration_testing>
    </if_backend_changes>
    <validation_criteria>
      <api_responses>verify correct responses</api_responses>
      <error_handling>test error scenarios</error_handling>
      <database_operations>verify data persistence</database_operations>
      <authentication>test auth flows if applicable</authentication>
    </validation_criteria>
  </backend_work>
</validation_requirements>

<validation_workflow>
  <step_1_detect_work_type>
    <frontend_indicators>
      - React/Vue/Angular components modified
      - CSS/styling changes
      - UI/UX features added
      - Frontend routes added
    </frontend_indicators>
    <backend_indicators>
      - API endpoints modified
      - Database models changed
      - Business logic updated
      - Authentication changes
    </backend_indicators>
  </step_1_detect_work_type>
  
  <step_2_mandatory_testing>
    <if_frontend_work>
      <playwright_validation>
        <requirement>MUST execute Playwright tests that cover new functionality</requirement>
        <if_no_playwright_tests>
          <action>CREATE Playwright tests for new functionality</action>
          <no_skip_allowed>true</no_skip_allowed>
        </if_no_playwright_tests>
        <test_requirements>
          - Navigate to feature in browser
          - Test user interactions (clicks, form inputs, etc.)
          - Verify visual elements appear correctly
          - Test responsive behavior
          - Validate error states
        </test_requirements>
      </playwright_validation>
      <manual_browser_verification>
        <if_playwright_fails>
          <requirement>MANUAL browser testing required</requirement>
          <steps>
            1. Start development servers (./start.sh)
            2. Navigate to feature in browser
            3. Test all user interactions
            4. Verify functionality works as expected
            5. Document any issues found
          </steps>
        </if_playwright_fails>
      </manual_browser_verification>
    </if_frontend_work>
    
    <if_backend_work>
      <api_validation>
        <requirement>MUST test API endpoints directly</requirement>
        <test_methods>
          - curl commands to test endpoints
          - Postman/REST client testing
          - Backend unit tests covering new logic
          - Integration tests if applicable
        </test_methods>
        <validation_steps>
          1. Start backend server
          2. Test all modified endpoints
          3. Verify responses match specifications
          4. Test error scenarios
          5. Validate database changes
        </validation_steps>
      </api_validation>
    </if_backend_work>
  </step_2_mandatory_testing>
  
  <step_3_validation_proof>
    <evidence_required>
      <frontend>
        - Screenshots of working feature
        - Playwright test results showing PASS
        - Confirmation of user flow completion
      </frontend>
      <backend>
        - API response examples
        - Test output showing successful validation
        - Database verification if applicable
      </backend>
    </evidence_required>
  </step_3_validation_proof>
</validation_workflow>

<blocking_criteria>
  <absolute_requirements>
    <no_green_checkmarks>until validation proven</no_green_checkmarks>
    <no_task_completion>until functionality verified</no_task_completion>
    <no_git_commits>until validation complete</no_git_commits>
    <no_pr_creation>until all features tested</no_pr_creation>
  </absolute_requirements>
  
  <failure_scenarios>
    <feature_broken>
      <action>FIX immediately - do not proceed</action>
      <status>mark task as blocked with ⚠️ emoji</status>
    </feature_broken>
    <partial_functionality>
      <action>COMPLETE implementation before validation</action>
      <status>return to development step</status>
    </partial_functionality>
    <validation_impossible>
      <action>CREATE minimal validation test</action>
      <requirement>at least basic functionality check</requirement>
    </validation_impossible>
  </failure_scenarios>
</blocking_criteria>

<validation_checklist>
  <frontend_validation>
    - [ ] Development servers started successfully
    - [ ] Feature accessible in browser at correct URL
    - [ ] All user interactions work as expected
    - [ ] Visual design matches requirements
    - [ ] Responsive behavior verified
    - [ ] Error states tested and working
    - [ ] Playwright tests pass (or created and passing)
    - [ ] No console errors in browser
  </frontend_validation>
  
  <backend_validation>
    - [ ] Backend server started successfully
    - [ ] All modified endpoints respond correctly
    - [ ] Request/response formats match specifications
    - [ ] Authentication working if applicable
    - [ ] Database operations successful
    - [ ] Error handling working correctly
    - [ ] Integration with frontend verified
    - [ ] API tests pass
  </backend_validation>
</validation_checklist>

<completion_requirements>
  <frontend_complete_only_when>
    ✅ User can successfully complete the intended workflow in browser
    ✅ Playwright tests confirm functionality (or manual testing documented)
    ✅ No blocking bugs or errors
    ✅ Feature works as specified in requirements
  </frontend_complete_only_when>
  
  <backend_complete_only_when>
    ✅ API endpoints return correct responses
    ✅ Database operations work correctly
    ✅ Error handling functions properly
    ✅ Integration with frontend confirmed
  </backend_complete_only_when>
</completion_requirements>

<instructions>
  ACTION: Identify work type and execute mandatory validation
  REQUIRE: Proof of working functionality before any completion
  BLOCK: All progress until validation succeeds
  TEST: Every user-facing change in browser/API client
  VERIFY: Complete workflows, not just individual functions
  DOCUMENT: Validation evidence in task updates
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

<step number="13" name="autonomous_preparation_for_merge">

### Step 13: Autonomous Preparation for Merge

<step_metadata>
  <purpose>Complete ALL validation work autonomously before requesting merge approval</purpose>
  <priority>CRITICAL - no shortcuts allowed</priority>
  <execution>fully autonomous until READY TO MERGE</execution>
  <human_approval>required only for final merge decision</human_approval>
</step_metadata>

<autonomous_workflow>
  <phase_1_deep_subagent_analysis>
    <mandatory_subagent_usage>
      <senior_software_engineer_subagent>
        <purpose>COMPREHENSIVE code review, architecture analysis, and implementation validation</purpose>
        <requirement>MANDATORY - cannot proceed without full subagent analysis</requirement>
        <deep_analysis_tasks>
          - Line-by-line code review of ALL changes
          - Architecture pattern validation and recommendations
          - Cross-reference implementation against task requirements
          - Identify security vulnerabilities and performance issues
          - Validate error handling and edge case coverage
          - Assess code maintainability and scalability
          - Compare actual implementation to spec requirements
          - Flag any discrepancies between tasks.md and actual code
        </deep_analysis_tasks>
        <recursive_validation>
          - Re-analyze after any fixes or changes
          - Verify fixes don't introduce new issues
          - Confirm all recommendations are addressed
        </recursive_validation>
      </senior_software_engineer_subagent>
      
      <qa_test_engineer_subagent>
        <purpose>EXHAUSTIVE testing strategy analysis and validation</purpose>
        <requirement>MANDATORY - must validate all testing approaches</requirement>
        <comprehensive_testing_analysis>
          - Analyze test coverage gaps and missing scenarios
          - Validate test quality and effectiveness
          - Design additional tests for edge cases and error conditions
          - Review Playwright test completeness for user workflows
          - Assess integration test coverage
          - Validate mocking strategies and test isolation
          - Compare test coverage to feature requirements
          - Identify untested code paths and business logic
        </comprehensive_testing_analysis>
        <test_execution_validation>
          - Verify all tests actually pass (not just reported as passing)
          - Analyze test output for hidden failures or warnings
          - Validate test reliability and consistency
        </test_execution_validation>
      </qa_test_engineer_subagent>
      
      <code_refactoring_expert_subagent>
        <purpose>DEEP code quality analysis and improvement recommendations</purpose>
        <requirement>MANDATORY - must analyze code quality thoroughly</requirement>
        <quality_analysis_tasks>
          - Identify code smells and technical debt
          - Suggest refactoring opportunities for better maintainability
          - Analyze code complexity and readability
          - Validate naming conventions and code organization
          - Check for duplicate code and missing abstractions
          - Assess adherence to SOLID principles
          - Review error handling patterns
        </quality_analysis_tasks>
      </code_refactoring_expert_subagent>
      
      <task_comparison_subagent>
        <purpose>METICULOUS comparison of implementation against task requirements</purpose>
        <requirement>MANDATORY - validate every task claim against actual code</requirement>
        <comparison_analysis>
          - Read tasks.md line by line
          - Verify each claimed completion against actual codebase
          - Identify tasks marked complete but not actually implemented
          - Find implemented features not reflected in task status
          - Validate that all acceptance criteria are met
          - Cross-check spec requirements against implementation
          - Flag any missing functionality or incomplete features
        </comparison_analysis>
        <recursive_verification>
          - Re-check after any implementation changes
          - Validate task status updates are accurate
          - Ensure no false completion claims
        </recursive_verification>
      </task_comparison_subagent>
    </mandatory_subagent_usage>
  </phase_1_deep_subagent_analysis>

  <phase_2_comprehensive_testing>
    <mandatory_test_execution>
      <unit_tests>
        <requirement>100% pass rate - NO EXCEPTIONS</requirement>
        <action>fix immediately if any failures</action>
      </unit_tests>
      <integration_tests>
        <requirement>all integration points validated</requirement>
        <action>test API endpoints, database operations</action>
      </integration_tests>
      <playwright_tests>
        <requirement>MANDATORY for all frontend work</requirement>
        <action>create tests if missing, ensure all pass</action>
        <validation>must see feature working in browser</validation>
      </playwright_tests>
      <linting_and_typing>
        <requirement>zero errors, zero warnings</requirement>
        <action>fix all issues immediately</action>
      </linting_and_typing>
    </mandatory_test_execution>
  </phase_2_comprehensive_testing>

  <phase_3_functionality_validation>
    <end_to_end_validation>
      <frontend_workflow>
        <requirement>complete user workflows tested</requirement>
        <validation>manual verification in browser if needed</validation>
        <evidence>screenshots or test results required</evidence>
      </frontend_workflow>
      <backend_validation>
        <requirement>API endpoints tested with real requests</requirement>
        <validation>curl commands or API client testing</validation>
        <evidence>response examples documented</evidence>
      </backend_validation>
      <integration_validation>
        <requirement>frontend-backend communication verified</requirement>
        <validation>full stack workflows tested</validation>
      </integration_validation>
    </end_to_end_validation>
  </phase_3_functionality_validation>

  <phase_4_pr_optimization>
    <pr_quality_check>
      <description>clear, detailed PR description</description>
      <linked_issues>proper "Fixes #123" linking</linked_issues>
      <commit_messages>conventional commit format</commit_messages>
      <branch_status>no merge conflicts, up to date</branch_status>
    </pr_quality_check>
    <github_checks>
      <ci_cd>all GitHub Actions passing</ci_cd>
      <security>no security alerts</security>
      <dependencies>no vulnerable dependencies</dependencies>
    </github_checks>
  </phase_4_pr_optimization>
</autonomous_workflow>

<ready_to_merge_validation>
  <comprehensive_checklist>
    <code_quality>
      - [ ] Subagent code review completed ✅
      - [ ] Architecture validated ✅
      - [ ] Coding standards enforced ✅
      - [ ] No code smells or issues ✅
    </code_quality>
    <testing_complete>
      - [ ] Subagent testing review completed ✅
      - [ ] Unit tests: 100% passing ✅
      - [ ] Integration tests: 100% passing ✅
      - [ ] Playwright tests: created and passing ✅
      - [ ] Linting: zero errors/warnings ✅
      - [ ] TypeScript: zero errors ✅
    </testing_complete>
    <functionality_proven>
      - [ ] Frontend: browser validation completed ✅
      - [ ] Backend: API testing completed ✅
      - [ ] End-to-end workflows verified ✅
      - [ ] Evidence documented ✅
    </functionality_proven>
    <pr_ready>
      - [ ] PR description complete ✅
      - [ ] Issues properly linked ✅
      - [ ] No merge conflicts ✅
      - [ ] All GitHub checks passing ✅
    </pr_ready>
  </comprehensive_checklist>
</ready_to_merge_validation>

<blocking_stop_message>
  <when_all_validation_complete>
    <display_message>
🚨🛑 WORKFLOW COMPLETE - MERGE APPROVAL REQUIRED 🛑🚨

╔══════════════════════════════════════════════════════════════╗
║                     READY TO MERGE                          ║
║                                                              ║
║  ✅ Code implemented and validated                          ║
║  ✅ Subagent expert review completed                        ║
║  ✅ All tests passing (unit, integration, Playwright)       ║
║  ✅ Browser validation successful                           ║
║  ✅ API endpoints tested and working                        ║
║  ✅ PR optimized and conflict-free                          ║
║  ✅ GitHub checks passing                                    ║
║  ✅ Issues properly linked                                   ║
║                                                              ║
║  🛑 BLOCKING: Cannot proceed without merge approval         ║
║                                                              ║
║  PR #[PR_NUMBER]: [PR_TITLE]                               ║
║  Fixes: #[ISSUE_NUMBER]                                     ║
║                                                              ║
║  Type "merge" to complete workflow and merge PR            ║
║  Type "review" to see detailed validation results          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
    </display_message>
    <wait_for_approval>true</wait_for_approval>
    <valid_responses>["merge", "review"]</valid_responses>
  </when_all_validation_complete>
</blocking_stop_message>

<approval_responses>
  <if_user_types_merge>
    <action>proceed to Step 14 (Execute Merge)</action>
    <message>🚀 Merge approved! Executing final merge and cleanup...</message>
  </if_user_types_merge>
  <if_user_types_review>
    <action>display detailed validation results</action>
    <return>to blocking stop message</return>
  </if_user_types_review>
  <if_user_says_anything_else>
    <message>🛑 Merge approval required. Type "merge" to proceed or "review" to see validation details.</message>
    <wait>continue waiting for valid response</wait>
  </if_user_says_anything_else>
</approval_responses>

<error_handling>
  <validation_failures>
    <action>FIX immediately and retry validation</action>
    <no_shortcuts>cannot reach STOP message until all validation passes</no_shortcuts>
  </validation_failures>
  <subagent_not_used>
    <action>MANDATORY deep subagent usage - cannot proceed without ALL four subagents</action>
    <required_subagents>
      - senior-software-engineer (code review & architecture)
      - qa-test-engineer (testing strategy & validation)  
      - code-refactoring-expert (quality analysis)
      - general-purpose (task comparison & verification)
    </required_subagents>
    <message>🔴 Must use ALL required subagents for comprehensive validation - no shortcuts allowed</message>
    <enforcement>block progress until all subagent analyses complete</enforcement>
  </subagent_not_used>
  <tests_failing>
    <action>FIX all test failures before proceeding</action>
    <message>🔴 All tests must pass before reaching READY TO MERGE state</message>
  </tests_failing>
</error_handling>

<instructions>
  ACTION: Execute complete autonomous workflow with no shortcuts
  REQUIRE: Use subagents for expert review and testing validation
  VALIDATE: Every aspect of code quality and functionality
  BLOCK: At READY TO MERGE until user approval
  ENSURE: No false "complete" claims - everything must be actually validated
</instructions>

</step>

<step number="14" name="execute_approved_merge">

### Step 14: Execute Approved Merge

<step_metadata>
  <executes>only after user types "merge" in Step 13</executes>
  <purpose>execute the actual merge and complete workflow</purpose>
  <priority>FINAL - completes entire Agent OS workflow</priority>
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
  <success_message>
🎉 **AGENT OS WORKFLOW COMPLETE!** 🎉

✅ **Merge Successful:**
- PR #[PR_NUMBER] merged to main
- Issue #[ISSUE_NUMBER] automatically closed
- Feature branch [BRANCH_NAME] deleted
- Workspace cleaned and reset

✅ **Quality Assurance Completed:**
- Subagent expert review ✅
- Comprehensive testing ✅
- Browser/API validation ✅
- All checks passing ✅

🚀 **Ready for next feature!**
The workspace is clean and ready for your next Agent OS workflow.
  </success_message>
</completion_messages>

<instructions>
  ACTION: Execute approved merge and complete Agent OS workflow
  VERIFY: Merge successful and workspace clean
  CONFIRM: All issues closed and branches cleaned up
  CELEBRATE: Successful completion of full validation workflow
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
    - [ ] Project memory refreshed (Step 1.2)
    - [ ] Task implementation complete
    - [ ] All quality checks passed (Step 8):
      - [ ] Linting: zero errors/warnings
      - [ ] TypeScript: zero errors (if applicable)
      - [ ] Unit tests: 100% passing
      - [ ] Playwright tests: passed (if web project)
    - [ ] MANDATORY functionality validation completed (Step 8.5):
      - [ ] Frontend work: Browser validation completed
      - [ ] Backend work: API testing completed
      - [ ] Evidence of working functionality documented
    - [ ] tasks.md updated with validation proof
    - [ ] Code committed and pushed
    - [ ] Pull request created
    - [ ] Roadmap checked/updated
    - [ ] Summary provided to user
    - [ ] Cleanup proposed and executed (Steps 13-14)
    - [ ] Workspace reset to clean state
  </verify>
</final_checklist>
