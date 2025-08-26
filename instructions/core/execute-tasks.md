---
description: Execute spec tasks systematically with Agent OS workflow
allowed-tools: [Bash, Read, Write, Edit, MultiEdit, Glob, Grep, Task, TodoWrite]
argument-hint: [task-number] or next
version: 2.0.0
---

# Pre-Flight

<pre_flight_check>
  EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md
</pre_flight_check>

# Phase 0: Repository Discovery Gate (BLOCKING)

> Be a senior developer: investigate before building. This phase is mandatory and blocks planning/implementation until completed with evidence.

<discovery_gate>
  <rules>
    - STOP. Do not write analysis, specs, or suggestions yet
    - Reply ONLY with findings + code citations/snippets; no opinions
    - Use precise file paths and quote exact lines where possible
  </rules>
  <checklist>
    - README.md: show relevant excerpts that describe current features/deployment
    - docs/: list files present (if any) and quote relevant sections
    - Dependencies: summarize from package.json/requirements.txt/pyproject
    - Backend routes/endpoints: list existing endpoints (show file and excerpt)
    - Frontend components/pages: list key components (paths) that exist
    - Database schema/migrations: show existing models/migrations snippets
    - Tests: list any test files and their status (or state "Not found")
    - Deployment configs: Dockerfile/docker-compose/start scripts if present
    - Active issue: quote the EXACT requirements from the issue body
    - Verification scripts: list any `check_*`, `status_*`, `monitor_*` scripts (if found) and run them; paste exact command and full output; for any logs referenced, show `ls -la` timestamps to prove recency
  </checklist>
  <evidence_requirements>
    - Provide code excerpts with file paths (method signatures, route decorators, schema definitions)
    - For lists, provide directories with brief notes; for claims, show snippets
    - If an item is missing, write "Not found" (do NOT assume)
    - For any claim about "current" state, show the command you ran and its actual output first (e.g., `ps aux | grep ...`, `ls -la <file>`)
  </evidence_requirements>
  <completion_marker>
    - Output must end with: DISCOVERY_COMPLETE: yes
  </completion_marker>
  <block>If DISCOVERY_COMPLETE marker or required evidence is missing, DO NOT proceed to Phase 1</block>
</discovery_gate>

# Phase 0.5: Transparent Work Session Detection (AUTO-START)

> Automatically detect proper workflow conditions and enable transparent commit batching

<session_detection>
  <purpose>Enable transparent work session batching when proper Agent OS workflow detected</purpose>
  <conditions>
    - Git workspace is clean (no uncommitted changes)
    - Active spec exists in .agent-os/specs/ with tasks.md
    - GitHub issue reference found in spec folder or environment
  </conditions>
  <validation>
    Execute workflow validator to check conditions:
    !~/.agent-os/scripts/workflow-validator.sh check-with-override
  </validation>
  <auto_start_logic>
    IF all conditions met:
      - Print: "✅ Workflow conditions met - enabling transparent work session batching"
      - Start work session: ~/.agent-os/scripts/work-session-manager.sh start "Auto-started for execute-tasks workflow"
      - Set environment: export AGENT_OS_WORK_SESSION=true
      - Continue to Phase 1 with transparent batching enabled
    ELSE:
      - Print helpful guidance from validator output
      - Check for override: if AGENT_OS_FORCE_SESSION=true, start session anyway
      - Otherwise block execution until conditions met
  </auto_start_logic>
  <transparency>
    Session management should be invisible to user unless they request details
  </transparency>
</session_detection>

# Task Execution Rules

> Lightweight orchestrator using Claude Code best practices
> Executes Agent OS workflows through dynamic bash scripts and modular imports

## Overview

Execute spec tasks systematically following the Agent OS TDD workflow with comprehensive quality assurance and git integration.

**Prerequisites:**
- Spec documentation exists in @.agent-os/specs/
- Tasks defined in spec's tasks.md  
- Development environment configured
- Git repository initialized

## Dynamic Workflow Execution

### Phase 1: Hygiene and Setup (runs only after Phase 0 discovery complete)

Execute workspace validation and project context loading:

!~/.agent-os/scripts/workspace-hygiene-check.sh
!~/.agent-os/scripts/project-context-loader.sh  
!~/.agent-os/scripts/task-validator.sh

**Import detailed workflow steps:**
@~/.agent-os/workflow-modules/step-1-hygiene-and-setup.md

### Phase 1.5: Deep Reality Check (Dev/Test/Prod)

