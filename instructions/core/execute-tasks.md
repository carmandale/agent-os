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

### Phase 1: Hygiene and Setup

Execute workspace validation and project context loading:

!~/.agent-os/scripts/workspace-hygiene-check.sh
!~/.agent-os/scripts/project-context-loader.sh  
!~/.agent-os/scripts/task-validator.sh

**Import detailed workflow steps:**
@~/.agent-os/workflow-modules/step-1-hygiene-and-setup.md

### Phase 2: Planning and Implementation

**Import planning and execution workflow:**
@~/.agent-os/workflow-modules/step-2-planning-and-execution.md

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

### Phase 4: Git Integration and Completion

**Import git workflow and completion:**
@~/.agent-os/workflow-modules/step-4-git-integration.md

**Full Integration Workflow (MANDATORY):**
- Commit with proper message and issue reference
- Create pull request with comprehensive description
- Update roadmap if applicable  
- Execute autonomous merge preparation with subagent validation
- Complete workspace cleanup and branch management

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