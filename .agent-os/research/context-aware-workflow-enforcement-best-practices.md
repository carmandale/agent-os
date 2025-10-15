# Context-Aware Workflow Enforcement: Best Practices Research

> Research Date: 2025-10-15
> Purpose: Inform development of context-aware commit reminders and workflow gates
> Related Issues: #22, #37, #98

## Executive Summary

This research document synthesizes best practices from industry-standard tools, academic research, and real-world implementations to guide the development of context-aware workflow enforcement systems. Key findings emphasize:

1. **Context awareness is critical** - 65% of developers report AI tools "miss relevant context" as their primary frustration
2. **Time-based heuristics must balance security and UX** - Industry standards suggest 15-30 minutes for low-risk inactivity, 2-5 minutes for high-value operations
3. **Developer flow state is fragile** - Interruptions cost 20-60 minutes of recovery time; self-interruptions (like commit reminders) can be more disruptive than external ones
4. **Porcelain format is essential** - Git provides stable, parse-friendly output formats specifically for automation
5. **Hooks should be fast and informative** - Slow hooks frustrate developers; clear feedback is mandatory

---

## 1. Detecting Active Work Sessions

### Industry Approaches to Session Detection

#### Time-Based Heuristics

**OWASP/NIST Security Standards:**
- **Idle Timeout (Inactivity):** 15-30 minutes for low-risk applications, 2-5 minutes for high-value applications
- **Absolute Timeout (Maximum Session):** 4-8 hours for full-day office work, 12 hours maximum before re-authentication
- **Sliding Expiry Pattern:** Extend expiration time when user is active during the session

**Source:** [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)

**Key Principle:** "Session timeout management and expiration must be enforced server-side" with sliding expiry to prevent timeout during legitimate use while reducing risk for inactive users.

#### Development Tool Implementations

**Active Session History (Database Performance):**
- Captures session state every second (or configurable interval)
- Records: SQL being executed, wait events, time model statistics, session metadata
- Used by Oracle Database and other enterprise systems for real-time monitoring

**Idle Time Tracking (Developer Tools):**
- **Teramind:** Automatically detects keyboard/mouse inactivity
- **TimeCamp:** Adjustable inactivity thresholds trigger notifications
- Common threshold: 5-15 minutes of no input triggers "idle" status

**Pattern:** Most development tools use 5-15 minute inactivity windows, with configurable thresholds based on project needs.

### Git-Specific Session Detection Patterns

#### Work-in-Progress (WIP) Branch Detection

