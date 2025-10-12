# Spec Requirements Document

> Spec: Stop-Hook Context Enhancement
> Created: 2025-10-12
> GitHub Issue: #98
> Status: Planning

## Overview

Enhance the stop-hook commit reminder system to provide context-aware information (GitHub issue, active spec, current branch) making commit messages more actionable and reducing friction in the commit workflow.

## User Stories

### Context-Aware Commit Reminders

As a developer using Agent OS, I want the stop-hook to show me what issue I'm working on and my current branch, so that I can quickly write meaningful commit messages without context-switching to check my current work.

When I see the stop-hook reminder, I often need to run `git branch` or check my GitHub issues to remember what I'm working on. This breaks my flow and adds unnecessary friction. The stop-hook should automatically show me the relevant context including the issue number from my branch name, the active spec folder if I'm in an Agent OS workflow, and suggest a properly formatted commit message with the issue reference.

### Smart Commit Message Suggestions

As a developer who wants to follow commit conventions, I want the stop-hook to suggest commit messages based on my current work context, so that I can maintain consistent, well-formatted commit messages without thinking about the format.

Instead of seeing a generic "describe your work" placeholder, I want to see a suggested commit message like `feat: add context extraction to stop-hook #98` that already includes the issue number and follows conventional commit format.

## Spec Scope

1. **Branch Context Extraction** - Display current branch name in stop-hook message
2. **Issue Number Detection** - Extract and show GitHub issue number from branch name (supports #123, 123-, and other patterns)
3. **Active Spec Display** - Show active Agent OS spec folder when working on a spec
4. **Smart Commit Suggestions** - Generate context-aware commit message suggestions with issue references
5. **Performance Optimization** - Keep message generation fast (<50ms) with no external API calls

## Out of Scope

- GitHub CLI integration for issue titles (future enhancement)
- Cached issue metadata with TTL
- Conventional commit type detection based on changed files
- Work session mode integration (separate feature)

## Expected Deliverable

1. **Enhanced Stop-Hook Messages** - Stop-hook displays branch, issue #, and spec context when available, with graceful fallback when context is missing
2. **Commit Message Generation** - Smart suggestions include issue number in proper format (`feat: description #123`)
3. **Performance Maintained** - Message generation adds <50ms latency, no external dependencies or API calls

## Spec Documentation

- Tasks: @.agent-os/specs/2025-10-12-stop-hook-context-#98/tasks.md
- Technical Specification: @.agent-os/specs/2025-10-12-stop-hook-context-#98/sub-specs/technical-spec.md
- Tests Specification: @.agent-os/specs/2025-10-12-stop-hook-context-#98/sub-specs/tests.md