<deep_reality_check>
  <instructions>
    - Build a table for Dev / Test / Prod with columns:
      - Config sources consulted (files/env)
      - Effective DB URL/driver (mask credentials)
      - Fallbacks/defaults detected
      - Migrations head vs current
      - Where/how connections are created (file:line)
    - Paste quoted file excerpts with file:line ranges for each row (evidence before conclusions)
    - You may run `/update-documentation --deep --dry-run` to aid discovery, but you must still paste the table and citations
  </instructions>
  <block>
    - Block only on contradictions (e.g., claims of PostgreSQL while only SQLite signals exist) or missing citations for conclusions
    - If sources do not exist yet for a new project, record "Not applicable" and proceed
  </block>
</deep_reality_check>

### Phase 2: Planning and Implementation

**Import planning and execution workflow:**
@~/.agent-os/workflow-modules/step-2-planning-and-execution.md

**Senior Developer Guardrails:**
- Do not propose new work that duplicates existing implementation discovered in Phase 0
- Map each planned step to findings: ✅ already implemented (reference), ⚠️ extend/modify (reference), ❌ new
- If conflicts arise between plan and findings, revise plan to align with reality

**Task Assignment Logic:**
- User specifies exact task(s) OR find next uncompleted parent task
- Read spec documentation for complete context
- Create detailed implementation plan and get user approval
- Execute following TDD approach with coding standards

#### Per-Task Delegation

LOAD @~/.agent-os/instructions/core/execute-task.md ONCE

FOR each selected parent task:
  EXECUTE @~/.agent-os/instructions/core/execute-task.md with:
    - parent_task_number
    - all associated subtasks
  UPDATE tasks.md status
END FOR

### Phase 3: Quality Assurance  

**Import quality assurance workflow:**
@~/.agent-os/workflow-modules/step-3-quality-assurance.md

**MANDATORY Quality Gates:**
- Update task status accurately (no false completion claims)
- Pass ALL linting and typing checks (zero tolerance)
- Achieve 100% test pass rate (unit, integration, Playwright)
- Complete functionality validation (browser/API testing)
- **CRITICAL:** Quality passing ≠ completion (must proceed to git integration)

**Resolution Mandate:**
- For every identified failure, follow this loop until green:
  1) Show exact error/log output
  2) Apply fix
  3) Re-run the command/tests and paste actual passing output
  4) Only then proceed to the next failure
- Do not summarize what you "would" do; show evidence that it works now

### Phase 4: Git Integration and Completion

**Import git workflow and completion:**
@~/.agent-os/workflow-modules/step-4-git-integration.md

**Full Integration Workflow (MANDATORY):**
- Commit with proper message and issue reference
- Create pull request with comprehensive description
- Update roadmap if applicable  
- Execute autonomous merge preparation with subagent validation
- Complete workspace cleanup and branch management

**Evidence Requirements for Completion:**
- PR description must include an Evidence/Test Results/Verification section with real outputs (tests, curl, screenshots) per repo guard
- Link to code citations for implemented changes
 - Include a "Verification Scripts" subsection listing any `check_*`/`status_*` scripts run with their outputs and relevant timestamps for any logs referenced
 - Include a "Documentation Updates" subsection, and if requested, paste output from `/update-documentation --deep --dry-run`

<evidence_only_fallback>
  If the assistant is corrected twice in this PR for making claims without evidence, switch to Evidence‑Only Mode:
  - Paste commands and outputs only; no analysis until the user confirms
  - Completion remains blocked until evidence sections are present
</evidence_only_fallback>

## Execution Standards

**Code Style:** Follow @.agent-os/product/code-style.md
**Best Practices:** Follow @.agent-os/product/dev-best-practices.md  
**Testing:** Comprehensive TDD approach
**Git Workflow:** Professional development with issue tracking

## Error Handling

**Blocking Issues:** Document with ⚠️ emoji in tasks.md
**Quality Failures:** Fix before proceeding (never commit broken code)
**Validation Failures:** Complete functionality proof required
**Workflow Abandonment:** NOT ALLOWED - must complete Steps 9-14

## Completion Definition

**❌ Incomplete:** Code works and tests pass (technical-only)
**✅ Complete:** Code works + committed + PR created + workspace clean + issues closed

**ENFORCEMENT:** Cannot claim completion without full git integration workflow execution.

---

*This orchestrator follows Claude Code best practices using bash execution (`!`) and file imports (`@`) to maintain performance while preserving comprehensive Agent OS workflow capabilities.*