<img width="1280" height="640" alt="agent-os-og" src="https://github.com/user-attachments/assets/e897628e-7063-4bab-a69a-7bb6d7ac8403" />

## Your system for spec-driven agentic development.

[Agent OS](https://buildermethods.com/agent-os) transforms AI coding agents from confused interns into productive developers. With structured workflows that capture your standards, your stack, and the unique details of your codebase, Agent OS gives your agents the specs they need to ship quality code on the first try—not the fifth.

---

### About This Fork

This is an enhanced fork of the original [Agent OS by Builder Methods](https://github.com/buildermethods/agent-os). We're building on Brian Casel's excellent foundation to add:

- **🤖 Native Claude Code Agents**: Builder Methods' 5 specialized agents integrated directly with Claude Code
- **Background Task Management**: Run development tasks (builds, tests, servers) in background without blocking AI workflows
- **GitHub Issues Workflow Enforcement**: Strict requirement for issue-based development with automated tracking
- **Enhanced CLI Tools**: Unified `aos` command with comprehensive project management and task monitoring
- **Tab Indentation**: Preference for tabs over spaces in all generated code
- **Python/React Stack Defaults**: Updated tech stack templates for Python backend (FastAPI/Django) and React frontend development
- **Enhanced Workflow Automation**: Additional hooks and integrations for Claude Code and other AI assistants
- **Improved Error Handling**: More robust workspace hygiene checks and recovery mechanisms

All core Agent OS functionality remains intact, with these enhancements making it even more powerful for professional development teams.

Use it with:

✅ Claude Code, Cursor, or any other AI coding tool.

✅ New products or established codebases.

✅ Big features, small fixes, or anything in between.

✅ Any language or framework.

---

## Quick Start

### Installation
```bash
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash
```

### Background Task Management (New!)
```bash
# Install the aos CLI tool
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/tools/install-aos-alias.sh | bash

# Run dev server in background
aos run "npm run dev"

# List running tasks
aos tasks

# Monitor task output
aos monitor <task-id>

# View logs
aos logs <task-id>

# Stop a task
aos stop <task-id>
```

### AI Assistant Setup
```bash
# For Claude Code
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup-claude-code.sh | bash

# For Cursor
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup-cursor.sh | bash
```

---

### Features

#### 🤖 Native Claude Code Agents (v2.4.0)
- **Builder Methods Architecture**: 5 specialized agents integrated with Claude Code
  - `context-fetcher`: Intelligent codebase search and documentation retrieval
  - `date-checker`: Accurate system date determination for specs
  - `file-creator`: Template-based file generation from structured specs
  - `git-workflow`: Complete git operations and GitHub integration
  - `test-runner`: Multi-framework test execution across languages
- **Native Integration**: Uses Claude Code's built-in agent system via `subagent=` attributes
- **Automatic Invocation**: Agents triggered automatically during workflow execution
- **Zero Configuration**: Installed to `~/.claude/agents/` and work immediately

#### 🚀 Background Task Management
- **Non-blocking development**: Keep working while builds/tests run
- **Task monitoring**: Real-time log viewing and process management  
- **Error debugging**: Automatic detection and troubleshooting
- **Unified CLI**: All functionality through single `aos` command

#### 📋 Structured Workflows
- **Product Planning**: Initialize projects with mission, roadmap, and tech stack
- **Feature Specification**: Create detailed specs with tasks and acceptance criteria
- **Task Execution**: TDD-focused implementation with quality gates
- **Git Integration**: Automatic PR creation with issue linking

#### 🛡️ Quality Assurance
- **Workflow Enforcement**: Hooks prevent incomplete work and ensure testing
- **Reality Checking**: Validation of task status against actual implementation
- **Testing Requirements**: Mandatory verification before completion claims

### What's New in v4.0.0

- **Evidence-Based Development (Anti-Fabrication)**
  - Evidence Guard CI (`.github/workflows/evidence-guard.yml`) blocks PRs that claim completion without an "Evidence/Test Results/Verification" section.
  - `scripts/testing-enforcer.sh` scans PR bodies for completion language and requires concrete proof (test output, screenshots, command results).

- **No-Quick-Fixes Policy Enforcement**
  - Quick Fix Guard CI (`.github/workflows/quickfix-guard.yml`) flags PRs that attempt shortcuts without explicit approval and scope.
  - `instructions/core/execute-task.md` includes a `<quick_fix_gate>` to prevent roadmap-bypassing work.

- **Context-Aware Workflow Enforcement (Spec #22)**
  - `scripts/intent-analyzer.sh` classifies intent (maintenance vs new work).
  - `scripts/workspace-state.sh` provides TTL-cached git/PR state.
  - `scripts/context-aware-wrapper.sh` allows maintenance with a dirty workspace, blocks new work until hygiene is clean; supports override via `AGENT_OS_NEW_WORK=1`.

- **Project Configuration Memory (Spec #12)**
  - `scripts/config-resolver.py` resolves ports/package managers from `.agent-os/product/tech-stack.md`, `.env`, `.env.local`, `start.sh` with precedence.
  - `scripts/session-memory.sh` caches and exports config with TTL/mtime invalidation.
  - `scripts/config-validator.sh` and `scripts/pre-command-guard.sh` validate upcoming commands against project config.

- **Instruction Structure & Orchestrator Updates**
  - Reintroduced `instructions/core/` and `instructions/meta/` as single source of truth; XML tag structure for machine-readable execution.
  - `instructions/core/execute-tasks.md` now includes a mandatory Phase 0 Repository Discovery Gate and stricter quality/PR evidence requirements; single-task flow is handled by `instructions/core/execute-task.md`.

- **CLI Versioning & Status**
  - Canonical version file is `~/.agent-os/VERSION` (uppercase). `aos status` compares local vs remote and reports currency.

Why these changes: to stop fabricated success claims, prevent shortcuts that diverge from the roadmap, maintain consistent project config mid-session, and enforce senior-style discovery before building. These guardrails significantly improve reliability and trust.

---

### Documentation & Installation

Docs, installation, useage, & best practices 👉 [It's all here](https://buildermethods.com/agent-os)

#### Core Slash Commands (Claude Code)

```bash
# Documentation updater - detects drift and provides actionable recommendations
/update-documentation               # Default: dry-run mode for safe operation
/update-documentation --dry-run     # Quick health check of recent activity
/update-documentation --deep        # Comprehensive audit of all Agent OS docs
/update-documentation --diff-only   # Show only git diff without analysis
/update-documentation --create-missing  # Create minimal scaffolds for missing docs

# Features:
# - Detects missing CHANGELOG entries for recent commits
# - Identifies open issues without corresponding specs
# - Validates file references in documentation
# - Cross-references specs with GitHub issues
# - Checks roadmap completion status
# - Evidence-based operation only (no fabrication)

# Install via: curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup-claude-code.sh | bash
```

---

### Created by Brian Casel @ Builder Methods

Created by Brian Casel, the creator of [Builder Methods](https://buildermethods.com), where Brian helps professional software developers and teams build with AI.

Get Brian's free resources on building with AI:
- [Builder Briefing newsletter](https://buildermethods.com)
- [YouTube](https://youtube.com/@briancasel)
