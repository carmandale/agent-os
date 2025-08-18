# Spec Requirements Document

> Spec: Project Root Resolver Standardization
> Created: 2025-08-18
> GitHub Issue: #58
> Status: Planning

## Overview

Implement a standardized project root resolution system across all Agent OS hooks and scripts to ensure consistent behavior when working from any subdirectory within a project.

## User Stories

### Reliable Hook Operation from Subdirectories

As a developer using Agent OS with Claude Code, I want the workflow enforcement hooks to work correctly when I'm editing files in subdirectories, so that I don't experience inconsistent behavior or false negatives when Agent OS tries to determine my project context.

**Workflow:** Developer opens Claude Code from a subdirectory like `src/components/`, edits files, and triggers Agent OS hooks. The hooks should correctly identify the project root and apply appropriate workflow enforcement regardless of the current working directory.

## Spec Scope

1. **Unified Project Root Resolver** - Create a single, robust function/script that can be used by all Agent OS components to consistently determine project root
2. **Priority-Based Resolution Strategy** - Implement a clear resolution order: CLAUDE_PROJECT_DIR env var, hook payload fields, file system ascent, fallback to cwd
3. **Hook Integration Updates** - Update all existing hooks to use the standardized resolver
4. **Script Integration Updates** - Update config-resolver.py and other scripts to use the standardized resolver
5. **Comprehensive Testing** - Ensure the resolver works correctly from any subdirectory depth and handles edge cases

## Out of Scope

- Changes to Claude Code's hook payload structure (we work with what's provided)
- Platform-specific path resolution beyond standard Unix/Windows compatibility
- Performance optimization beyond basic caching (can be added later if needed)

## Expected Deliverable

1. All Agent OS hooks work consistently from any subdirectory within a project
2. A single, well-tested project root resolution module that can be imported/called by any component
3. Clear documentation of the resolution order and fallback behavior
4. Verification that existing functionality is preserved while fixing subdirectory issues

## Spec Documentation

- Tasks: @.agent-os/specs/2025-08-18-project-root-resolver-#58/tasks.md
- Technical Specification: @.agent-os/specs/2025-08-18-project-root-resolver-#58/sub-specs/technical-spec.md
- Tests Specification: @.agent-os/specs/2025-08-18-project-root-resolver-#58/sub-specs/tests.md