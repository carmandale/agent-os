# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Context

This is **Agent OS** - the framework itself that enables AI-assisted development workflows. Uniquely, Agent OS also uses itself for its own development (eating its own dog food). This means:
- It IS the Agent OS framework that other projects depend on
- It ALSO uses Agent OS workflows for its own development
- Changes here affect both the framework AND how it develops itself

### Agent OS Documentation (Self-Usage)

#### Product Context
- **Mission & Vision:** @.agent-os/product/mission.md
- **Technical Architecture:** @.agent-os/product/tech-stack.md
- **Development Roadmap:** @.agent-os/product/roadmap.md
- **Decision History:** @.agent-os/product/decisions.md

#### Development Standards
- **Code Style:** @~/.agent-os/standards/code-style.md
- **Best Practices:** @~/.agent-os/standards/best-practices.md

#### Project Management
- **Active Specs:** @.agent-os/specs/
- **Spec Planning:** Use `@~/.agent-os/instructions/core/create-spec.md`
- **Tasks Execution:** Use `@~/.agent-os/instructions/core/execute-tasks.md`

## CRITICAL: Development Workflow

### Repository Structure

**SOURCE CODE** (what we develop and edit):
- `commands/` - Command definitions  
- `hooks/` - Hook scripts (Python & shell)
- `instructions/` - Workflow instructions
- `scripts/` - Utility scripts
- `tools/` - CLI tools (aos command)
- `setup.sh` and setup scripts
- `CLAUDE.md` (this file)

**PROJECT'S AGENT OS CONFIG** (part of repo, but managed by workflows):
- `.agent-os/` - This project's Agent OS config
- `.claude/` - This project's Claude settings
- `.cursor/` - This project's Cursor settings

**INSTALLATION LOCATIONS** (deployed by setup scripts, NEVER edit directly):
- `~/.agent-os/` - User's global Agent OS installation
- `~/.claude/settings.json` - User's Claude Code configuration (per [Anthropic docs](https://docs.anthropic.com/en/docs/claude-code/settings))

### NEVER EDIT
1. **User's home directory files** (`~/.agent-os/`, `~/.claude/`, etc.)
2. **Project's installation files** (`.agent-os/`, `.claude/`, `.cursor/` in the repo)

### REQUIRED WORKFLOW
```
1. PLAN - Discuss changes needed
2. EDIT SOURCE - Modify source files in repo ONLY
3. TEST - Run test scripts
4. COMMIT - Commit to repo
5. PUSH - Push to GitHub
6. INSTALL - Run setup.sh from GitHub (the "real" install)
7. VERIFY - Test that installation works
```

**All changes must go through source code → installation scripts → deployed files**

## Build and Test Commands

```bash
# Installation and Setup
./setup.sh                          # Install Agent OS base system
./setup.sh --overwrite-instructions # Update instruction files
./setup.sh --overwrite-standards    # Update standards files
./setup-claude-code.sh              # Install Claude Code commands
./update-local-install.sh           # Update local installation from repo

# Health Check
./check-agent-os.sh                 # Verify Agent OS installation

# Testing
./test-workflow-detection.sh        # Test workflow detection system
python validate_subagents.py        # Validate subagent definitions
bats tests/test-update-documentation.bats  # Test documentation drift detection

# Development Tools
aos status                          # Check Agent OS installation status
aos update                          # Update Agent OS components
aos run "command"                   # Run command in background
aos tasks                           # List background tasks
aos logs <task-id>                  # View task logs

# Documentation Commands
/update-documentation               # Check for documentation drift (dry-run)
/update-documentation --deep        # Comprehensive documentation audit
/update-documentation --diff-only   # Show git diff without analysis
/update-documentation --create-missing  # Create missing docs (use with caution)
```

> Codex CLI shares the same Agent OS command set. `setup.sh` now installs the markdown prompts into `$CODEX_HOME/prompts` (default `~/.codex/prompts`). Set `CODEX_HOME` before running if you use a custom location, or pass `--skip-codex-commands` to omit Codex support on machines that don't run it.

## Architecture Overview

### Core Directory Structure
- **`instructions/`** - Core workflow instruction files (plan-product.md, create-spec.md, execute-tasks.md, analyze-product.md)
- **`workflow-modules/`** - Modular workflow components (step-1 through step-4)
- **`standards/`** - Default development standards templates
- **`claude-code/agents/`** - Native Claude Code agent definitions (Builder Methods architecture)
- **`hooks/`** - Claude Code hooks for workflow enforcement
- **`tools/`** - CLI tools including aos command
- **`scripts/`** - Dynamic workflow validation scripts

### Subagent System (v2.4.0)
Agent OS uses Builder Methods' native Claude Code agent architecture with 5 specialized agents:
- **context-fetcher** - Codebase search and documentation retrieval
- **date-checker** - Accurate date determination for specs
- **file-creator** - Template-based file generation
- **git-workflow** - Git operations and GitHub integration  
- **test-runner** - Multi-framework test execution

Agents are triggered via `subagent="agent-name"` XML attributes in instruction files.

