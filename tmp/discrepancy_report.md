# Agent OS Internal Discrepancy Report

## Executive Summary
- **Installed version** (July 29, 2025): WORKING in production
- **Repo version** (Aug 17-18, 2025): BROKEN with recent "improvements"
- **27 files installed** vs **44 files in repo** (17 new untested files)

## Working (Installed) vs Broken (Repo)

### Critical Shell Scripts

**File: stop-hook.sh**
- Installed checksum: 457a6228a2d48785f93f5a795ba18c88
- Repo checksum: DIFFERENT (complete rewrite)
- Key difference: Repo removed `set -e`, changed sourcing, new untested logic
- Risk: **HIGH** - Core workflow enforcement broken
- Recommendation: **KEEP INSTALLED** - working in production

**File: post-tool-use-hook.sh**
- Installed checksum: 5eb0e8a766aca3f49f59cf27e3644e98
- Repo checksum: DIFFERENT (133 lines → 197 lines)
- Key difference: Repo version more complex, removed error handling
- Risk: **HIGH** - Auto-commit functionality at risk
- Recommendation: **KEEP INSTALLED** - simpler and working

**File: user-prompt-submit-hook.sh**
- Installed checksum: b1aee1c7b1974a4fec71efbddb387370
- Repo checksum: DIFFERENT (128 lines → 172 lines)
- Key difference: Added trap handler, removed `set -e`
- Risk: **HIGH** - Context injection broken
- Recommendation: **KEEP INSTALLED** - proven stable

### Missing Critical Files (Not Installed)

**File: pre-bash-hook.sh**
- Status: EXISTS in repo, NOT installed
- Risk: **MEDIUM** - Bash observation not working
- Recommendation: **TEST BEFORE INSTALLING**

**File: post-bash-hook.sh**
- Status: EXISTS in repo, NOT installed  
- Risk: **MEDIUM** - Bash result reporting missing
- Recommendation: **TEST BEFORE INSTALLING**

**File: notify-hook.sh**
- Status: EXISTS in repo, NOT installed
- Risk: **LOW** - Optional notifications
- Recommendation: **SKIP** - not critical

### Python Scripts

**File: workflow-enforcement-hook.py**
- Installed checksum: cc3f25e67b673a637f00c0f3f92c3c0e
- Repo checksum: DIFFERENT (46 lines changed)
- Recent changes: Aug 17 - JSON decision returns, hygiene blocks
- Risk: **HIGH** - Core gating logic modified
- Recommendation: **KEEP INSTALLED** until tested

**File: context_aware_hook.py**
- Status: IDENTICAL checksums (f84be85a38f46ccab1c2592a1b2baf2e)
- Risk: **NONE**
- Recommendation: **KEEP AS IS**

## Documentation Cleanup Needed

### Outdated Files to DELETE

**File: docs/BUILDER_METHODS_EVALUATION.md**
- Why outdated: Subagents already implemented (v2.4.0)
- Action: **DELETE** - implementation complete

**File: docs/SUBAGENT_IMPLEMENTATION_SPEC.md**
- Why outdated: Superseded by implemented system
- Action: **DELETE** - spec fulfilled

**File: docs/BACKGROUND_TASKS_SPEC.md**
- Why outdated: Background tasks complete (v2.2.0)
- Action: **DELETE** - already implemented

### Files to UPDATE

**File: docs/UPDATE_GUIDE.md**
- Current state: May reference old hooks
- Reality: Hooks have diverged significantly
- Action: **UPDATE** to warn about version mismatch

**File: .agent-os/product/roadmap.md**
- Current state: Shows hooks as complete
- Reality: Hooks need reconciliation
- Action: **ADD** note about reconciliation needed

## Consolidation Opportunities

### Hook Documentation (Too Many Files)
These files say similar things:
- `hooks/README.md`: General hooks documentation
- `hooks/README-context-aware-hook.md`: Specific feature
- `hooks/instructions/*.md`: More documentation
- `.agent-os/specs/2025-08-18-claude-code-hooks-improvement-#62/research-report.md`: Analysis

Action: **MERGE** into single authoritative `hooks/README.md`

### Problem Documentation (Redundant)
- `docs/CLAUDE_PROBLEMS_001.md`: 32k of problems
- `docs/CLAUDE_PROBLEMS_002.md`: 4.1k more problems
- `docs/KNOWN_ISSUES.md`: 2.5k of issues

Action: **MERGE** into `docs/KNOWN_ISSUES.md` with clear sections

## Root Cause Analysis

1. **Recent commits (Aug 17-18)** attempted to "fix" hooks with:
   - JSON decision returns
   - Hygiene blocking
   - Project-aware delegation
   
2. **Breaking changes**:
   - Removed `set -e` error handling
   - Changed function signatures
   - Added untested complexity

3. **Installation disconnect**:
   - No automatic update mechanism
   - Files copied once on July 29
   - Repo evolved without testing in production

## Risk Assessment

**CRITICAL FINDING**: The working production hooks from July 29 should be preserved. Recent repo changes are untested and potentially breaking.

**Recommendation**: Create a `hooks-stable/` directory with working versions before any reconciliation.