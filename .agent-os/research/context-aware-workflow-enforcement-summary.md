# Context-Aware Workflow Enforcement: Executive Summary

> Research Date: 2025-10-15
> Full Report: `context-aware-workflow-enforcement-best-practices.md`
> Related Issues: #22, #37, #98

## Purpose

This research informs Agent OS's development of intelligent workflow enforcement that distinguishes active maintenance work from new feature development, providing context-aware commit reminders without disrupting developer flow.

## Key Findings

### 1. Context Awareness is Critical

**Industry Data:**
- 65% of developers report AI tools "miss relevant context" as primary frustration
- #1 requested improvement: "better contextual understanding" (26% of all votes)
- Hallucinations and quality issues often stem from poor context awareness

**Implication for Agent OS:** Time-based heuristics alone create false positives. Must combine multiple context signals.

### 2. Developer Flow State is Fragile

**Research Findings:**
- Interruption recovery time: 20-60 minutes
- Developers get only ONE 2-hour uninterrupted session per day
- Self-interruptions (like commit reminders) are MORE disruptive than external ones

**Implication for Agent OS:** Trigger reminders only at natural breakpoints (end of session, branch switch), never during active editing.

### 3. Time-Based Heuristics Standards

**Industry Benchmarks:**

| Use Case | Threshold | Authority |
|----------|-----------|-----------|
| Idle detection (low-risk) | 15-30 minutes | OWASP |
| Idle detection (high-value) | 2-5 minutes | OWASP |
| Active work indicator | <30 minutes since activity | Development tools |
| Stale work flag | >24 hours since last commit | Git conventions |
| Abandoned work flag | >7 days since last commit | GitHub patterns |

**Implication for Agent OS:** Use 30-minute threshold for detecting "no recent activity", then examine context before taking action.

### 4. Git Porcelain Format is Essential

**Why:**
- Guaranteed stable across Git versions
- Unaffected by user configuration
- Designed specifically for script parsing

**Commands:**
```bash
git status --porcelain              # Detect changes
git status --porcelain=v2 --branch  # Include branch info
git for-each-ref --sort=-committerdate  # Branch activity
```

**Implication for Agent OS:** Never parse human-readable git output; always use porcelain format.

### 5. Hooks Must Be Fast and Clear

**Industry Standards:**
- Target: <100ms for context extraction
- Maximum: 10 seconds for any hook
- Requirement: Clear, actionable error messages

**Anti-Pattern:** Slow or opaque hooks get bypassed with `--no-verify`

**Implication for Agent OS:** Cache context (5-minute TTL), provide explicit next steps in all messages.

## Recommended Architecture

### Hybrid Time + Context Detection

```
Step 1: Fast Time Check (5ms)
  └─> If last activity < 30 min → SKIP (active work)
  └─> If last activity > 30 min → CONTINUE

Step 2: Context Analysis (cached, 50-100ms)
  └─> Git status (dirty/clean)
  └─> Branch info (name, last commit)
  └─> PR status (open/draft/merged)
  └─> Issue references

Step 3: Decision Logic
  └─> Dirty + active PR = ACTIVE (no action)
  └─> Clean + old commits = IDLE (gentle reminder)
  └─> Dirty + old commits = STALE (stronger reminder)
  └─> Merged PR + dirty = CLEANUP REQUIRED (block new work)
```

### Progressive Reminder Strategy

| Level | Trigger | Action | Tone |
|-------|---------|--------|------|
| **Nudge** | 2 hours uncommitted | Gentle suggestion | Informational |
| **Reminder** | 4 hours uncommitted | Explicit reminder | Encouraging |
| **Warning** | 24 hours uncommitted | Strong recommendation | Urgent |
| **Block** | New work without cleanup | Prevent action | Mandatory |

### Context Indicators

**High-Confidence Active Work:**
1. Uncommitted changes present (dirty workspace)
2. Recent commits (<4 hours ago)
3. Open draft PR on current branch
4. Recent file modifications (<2 hours)
5. Linked active issue

**High-Confidence Abandoned Work:**
1. Clean workspace + no commits in 7+ days
2. Merged PR but still on feature branch
3. Closed issue with uncommitted changes
4. No activity in past week

## Implementation Recommendations

### 1. Context Extraction Performance

**Target Benchmarks:**

| Operation | Target | Maximum |
|-----------|--------|---------|
| Check dirty status | <5ms | 10ms |
| Get branch name | <5ms | 10ms |
| Get last commit date | <10ms | 25ms |
| Check PR status | <50ms | 100ms |
| **Total context** | **<100ms** | **200ms** |

**Cache Strategy:**
- TTL: 5 minutes
- Invalidate on: commit, branch switch, file changes
- Storage: `/tmp/agent-os-context-$UID.json`

### 2. Stop-Hook Context Logic

```bash
IF uncommitted_changes THEN
  IF last_commit < 2_hours THEN
    → "💡 Consider committing recent work"
  ELSIF last_commit < 24_hours THEN
    → "📋 Uncommitted work from today - please commit"
  ELSE
    → "⚠️ STALE: Commit or stash before losing context"
  ENDIF
ELSIF open_pr THEN
  → "✅ Clean workspace. Review and merge PR"
ELSIF active_issue THEN
  → "📌 Working on issue - ready for next session"
ELSE
  → "✅ Clean workspace. No active work."
ENDIF
```

