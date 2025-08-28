# Changelog

All notable changes to Agent OS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Documentation Drift Detection Command** (#40)
  - `/update-documentation` command for detecting documentation drift
  - Normal mode for quick health checks of recent activity
  - `--deep` mode for comprehensive audit of all Agent OS documentation
  - Detects missing CHANGELOG entries, issues without specs, broken file references
  - Cross-references specs with GitHub issues and validates roadmap status
  - Evidence-based operation only (no fabrication)
  - Integrated into git workflow (Phase 4) for PR creation
  - Bats test suite with 14 comprehensive tests

### Changed
- Updated `workflow-modules/step-4-git-integration.md` to include mandatory documentation check
- PR template now includes Documentation Updates section
- `instructions/core/execute-task.md` already includes documentation sync step

## [4.0.0] - 2025-08-17

### Added
- **Evidence-Based Development (Anti-Fabrication)** (#35)
  - Evidence Guard CI workflow requires an "Evidence/Test Results/Verification" section in PRs
  - `scripts/testing-enforcer.sh` scans PR bodies for completion claims and enforces proof
- **No-Quick-Fixes Policy**
  - Quick Fix Guard CI workflow flags shortcut PRs without explicit approval/scope
  - `<quick_fix_gate>` added to `instructions/core/execute-task.md`
- **Context-Aware Workflow Enforcement** (#22, #38, #39)
  - `scripts/intent-analyzer.sh`, `scripts/context-aware-wrapper.sh`
  - `scripts/workspace-state.sh` with TTL-cached git/PR state
  - Allows maintenance on dirty workspaces; blocks new work until hygiene is clean
- **Project Configuration Memory** (#12, #36, #37)
  - `scripts/config-resolver.py`, `scripts/session-memory.sh`
  - `scripts/config-validator.sh`, `scripts/pre-command-guard.sh`
  - Resolves ports/package managers/startup commands with precedence and cache
- **Instruction Structure & Orchestrator**
  - `instructions/core/` and `instructions/meta/` restored as source of truth with XML tags
  - `instructions/core/execute-tasks.md` adds Phase 0 Repository Discovery Gate and PR evidence requirements
  - Added Phase 1.5 Deep Reality Check (Dev/Test/Prod) with citations; Phase 0 verification scripts pre-check; Phase 4 PR evidence-only fallback after repeated violations (PR #45)

### Changed
- **Versioning**: Canonical version file is `~/.agent-os/VERSION` (uppercase); CLI and docs updated
- **CLI**: Setup version variable set to `4.0.0`; `aos status` continues version checks against remote
- **README**: Added “What’s New in v4.0.0” summarizing the guardrails and rationale

### Notes
- Why: stop fabricated completion claims, prevent roadmap-bypassing shortcuts, maintain config consistency mid-session, and enforce senior-style discovery before building; these guardrails improve reliability and trust.

## [2.4.0] - 2025-08-15

### Changed
- **BREAKING: Refactored to Builder Methods Subagent Architecture** (#27)
  - Migrated from Python subagent modules to Claude Code native agent system
  - Agents now defined as markdown files in `~/.claude/agents/`
  - Instructions use `subagent=` attributes for automatic agent routing
  - Removed 4,400+ lines of Python code in favor of 1,000 lines of markdown

### Added
- **Native Claude Code Agent Integration**
  - Five Builder Methods agents installed to `~/.claude/agents/`
  - Automatic agent invocation through instruction step attributes
  - Seamless integration with Claude Code's Task tool

### Removed
- Python subagent implementation (`hooks/subagents/*.py`)
- Python detection and wrapper systems
- Manual override and user experience systems
- All Python-based subagent tests

### Improved
- **Simplicity**: Native Claude Code integration vs custom Python wrapper
- **Performance**: Direct agent invocation vs Python detection layer
- **Maintainability**: 75% less code to maintain
- **Compatibility**: Works with Claude Code's evolving agent system

## [2.3.0] - 2025-01-15

### Added
- **Builder Methods Subagents System**: 5 specialized AI agents for optimized development (#25)
  - `context-fetcher`: Intelligent codebase search and analysis
  - `date-checker`: Accurate date determination for specs
  - `file-creator`: Template-based file generation
  - `git-workflow`: Complete git operations and GitHub integration
  - `test-runner`: Multi-framework test execution
- **Automatic Subagent Detection**: Sub-millisecond (0.01ms) pattern matching
- **Context Optimization**: 25% reduction in token usage through intelligent routing
- **Task Tool Integration**: Transparent wrapper for Claude Code Task tool
- **Zero-Configuration Deployment**: Works out-of-the-box with no setup required

### Improved
- **Performance**: Subagent detection averages 0.01ms (100x faster than 10ms requirement)
- **Token Efficiency**: Specialized agents use 25% fewer tokens than general-purpose
- **Developer Experience**: Automatic routing means no manual agent selection needed
- **Installation**: Subagents now integrated into main setup.sh script

### Changed
- Version tracking moved to uppercase `VERSION` file (was `.version`)
- README updated with subagents as primary fork enhancement

## [2.2.0] - 2025-01-10

### Added
- **Bash Observation System**: Hook-based observation of Claude Code's native background execution
  - Pre-bash and post-bash hooks for command classification and reporting  
  - Observed command history stored in `observed-bash.jsonl`
  - Dashboard command for viewing command execution history
  - Notification system for gentle reminders about running processes
- **aos v4**: Unified CLI combining Agent OS management with Bash observation
  - All v3 features plus Bash observation dashboard
  - Single `aos` command for core functionality
  - Comprehensive status reporting and project management
- **Bash Observation Specification**: Complete planning document for hook-based observation

### Improved
- **Developer Workflow**: Enable non-blocking development with Claude Code's native backgrounding
- **Command Visibility**: Observe all Bash executions through hook system
- **Error Reporting**: Automatic detection and reporting of command failures

## [2.1.0] - 2025-01-10

### Added
- **aos v3**: Comprehensive project validation
  - Separate tracking of global vs project status
  - Detection of outdated project components
  - Actionable status reports showing what needs updating
  - Smart validation of Claude commands, Cursor rules, and hooks

### Improved
- **Status Command**: Now validates both Agent OS installation AND project setup
- **Better Diagnostics**: Shows specific issues that need fixing
- **Quick Actions**: Provides exact commands to fix detected issues

## [2.0.0] - 2025-01-10

### Added
- **Workflow Enforcement Hooks v2 & v3**: Improved hooks with better compound command handling
- **Update System**: Comprehensive update guide and `check-updates.sh` script
- **Smart `aos` Alias v2**: Improved interactive setup with smart updates
- **Version Tracking**: Proper VERSION file and release system
- **Documentation**: 
  - UPDATE_GUIDE.md for handling updates
  - PRODUCT_DOCS_TRACKING.md for gitignore best practices
  - Expanded workflow modules with better enforcement
- **Testing Reminders**: Hook system to prevent false completion claims (#9)

### Changed
- **Hook Improvements**:
  - TodoWrite no longer blocks as "new work"
  - Better handling of compound git commands
  - Smart detection of documentation updates (v3)
  - Allow file operations (chmod, mv, rm, cp) with git
- **Workflow Modules**: Enhanced with stricter validation requirements
- **Installation Process**: Quieter output, better error handling

### Fixed
- Compound command blocking in hooks (e.g., `chmod +x && git add && git commit`)
- Redundant update messages in `aos` alias
- False completion claims without actual testing
- Configuration amnesia issues (#12)

### Security
- Hooks now properly validate work before allowing completion claims
- Stricter enforcement of testing requirements

## [1.1.0] - 2025-01-07

### Added
- Initial Claude Code hooks implementation
- Workspace hygiene checking
- Task status validation
- GitHub workflow integration

### Changed
- Enhanced error handling in setup scripts
- Improved workspace validation

## [1.0.0] - 2024-12-15

### Added
- Initial fork from Builder Methods Agent OS
- Tab indentation preference
- Python/React stack defaults
- GitHub Issues workflow enforcement
- Basic installation scripts

---

## Release Types

- **Major (X.0.0)**: Breaking changes, architectural updates
- **Minor (0.X.0)**: New features, backwards compatible
- **Patch (0.0.X)**: Bug fixes, minor improvements