**git-wip Tool** ([github.com/bartman/git-wip](https://github.com/bartman/git-wip)):
- Automatically captures state on file save
- Creates WIP branches for throwaway checkpoints
- Integrates with editors to track development state
- Pattern: "WIP" prefix convention indicates active development

**Abandoned Branch Detection:**
- Tag abandoned branches with prefix (e.g., `archive/` or `wip/`)
- Time-based heuristic: Unmerged branches created >30 days ago
- Notification pattern: Email warning before deletion
- Preservation strategy: Tag instead of delete, allow cherry-picking later

**Source:** [Software Engineering StackExchange - Abandoned Branches](https://softwareengineering.stackexchange.com/questions/450379/what-do-you-do-with-branches-youve-abandoned)

#### Stale Branch Detection Scripts

**Common Pattern:**
```bash
# Find branches with no activity in 30+ days
git for-each-ref --sort=-committerdate --format='%(committerdate:iso8601) %(refname:short)' refs/heads/
```

**Time Thresholds:**
- **Active:** Last commit within 7 days
- **Stale:** Last commit 7-30 days ago
- **Abandoned:** Last commit >30 days ago, unmerged

**Source:** [GitHub Gist - Stale Branch Detection](https://gist.github.com/mroderick/4472d26c77ca9b7febd0)

### Context Indicators for Active Development

**Strong Indicators (Maintenance/Active Work):**
1. **Dirty workspace** - Uncommitted changes present
2. **Recent commit activity** - Commits within last 4 hours
3. **Feature branch with open PR** - Issue linked, PR in draft/review
4. **Recent file modifications** - File mtimes within last 2 hours
5. **Terminal activity** - Shell commands run within last 30 minutes

**Weak Indicators (Possibly Abandoned):**
1. **Clean workspace, old commits** - No changes, last commit >24 hours ago
2. **Merged PR, still on branch** - Work complete but not cleaned up
3. **No linked issue** - Ad-hoc work without tracking
4. **Long period between commits** - Days/weeks between commits on same branch

**Anti-Indicators (Definitely Not Active):**
1. **Closed issue, clean workspace** - Work marked complete
2. **Merged branch** - Already integrated
3. **Last activity >7 days** - Clearly abandoned

---

## 2. Balancing Workflow Enforcement with Developer Flexibility

### Developer Flow State Protection

#### The Cost of Interruptions

**Research Findings:**
- **Recovery Time:** 20-60 minutes to regain flow state after interruption
- **Pre-Flow Time:** 10-15 minutes to start editing code after resumption
- **Daily Uninterrupted Time:** Programmers typically get only ONE 2-hour uninterrupted session per day
- **Self-Interruption Impact:** More disruptive than external interruptions, negative effect on task performance

**Sources:**
- [Stack Overflow - Developer Flow State](https://stackoverflow.blog/2018/09/10/developer-flow-state-and-its-impact-on-productivity/)
- [Swarmia - Reduce Interruptions](https://www.swarmia.com/blog/reduce-interruptions-help-engineers-stay-in-flow/)
- [Game Developer - Programmer Interrupted](https://www.gamedeveloper.com/programming/programmer-interrupted)

#### Coping Strategies Developers Use

**Intentional Roadblocks:**
- Insert compile errors as reminder markers
- Leave TODO comments at stopping points
- Use commit message drafting as memory aid

**Implication:** Developers naturally create "resume points" to minimize context loss. Workflow tools should support this pattern, not fight it.

#### Best Practices for Interruption Management

**From Industry Research:**

1. **Protect Focus Time:**
   - Designate inviolate blocks for focused work
   - Set "focus time" status in communication tools
   - Block calendar during deep work periods

2. **Promote Asynchronous Communication:**
   - Prefer Slack messages, recorded videos, written updates
   - Allow team members to respond without interrupting flow

3. **Reflective Goal-Setting:**
   - 80% of developers report daily reflection improves productivity
   - Regular "nudging" helps structure work without interrupting
   - Brief check-ins at natural breakpoints (commit time, PR creation)

**Source:** [2018 and 2023 studies on work habits and nudging](https://www.aviator.co/blog/consistently-maintaining-flow-state-for-developers/)

### Git Hooks Best Practices for Developer Experience

#### Core Principles from Industry Leaders

**1. Keep Hooks Fast**
- Long-running hooks frustrate developers and slow workflow
- Target: Sub-second for simple checks, <10 seconds for complex validation
- If longer processing needed, defer to CI/CD pipeline

**2. Provide Clear, Actionable Feedback**
- Explain WHY hook failed
- Show WHAT needs to be fixed
- Provide COMMANDS to resolve issues

**Example:**
```
❌ Commit blocked: Missing issue reference

Your commit message must reference a GitHub issue:
  feat: implement login #123
  fix: resolve auth bug #456

Current message: "feat: implement login"
Suggested fix: Add issue number, e.g., "#123"
```

**3. Version Control Hooks in Repository**
- Share hooks across team via `.git/hooks/` or tool like `pre-commit`
- Ensures consistent standards for all developers
- Enables collaborative improvement

**4. Automate Installation**
- Single setup script to install hooks
- Eliminates manual effort, ensures consistency
- Example: `./setup-hooks.sh` or `pre-commit install`

**5. Balance Local and CI/CD Enforcement**
- Local hooks provide immediate feedback (developer convenience)
- CI/CD provides mandatory enforcement (team standards)
- Pattern: "Fast local checks + comprehensive CI validation"

**Sources:**
- [Atlassian Git Hooks Tutorial](https://www.atlassian.com/git/tutorials/git-hooks)
- [Smashing Magazine - Git Hooks for Teams](https://www.smashingmagazine.com/2019/12/git-hooks-team-development-workflow/)
- [Kinsta - Mastering Git Hooks](https://kinsta.com/blog/git-hooks/)

#### Hook Types and Use Cases

**Client-Side Hooks (Developer Machine):**
- `pre-commit` - Inspect snapshot before commit (linting, formatting, tests)
- `prepare-commit-msg` - Edit default commit message before author edits
- `commit-msg` - Validate commit message format
- `post-commit` - Notifications, logging after successful commit
- `pre-push` - Prevent pushes to certain branches, run additional tests

**Server-Side Hooks (Git Server):**
- `pre-receive` - Enforce team guidelines, reject bad commits
- `post-receive` - Trigger CI/CD, send notifications

**Recommendation:** For workflow enforcement, use `pre-commit` for fast local checks and `pre-push` for more comprehensive validation. Always pair with CI/CD for mandatory enforcement.

#### Popular Frameworks

**pre-commit Framework** ([pre-commit.com](https://pre-commit.com/)):
- Most widely adopted (GitHub: 10k+ stars)
- YAML configuration (`.pre-commit-config.yaml`)
- Language-agnostic plugin system
- Automatic installation and updates
- Example configuration:
  ```yaml
  repos:
    - repo: https://github.com/pre-commit/pre-commit-hooks
      rev: v4.4.0
      hooks:
        - id: trailing-whitespace
        - id: check-json
        - id: check-merge-conflict
  ```

**Key Insight:** "Think of Git hooks as a convenient developer tool rather than strictly enforced policy" - local hooks can be bypassed (`--no-verify`), so critical enforcement must happen server-side or in CI.

---

## 3. Context-Aware Commit Reminders and Workflow Gates

### Context-Aware Features in Modern AI Tools

#### JetBrains AI Assistant 2024.3

**Context Management Features:**
- Transparent context UI showing every element included
- Automatic inclusion of open files with selected code
- Inline AI prompts are context-aware, auto-including related files/symbols
- Workspace rules and shared coding standards retention

**Performance:**
- Context-aware indexing ingests full workspaces (code, docs, dependencies)
- Updates understanding with every commit
- Maintains awareness across branches

**Source:** [JetBrains AI Blog 2024.3](https://blog.jetbrains.com/ai/2024/11/jetbrains-ai-assistant-2024-3/)

#### Industry Context Management Patterns

**Multi-Agent Workflow Systems:**
- Specialized agents for distinct tasks (code generation, review, documentation, testing)
- Agents communicate context between each other
- Spring AI Alibaba: Process orchestration and context memory management built-in

**Key Problem Identified:**
- 65% of developers report AI tools "miss relevant context"
- #1 requested fix: "improved contextual understanding" (26% of all votes)
- Hallucinations often stem from poor contextual awareness

**Source:** [Qodo - State of AI Code Quality 2025](https://www.qodo.ai/reports/state-of-ai-code-quality/)

### Commit Reminder Strategies

#### When to Remind vs When to Block

**Reminder Scenarios (Gentle Nudge):**
- Uncommitted changes AND last commit >2 hours ago
- Many files changed (>5) with no recent commits
- End of working session (e.g., stop-hook in Claude Code)
- Natural breakpoints: PR creation, branch switching, day end

**Blocking Scenarios (Hard Gate):**
- Starting new feature work without creating issue
- Creating PR without linked issue
- Pushing to main/master without review
- Committing secrets/credentials (security violation)

**Pattern:** Reminders during active work, blocks when violating process requirements.

#### Intelligent Reminder Timing

**Good Times for Commit Reminders:**
1. **Natural breakpoints:**
   - Switching branches
   - Ending AI coding session
   - Closing terminal/editor
   - Before running tests

2. **Time-based triggers:**
   - After 2 hours of changes without commit
   - At end of typical work session (6-8 hours since first file change)
   - Daily standup time (if configured)

3. **Context-based triggers:**
   - Large changeset accumulated (>10 files or >500 lines)
   - Test suite passes after failing
   - Code review feedback addressed

**Bad Times for Commit Reminders:**
- During active editing (keystroke detection)
- Immediately after previous commit (<5 minutes)
- During failing tests
- Mid-refactoring (detected by many "WIP" comments)

#### Message Crafting Best Practices

**From Git Commit Message Standards:**

**Good Commit Message Structure:**
```
<type>(<scope>): <subject> #issue

<body>

<footer>
```

**Types:** feat, fix, docs, style, refactor, test, chore

**Imperative Mood:** "Add feature" not "Added feature"
- Describes what commit DOES, not what was DONE
- Present tense preferred

**Issue References:** Always link to tracking issue/ticket
- Provides context and traceability
- Enables automated project management

**Sources:**
- [Codefinity - 7 Best Practices](https://codefinity.com/blog/7-Best-Practices-of-Git-Commit-Messages)
- [Axolo - Git Commit Message Templates](https://axolo.co/blog/p/git-commit-messages-best-practices-examples)
- [GitKraken - Git Best Practices](https://www.gitkraken.com/learn/git/best-practices/git-commit-message)

**Context-Aware Message Generation:**
- Claude Code can analyze changes and recent history
- Auto-compose commit message with full context
- Include: What changed, why it changed, related issue

**Source:** [Anthropic - Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)

---

## 4. Time-Based vs Context-Based Heuristics

### Time-Based Heuristics

#### Advantages

1. **Simple to Implement:** Just check timestamps
2. **Predictable Behavior:** Developers know exact timeout values
3. **Universal Applicability:** Works regardless of project specifics
4. **Security Compliance:** Meets audit requirements (OWASP, NIST)

#### Disadvantages

1. **False Positives:** Developers thinking/researching without typing
2. **False Negatives:** Quick edits might miss long thoughtful work
3. **Rigid Boundaries:** Doesn't account for work patterns
4. **User Frustration:** Arbitrary timeouts interrupt flow

#### Recommended Time Thresholds

**From Industry Standards:**

| Activity | Threshold | Source |
|----------|-----------|--------|
| Idle timeout (low-risk) | 15-30 minutes | OWASP |
| Idle timeout (high-value) | 2-5 minutes | OWASP |
| Absolute session timeout | 4-8 hours | NIST |
| Active work detection | Last activity <30 min | Dev tools consensus |
| Stale work detection | Last activity >24 hours | Git tooling |
| Abandoned work detection | Last activity >7 days | GitHub conventions |

**Sliding Window Pattern:**
- Initial timeout: 30 minutes
- Each activity resets countdown
- Maximum session: 8 hours (force break)
- Grace period: 5 minutes before timeout to save work

### Context-Based Heuristics

#### Advantages

1. **Intelligent Detection:** Understands work state beyond time
2. **Fewer False Positives:** Reading docs/thinking doesn't trigger timeout
3. **Better UX:** Adapts to developer behavior patterns
4. **Accurate State Detection:** Knows difference between active work and abandoned work

#### Disadvantages

1. **Complex Implementation:** Requires multiple signal sources
2. **Harder to Predict:** Developers may not understand why action triggered
3. **More Failure Modes:** Each context source can break
4. **Performance Overhead:** Extracting context takes time

#### Context Signals for Workflow State

**High-Confidence Active Work Signals:**
1. **Dirty Git Status:** `git status --porcelain` returns non-empty
2. **Open Draft PR:** PR exists with current branch, not marked ready
3. **Recent Commits:** Commits within last 4 hours on current branch
4. **Linked Active Issue:** Issue referenced in commits, still open
5. **File System Activity:** Modified files within last 2 hours (mtime)

**Medium-Confidence Signals:**
1. **Branch Naming:** Follows feature branch convention (`feature/*`, `fix/*`)
2. **Commit Patterns:** Regular commits, not large infrequent dumps
3. **Test State:** Tests recently run and passing/failing (not stale)

**Low-Confidence Signals:**
1. **Time of Day:** Within typical working hours for developer
2. **Day of Week:** Weekday vs weekend
3. **Historical Patterns:** Similar branches in past

**Anti-Patterns (Likely Abandoned):**
1. **Clean Workspace + Old Commits:** Nothing to commit, last commit >7 days
2. **Merged PR + Still on Branch:** Work done, just forgot to cleanup
3. **No Issue Reference:** Ad-hoc uncommitted work
4. **Failed Tests Uncorrected:** Tests failing >24 hours without fixes

### Hybrid Approach (Recommended)

**Combine Time and Context:**

```
IF last_activity > 30_minutes THEN
  IF has_uncommitted_changes THEN
    → State: ACTIVE (maintenance/debugging)
    → Action: Gentle reminder to commit
  ELSIF last_commit < 24_hours AND has_open_pr THEN
    → State: ACTIVE (feature work in progress)
    → Action: No interruption
  ELSIF last_commit > 7_days THEN
    → State: ABANDONED
    → Action: Suggest cleanup (archive branch, close issue)
  ELSE
    → State: IDLE
    → Action: No action needed
  ENDIF
ENDIF
```

**Decision Tree Pattern:**
1. Check time threshold first (fast, simple)
2. If time threshold exceeded, examine context
3. Use context to refine action (remind, block, or nothing)
4. Provide clear explanation based on detected context

**Benefits:**
- Fast common case (check timestamp)
- Accurate edge cases (use context)
- Explainable decisions (show reasoning)
- Graceful degradation (if context unavailable, fall back to time)

---

## 5. Shell Script Patterns for Git Context Extraction

### Porcelain Format: The Foundation

#### Why Porcelain Format?

**Git's Official Guidance:**
> "The porcelain format is guaranteed not to change in a backwards-incompatible way between Git versions or based on user configuration, making it ideal for parsing by scripts."

**Benefits:**
- Stable across Git versions
- Unaffected by user's git config settings
- Machine-readable, structured output
- Well-documented format specification

**Sources:**
- [Git Documentation - git-status](https://git-scm.com/docs/git-status)
- [Stefan Judis - Porcelain Mode](https://www.stefanjudis.com/today-i-learned/the-short-version-of-git-status-and-the-close-but-different-porcelain-mode/)

### Essential Shell Script Patterns

#### 1. Detecting Dirty Workspace

**Simple Boolean Check:**
```bash
#!/bin/bash

if [ -n "$(git status --porcelain)" ]; then
  echo "Workspace is dirty - uncommitted changes present"
  exit 1
else
  echo "Workspace is clean"
  exit 0
fi
```

**Pattern:** Empty output means clean workspace; any output means changes exist.

**Source:** [Stack Overflow - Check Git Changes](https://stackoverflow.com/questions/5143795/how-can-i-check-in-a-bash-script-if-my-local-git-repository-has-changes)

#### 2. Parsing Change Types

**Categorize Changes:**
```bash
#!/bin/bash

git status --porcelain | while read status file; do
  case "$status" in
    M*)  echo "Modified: $file" ;;
    A*)  echo "Added: $file" ;;
    D*)  echo "Deleted: $file" ;;
    R*)  echo "Renamed: $file" ;;
    C*)  echo "Copied: $file" ;;
    U*)  echo "Unmerged: $file" ;;
    \?\?) echo "Untracked: $file" ;;
    *)   echo "Unknown status '$status': $file" ;;
  esac
done
```

**Pattern:** First two characters indicate staging status and working tree status.

**Source:** [Code Review StackExchange - Parse Git Status](https://codereview.stackexchange.com/questions/117639/bash-function-to-parse-git-status)

#### 3. Extracting Branch Information

**Current Branch Name:**
```bash
# Method 1: Using symbolic-ref (modern)
branch=$(git symbolic-ref --short HEAD 2>/dev/null)

# Method 2: Using rev-parse (alternative)
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Method 3: Using porcelain v2 format (most reliable)
branch=$(git status --porcelain=v2 --branch | sed -n -E 's/^# branch\.head (.*)/\1/p')
```

**Pattern:** Multiple methods for redundancy; porcelain v2 is most reliable for scripts.

**Source:** [Baeldung - Assign Git Branch to Variable](https://www.baeldung.com/linux/shell-assign-current-git-branch-name-to-variable)

#### 4. Branch Last Activity Timestamp

**Get Last Commit Date:**
```bash
#!/bin/bash

# For current branch
last_commit_date=$(git log -1 --format=%cd --date=iso)
last_commit_relative=$(git log -1 --format=%cd --date=relative)

echo "Last commit: $last_commit_date ($last_commit_relative)"

# For all branches with sorting
git for-each-ref --sort=-committerdate \
  --format='%(committerdate:iso8601) %(committerdate:relative) %(refname:short)' \
  refs/heads/
```

**Pattern:** `for-each-ref` with custom format provides flexible branch inspection.

**Source:** [GitHub Gist - Branch Last Commit](https://gist.github.com/jasonrudolph/1810768)

#### 5. Detecting Open Pull Requests

**Using GitHub CLI:**
```bash
#!/bin/bash

current_branch=$(git symbolic-ref --short HEAD)

# Check for open PR on current branch
pr_info=$(gh pr list --head "$current_branch" --json number,state,isDraft 2>/dev/null)

if [ -n "$pr_info" ]; then
  pr_number=$(echo "$pr_info" | jq -r '.[0].number')
  pr_state=$(echo "$pr_info" | jq -r '.[0].state')
  is_draft=$(echo "$pr_info" | jq -r '.[0].isDraft')

  echo "Branch has open PR #$pr_number (state: $pr_state, draft: $is_draft)"
else
  echo "No open PR for current branch"
fi
```

**Pattern:** Leverage `gh` CLI for GitHub-specific context; graceful failure if not available.

**Source:** Agent OS codebase and GitHub CLI documentation

#### 6. Extracting Issue References

**From Commit Messages:**
```bash
#!/bin/bash

# Get issue numbers from recent commits
issue_numbers=$(git log --oneline -10 | grep -oE '#[0-9]+' | sort -u)

if [ -z "$issue_numbers" ]; then
  echo "No issue references found in recent commits"
  exit 1
else
  echo "Related issues:"
  echo "$issue_numbers"
fi
```

**Pattern:** Regex extraction from git log output; assumes `#123` format.

#### 7. Comprehensive Context Extraction Function

**Reusable Context Gatherer:**
```bash
#!/bin/bash

get_git_context() {
  local context_file="${1:-/tmp/git-context.json}"

  # Branch information
  local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  local last_commit_date=$(git log -1 --format=%cd --date=iso 2>/dev/null)
  local last_commit_hash=$(git rev-parse --short HEAD 2>/dev/null)

  # Workspace status
  local is_dirty="false"
  [ -n "$(git status --porcelain)" ] && is_dirty="true"

  local modified_count=$(git status --porcelain | grep -c '^.M')
  local untracked_count=$(git status --porcelain | grep -c '^??')
  local staged_count=$(git status --porcelain | grep -c '^M.')

  # Issue references
  local issue_refs=$(git log --oneline -10 | grep -oE '#[0-9]+' | sort -u | paste -sd ',' -)

  # Generate JSON
  cat > "$context_file" <<EOF
{
  "branch": "$current_branch",
  "last_commit_date": "$last_commit_date",
  "last_commit_hash": "$last_commit_hash",
  "is_dirty": $is_dirty,
  "modified_files": $modified_count,
  "untracked_files": $untracked_count,
  "staged_files": $staged_count,
  "issue_references": "$issue_refs",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

  echo "$context_file"
}

# Usage
context_file=$(get_git_context)
echo "Context saved to: $context_file"
cat "$context_file"
```

**Pattern:** Single function to gather all context; outputs structured JSON for easy parsing.

### Performance Considerations

**Optimization Tips:**

1. **Cache Results:** Store context for short duration (30-60 seconds) to avoid repeated git calls
2. **Fail Fast:** Check existence before complex operations (`git rev-parse --git-dir` before status)
3. **Limit Log Depth:** Use `-n 10` or similar to avoid scanning entire history
4. **Parallel Execution:** Run independent checks concurrently with `&` and `wait`
5. **Avoid Pipes:** Direct output to variables when possible to reduce subshells

**Benchmark Example:**
```bash
#!/bin/bash

# Slow: Multiple git calls in sequence
start=$(date +%s%N)
branch=$(git symbolic-ref --short HEAD)
status=$(git status --porcelain)
log=$(git log -1 --format=%cd)
end=$(date +%s%N)
echo "Sequential: $((($end - $start) / 1000000))ms"

# Fast: Single git call with formatting
start=$(date +%s%N)
git_info=$(git log -1 --format="%D|%cd" && git status --porcelain)
end=$(date +%s%N)
echo "Combined: $((($end - $start) / 1000000))ms"
```

**Target Performance:**
- Simple checks (<5ms): dirty status, branch name
- Medium checks (<50ms): commit history, file counts
- Complex checks (<200ms): PR status, issue linking
- **Total context extraction: <300ms** to avoid flow disruption

---

## 6. Real-World Examples and Tools

### Popular Pre-commit Frameworks

#### 1. pre-commit (Most Popular)

**Repository:** [github.com/pre-commit/pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks)

**Features:**
- 35+ built-in hooks (trailing whitespace, JSON validation, merge conflict detection, etc.)
- Language-agnostic plugin system
- Automatic dependency management
- Easy configuration via `.pre-commit-config.yaml`

**Example Configuration:**
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: detect-private-key
```

**Installation:**
```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files  # Test on existing files
```

#### 2. Husky (JavaScript/Node.js Ecosystem)

**Repository:** [github.com/typicode/husky](https://github.com/typicode/husky)

**Features:**
- NPM-based hook management
- Simple setup for JS projects
- Often paired with `lint-staged` for incremental checks

**Example:**
```json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged",
      "commit-msg": "commitlint -E HUSKY_GIT_PARAMS"
    }
  }
}
```

#### 3. commitlint (Commit Message Validation)

**Repository:** [github.com/conventional-changelog/commitlint](https://github.com/conventional-changelog/commitlint)

**Features:**
- Enforces Conventional Commits format
- Configurable rules
- Integrates with Husky or pre-commit

**Example Configuration:**
```js
// commitlint.config.js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', [
      'feat', 'fix', 'docs', 'style', 'refactor', 'test', 'chore'
    ]],
    'subject-case': [2, 'never', ['upper-case']],
    'subject-min-length': [2, 'always', 10],
    'body-max-line-length': [2, 'always', 100]
  }
};
```

### Workflow Enforcement in Production Systems

#### GitHub Actions + Local Hooks Pattern

**Strategy:** Fast local feedback + mandatory CI enforcement

**Local Hook (`.git/hooks/pre-commit`):**
```bash
#!/bin/bash
# Quick checks (linting, formatting)
npm run lint:quick || exit 1
```

**GitHub Actions (`.github/workflows/ci.yml`):**
```yaml
name: CI
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run comprehensive checks
        run: |
          npm run lint
          npm run test
          npm run build
```

**Why Both?**
- Local: Immediate feedback, saves CI minutes
- CI: Mandatory enforcement, catches bypassed hooks (`git commit --no-verify`)

**Source:** [Thomas Thornton - Pre-commit as GitHub Actions](https://thomasthornton.cloud/2022/08/04/running-pre-commit-hooks-as-github-actions/)

### Context-Aware Tools in Production

#### git-wip: Work-in-Progress Tracking

**Repository:** [github.com/bartman/git-wip](https://github.com/bartman/git-wip)

**Concept:**
- Automatically capture state on every file save
- Creates WIP commits on separate branch
- Never interferes with main workflow
- Provides safety net for lost work

**Editor Integration:**
```bash
# Vim integration
autocmd BufWritePost * silent !git wip save "WIP from Vim" --editor -- "%"

# VSCode: Use extension or save hook
```

**Use Case:** Perfect for exploratory development where you want undo/redo across sessions without polluting commit history.

#### Stale Branch Detection Scripts

**Pattern from Production Systems:**
```bash
#!/bin/bash
# detect-stale-branches.sh

STALE_DAYS=30
ABANDONED_DAYS=90

echo "=== Stale Branch Report ==="
echo ""

# Recent branches (< 30 days)
echo "✅ Active branches:"
git for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname:short)' refs/heads/ | head -10

# Stale branches (30-90 days)
echo ""
echo "⚠️  Stale branches (consider cleanup):"
git for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname:short)' refs/heads/ | \
  awk -v days=$STALE_DAYS '$1 < strftime("%Y-%m-%d", systime() - days * 86400)'

# Abandoned branches (> 90 days)
echo ""
echo "❌ Abandoned branches (should delete/archive):"
git for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname:short)' refs/heads/ | \
  awk -v days=$ABANDONED_DAYS '$1 < strftime("%Y-%m-%d", systime() - days * 86400)'
```

**Source:** [GitHub Gist - Stale Branches](https://gist.github.com/mroderick/4472d26c77ca9b7febd0)

---

## 7. Synthesis: Recommendations for Agent OS

### Architecture Recommendations

#### 1. Hybrid Time + Context Detection System

**Implementation Pattern:**
```
┌─────────────────────────────────────────────────┐
│ Phase 1: Fast Time Check                       │
│ - Check last activity timestamp                │
│ - If < 30 min: SKIP (active work)             │
│ - If > 30 min: CONTINUE to Phase 2            │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Phase 2: Context Analysis (Cached 5 min)       │
│ - Git status (dirty/clean)                     │
│ - Branch info (name, last commit)              │
│ - PR status (open/draft/merged)                │
│ - Issue references                             │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│ Phase 3: Decision Logic                        │
│ - Dirty + active PR = ACTIVE (no action)       │
│ - Clean + old commits = IDLE (gentle reminder) │
│ - Clean + closed issue = COMPLETE (suggest PR) │
│ - Merged PR = CLEANUP (suggest branch delete)  │
└─────────────────────────────────────────────────┘
```

**Benefits:**
- Fast common case (time check only)
- Accurate edge cases (context-aware decisions)
- Cacheable context (avoid repeated git calls)
- Clear decision trail (explainable to users)

#### 2. Progressive Reminder Strategy

**Escalation Levels:**

| Level | Trigger | Action | Tone |
|-------|---------|--------|------|
| **Nudge** | 2 hours uncommitted work | Gentle suggestion in summary | Informational |
| **Reminder** | 4 hours uncommitted work | Explicit reminder with next steps | Encouraging |
| **Warning** | 24 hours uncommitted work | Strong recommendation to commit/PR | Urgent |
| **Block** | Starting new issue without cleanup | Prevent new work until resolved | Mandatory |

**Message Examples:**

**Nudge:**
```
💡 You have uncommitted changes from earlier today.
Consider committing your progress: git add . && git commit
```

**Reminder:**
```
📋 Your work on issue #123 has uncommitted changes for 4 hours.
Recommended: Commit current state before losing context.
  git add .
  git commit -m "feat: implement auth middleware #123"
```

**Warning:**
```
⚠️  Uncommitted work from yesterday detected!
You have 15 modified files without commits.
Please commit or stash before starting new work:
  git status  # Review changes
  git add .
  git commit -m "feat: complete user profile #123"
```

**Block:**
```
❌ Cannot start new issue without completing current work.

Current state:
  - Issue #123: Open with uncommitted changes
  - Branch: feature/user-profile (dirty)
  - Last commit: 2 days ago

Required actions:
  1. Review uncommitted changes: git status
  2. Commit or stash: git commit / git stash
  3. Close or update issue #123
  4. Then create new issue for next feature
```

#### 3. Stop-Hook Integration Pattern

**Current Challenge:** stop-hook runs at end of every Claude Code session, but should behave differently based on context.

**Context-Aware Stop-Hook Logic:**

```bash
#!/bin/bash
# stop-hook.sh

source "$(dirname "$0")/workspace-state.sh"  # Get cached context

# Extract key signals
has_uncommitted=$(workspace_state_get "has_uncommitted")
last_commit_hours=$(workspace_state_get "hours_since_last_commit")
has_open_pr=$(workspace_state_get "has_open_pr")
has_active_issue=$(workspace_state_get "has_active_issue")

# Decision logic
if [[ "$has_uncommitted" == "true" ]]; then
  # Uncommitted changes exist

  if [[ "$last_commit_hours" -lt 2 ]]; then
    # Recent commit, probably mid-feature
    echo "💾 Uncommitted changes detected."
    echo "Consider committing before next session: git add . && git commit"

  elif [[ "$last_commit_hours" -lt 24 ]]; then
    # Same-day work, moderate urgency
    echo "📋 You have uncommitted changes from earlier today."
    echo ""
    echo "Recommended actions:"
    echo "  git status              # Review changes"
    echo "  git add .               # Stage changes"
    echo "  git commit -m '...'     # Commit with message"

  else
    # Old work, high urgency
    echo "⚠️  IMPORTANT: Uncommitted changes from >24 hours ago!"
    echo ""
    echo "Please commit or stash before losing context:"
    echo "  git status              # Review changes"
    echo "  git add .               # Stage all changes"
    echo "  git commit -m '...'     # Commit with descriptive message"
    echo ""
    echo "Or stash for later:"
    echo "  git stash save 'WIP: describe work here'"
  fi

elif [[ "$has_open_pr" == "true" ]]; then
  # Clean workspace, PR exists - probably done with feature
  echo "✅ Clean workspace. PR #$pr_number is open."
  echo ""
  echo "Next steps:"
  echo "  • Review PR and address feedback"
  echo "  • Merge when ready"
  echo "  • Close related issue after merge"

elif [[ "$has_active_issue" == "true" ]]; then
  # Clean workspace, issue open - work in progress
  echo "📌 Working on issue #$issue_number"
  echo "Clean workspace - ready for next session."

else
  # Clean workspace, no active work
  echo "✅ Clean workspace. No active work detected."
fi
```

**Key Features:**
- Uses cached workspace state (no performance hit)
- Different messages based on context
- Escalates tone with urgency
- Provides concrete next steps
- Never blocks (informational only)

#### 4. Pre-Task Context Validation

**When Starting New Work:**

```bash
#!/bin/bash
# pre-task-validation.sh (called from execute-tasks.md workflow)

echo "🔍 Validating workspace before starting new task..."

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo "❌ Cannot start new task with uncommitted changes."
  echo ""
  echo "Current changes:"
  git status --short
  echo ""
  echo "Required actions:"
  echo "  1. Review changes: git status"
  echo "  2. Commit: git add . && git commit -m '...'"
  echo "  3. OR stash: git stash save 'WIP: ...'"
  echo ""
  exit 1
fi

# Check for open PRs on current branch
current_branch=$(git symbolic-ref --short HEAD)
pr_info=$(gh pr list --head "$current_branch" --json number,state 2>/dev/null)

if [ -n "$pr_info" ]; then
  pr_number=$(echo "$pr_info" | jq -r '.[0].number')
  pr_state=$(echo "$pr_info" | jq -r '.[0].state')

  echo "⚠️  Open PR #$pr_number exists for current branch ($pr_state)."
  echo ""
  echo "Recommended actions:"
  echo "  1. Complete PR review and merge"
  echo "  2. Switch to main: git checkout main"
  echo "  3. Pull latest: git pull origin main"
  echo "  4. Then create new branch for new task"
  echo ""
  read -p "Continue anyway? (y/N): " confirm
  if [[ "$confirm" != "y" ]]; then
    exit 1
  fi
fi

echo "✅ Workspace validation passed. Ready to start new task."
```

**Integration Point:** Execute-tasks workflow should call this before creating feature branch.

### Performance Targets

**Context Extraction Benchmarks:**

| Operation | Target | Maximum Acceptable |
|-----------|--------|-------------------|
| Check dirty status | <5ms | 10ms |
| Get branch name | <5ms | 10ms |
| Get last commit date | <10ms | 25ms |
| Count file changes | <10ms | 25ms |
| Check PR status (gh CLI) | <50ms | 100ms |
| **Total context extraction** | **<100ms** | **200ms** |

**Caching Strategy:**
- Cache full context for 5 minutes (TTL)
- Invalidate on: commit, branch switch, file changes
- Store in: `/tmp/agent-os-context-$UID.json`

**Implementation:**
```bash
CONTEXT_CACHE="/tmp/agent-os-context-$UID.json"
CACHE_TTL=300  # 5 minutes

get_cached_context() {
  if [ -f "$CONTEXT_CACHE" ]; then
    local age=$(($(date +%s) - $(stat -f %m "$CONTEXT_CACHE" 2>/dev/null || stat -c %Y "$CONTEXT_CACHE")))
    if [ "$age" -lt "$CACHE_TTL" ]; then
      cat "$CONTEXT_CACHE"
      return 0
    fi
  fi

  # Cache miss or expired - regenerate
  extract_fresh_context > "$CONTEXT_CACHE"
  cat "$CONTEXT_CACHE"
}
```

### User Experience Guidelines

**1. Transparency**
- Always explain WHY action is taken
- Show detected context that led to decision
- Provide option to override if appropriate

**2. Actionability**
- Every message includes concrete next steps
- Show exact commands to resolve issues
- Link to documentation for complex scenarios

**3. Non-Interruption**
- Prefer end-of-session reminders over mid-work interruptions
- Use progressive escalation (nudge → reminder → warning → block)
- Never block maintenance work (only new feature starts)

**4. Consistency**
- Same triggers always produce same messages
- Predictable behavior builds user trust
- Document decision logic in user-facing docs

**5. Graceful Degradation**
- If context unavailable (git error, gh not installed), fall back to time-only
- Provide partial context rather than failing completely
- Log errors but don't expose to user

---

## 8. Anti-Patterns to Avoid

Based on research findings, these are common mistakes to avoid:

### ❌ Anti-Pattern 1: Interrupting Active Flow

**Problem:** Popping up commit reminders while developer is actively coding.

**Why Bad:** Takes 20-60 minutes to regain flow state; self-interruptions worse than external ones.

**Solution:** Only remind at natural breakpoints (end of session, branch switch, etc.).

### ❌ Anti-Pattern 2: Slow Hooks

**Problem:** Pre-commit hook takes >10 seconds to run.

**Why Bad:** Developers will bypass with `--no-verify` to avoid frustration.

**Solution:** Keep hooks <1 second for simple checks, <10 seconds maximum. Defer heavy validation to CI.

### ❌ Anti-Pattern 3: Opaque Failures

**Problem:** Hook fails with message like "Error: validation failed"

**Why Bad:** Developers don't know what to fix or why it failed.

**Solution:** Always provide: (1) what went wrong, (2) why it matters, (3) how to fix it.

### ❌ Anti-Pattern 4: Rigid Time Boundaries

**Problem:** Exactly 30-minute timeout, no exceptions.

**Why Bad:** Developers reading docs, researching, or thinking don't produce git activity but are actively working.

**Solution:** Use context signals to detect actual work state, not just timestamps.

### ❌ Anti-Pattern 5: Blocking Legitimate Maintenance

**Problem:** Requiring clean workspace even for quick bug fixes.

**Why Bad:** Forces artificial commits or stashes for unrelated work-in-progress.

**Solution:** Distinguish "starting new feature" (requires clean slate) from "maintenance on existing work" (allows dirty workspace).

### ❌ Anti-Pattern 6: Uncacheable Context Extraction

**Problem:** Running full git status + log + PR check on every command.

**Why Bad:** 100-200ms overhead on every interaction breaks flow.

**Solution:** Cache context for 5 minutes, invalidate on state changes.

### ❌ Anti-Pattern 7: False Positives

**Problem:** Marking branch as "abandoned" after long weekend.

**Why Bad:** Wastes time investigating false alarms, erodes trust.

**Solution:** Use multiple signals (time + PR status + issue state) before flagging as abandoned.

### ❌ Anti-Pattern 8: Non-Bypassable Workflow Enforcement

**Problem:** No way to override hooks even when you know what you're doing.

**Why Bad:** Treats developers like they can't make decisions.

**Solution:** Soft enforcement locally (can override), hard enforcement in CI (team standard).

---

## 9. Testing and Validation Strategies

### Unit Testing Context Detection

**Test Cases for Workspace State Detection:**

```bash
# Test: Detect dirty workspace
setup_dirty_workspace() {
  echo "test" > test.txt
  git add test.txt
  echo "modified" >> test.txt
}

test_detects_dirty_workspace() {
  setup_dirty_workspace
  result=$(detect_workspace_state)
  assert_equals "dirty" "$result"
}

# Test: Detect clean workspace
test_detects_clean_workspace() {
  git reset --hard HEAD
  result=$(detect_workspace_state)
  assert_equals "clean" "$result"
}

# Test: Detect stale work
test_detects_stale_work() {
  # Backdate last commit to 8 days ago
  GIT_COMMITTER_DATE="2025-10-07T12:00:00" \
    git commit --amend --no-edit --date="2025-10-07T12:00:00"

  result=$(detect_work_age)
  assert_greater_than "$result" 7  # Days
}
```

### Integration Testing Workflow Scenarios

**Scenario Matrix:**

| Workspace State | Last Commit | Open PR | Expected Action |
|----------------|-------------|---------|-----------------|
| Clean | <1 hour | No | No action (recent commit) |
| Clean | >24 hours | No | No action (nothing to commit) |
| Clean | Any | Yes (open) | Remind to review PR |
| Dirty | <2 hours | No | Gentle nudge to commit |
| Dirty | >4 hours | No | Reminder to commit |
| Dirty | >24 hours | No | Warning to commit |
| Dirty | Any | Yes (draft) | No action (work in progress) |
| Dirty | Any | Yes (merged) | Block: cleanup required |

**Test Implementation:**
```bash
#!/bin/bash
# test-workflow-scenarios.sh

run_scenario_tests() {
  local failed=0

  for scenario in scenarios/*.sh; do
    echo "Testing: $(basename $scenario)"

    # Setup scenario
    source "$scenario"
    setup_scenario

    # Run context detection
    actual_action=$(determine_workflow_action)

    # Verify expected action
    if [[ "$actual_action" == "$expected_action" ]]; then
      echo "  ✅ PASS"
    else
      echo "  ❌ FAIL: Expected '$expected_action', got '$actual_action'"
      ((failed++))
    fi

    # Cleanup
    teardown_scenario
  done

  echo ""
  echo "Results: $((total - failed))/$total passed"
  return $failed
}
```

### Performance Benchmarking

**Benchmark Script:**
```bash
#!/bin/bash
# benchmark-context-extraction.sh

benchmark() {
  local name="$1"
  local command="$2"
  local iterations=100

  echo "Benchmarking: $name"

  total_ms=0
  for i in $(seq 1 $iterations); do
    start=$(date +%s%N)
    eval "$command" > /dev/null 2>&1
    end=$(date +%s%N)
    ms=$((($end - $start) / 1000000))
    total_ms=$(($total_ms + $ms))
  done

  avg_ms=$(($total_ms / $iterations))
  echo "  Average: ${avg_ms}ms ($iterations iterations)"

  if [ $avg_ms -lt 100 ]; then
    echo "  ✅ PASS (target: <100ms)"
  else
    echo "  ⚠️  WARN: Exceeds 100ms target"
  fi
}

benchmark "Git status (porcelain)" "git status --porcelain"
benchmark "Get branch name" "git symbolic-ref --short HEAD"
benchmark "Last commit date" "git log -1 --format=%cd"
benchmark "Full context extraction" "extract_git_context"
```

### User Acceptance Testing

**Feedback Collection Points:**

1. **After First Use:**
   - "Did the workflow reminder help or hinder?"
   - "Was the message clear and actionable?"

2. **After One Week:**
   - "How often do reminders appear?"
   - "Are they accurate (true positives)?"
   - "Have you bypassed hooks? Why?"

3. **After One Month:**
   - "Has workflow enforcement improved code quality?"
   - "Do you feel more or less productive?"
   - "What would you change?"

---

## 10. Implementation Checklist

### Phase 1: Foundation (Week 1-2)

- [ ] Implement porcelain-based git context extraction
- [ ] Create workspace state cache (5-minute TTL)
- [ ] Build time-based heuristics (30min idle, 24hr stale, 7day abandoned)
- [ ] Add context signals (dirty status, PR status, issue references)
- [ ] Write unit tests for all context extraction functions
- [ ] Benchmark performance (<100ms target)

### Phase 2: Decision Logic (Week 2-3)

- [ ] Implement hybrid time+context decision tree
- [ ] Create progressive reminder levels (nudge/reminder/warning/block)
- [ ] Draft message templates for each scenario
- [ ] Add user-facing explanations for each action
- [ ] Test decision logic against scenario matrix
- [ ] Document decision logic in user docs

### Phase 3: Hook Integration (Week 3-4)

- [ ] Integrate context-aware logic into stop-hook
- [ ] Update pre-task validation in execute-tasks workflow
- [ ] Add context injection to workflow modules
- [ ] Implement graceful degradation (if git/gh unavailable)
- [ ] Test with real Agent OS workflows
- [ ] Get user feedback on messaging and timing

### Phase 4: Optimization (Week 4-5)

- [ ] Profile performance under various conditions
- [ ] Optimize cache invalidation strategy
- [ ] Add circuit breakers for slow operations
- [ ] Implement timeout safeguards
- [ ] Add detailed logging for debugging
- [ ] Create troubleshooting guide

### Phase 5: Polish (Week 5-6)

- [ ] Refine messages based on user feedback
- [ ] Add color coding and formatting to output
- [ ] Create configuration options (timeouts, thresholds)
- [ ] Write comprehensive user documentation
- [ ] Create video walkthrough of feature
- [ ] Prepare release notes and migration guide

---

## 11. Conclusion and Key Takeaways

### Most Important Findings

1. **Context beats time alone** - 65% of developers want better contextual understanding from AI tools. Time thresholds are necessary but insufficient.

2. **Flow state is precious** - Interruptions cost 20-60 minutes to recover. Design for natural breakpoints, not arbitrary triggers.

3. **Fast and informative wins** - Hooks must be <100ms and provide actionable feedback. Slow or opaque hooks get bypassed.

4. **Porcelain format is mandatory** - Git's stable, machine-readable output formats are designed for scripts. Use them.

5. **Progressive escalation works** - Start with nudges, escalate to reminders, warnings, and finally blocks. Match urgency to context.

6. **Local + CI is best practice** - Fast local checks for convenience, mandatory CI checks for enforcement. Don't rely solely on local hooks.

7. **Multiple signals required** - Single indicators (time alone, dirty status alone) create false positives. Combine multiple context signals.

8. **Graceful degradation essential** - If advanced context unavailable, fall back to simpler checks. Never completely fail.

### Success Metrics

**Quantitative:**
- Context extraction <100ms (p95)
- <5% false positives (flagged as abandoned when active)
- <2% false negatives (missed abandoned work)
- Hook bypass rate <10% (indicates trust)

**Qualitative:**
- User reports feeling "helped not hindered"
- Feedback: "Messages are clear and actionable"
- Increased commit frequency (smaller, more frequent commits)
- Reduced PR cleanup time (better hygiene)

### Future Research Directions

1. **Machine Learning for Work Patterns**
   - Learn individual developer patterns
   - Predict optimal reminder times based on history
   - Adapt thresholds to team norms

2. **IDE Integration**
   - Native VS Code / JetBrains integration
   - Real-time context awareness during editing
   - Inline suggestions in editor

3. **Team Analytics**
   - Aggregate workflow health across team
   - Identify systemic blockers
   - Benchmark against industry standards

4. **Advanced Context Sources**
   - Calendar integration (meeting times, focus blocks)
   - Slack status (in meeting, deep work mode)
   - Task management systems (Jira, Linear)

---

## 12. References and Further Reading

### Official Documentation

1. **Git Documentation**
   - [git-status porcelain format](https://git-scm.com/docs/git-status)
   - [Git Hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
   - [git-for-each-ref](https://git-scm.com/docs/git-for-each-ref)

2. **Security Standards**
   - [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
   - [NIST Authentication Guidelines](https://pages.nist.gov/800-63-3/)

3. **GitHub CLI**
   - [gh pr commands](https://cli.github.com/manual/gh_pr)
   - [gh issue commands](https://cli.github.com/manual/gh_issue)

### Research Papers and Articles

1. **Developer Flow State**
   - [Stack Overflow: Developer Flow State and Productivity](https://stackoverflow.blog/2018/09/10/developer-flow-state-and-its-impact-on-productivity/)
   - [Swarmia: Reduce Interruptions to Help Engineers Stay in Flow](https://www.swarmia.com/blog/reduce-interruptions-help-engineers-stay-in-flow/)
   - [Game Developer: Programmer, Interrupted](https://www.gamedeveloper.com/programming/programmer-interrupted)

2. **AI Coding Tools Context**
   - [Qodo: State of AI Code Quality 2025](https://www.qodo.ai/reports/state-of-ai-code-quality/)
   - [JetBrains AI Assistant 2024.3 Release](https://blog.jetbrains.com/ai/2024/11/jetbrains-ai-assistant-2024-3/)
   - [Anthropic: Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)

3. **Git Workflow Best Practices**
   - [Atlassian Git Hooks Tutorial](https://www.atlassian.com/git/tutorials/git-hooks)
   - [Smashing Magazine: Git Hooks for Team Development](https://www.smashingmagazine.com/2019/12/git-hooks-team-development-workflow/)
   - [Kinsta: Mastering Git Hooks](https://kinsta.com/blog/git-hooks/)

### Tools and Frameworks

1. **Pre-commit Frameworks**
   - [pre-commit.com](https://pre-commit.com/) - Most popular multi-language framework
   - [github.com/pre-commit/pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks) - Official hook collection

2. **Commit Message Tools**
   - [commitlint](https://commitlint.js.org/) - Lint commit messages
   - [Conventional Commits](https://www.conventionalcommits.org/) - Specification

3. **Git Utilities**
   - [github.com/bartman/git-wip](https://github.com/bartman/git-wip) - Work-in-progress tracking
   - [github.com/robertgzr/porcelain](https://github.com/robertgzr/porcelain) - Git status parser

### Community Resources

1. **Stack Overflow Discussions**
   - [Parse git status in bash](https://codereview.stackexchange.com/questions/117639/bash-function-to-parse-git-status)
   - [Detect git changes in script](https://stackoverflow.com/questions/5143795/how-can-i-check-in-a-bash-script-if-my-local-git-repository-has-changes)
   - [List branches by date](https://stackoverflow.com/questions/5188320/how-can-i-get-a-list-of-git-branches-ordered-by-most-recent-commit)

2. **GitHub Gists**
   - [List branches by last commit date](https://gist.github.com/jasonrudolph/1810768)
   - [Stale branch detection](https://gist.github.com/mroderick/4472d26c77ca9b7febd0)

3. **Blog Posts**
   - [Amit Dhamu: Git Status Porcelain](https://amitd.co/code/shell/git-status-porcelain)
   - [Stefan Judis: Porcelain vs Short Format](https://www.stefanjudis.com/today-i-learned/the-short-version-of-git-status-and-the-close-but-different-porcelain-mode/)

---

## Appendix A: Quick Reference Shell Scripts

### A1: Basic Context Extraction

```bash
#!/bin/bash
# quick-context.sh - Fast context extraction for Agent OS

# Check if dirty
is_dirty() {
  [ -n "$(git status --porcelain)" ]
}

# Get current branch
current_branch() {
  git symbolic-ref --short HEAD 2>/dev/null || echo "detached"
}

# Hours since last commit
hours_since_last_commit() {
  local last_commit_timestamp=$(git log -1 --format=%ct 2>/dev/null || echo "0")
  local now=$(date +%s)
  echo $(( ($now - $last_commit_timestamp) / 3600 ))
}

# Count file changes
count_changes() {
  local modified=$(git status --porcelain | grep -c '^.M' || echo "0")
  local untracked=$(git status --porcelain | grep -c '^??' || echo "0")
  local staged=$(git status --porcelain | grep -c '^M.' || echo "0")
  echo "$staged staged, $modified modified, $untracked untracked"
}

# Quick summary
echo "Branch: $(current_branch)"
echo "Dirty: $(is_dirty && echo 'yes' || echo 'no')"
echo "Hours since last commit: $(hours_since_last_commit)"
echo "Changes: $(count_changes)"
```

### A2: Decision Logic Template

```bash
#!/bin/bash
# workflow-decision.sh - Determine workflow action

source quick-context.sh

make_decision() {
  local is_dirty=$(is_dirty && echo "true" || echo "false")
  local hours=$(hours_since_last_commit)

  if [[ "$is_dirty" == "false" ]]; then
    echo "action=none; reason=clean workspace"
    return 0
  fi

  if [[ "$hours" -lt 2 ]]; then
    echo "action=nudge; reason=recent commit but uncommitted changes"
  elif [[ "$hours" -lt 24 ]]; then
    echo "action=remind; reason=same-day work uncommitted"
  else
    echo "action=warn; reason=stale uncommitted work"
  fi
}

make_decision
```

### A3: Message Templates

```bash
#!/bin/bash
# messages.sh - User-facing message templates

message_nudge() {
  cat <<EOF
💡 You have uncommitted changes from earlier today.
Consider committing your progress:
  git add . && git commit -m "feat: describe changes #123"
EOF
}

message_remind() {
  cat <<EOF
📋 Your work on issue #$1 has uncommitted changes for $2 hours.

Recommended: Commit current state before losing context.
  git status              # Review changes
  git add .               # Stage changes
  git commit -m "..."     # Commit with message
EOF
}

message_warn() {
  cat <<EOF
⚠️  IMPORTANT: Uncommitted changes from >24 hours ago!

Please commit or stash before losing context:
  git status              # Review changes
  git add .               # Stage all changes
  git commit -m "..."     # Commit with descriptive message

Or stash for later:
  git stash save 'WIP: describe work here'
EOF
}

message_block() {
  cat <<EOF
❌ Cannot start new issue without completing current work.

Current state:
  - Issue #$1: Open with uncommitted changes
  - Branch: $2 (dirty)
  - Last commit: $3 days ago

Required actions:
  1. Review uncommitted changes: git status
  2. Commit or stash: git commit / git stash
  3. Close or update issue #$1
  4. Then create new issue for next feature
EOF
}
```

---

## Document Metadata

**Title:** Context-Aware Workflow Enforcement: Best Practices Research
**Version:** 1.0
**Date:** 2025-10-15
**Authors:** Research conducted for Agent OS development team
**Purpose:** Inform implementation of context-aware commit reminders and workflow gates (#22, #37, #98)
**Status:** Complete - Ready for implementation planning

**Next Steps:**
1. Review findings with development team
2. Prioritize recommendations for implementation
3. Create detailed technical spec based on selected approach
4. Begin Phase 1 implementation (Foundation)

**Related Documents:**
- `/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/agent-os/.agent-os/specs/2025-07-29-claude-code-hooks-#37/spec.md`
- `/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/agent-os/.agent-os/specs/2025-07-30-project-config-amnesia-#12/spec.md`
- `/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/agent-os/.agent-os/product/roadmap.md` (Phase 0.5)
