# Merge Command Specification

> **Created:** 2025-10-13
> **Issue:** #100
> **Status:** Ready for Implementation
> **Size Estimate:** XL (32-46 hours)

## Quick Links

- **GitHub Issue:** https://github.com/carmandale/agent-os/issues/100
- **Spec Overview:** [spec.md](./spec.md)
- **Technical Details:** [technical-spec.md](./technical-spec.md)
- **Test Requirements:** [tests.md](./tests.md)
- **Implementation Tasks:** [tasks.md](./tasks.md)

## Overview

This specification defines an intelligent `/merge` command for Agent OS that automates the complete PR merge workflow with safety checks, code review integration, and automatic worktree cleanup.

### Key Features

- **Context-aware PR inference** from conversation, branch, or explicit argument
- **Pre-merge validation** (CI status, reviews, conflicts, branch protection)
- **Review feedback integration** with CodeRabbit/Codex
- **Safe merge execution** via GitHub CLI
- **Automatic worktree cleanup** after successful merge

### User Value

Reduces PR merge workflow from **5-10 minutes** to **<1 minute** while eliminating premature merges through comprehensive validation checks.

## Problem Being Solved

Current workflow requires manual steps across multiple tools:
1. Checking PR status on GitHub web UI
2. Reviewing code review feedback (CodeRabbit/Codex)
3. Addressing review comments
4. Verifying CI status
5. Manual merge execution
6. Worktree cleanup and branch deletion

The `/merge` command automates all these steps with safety checks and user confirmations.

## Implementation Approach

### 4-Phase Plan

1. **Phase 1:** Core Merge Automation (MVP) - 6-8 hours
   - PR inference, validation, basic merge, main branch update

2. **Phase 2:** Review Feedback Integration - 4-6 hours
   - CodeRabbit/Codex comment detection and user interaction

3. **Phase 3:** Worktree Management - 3-4 hours
   - Automatic worktree detection and cleanup after merge

4. **Phase 4:** Advanced Features & Polish - 4-6 hours
   - Flags (--dry-run, --force, --auto), error handling, documentation

### TDD Approach

All implementation follows Test-Driven Development:
1. Write test (red)
2. Implement feature (green)
3. Verify test passes (green)

## Files in This Spec

### Core Documents

- **spec.md** - High-level specification with problem statement, solution, and success metrics
- **technical-spec.md** - Detailed architecture, components, data flow, and implementation details
- **tests.md** - Comprehensive test requirements (unit, integration, edge cases, manual scenarios)
- **tasks.md** - 50 implementation tasks organized by phase with time estimates

### Supporting Files

- **README.md** (this file) - Spec overview and navigation guide

## Getting Started with Implementation

### Prerequisites

1. Read all spec documents in order: spec.md → technical-spec.md → tests.md → tasks.md
2. Understand existing Agent OS patterns:
   - `commands/workflow-status.md` - Command structure
   - `scripts/workflow-complete.sh` - Workflow automation patterns
   - `scripts/workflow-status.sh` - Worktree detection patterns
3. Review research documents:
   - `docs/research/pr-merge-automation-best-practices.md`
   - `docs/research/gh-cli-worktree-claude-commands.md`

### Recommended Implementation Order

1. **Setup** (Tasks 1.1-1.3)
   - Create command file, script skeleton, installer integration

2. **Phase 1: MVP** (Tasks 1.4-1.14)
   - Implement core merge workflow with safety checks

3. **Test & Validate Phase 1**
   - Ensure MVP works reliably before adding complexity

4. **Phase 2: Review Integration** (Tasks 2.1-2.6)
   - Add CodeRabbit/Codex feedback handling

5. **Phase 3: Worktree Management** (Tasks 3.1-3.6)
   - Add automatic worktree cleanup

6. **Phase 4: Polish** (Tasks 4.1-4.13)
   - Add flags, error handling, documentation

7. **Final Integration** (Tasks 5.1-5.4)
   - PR creation, roadmap update, deployment

### Key Design Principles

- **Safety First:** Multiple validation checks prevent premature merges
- **User Control:** Confirmation prompts before destructive operations
- **Graceful Degradation:** Handle errors with clear messages and recovery suggestions
- **Portable:** Works on macOS and Linux with standard tools (bash, gh, git)
- **Consistent:** Follows Agent OS conventions and patterns

## Testing Requirements

### Test Coverage Goals

- Unit Tests: 90%+ code coverage
- Integration Tests: All critical paths
- Edge Cases: All identified scenarios
- Manual Tests: All user-facing workflows

### Key Test Files

- `tests/unit/test-pr-inference.bats` - PR number inference logic
- `tests/unit/test-validation.bats` - Pre-merge validation checks
- `tests/unit/test-review-feedback.bats` - Review comment detection
- `tests/unit/test-merge-execution.bats` - Merge operation
- `tests/unit/test-worktree-cleanup.bats` - Worktree cleanup
- `tests/integration/test-merge-workflow.bats` - End-to-end workflows
- `tests/edge-cases/test-merge-edge-cases.bats` - Edge case handling

## Dependencies

### Required Tools

- `gh` (GitHub CLI) v2.0+
- `git` v2.17+ (for `git worktree remove`)
- `jq` for JSON parsing
- `bash` 4.0+ for associative arrays
- `bats` (Bash Automated Testing System)

### Integration Points

- GitHub API via `gh` CLI
- CodeRabbit review system (optional)
- Codex review system (optional)
- Agent OS worktree management
- Claude Code command system

## Success Metrics

### Quantitative

- Time savings: 5-10 minutes → <1 minute per merge
- Error reduction: 100% prevention of premature merges
- Adoption: 80%+ of Agent OS users within 1 month
- Worktree cleanup: Eliminate orphaned worktrees

### Qualitative

- Users report merge process feels "seamless"
- Reduced anxiety about merge safety
- Positive feedback on review integration
- Perceived as "Agent OS magic"

## Related Work

- **Issue #37:** Claude Code hooks implementation (workflow enforcement)
- **Issue #97:** Worktree listing feature (worktree management)
- **Issue #98:** Stop-hook context enhancement (context awareness)

## Questions or Issues?

- Open discussion in GitHub issue #100
- Refer to technical-spec.md for architecture details
- Check tests.md for test scenarios and acceptance criteria
- Review tasks.md for implementation task breakdown

---

**Status:** Ready for Implementation
**Next Step:** Begin Phase 1 implementation (Tasks 1.1-1.3: Setup)
