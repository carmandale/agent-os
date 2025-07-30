# Spec Requirements Document

> Spec: Hook Deadlock Resolution
> Created: 2025-07-30
> GitHub Issue: #10
> Status: Planning

## Overview

Resolve the deadlock situation where Claude cannot help users debug issues when the workspace has uncommitted changes, by implementing intelligent hook behavior and clear workflow guidance.

## User Stories

### Debugging with Dirty Workspace

As a developer using Agent OS, I want Claude to help me debug issues even when I have uncommitted changes, so that I don't get stuck in a deadlock where I can't debug without committing and can't commit without understanding the issue.

When I report a problem like "authentication doesn't work" while having uncommitted changes, Claude should guide me through a clear process: first understanding what changes exist, then either committing, stashing, or working around them to debug the actual issue.

### Clear Workflow Recovery

As a developer experiencing hook blocks, I want clear and actionable guidance on how to proceed, so that I don't see Claude repeatedly trying the same blocked operations.

When hooks block an operation, the message should clearly explain what operations ARE allowed and provide a specific sequence of steps to resolve the situation.

## Spec Scope

1. **Intelligent Hook Behavior** - Allow read-only operations during dirty workspace state
2. **Enhanced Error Messages** - Provide clear, actionable guidance with allowed operations highlighted
3. **Workflow Recovery Module** - Add explicit dirty workspace resolution workflow
4. **Debug Mode Support** - Enable temporary read-only mode for investigation
5. **Claude Instruction Updates** - Ensure Claude understands the hook behavior

## Out of Scope

- Complete hook system rewrite
- Changing the fundamental git-first workflow philosophy
- Automatic commit or stash operations without user consent
- Bypassing security or quality checks

## Expected Deliverable

1. Users can get debugging help even with uncommitted changes
2. Claude provides clear guidance instead of hitting the same blocks repeatedly
3. No more deadlock situations where debugging is impossible

## Spec Documentation

- Tasks: @.agent-os/specs/2025-07-30-hook-deadlock-resolution-#10/tasks.md
- Technical Specification: @.agent-os/specs/2025-07-30-hook-deadlock-resolution-#10/sub-specs/technical-spec.md
- Tests Specification: @.agent-os/specs/2025-07-30-hook-deadlock-resolution-#10/sub-specs/tests.md