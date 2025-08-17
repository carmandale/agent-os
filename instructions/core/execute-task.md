---
description: Rules to execute a single parent task (and its subtasks) with strict subagent enforcement
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# Task Execution Rules (Single Task)

<ai_meta>
  <enforcement>
    - For any <step> that declares subagent="...", the specified subagent MUST be invoked to perform that step
    - Generic tool use is NOT permitted for those steps
    - Validator: fail if a required subagent step is executed without its subagent
  </enforcement>
  <parsing_rules>
    - Process XML blocks first for structured data
    - Execute instructions in sequential order
    - Use templates as exact patterns
  </parsing_rules>
  <file_conventions>
    - encoding: UTF-8
    - line_endings: LF
    - indent: 2 spaces
    - markdown_headers: no indentation
  </file_conventions>
</ai_meta>

<pre_flight_check>
  EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md
</pre_flight_check>

<process_flow>

<step number="1" subagent="context-fetcher" name="task_understanding">

### Step 1: Task Understanding

Read and analyze the given parent task and all its subtasks from tasks.md to gain complete understanding of what needs to be built.

<task_analysis>
  <read_from_tasks_md>
    - Parent task description
    - All sub-task descriptions
    - Task dependencies
    - Expected outcomes
  </read_from_tasks_md>
</task_analysis>

<instructions>
  SUBAGENT: Use context-fetcher to extract only the relevant sections from tasks.md
  ACTION: Summarize scope, dependencies, and expected deliverables
</instructions>

</step>

<step number="2" subagent="context-fetcher" name="technical_spec_review">

### Step 2: Technical Specification Review

Search and extract relevant sections from technical-spec.md to understand the technical implementation approach for this task.

<selective_reading>
  <search_technical_spec>
    FIND sections related to:
    - Current task functionality
    - Implementation approach for this feature
    - Integration requirements
    - Performance criteria
  </search_technical_spec>
</selective_reading>

<instructions>
  SUBAGENT: Use context-fetcher to return only task-relevant excerpts
</instructions>

</step>

<step number="3" subagent="context-fetcher" name="best_practices_review">

### Step 3: Best Practices Review

Use context-fetcher to retrieve relevant sections from @~/.agent-os/standards/best-practices.md that apply to the current task.

<instructions>
  SUBAGENT: Use context-fetcher
  REQUEST: "Find best practices relevant to this task's stack and feature type"
</instructions>

</step>

<step number="4" subagent="context-fetcher" name="code_style_review">

### Step 4: Code Style Review

Use context-fetcher to retrieve code style rules from @~/.agent-os/standards/code-style.md for the languages and file types being used.

<instructions>
  SUBAGENT: Use context-fetcher
  REQUEST: "Find style rules for languages and files used in this task"
</instructions>

</step>

<step number="5" name="implementation_tdd">

### Step 5: Implement via TDD

Execute the parent task and all subtasks using a test-driven approach.

<typical_task_structure>
  <first_subtask>Write tests for [feature]</first_subtask>
  <middle_subtasks>Implementation steps</middle_subtasks>
  <final_subtask>Verify all tests pass</final_subtask>
</typical_task_structure>

<instructions>
  ACTION: Implement subtasks in order, keeping tests green
  UPDATE: Mark each subtask complete as finished
</instructions>

</step>

<step number="6" subagent="test-runner" name="task_test_verification">

### Step 6: Task-Specific Test Verification

Use test-runner to run and verify only the tests specific to this parent task to ensure the feature is working correctly.

<focused_test_execution>
  <run_only>
    - All new tests for this task
    - All tests updated during this task
  </run_only>
  <skip>
    - Full test suite (covered by orchestrator)
  </skip>
</focused_test_execution>

<instructions>
  SUBAGENT: Use test-runner
  REQUIREMENT: 100% pass rate for task-specific tests
</instructions>

</step>

<step number="7" name="task_status_updates">

### Step 7: Task Status Updates

Update tasks.md immediately after completing the task.

<update_format>
  <completed>- [x] Task description</completed>
  <blocked>
    - [ ] Task description
    ⚠️ Blocking issue: [DESCRIPTION]
  </blocked>
</update_format>

<instructions>
  ACTION: Update tasks.md status blocks accurately
  LIMIT: Maximum 3 attempts before marking as blocked
</instructions>

</step>

<step number="8" name="documentation_sync">

### Step 8: Documentation Sync (Read-only by default)

Run the core slash command to surface evidence-backed documentation updates.

<instructions>
  ACTION: `/update-documentation --dry-run`
  RESULT: Show proposed doc updates based on real diffs (no fabrication)
  OPTION: If user approves and evidence exists, rerun with `--create-missing` to scaffold required docs
  NOTE: Do not write without explicit approval
  EVIDENCE: Include output in PR under "Documentation Updates"
  </instructions>

</step>

<conditional_steps>
  <security_review subagent="security-threat-analyst">
    <trigger>auth, user data, input handling</trigger>
  </security_review>
  <performance_review subagent="performance-optimizer">
    <trigger>performance-critical paths</trigger>
  </performance_review>
  <quick_fix_gate>
    <policy>No‑Quick‑Fixes: roadmap/spec‑first, no hidden fallbacks</policy>
    <if_shortcut_proposed>
      <require>
        - explicit_user_approval_phrase
        - scope_and_timebox
        - rollback_plan_and_tracking_issue
        - tests_that_expose_limitation
      </require>
    </if_shortcut_proposed>
  </quick_fix_gate>
</conditional_steps>

</process_flow>

## Final Check

<final_checklist>
  <verify>
    - [ ] All task-specific tests pass (test-runner)
    - [ ] tasks.md updated
    - [ ] Blocking issues documented (if any)
  </verify>
</final_checklist>


