# Implementation Context: Merge Command

> **Spec:** 2025-10-13-merge-command-#100
> **Purpose:** Reference guide for implementation

## Agent OS Patterns to Follow

### Command Structure Pattern

**Reference:** `commands/workflow-status.md`

All Agent OS commands follow this structure:

```markdown
---
allowed-tools: Bash(git status:*), Bash(gh pr:*), ...
description: Brief description of what the command does
argument-hint: [--flag1|--flag2] <optional-arg>
---

## Context

Provide relevant context information using !` ` for command execution:
- Current status: !`command to get status`
- Relevant data: !`another command`

## Task

Execute the main script with captured arguments:
!`~/.agent-os/scripts/workflow-merge.sh $ARGUMENTS`
```

**For /merge command:**
- allowed-tools: Must include git operations, gh CLI, worktree commands
- description: "Intelligently merge pull requests with safety checks and worktree cleanup"
- argument-hint: "[--dry-run|--force|--auto] [pr_number]"

### Script Structure Pattern

**Reference:** `scripts/workflow-complete.sh:1-100`

Agent OS scripts follow this structure:

```bash
#!/usr/bin/env bash
# Script name and purpose
# Usage: script-name [options]

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'  # No Color

# Global variables
DRY_RUN=false
FORCE=false

# Helper functions
print_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Main functions
main() {
    parse_arguments "$@"
    # Main logic here
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run) DRY_RUN=true; shift ;;
            --force) FORCE=true; shift ;;
            *) PR_NUMBER="$1"; shift ;;
        esac
    done
}

# Entry point
main "$@"
```

### Installation Pattern

**Reference:** `setup-claude-code.sh:65-77`

Commands are installed via curl during setup:

```bash
for cmd in plan-product create-spec execute-tasks workflow-status workflow-complete workflow-merge; do
    if [ -f "$HOME/.claude/commands/${cmd}.md" ] && [ "$OVERWRITE_COMMANDS" = false ]; then
        echo "  ⚠️  ~/.claude/commands/${cmd}.md already exists - skipping"
    else
        curl -s -o "$HOME/.claude/commands/${cmd}.md" \
            "https://raw.githubusercontent.com/carmandale/agent-os/main/commands/${cmd}.md"
        echo "  ✅ Installed ${cmd}"
    fi
done
```

**Action Required:** Add `workflow-merge` to this list in Task 1.3

## Existing Code to Leverage

### Worktree Detection

**Reference:** `scripts/workflow-status.sh:282-365`

```bash
check_worktrees() {
    # Get all worktrees in porcelain format
    local worktrees=$(git worktree list --porcelain 2>/dev/null || echo "")

    if [[ -z "$worktrees" ]]; then
        echo "No worktrees found"
        return 1
    fi

    # Parse worktree info
    while IFS= read -r line; do
        case "$line" in
            worktree*)
                worktree_path="${line#worktree }"
                ;;
            branch*)
                branch_name="${line#branch refs/heads/}"
                ;;
        esac
    done <<< "$worktrees"
}
```

**Use in Task 3.1:** Adapt this pattern for `detect_worktree()` function

### GitHub Issue Extraction from Branch

**Reference:** `scripts/workflow-status.sh:367-389`

```bash
detect_issue_number() {
    local branch="$1"
    local issue_number=""

    # Pattern 1: issue-123
    if [[ $branch =~ issue-([0-9]+) ]]; then
        issue_number="${BASH_REMATCH[1]}"
    # Pattern 2: 123-feature-name
    elif [[ $branch =~ ^([0-9]+)- ]]; then
        issue_number="${BASH_REMATCH[1]}"
    # Pattern 3: feature-#123-description or bugfix-456-fix
    elif [[ $branch =~ (feature|bugfix|hotfix)-\#?([0-9]+) ]]; then
        issue_number="${BASH_REMATCH[2]}"
    fi

    echo "$issue_number"
}
```

**Use in Task 1.5:** Integrate into PR inference logic

### Git Workflow Patterns

**Reference:** `workflow-modules/step-4-git-integration.md:134-198`

Standard git operations used in Agent OS:

