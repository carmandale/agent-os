---
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(grep:*), Bash(sed:*), Bash(awk:*), Bash(~/.agent-os/scripts/update-documentation.sh:*)
description: Update project documentation deterministically based on real diffs (discovery-first; evidence only)
argument-hint: [--dry-run|--diff-only|--create-missing|--deep]
---

## Context

- Current git status: !`git status --porcelain`
- Changed files (head): !`git diff --name-only HEAD`

## Task

Run the documentation updater in the requested mode and include only evidence-backed proposals. Do not fabricate or summarize without showing real data.

### Proposed updates

!`~/.agent-os/scripts/update-documentation.sh --dry-run $ARGUMENTS`

If flags are provided, pass them through; otherwise default to `--dry-run`.

## Notes

- This is a core user-level command. It calls the shared updater installed at `~/.agent-os/scripts/update-documentation.sh`.
- Use `--deep` to run a senior-style, evidence-first audit that detects non-obvious documentation drift and outputs cited proposals.
- Use this before PR creation and after completing a task to surface required doc updates.

