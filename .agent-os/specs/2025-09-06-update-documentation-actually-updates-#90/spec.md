# Update Documentation Command Enhancement

> **Issue:** #90  
> **Created:** 2025-09-06  
> **Status:** Planning  
> **Priority:** High  
> **Effort:** Large (L)

## Overview

Transform the misleading `/update-documentation` command from a documentation analysis tool into a fully functional documentation update system that actually performs the updates it was designed to do. This addresses the critical user experience issue where the command name promises functionality it doesn't deliver.

## Problem Statement

The current `/update-documentation` command suffers from a fundamental naming/functionality mismatch:

- **Name promises**: "update-documentation" implies it will update documentation
- **Reality delivers**: Only analysis and recommendations (essentially "check-documentation")
- **User expectation**: Command should automatically update documentation files
- **Current behavior**: Shows what needs updating but requires manual intervention

This creates workflow inefficiency, user frustration, and undermines trust in Agent OS commands.

## User Stories

### Primary User Story: Documentation Maintainer

As a **project maintainer**, I want to run `/update-documentation` and have it automatically update my documentation files, so that I can keep my project documentation current without manual effort.

**Detailed Workflow:**
1. Developer completes feature work and creates PR
2. Before merging, developer runs `/update-documentation`  
3. Command automatically updates CHANGELOG.md with PR information
4. Command updates roadmap completion status
5. Command creates missing spec directories for open issues
6. Command fixes broken file references in documentation
7. Developer reviews changes and commits updated documentation

### Secondary User Story: Team Lead

As a **team lead**, I want to run `/update-documentation --preview` to see what would be updated before making changes, so that I can review documentation updates before applying them.

**Detailed Workflow:**
1. Team lead runs `/update-documentation --preview` (replaces `--dry-run`)
2. Command shows comprehensive preview of all pending updates
3. Team lead reviews proposed changes
4. Team lead runs `/update-documentation` to apply changes
5. Documentation is automatically updated and ready for commit

### Tertiary User Story: CI/CD Pipeline

As a **CI/CD system**, I want to run `/update-documentation --verify` to check if documentation is current without making changes, so that I can fail builds when documentation is out of sync.

**Detailed Workflow:**
1. CI runs `/update-documentation --verify` after tests pass
2. Command checks all documentation for currency  
3. If updates needed, CI fails with specific recommendations
4. If current, CI proceeds with deployment
5. Team gets immediate feedback on documentation debt

## Spec Scope

1. **Auto-update CHANGELOG.md** - Automatically append recent PR information with proper formatting
2. **Create missing spec directories** - Generate spec folders for open GitHub issues that lack them
3. **Update roadmap completion status** - Mark roadmap items complete based on closed issues/PRs
4. **Sync product documentation** - Update product docs to reflect actual implementation status  
5. **Fix broken file references** - Automatically repair broken `@` references and file links
6. **Granular operation flags** - Individual flags for each update operation type
7. **Preview mode** - Show all pending changes before applying (replaces `--dry-run`)
8. **Verification mode** - Check currency without updates (for CI/CD)

## Out of Scope

- **Content generation** - Won't write new documentation content, only update existing structures
- **Complex content analysis** - Won't analyze documentation quality or completeness
- **External service integration** - Won't sync with external documentation platforms
- **Rollback functionality** - Won't provide undo capabilities (use git for rollback)
- **Interactive editing** - Won't open editors or prompt for content details

## Expected Deliverable

1. **Functional `/update-documentation` command** - Actually updates documentation as name implies
2. **Comprehensive flag system** - Granular control over update operations  
3. **Preview/verification modes** - Safe preview and CI-friendly verification
4. **Backward compatibility** - Existing workflows continue to work but with actual functionality
5. **Complete test coverage** - Comprehensive testing of all update operations
6. **Updated documentation** - README and help text reflect actual functionality

## Success Metrics

- **User expectation alignment**: Command name matches actual behavior
- **Workflow efficiency**: Reduce manual documentation updates by 80%
- **Error reduction**: Eliminate broken file references and outdated information
- **CI/CD integration**: Enable automated documentation currency checking
- **Developer satisfaction**: Positive feedback on actual update functionality

## Risk Mitigation

- **Data safety**: All operations work on git-tracked files (rollback via git)
- **Validation**: Extensive testing ensures updates don't corrupt documentation
- **Incremental deployment**: Gradual rollout with feature flags for each update type
- **Monitoring**: Comprehensive logging of all update operations for debugging

## Spec Documentation

- Tasks: @.agent-os/specs/2025-09-06-update-documentation-actually-updates-#90/tasks.md
- Technical Specification: @.agent-os/specs/2025-09-06-update-documentation-actually-updates-#90/sub-specs/technical-spec.md
- Tests Specification: @.agent-os/specs/2025-09-06-update-documentation-actually-updates-#90/sub-specs/tests.md