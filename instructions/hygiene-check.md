---
description: Workspace Hygiene Check Rules for Agent OS
globs:
alwaysApply: false
version: 1.1.0
lastUpdated: 2025-07-26
encoding: UTF-8
---

# Workspace Hygiene Check Instructions

<ai_meta>
  <parsing_rules>
    - Process XML blocks first for structured data
    - Execute instructions in sequential order
    - Use templates as exact patterns
    - Provide comprehensive status report
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
  - Provide comprehensive workspace status assessment
  - Identify potential issues before they block work
  - Give actionable recommendations for cleanup
  - Verify Agent OS configuration and tools
</purpose>

<context>
  - Standalone hygiene verification command
  - Non-blocking assessment (reports status, doesn't stop execution)
  - Can be run at any time for troubleshooting
  - Complements the blocking hygiene checks in main workflows
</context>

## Hygiene Check Process

<step number="1" name="git_status_assessment">

### Step 1: Git Repository Assessment

<step_metadata>
  <checks>git repository state</checks>
  <reports>working directory status</reports>
</step_metadata>

<git_checks>
  <working_directory>
    <check>git status --porcelain</check>
    <assessment>
      <clean>empty output = clean working directory</clean>
      <dirty>any output = uncommitted changes</dirty>
    </assessment>
  </working_directory>
  <current_branch>
    <check>git branch --show-current</check>
    <assessment>
      <main_branches>main, master, staging, develop</main_branches>
      <feature_branches>feature/*, spec/*, hotfix/*</feature_branches>
    </assessment>
  </current_branch>
  <unpushed_commits>
    <check>git log --oneline @{upstream}..HEAD</check>
    <assessment>commits ahead of remote</assessment>
  </unpushed_commits>
</git_checks>

<git_report_template>
  ## 📂 Git Repository Status
  
  - **Working Directory**: [CLEAN ✅ / DIRTY ⚠️]
  - **Current Branch**: `[BRANCH_NAME]` [APPROPRIATE ✅ / NEEDS_ATTENTION ⚠️]
  - **Unpushed Commits**: [COUNT] commits ahead of remote
  - **Overall Git Status**: [READY ✅ / NEEDS_CLEANUP ⚠️]
  
  [IF_DIRTY]
  ⚠️ **Uncommitted Changes Found:**
  ```
  [GIT_STATUS_OUTPUT]
  ```
  **Recommendation**: Commit or stash changes before starting new work.
  
  [IF_WRONG_BRANCH]
  ⚠️ **Branch Consideration**: Currently on `[BRANCH]`. 
  **Recommendation**: Consider switching to `main` for new work.
</git_report_template>

</step>

<step number="2" name="github_status_assessment">

### Step 2: GitHub Issues & PRs Assessment

<step_metadata>
  <checks>open issues and pull requests</checks>
  <identifies>completed work needing cleanup</identifies>
</step_metadata>

<github_checks>
  <open_prs>
    <check>gh pr list --state open</check>
    <assessment>identify mergeable PRs</assessment>
  </open_prs>
  <open_issues>
    <check>gh issue list --state open</check>
    <assessment>identify completed issues</assessment>
  </open_issues>
  <pr_status>
    <check>gh pr status</check>
    <assessment>current PR context</assessment>
  </pr_status>
</github_checks>

<github_report_template>
  ## 🔗 GitHub Status
  
  - **Open Pull Requests**: [COUNT] ([MERGEABLE_COUNT] ready to merge)
  - **Open Issues**: [COUNT] ([COMPLETED_COUNT] appear completed)
  - **Current PR Context**: [NONE / CURRENT_PR_INFO]
  - **Overall GitHub Status**: [CLEAN ✅ / NEEDS_ATTENTION ⚠️]
  
  [IF_MERGEABLE_PRS]
  ✅ **Ready to Merge:**
  [LIST_OF_MERGEABLE_PRS]
  **Recommendation**: Consider merging completed PRs.
  
  [IF_COMPLETED_ISSUES]
  ✅ **Appear Completed:**
  [LIST_OF_COMPLETED_ISSUES]
  **Recommendation**: Review and close completed issues.
</github_report_template>

</step>

<step number="3" name="agent_os_specs_assessment">

### Step 3: Agent OS Specs Assessment

<step_metadata>
  <checks>existing Agent OS specifications</checks>
  <identifies>incomplete or abandoned specs</identifies>
</step_metadata>

<specs_checks>
  <spec_directories>
    <check>find .agent-os/specs/ -type d -name "*-*-*-*"</check>
    <assessment>existing spec folders</assessment>
  </spec_directories>
  <incomplete_tasks>
    <check>grep -r "- \[ \]" .agent-os/specs/*/tasks.md</check>
    <assessment>uncompleted tasks</assessment>
  </incomplete_tasks>
  <recent_specs>
    <check>most recent spec activity</check>
    <assessment>specs modified in last 7 days</assessment>
  </recent_specs>
</specs_checks>

<specs_report_template>
  ## 📋 Agent OS Specs Status
  
  - **Total Specs**: [COUNT] specifications found
  - **Recent Activity**: [COUNT] specs modified in last 7 days
  - **Incomplete Tasks**: [COUNT] uncompleted tasks across all specs
  - **Overall Specs Status**: [ORGANIZED ✅ / NEEDS_REVIEW ⚠️]
  
  [IF_INCOMPLETE_TASKS]
  📝 **Incomplete Tasks Found:**
  [LIST_BY_SPEC_WITH_TASK_COUNTS]
  **Recommendation**: Review and complete or archive stale specs.
  
  [IF_OLD_SPECS]
  📅 **Stale Specs** (>30 days old with incomplete tasks):
  [LIST_OF_STALE_SPECS]
  **Recommendation**: Consider archiving or updating these specs.
</specs_report_template>

</step>

<step number="4" name="development_tools_assessment">

### Step 4: Development Tools Assessment

<step_metadata>
  <checks>quality assurance tools availability</checks>
  <verifies>linting and testing configuration</verifies>
</step_metadata>

<tools_checks>
  <linting_tools>
    <javascript_typescript>
      <eslint>check for .eslintrc* or eslint.config.*</eslint>
      <prettier>check for .prettierrc* or prettier.config.*</prettier>
      <typescript>check for tsconfig.json</typescript>
    </javascript_typescript>
    <python>
      <ruff>check for ruff.toml or pyproject.toml with [tool.ruff]</ruff>
      <mypy>check for mypy.ini or pyproject.toml with [tool.mypy]</mypy>
    </python>
  </linting_tools>
  <testing_tools>
    <unit_testing>
      <javascript>check for vitest, jest, or test scripts in package.json</javascript>
      <python>check for pytest in dependencies or test directories</python>
    </unit_testing>
    <web_ui_testing>
      <playwright>check for playwright.config.* or @playwright/test</playwright>
      <cypress>check for cypress.config.* or cypress dependencies</cypress>
    </web_ui_testing>
  </testing_tools>
  <environment_config>
    <port_configuration>
      <frontend>check for PORT in .env.local</frontend>
      <backend>check for API_PORT in .env</backend>
    </port_configuration>
    <python_environment>
      <uv>check if uv is available and .venv exists</uv>
      <requirements>check for requirements.txt or pyproject.toml</requirements>
    </python_environment>
  </environment_config>
</tools_checks>

<tools_report_template>
  ## 🔧 Development Tools Status
  
  ### Quality Assurance Tools
  - **ESLint**: [CONFIGURED ✅ / NOT_FOUND ⚠️ / NOT_APPLICABLE ➖]
  - **Prettier**: [CONFIGURED ✅ / NOT_FOUND ⚠️ / NOT_APPLICABLE ➖]
  - **TypeScript**: [CONFIGURED ✅ / NOT_FOUND ⚠️ / NOT_APPLICABLE ➖]
  - **Ruff (Python)**: [CONFIGURED ✅ / NOT_FOUND ⚠️ / NOT_APPLICABLE ➖]
  - **MyPy (Python)**: [CONFIGURED ✅ / NOT_FOUND ⚠️ / NOT_APPLICABLE ➖]
  
  ### Testing Tools
  - **Unit Tests**: [CONFIGURED ✅ / NOT_FOUND ⚠️]
  - **Playwright**: [CONFIGURED ✅ / NOT_FOUND ⚠️ / NOT_APPLICABLE ➖]
  - **Overall Testing**: [READY ✅ / NEEDS_SETUP ⚠️]
  
  ### Environment Configuration
  - **Port Configuration**: [CONFIGURED ✅ / NEEDS_SETUP ⚠️]
  - **Python Environment (uv)**: [READY ✅ / NEEDS_SETUP ⚠️ / NOT_APPLICABLE ➖]
  - **Overall Environment**: [READY ✅ / NEEDS_SETUP ⚠️]
  
  [IF_MISSING_TOOLS]
  🛠️ **Setup Recommendations:**
  [LIST_OF_MISSING_TOOLS_WITH_SETUP_COMMANDS]
</tools_report_template>

</step>

<step number="5" name="comprehensive_summary">

### Step 5: Comprehensive Summary & Recommendations

<step_metadata>
  <creates>overall hygiene score</creates>
  <provides>actionable next steps</provides>
</step_metadata>

<summary_template>
  # 🧹 Workspace Hygiene Report
  
  **Overall Status**: [EXCELLENT ✅ / GOOD ✅ / NEEDS_ATTENTION ⚠️ / CRITICAL ❌]
  **Hygiene Score**: [X/10] 
  
  ## Quick Status
  
  | Category | Status | Score |
  |----------|--------|-------|
  | Git Repository | [ICON] | [X/3] |
  | GitHub Issues/PRs | [ICON] | [X/2] |
  | Agent OS Specs | [ICON] | [X/2] |
  | Development Tools | [ICON] | [X/3] |
  
  ## Priority Actions
  
  [IF_CRITICAL_ISSUES]
  ### 🚨 Critical Issues (Fix Before Any Work)
  1. [CRITICAL_ISSUE_1]
  2. [CRITICAL_ISSUE_2]
  
  [IF_RECOMMENDED_ACTIONS]
  ### 💡 Recommended Improvements
  1. [RECOMMENDATION_1]
  2. [RECOMMENDATION_2]
  
  [IF_EXCELLENT_STATUS]
  ### 🎉 Workspace Status: Excellent!
  Your workspace is clean and ready for productive development. All systems are properly configured and no issues detected.
  
  ## Next Steps
  
  [IF_READY_FOR_WORK]
  ✅ **Ready for Development**
  Your workspace is clean and ready. You can safely:
  - Start new features with `/create-spec`
  - Execute existing tasks with `/execute-tasks`
  - Analyze products with `/analyze-product`
  
  [IF_NEEDS_CLEANUP]
  ⚠️ **Cleanup Required**
  Complete the priority actions above, then run this hygiene check again to verify.
  
  ---
  
  💡 **Tip**: Run `/hygiene-check` anytime to verify your workspace status before starting new work.
</summary_template>

<scoring_system>
  <git_repository>
    <clean_working_directory>1 point</clean_working_directory>
    <appropriate_branch>1 point</appropriate_branch>
    <no_unpushed_commits>1 point</no_unpushed_commits>
  </git_repository>
  <github_status>
    <no_mergeable_prs_waiting>1 point</no_mergeable_prs_waiting>
    <no_completed_issues_open>1 point</no_completed_issues_open>
  </github_status>
  <agent_os_specs>
    <no_stale_specs>1 point</no_stale_specs>
    <organized_task_status>1 point</organized_task_status>
  </agent_os_specs>
  <development_tools>
    <linting_configured>1 point</linting_configured>
    <testing_configured>1 point</testing_configured>
    <environment_configured>1 point</environment_configured>
  </development_tools>
</scoring_system>

<status_thresholds>
  <excellent>9-10 points</excellent>
  <good>7-8 points</good>
  <needs_attention>4-6 points</needs_attention>
  <critical>0-3 points</critical>
</status_thresholds>

</step>

## Execution Instructions

<instructions>
  ACTION: Execute all 5 steps systematically
  REPORT: Comprehensive status for each category
  SCORE: Calculate hygiene score based on findings
  RECOMMEND: Provide specific, actionable next steps
  FORMAT: Use emojis and clear formatting for easy scanning
  TONE: Helpful and encouraging, not judgmental
</instructions>

## Error Handling

<error_protocols>
  <git_not_repository>
    <message>This directory is not a Git repository</message>
    <recommendation>Initialize Git or navigate to project root</recommendation>
  </git_not_repository>
  <github_cli_missing>
    <message>GitHub CLI not available</message>
    <recommendation>Install with: brew install gh</recommendation>
  </github_cli_missing>
  <agent_os_not_found>
    <message>Agent OS not detected in this project</message>
    <recommendation>Run /analyze-product or /plan-product to initialize</recommendation>
  </agent_os_not_found>
</error_protocols> 