### 3. Pre-Task Validation

**Before starting new feature work:**

1. Check for uncommitted changes → BLOCK if present
2. Check for open PR on current branch → WARN, allow override
3. Verify clean workspace → BLOCK if dirty
4. Create GitHub issue → BLOCK if missing

**Philosophy:** Block when starting NEW work, allow flexibility during MAINTENANCE.

### 4. Message Templates

**Good Message Structure:**
```
[Icon] [Clear statement of situation]

[Context: What was detected]

[Action Required/Recommended:]
  • Specific command to run
  • What it does
  • Expected outcome

[Optional: Why this matters]
```

**Example:**
```
⚠️  Uncommitted changes detected from 2 days ago

Context:
  • 12 modified files on feature/user-auth branch
  • Last commit: 2025-10-13 (48 hours ago)
  • Related to issue #123

Action Required:
  1. Review changes: git status
  2. Commit work: git add . && git commit -m "feat: auth middleware #123"
  3. OR stash for later: git stash save "WIP: auth middleware"

Why: Uncommitted work risks being lost or forgotten between sessions.
```

## Shell Script Patterns

### Detect Dirty Workspace

```bash
if [ -n "$(git status --porcelain)" ]; then
  echo "dirty"
else
  echo "clean"
fi
```

### Get Hours Since Last Commit

```bash
last_commit=$(git log -1 --format=%ct 2>/dev/null || echo "0")
now=$(date +%s)
hours=$(( ($now - $last_commit) / 3600 ))
echo "$hours"
```

### Get Current Branch

```bash
# Most reliable for scripts
branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
```

### List Branches by Activity

```bash
git for-each-ref --sort=-committerdate \
  --format='%(committerdate:relative) %(refname:short)' \
  refs/heads/
```

### Check for Open PR

```bash
current_branch=$(git symbolic-ref --short HEAD)
pr_json=$(gh pr list --head "$current_branch" --json number,state 2>/dev/null)

if [ -n "$pr_json" ]; then
  pr_number=$(echo "$pr_json" | jq -r '.[0].number')
  echo "PR #$pr_number exists"
fi
```

## Anti-Patterns to Avoid

1. ❌ **Interrupting active flow** - Only remind at natural breakpoints
2. ❌ **Slow hooks** - Must be <100ms to avoid frustration
3. ❌ **Opaque failures** - Always explain what, why, how to fix
4. ❌ **Rigid time boundaries** - Use context to refine decisions
5. ❌ **Blocking maintenance** - Only block NEW feature work, not fixes
6. ❌ **Uncached context** - Cache for 5 minutes to avoid overhead
7. ❌ **False positives** - Combine multiple signals before flagging
8. ❌ **Non-bypassable enforcement** - Soft locally, hard in CI

## Success Metrics

### Quantitative Targets

- Context extraction <100ms (p95)
- <5% false positives (flagged as abandoned when active)
- <2% false negatives (missed abandoned work)
- Hook bypass rate <10% (indicates user trust)

### Qualitative Goals

- User feedback: "Helpful, not hindering"
- Messages are "clear and actionable"
- Increased commit frequency (better hygiene)
- Reduced PR cleanup time

## Next Steps

1. **Review** with development team
2. **Prioritize** recommendations for implementation
3. **Create** detailed technical spec
4. **Implement** in phases:
   - Phase 1: Foundation (context extraction, caching)
   - Phase 2: Decision logic (progressive reminders)
   - Phase 3: Hook integration (stop-hook, pre-task)
   - Phase 4: Optimization (performance, caching)
   - Phase 5: Polish (UX refinement, documentation)

## Key References

### Most Valuable Sources

1. **OWASP Session Management** - Industry-standard timeout thresholds
2. **Stack Overflow: Developer Flow State** - Research on interruption costs
3. **Atlassian Git Hooks Tutorial** - Best practices for hook implementation
4. **Qodo: State of AI Code Quality 2025** - Context awareness as #1 need
5. **Git Documentation: Porcelain Format** - Stable parsing specification

### Essential Tools

1. **pre-commit** (pre-commit.com) - Most popular hook framework
2. **GitHub CLI** (gh) - PR and issue automation
3. **git-wip** (bartman/git-wip) - WIP branch management pattern
4. **commitlint** - Commit message validation

## Conclusion

Context-aware workflow enforcement requires **hybrid time + context detection** with **progressive escalation** and **fast, cached context extraction**. The key is balancing automation (preventing bad states) with flexibility (allowing legitimate maintenance work) while respecting developer flow state.

**Core Principle:** Use time thresholds for initial detection, then examine context to make intelligent decisions about when to remind, warn, or block. Always provide clear, actionable guidance.

---

**Document Version:** 1.0
**Full Research:** `context-aware-workflow-enforcement-best-practices.md` (12,000+ words)
**Implementation Guide:** See "Appendix A: Quick Reference Shell Scripts" in full report
