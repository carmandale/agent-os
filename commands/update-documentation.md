---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(gh issue:*), Bash(gh pr:*), Bash(jq:*), Bash(~/.agent-os/scripts/update-documentation.sh:*)
description: Detect documentation drift and provide actionable recommendations for Agent OS projects
argument-hint: [--dry-run|--diff-only|--create-missing|--deep]
---

## Context

- Current git status: !`git status --porcelain`
- Changed files (head): !`git diff --name-only HEAD`

## Task

Run the documentation health check to detect drift and provide actionable recommendations. All findings are evidence-based with no fabrication.

### Documentation Health Report

!`~/.agent-os/scripts/update-documentation.sh $ARGUMENTS`

If no flags are provided, default to `--dry-run` for safe operation.

## Available Modes

- **Normal Mode (default)**: Quick health check focusing on recent activity and common drift patterns
- **--deep**: Comprehensive audit of all Agent OS documentation relationships and completeness
- **--diff-only**: Show only git diff statistics without documentation analysis
- **--create-missing**: Create minimal scaffolds for missing required documentation (use with caution)

## Notes

- This command targets Agent OS documentation: `.agent-os/product/`, `CHANGELOG.md`, `CLAUDE.md`, `docs/`, GitHub issues/PRs
- Normal mode checks: recent commits, open issues without specs, recent PRs not in CHANGELOG
- Deep mode adds: file reference validation, spec-issue cross-referencing, roadmap status, orphaned specs
- Use before PR creation and after task completion to ensure documentation is current