```bash
# Branch management
git checkout -b "feature/name-#123"
git branch --show-current
git fetch origin
git pull origin main

# Worktree operations
git worktree add ".worktrees/name-#123" "feature/name-#123"
git worktree list --porcelain
git worktree remove ".worktrees/name-#123"
git worktree prune

# Merge verification
git log --oneline -1 --grep="Merge pull request"
git merge --ff-only origin/main
```

**Use throughout:** Standard git operations for all phases

### Workflow Completion Pattern

**Reference:** `scripts/workflow-complete.sh:428-555`

The workflow-complete.sh script provides excellent patterns for:

1. **Phased Execution:**
```bash
echo "🎯 Phase 1: Pre-flight Checks"
run_phase_1_checks

echo "📝 Phase 2: Documentation Verification"
run_phase_2_docs

# ... etc
```

2. **Validation with Error Collection:**
```bash
local errors=()

if ! check_condition_1; then
    errors+=("Condition 1 failed")
fi

if ! check_condition_2; then
    errors+=("Condition 2 failed")
fi

if [[ ${#errors[@]} -gt 0 ]]; then
    print_error "Validation failed:"
    printf '  • %s\n' "${errors[@]}"
    return 1
fi
```

3. **Dry Run Mode:**
```bash
if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] Would execute: $command"
    return 0
fi

# Actually execute
eval "$command"
```

**Use in Tasks 1.9, 4.1:** Adopt these patterns

## GitHub CLI Commands Reference

### PR Information Queries

```bash
# Get PR details
gh pr view "$pr_number" --json \
    title,number,state,author,reviewDecision,mergeable,mergeStateStatus,mergeCommit

# Check CI status
gh pr checks "$pr_number" --json name,state,conclusion

# List PRs for current branch
gh pr list --head "$(git branch --show-current)" --json number,title

# Get PR comments
gh api "repos/$OWNER/$REPO/pulls/$pr_number/comments" \
    --jq '.[] | select(.user.login == "coderabbitai")'
```

### PR Merge Operations

```bash
# Merge with default strategy
gh pr merge "$pr_number" --merge --delete-branch

# Squash merge
gh pr merge "$pr_number" --squash --delete-branch

# Rebase merge
gh pr merge "$pr_number" --rebase --delete-branch

# Enable auto-merge (doesn't merge immediately)
gh pr merge "$pr_number" --auto --merge
```

### Repository Information

```bash
# Get current repo
gh repo view --json nameWithOwner --jq '.nameWithOwner'

# Check authentication
gh auth status
```

## Testing Infrastructure

### BATS Test Structure

**Reference:** Existing Agent OS tests use this pattern:

```bash
#!/usr/bin/env bats

load test_helper  # Common test utilities

setup() {
    # Run before each test
    export TEST_TEMP_DIR=$(mktemp -d)
    cd "$TEST_TEMP_DIR"
}

teardown() {
    # Run after each test
    rm -rf "$TEST_TEMP_DIR"
}

@test "descriptive test name" {
    # Arrange
    setup_test_conditions

    # Act
    run function_under_test "argument"

    # Assert
    assert_success
    assert_output "expected output"
}
```

### Mock Functions for Testing

```bash
# Mock gh command
mock_gh_command() {
    gh() {
        case "$1 $2" in
            "pr view")
                echo '{"number":123,"title":"Test PR","mergeable":"MERGEABLE"}'
                ;;
            "pr checks")
                echo '[{"name":"CI","state":"SUCCESS"}]'
                ;;
        esac
    }
    export -f gh
}
```

**Use in all test tasks:** Follow this mocking pattern

## Code Style Conventions

### From Agent OS Standards

**Reference:** `~/.agent-os/standards/code-style.md`

1. **Naming Conventions:**
   - Functions: `snake_case`
   - Constants: `UPPER_SNAKE_CASE`
   - Local variables: `snake_case`

2. **Indentation:**
   - Use tabs (not spaces)
   - Configure editor to show tabs as 4 spaces

3. **Comments:**
   - Add brief comments above non-obvious logic
   - Document the "why" not the "what"
   - Keep comments concise

4. **Error Handling:**
   - Always check return codes
   - Provide helpful error messages
   - Suggest recovery actions

## Security Considerations

### Authentication

