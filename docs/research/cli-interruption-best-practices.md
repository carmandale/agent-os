# CLI Interruption Messages and Developer Notifications: Best Practices Research

> Research Date: 2025-10-12
> Purpose: Inform Agent OS commit reminder and workflow notification design
> Scope: CLI interruption design, context-aware notifications, git workflows, user control

## Executive Summary

This research synthesizes best practices from authoritative sources on CLI interruption design, developer notification patterns, git workflow tools, and user control mechanisms. Key findings indicate that effective CLI interruptions balance **actionability**, **context awareness**, **progressive disclosure**, and **user control** to provide value without causing notification fatigue.

---

## 1. Effective Interruption Design

### Core Principles

**From [clig.dev](https://clig.dev/) - Command Line Interface Guidelines:**
- CLI programs should be "crash-only" - exit immediately on failure or interruption without extensive cleanup
- Developer-facing information should only appear in verbose mode by default
- Progress updates for long-running operations are the #1 priority for developer experience

**From [Evil Martians CLI UX Best Practices (2024)](https://evilmartians.com/chronicles/cli-ux-best-practices-3-patterns-for-improving-progress-displays):**
- "It's crucial for any interface, graphical or command-line, to provide updates on ongoing actions—it's simply good UX practice"
- Three essential patterns: spinners, "X of Y" counters, and progress bars
- If pressed for time, prioritize progress displays over all other improvements

**From [Toptal Notification Design Guide](https://www.toptal.com/designers/ux/notification-design):**
- Messages that interrupt must deliver **timely or actionable content**
- "A little bit of context goes a long way" - consider where users are and what they're trying to achieve
- Contextual updates get favorable responses; disruptive interruptions do not

### How to Design Messages That Interrupt Without Annoying

**Key Guidelines:**

1. **Provide Value, Not Interruption**
   - Follow best practices to ensure notifications are perceived as providing value, not as interruptions
   - Messages must communicate urgency AND deliver timely/actionable content
   - Reach users at the right moment in their workflow

2. **Context-Aware Timing**
   - Think about where users are in the product and what they're trying to achieve
   - Contextual updates are more likely to get favorable responses than workflow interruptions
   - Avoid interrupting focused work; align with natural workflow breakpoints

3. **Progressive Disclosure** (from [Nielsen Norman Group](https://www.nngroup.com/articles/progressive-disclosure/))
   - Initially show only the most important information
   - Offer specialized options or details upon request
   - Helps make applications easier to learn and less error-prone
   - Focus on the essential while revealing additional detail as needed

### What Information Is Most Valuable in Commit Reminders?

**From Git Commit Best Practices Research:**

1. **Branch Context**
   - Current branch name ([context-aware-prompt](https://github.com/byjg/context-aware-prompt))
   - Whether branch is feature/bugfix/hotfix

2. **Uncommitted Work Status** ([git-remind by suin](https://github.com/suin/git-remind))
   - Whether there are uncommitted files
   - Whether there are unpushed commits (ahead of remote)
   - Number of files changed

3. **Issue/Task Linkage**
   - Related GitHub issue number
   - Current task from task list
   - Expected commit message format

4. **Workflow State**
   - Time since last commit
   - Whether this is a logical commit point
   - What's been accomplished since last commit

### How to Make Messages Actionable vs Just Informational

**Actionable Message Design:**

1. **Clear Next Steps**
   - Provide specific commands to run
   - Example from Heroku CLI: "Run git push heroku main to trigger a new build"
   - Don't just state a problem; suggest the solution

2. **One-Action Responses**
   - Make it clear what single action resolves the notification
   - Avoid presenting multiple conflicting options
   - Use imperative voice: "Commit your changes" not "You have uncommitted changes"

3. **Contextual Commands**
   - Provide copy-pasteable commands with current context filled in
   - Example: `git commit -m "feat: [description] #123"` not just "create a commit"
   - Pre-populate with known information (issue number, branch name)

---

## 2. Context-Aware Notifications

### Examples of Tools with Smart, Context-Aware Reminders

**[git-remind by suin](https://github.com/suin/git-remind)** - Command line tool that:
- Checks across all git repositories on your computer
- Displays whether there are uncommitted files
- Shows ahead commits that should be pushed to remote
- Provides desktop notifications of git-commit/git-push status

**[GitKraken](https://www.gitkraken.com/git-client)** - AI-powered git client that:
- Suggests context-aware fixes with explanations and confidence levels
- Provides conflict prevention by notifying of potential conflicts
- Offers options to resolve conflicts proactively

**[GitHub CLI with AI](https://www.everydev.ai/tools/github-cli-with-ai)** - Terminal integration that:
- Provides context-specific guidance for commands
- Generates commands based on current repository state
- Leverages AI assistance for GitHub services

**[Cargo (Rust)](https://doc.rust-lang.org/cargo/)** - Build tool with smart progress:
- Built-in rate limiting to avoid updating display too fast
- Detects terminal capabilities (in-place updates vs line-by-line)
- Disables progress bars in CI environments automatically
- Verbose flags for different levels of detail (--verbose, -vv for "very verbose")

### How Good CLIs Surface Relevant Context

**Branch and Repository Information:**
- Display current branch name in prompts when in git working directory
- Show divergence from remote (ahead/behind commit counts)
- Indicate dirty working tree status

**Work-in-Progress Context:**
- Files changed since last commit
- Logical groupings of changes (by directory or purpose)
- Related issues or PRs in flight

**Workflow State:**
- Stage in development process (planning, implementing, testing, reviewing)
- Blockers or dependencies
- Next expected action

**Historical Context:**
- Recent commit messages for style reference
- Time since last commit
- Commit frequency patterns

### Progressive Disclosure in Terminal Messages

**From [Nielsen Norman Group](https://www.nngroup.com/articles/progressive-disclosure/) and [Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/uxguide/ctrl-progressive-disclosure-controls):**

**Level 1: Essential Information (Always Shown)**
- Current state (uncommitted changes, unpushed commits)
- Primary action needed (commit, push)
- Critical blockers (merge conflicts, dirty workspace)

**Level 2: Helpful Context (Shown on Request or Periodically)**
- Suggested commit message
- Related issue/task information
- Time-based reminders

**Level 3: Advanced Details (Shown Only When Needed)**
- Full diff of changes
- Commit history
- Detailed workflow guidance

**Implementation Pattern:**
```
[Essential] 3 uncommitted files • Branch: feature/auth • Issue #42

[Helpful - periodic] Reminder: Commit focused changes frequently
[Advanced - on demand] Run 'git diff' to review changes
```

---

## 3. Git Workflow Patterns

### How Developers Typically Group Commits

**From [Conventional Commits](https://www.conventionalcommits.org/) and [Axolo Git Best Practices](https://axolo.co/blog/p/git-commit-messages-best-practices-examples):**

**Atomic Commits:**
- Break changes into small, cohesive commits
- Focus on a single task or feature per commit
- Commit related changes together to maintain atomicity

**Logical Boundaries:**
- Complete implementation of a single function/method
- Completion of a test case
- Fix for a specific bug
- Refactoring of a specific component

**Team Collaboration Pattern:**
- Commit before switching context
- Commit before taking breaks
- Commit at end of work session
- Commit when tests pass

### What Makes a Good Commit Message Suggestion

**From [Conventional Commits Specification](https://www.conventionalcommits.org/) and [GitKraken Best Practices](https://www.gitkraken.com/learn/git/best-practices/git-commit-message):**

**Format:**
```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

**Type Conventions:**
- `feat` – new features
- `fix` – bug fixes
- `docs` – documentation updates
- `chore` – changes that don't modify src or test files
- `refactor` – code refactoring
- `test` – test-related changes
- `style` – formatting, missing semi-colons, etc.

**Writing Style:**
- Use imperative mood: "Fix bug" not "Fixed bug" or "Fixes bug"
- Subject line: ~50 characters max
- Body: wrap at 72 characters
- Reference issues: "Fixes #123" or "Relates to #456"

**What Makes a Good Suggestion:**
- Infers type from changed files (test files → test, docs → docs)
- Extracts scope from changed directories/modules
- Proposes subject based on function names or obvious changes
- Includes issue reference if determinable from branch name or context

### When Should Tools Remind vs Stay Silent

**Remind When:**

1. **Crossing Logical Boundaries**
   - Completed set of related changes (all tests passing)
   - End of work session (time-based: 2+ hours since last commit)
   - Context switch (switching branches, closing IDE)

2. **Risk of Data Loss**
   - Uncommitted changes for extended period (30+ minutes)
   - System shutdown imminent
   - Large number of files changed (10+ files)

3. **Workflow Milestones**
   - Feature implementation complete
   - All tests passing after failures
   - Ready for code review

**Stay Silent When:**

1. **Active Development**
   - Frequent file saves within short periods (< 5 minutes)
   - Tests currently failing (developer in debugging mode)
   - Large refactoring in progress (many files changing rapidly)

2. **Intentional Work Patterns**
   - User just committed (< 5 minutes ago)
   - User explicitly suppressed reminders
   - User in interactive git operation (rebase, merge)

3. **Uncertain Context**
   - Unclear if changes are related or separate
   - Can't determine logical commit boundary
   - Changes span multiple unrelated concerns

**From UX Research on Notification Frequency:**
- Monitor user opt-out rates and feedback to gauge impact
- Excessive notifications in short time frame → notification fatigue
- Treat users with respect; provide clear value for each interruption

---

## 4. User Control Mechanisms

### Best Practices for Suppression Mechanisms

**From UX and Developer Tool Research:**

**Multi-Level Control:**

1. **Temporary Suppression**
   - "Snooze" for current work session
   - "Skip for this commit cycle"
   - Time-based (suppress for 1 hour)

2. **Contextual Suppression**
   - "Don't remind me on this branch"
   - "Don't remind me for this file type"
   - "Don't remind me during [specific workflow stage]"

3. **Global Suppression**
   - Disable all reminders
   - Disable specific reminder types
   - Reduce reminder frequency

**Implementation Patterns:**

```bash
# Interactive response to reminder
[c] Commit now
[s] Skip this reminder
[d] Disable reminders for 1 hour
[n] Never remind me on this branch
[q] Disable all commit reminders
```

### Temporary vs Permanent Disable Patterns

**Temporary Disable (Recommended for Most Cases):**

1. **Session-Based**
   - Disable until IDE/terminal closes
   - Disable until branch switches
   - Disable until next git command

2. **Time-Based**
   - Disable for 30 minutes
   - Disable for 1 hour
   - Disable until end of workday

3. **Condition-Based**
   - Disable until tests pass
   - Disable until file count < threshold
   - Disable until next logical boundary

**Permanent Disable (Requires Extra Confirmation):**

1. **Warning Before Permanent**
   - "Are you sure? This will disable reminders for all projects"
   - Provide easy re-enable instructions
   - Explain what behavior will change

2. **Easy Re-Enable**
   - Show re-enable command in disable confirmation
   - Provide command in help documentation
   - Include re-enable in CLI tool status output

3. **Granular Permanent Control**
   - Disable only specific reminder types
   - Keep critical reminders enabled (data loss prevention)
   - Allow per-project configuration

### Smart Rate-Limiting Approaches

**From [Microsoft Learn Rate Limiting Pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/rate-limiting-pattern) and Research:**

**Adaptive Rate Limiting:**
- Adjust limits based on current context
- Relax during low-activity periods
- Tighten during high-activity periods

**Context-Aware Thresholds:**

1. **Development Phase Detection**
   - Planning phase: fewer reminders
   - Active development: moderate reminders
   - Cleanup phase: more frequent reminders

2. **Activity Level Monitoring**
   - High activity (many commits): reduce reminder frequency
   - Low activity (few commits): increase reminder frequency
   - Inactive period: reminder on first change

3. **Success Rate Tracking**
   - If user commits after reminder: maintain frequency
   - If user ignores reminders: reduce frequency
   - If user manually suppresses: honor preference

**Rate Limiting Implementation:**

```python
# Example rate limiting logic
def should_show_reminder(context):
    # Minimum time between reminders
    if time_since_last_reminder < MIN_INTERVAL:
        return False

    # Adaptive threshold based on activity
    if commit_frequency > HIGH_ACTIVITY_THRESHOLD:
        interval = LONG_INTERVAL
    elif commit_frequency > MEDIUM_ACTIVITY_THRESHOLD:
        interval = MEDIUM_INTERVAL
    else:
        interval = SHORT_INTERVAL

    return time_since_last_commit > interval
```

**Best Practices for Rate Limiting:**

1. **Start Conservative**
   - Begin with longer intervals
   - Learn user's patterns over time
   - Adjust based on engagement

2. **Respect User Actions**
   - If user dismisses, wait longer before next reminder
   - If user acts on reminder, maintain frequency
   - If user configures interval, use exact setting

3. **Provide Visibility**
   - Show current rate limit settings in config
   - Explain why reminder appeared (or didn't)
   - Allow easy adjustment of thresholds

**From Cargo's Approach:**
- Built-in rate limiting to avoid updating display too fast
- Usually fine to call update methods as often as needed
- Rate limiter handles actual display frequency

---

## Implementation Recommendations for Agent OS

Based on this research, here are specific recommendations for Agent OS commit reminders:

### 1. Message Design

**Essential Information (Always Show):**
```
📋 Commit reminder: 3 files changed on feature/auth-system #42
```

**Actionable Suggestions:**
```
Suggested: git commit -m "feat(auth): implement user login #42"

[c] Commit with suggestion  [e] Edit message  [s] Skip  [?] Help
```

**Progressive Detail:**
```
Level 1: Basic state
Level 2: Suggested action (shown periodically)
Level 3: Full context (on request)
```

### 2. Context Awareness

**Detection Points:**
- Uncommitted changes for 20+ minutes
- Tests pass after implementation work
- 5+ related files changed
- End of work session (IDE close, terminal exit)
- Branch switch attempt with uncommitted changes

**Contextual Information:**
- Current branch and issue
- Related task from tasks.md
- Recent commit style for consistency
- Files changed grouped by concern

### 3. User Control

**Suppression Hierarchy:**
```
[1] Skip this reminder (once)
[2] Snooze 30 minutes
[3] Disable for this branch
[4] Disable for this session
[5] Disable all commit reminders (requires confirmation)
```

**Rate Limiting:**
- Default: remind every 20 minutes if uncommitted
- After dismiss: wait 40 minutes
- After multiple dismisses: wait 60 minutes
- After commit: reset to default

### 4. Smart Timing

**Do Remind:**
- Logical completion (tests passing, feature done)
- Extended uncommitted period (20+ min)
- Work session end detection
- Risk of data loss (system events)

**Stay Silent:**
- Recent commit (< 10 minutes ago)
- Active development (frequent saves)
- Tests currently failing
- Interactive git operation in progress
- User explicitly suppressed

### 5. Configuration

**User Settings:**
```yaml
commit_reminders:
  enabled: true
  min_interval: 20m
  max_interval: 60m
  show_suggestions: true
  auto_link_issues: true
  context_detail_level: medium  # low, medium, high
```

---

## Key Takeaways

1. **Value Over Noise**: Every interruption must provide clear value and actionable next steps
2. **Context is King**: Leverage branch, issue, task, and workflow context to make reminders relevant
3. **Progressive Disclosure**: Start simple, offer detail on request, never overwhelm
4. **Respect User Control**: Provide multiple levels of suppression with easy re-enable
5. **Smart Timing**: Detect logical boundaries; avoid interrupting focused work
6. **Adaptive Behavior**: Learn from user responses and adjust frequency accordingly

---

## References

### CLI Design Guidelines
- **clig.dev** - Comprehensive command-line interface guidelines
  https://clig.dev/

- **Evil Martians CLI UX Best Practices (2024)** - Progress display patterns
  https://evilmartians.com/chronicles/cli-ux-best-practices-3-patterns-for-improving-progress-displays

- **Thoughtworks CLI Design Guidelines** - Developer experience elevation
  https://www.thoughtworks.com/en-us/insights/blog/engineering-effectiveness/elevate-developer-experiences-cli-design-guidelines

### Notification Design
- **Toptal Notification Design Guide** - Comprehensive notification UX
  https://www.toptal.com/designers/ux/notification-design

- **Nielsen Norman Group - Progressive Disclosure** - Information architecture pattern
  https://www.nngroup.com/articles/progressive-disclosure/

- **Apple Human Interface Guidelines - Notifications** - Platform notification standards
  https://developer.apple.com/design/human-interface-guidelines/notifications

### Git Workflow Tools
- **git-remind by suin** - Desktop notifications for uncommitted/unpushed changes
  https://github.com/suin/git-remind

- **GitKraken** - AI-powered git client with context-aware assistance
  https://www.gitkraken.com/git-client

- **GitHub CLI Extensions** - gh-notify, gh-notifications, gh-dash
  https://github.com/meiji163/gh-notify

### Git Best Practices
- **Conventional Commits Specification** - Standard commit message format
  https://www.conventionalcommits.org/

- **Axolo Git Commit Messages Guide** - Best practices and examples
  https://axolo.co/blog/p/git-commit-messages-best-practices-examples

- **GitKraken Git Commit Best Practices** - Comprehensive guide
  https://www.gitkraken.com/learn/git/best-practices/git-commit-message

### Rate Limiting and User Control
- **Microsoft Learn - Rate Limiting Pattern** - Architectural patterns
  https://learn.microsoft.com/en-us/azure/architecture/patterns/rate-limiting-pattern

- **Cargo Documentation** - Rust build tool progress and rate limiting
  https://doc.rust-lang.org/cargo/

- **Heroku CLI** - Developer experience patterns
  https://devcenter.heroku.com/articles/heroku-cli

---

*This research was conducted on 2025-10-12 to inform Agent OS CLI interruption and notification design decisions.*