### Installation Flow
1. **User Level**: `~/.agent-os/` - Global standards and instructions
2. **Project Level**: `.agent-os/` - Project-specific overrides
3. **Claude Agents**: `~/.claude/agents/` - Subagent definitions

### Key Design Principles
- **Shell-based**: All core functionality in bash scripts for universal compatibility
- **Markdown-driven**: Instructions and documentation in markdown format
- **Tool-agnostic**: Works with Claude Code, Cursor, or any AI assistant
- **Git-first**: All workflows require GitHub issues and proper branching

## Critical Implementation Notes

### When Modifying Shell Scripts
- Must work on macOS and Linux (use portable bash)
- Use `curl` for downloads (universally available)
- Preserve user customizations with --overwrite flags
- Test on clean systems without dependencies

### When Updating Instruction Files
- Maintain XML structure for parsing by AI assistants
- Include `subagent=` attributes for automatic delegation
- Add explicit "SUBAGENT: Use the X subagent" instructions
- Follow the exact template patterns (they're parsed programmatically)

### When Working with Subagents
- Agent definitions use YAML frontmatter with name, description, tools
- Agents must be in `~/.claude/agents/` to be recognized
- Update both XML attributes AND instruction text for invocation
- Test with `validate_subagents.py` after changes

### Version Management
- Version tracked in `VERSION` file
- Follow semantic versioning (MAJOR.MINOR.PATCH)
- Update roadmap.md when completing features
- Document decisions in decisions.md

### Background Task Management
- **NEVER create aos-background tool** - It was deprecated in favor of hooks
- Agent OS observes Claude Code's native backgrounding, doesn't manage processes
- Use `aos dashboard` and `aos notify` for Bash observation features
- See docs/IMPORTANT-NO-AOS-BACKGROUND.md for details

## Evidence-Based Development Protocol

When working on Agent OS itself:

1. **Show actual command output** - Never claim "tests pass" without showing output
2. **Verify file operations** - After creating/modifying files, show with `ls -la` or `cat`
3. **Prove functionality** - Test changes with real Agent OS workflows
4. **Document evidence** - Include command outputs in PR descriptions

## CRITICAL: Verification Requirements (Anti‑fabrication)

### NEVER simulate or fabricate results
- When asked to analyze or compare files, you MUST show actual file contents or excerpts
- When running ANY command, you MUST show the complete, actual terminal output
- If a file doesn't exist, show the real error message from the system
- If instructed to use subagents, you MUST actually invoke them, not simulate

### Required workflow
1. One command at a time — show full output before proceeding
2. Verify file existence with `ls -la` (or equivalent) before reading/analyzing
3. Use explicit tools for comparisons (e.g., `diff`, `git diff`) and paste excerpts
4. Record evidence in the conversation or PR description

### Forbidden behaviors
- Claiming to have run commands without showing output
- Summarizing file contents without showing actual data
- Making up differences or improvements without concrete evidence
- Ignoring explicit instructions about using specific subagents or tools

## CRITICAL: No‑Quick‑Fixes Policy

- Roadmap/Spec‑first: Prefer planned infrastructure and architecture over expedient workarounds
- Shortcuts require explicit user opt‑in with:
  - Scope/time‑box and rollback plan
  - Tracking issue link
  - Tests that expose the limitation (so it’s visible and not silently passing)
- Do not add default fallbacks that mask missing proper integrations

Example verification:
```bash
# After modifying setup.sh
./setup.sh --overwrite-instructions  # Show full output
ls -la ~/.agent-os/instructions/     # Verify files installed
grep "SUBAGENT:" ~/.agent-os/instructions/plan-product.md  # Verify content
```

## Meta-Development Considerations

When making changes to Agent OS:
- **User Impact**: How will this affect existing Agent OS installations?
- **Backward Compatibility**: Will existing workflows still work?
- **Cross-Platform**: Test on both macOS and Linux environments
- **Documentation**: Update README.md, relevant instruction files, and roadmap
- **Installation**: Ensure setup.sh properly installs new components

## Current Development Focus

Check `.agent-os/product/roadmap.md` for active development priorities. Key areas:
- Phase 0.5: Critical quality enforcement (Issues #6-9, #22)
- Verification protocol implementation
- Enhanced evidence-based execution

## Workflow Instructions

When asked to work on Agent OS:

1. **First**, check @.agent-os/product/roadmap.md for current priorities
2. **Then**, follow the appropriate instruction file:
   - For new features: @.agent-os/instructions/core/create-spec.md
   - For tasks execution: @.agent-os/instructions/core/execute-tasks.md
3. **Always**, adhere to the standards in the files listed above

### Important Notes
- Product-specific files in `.agent-os/product/` override any global standards
- User's specific instructions override (or amend) instructions found in `.agent-os/specs/...`
- Always adhere to established patterns, code style, and best practices documented above

## Workflow Enforcement

All work MUST follow this flow:
1. Create/reference GitHub issue
2. Create feature branch from issue
3. Follow TDD approach (tests first)
4. Verify with actual output (not claims)
5. Create PR with evidence of working functionality
6. Update roadmap if feature completed

Never mark work complete without:
- Showing test output
- Demonstrating functionality
- Creating proper PR with issue reference