- Never store credentials
- Rely on `gh auth status` for GitHub authentication
- Use existing GitHub CLI session

### Validation

- Always validate user input
- Check PR exists before operations
- Verify permissions via branch protection

### Destructive Operations

- Require user confirmation
- Display what will be affected
- Provide `--dry-run` option
- Implement `--force` with warnings

## Performance Targets

**From technical-spec.md:**

- PR inference: <1 second
- Pre-merge validation: 2-3 seconds
- Review feedback analysis: 1-2 seconds
- Merge execution: 2-5 seconds
- Worktree cleanup: 3-5 seconds
- **Total workflow: 10-20 seconds**

### Optimization Strategies

1. Parallel GitHub API calls where possible
2. Cache PR data (30-second TTL)
3. Use `--cached` flags when available
4. Minimize unnecessary git operations

## Error Handling Patterns

### Error Categories and Responses

1. **User Input Errors:**
   - Clear error message
   - Suggest correction
   - Exit with code 1

2. **Validation Failures:**
   - Display specific issues
   - Suggest fixes
   - Exit with code 2

3. **API/Network Errors:**
   - Report error
   - Provide manual fallback
   - Exit with code 3

4. **Git Operation Failures:**
   - Explain what failed
   - Provide recovery steps
   - Exit with code 4

### Example Error Messages

```bash
# Good: Specific, actionable
echo "❌ PR #123 has failing checks: 'tests/unit'"
echo "   Fix the failing tests and re-run /merge"
echo "   Or use --force to merge anyway (not recommended)"

# Bad: Vague, unhelpful
echo "Error: Validation failed"
```

## Integration Points

### Claude Code Command System

Commands are invoked via `/command-name` in Claude Code. The command markdown file:
1. Displays context information to Claude
2. Executes the bash script
3. Returns output to Claude for processing

### Agent OS Workflow

The merge command integrates into the Agent OS workflow:
1. User completes work in worktree
2. Creates PR via `/workflow-complete` or manually
3. Receives review feedback
4. Uses `/merge` to merge and cleanup

### CodeRabbit/Codex Integration

Review bots comment on PRs. The merge command:
1. Detects bot comments via GitHub API
2. Displays comments to user
3. Allows user to address before merging
4. Re-validates after changes

## References

### Internal Documentation

- **Agent OS Mission:** `.agent-os/product/mission.md`
- **Development Best Practices:** `~/.agent-os/standards/best-practices.md`
- **Git Workflow Module:** `workflow-modules/step-4-git-integration.md`
- **Command Reference:** All files in `commands/` directory
- **Script Library:** All files in `scripts/` directory

### External Documentation

- **GitHub CLI Manual:** https://cli.github.com/manual/
- **Git Worktree Docs:** https://git-scm.com/docs/git-worktree
- **BATS Testing:** https://github.com/bats-core/bats-core
- **Bash Best Practices:** https://google.github.io/styleguide/shellguide.html

### Research Documents

- **PR Merge Best Practices:** `docs/research/pr-merge-automation-best-practices.md`
- **GitHub CLI Patterns:** `docs/research/gh-cli-worktree-claude-commands.md`

## Implementation Checklist

Before starting implementation, ensure:

- [ ] Read all spec documents (spec.md, technical-spec.md, tests.md, tasks.md)
- [ ] Review referenced Agent OS code sections
- [ ] Understand existing command and script patterns
- [ ] Have required tools installed (gh, git, jq, bats)
- [ ] GitHub CLI authenticated (`gh auth status`)
- [ ] Test repository available for development
- [ ] Worktree for spec created (`.worktrees/merge-command-#100`)

## Quick Reference Commands

```bash
# Create development worktree
git worktree add .worktrees/merge-command-#100 feature/merge-command-#100

# Run tests
bats tests/test-workflow-merge.bats

# Install command locally (after implementation)
cp commands/workflow-merge.md ~/.claude/commands/
cp scripts/workflow-merge.sh ~/.agent-os/scripts/
chmod +x ~/.agent-os/scripts/workflow-merge.sh

# Test command
/merge --dry-run 123

# Check command output
/merge --help
```

---

This context document should be referenced throughout implementation to ensure consistency with Agent OS patterns and conventions.
