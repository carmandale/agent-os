# Spec Requirements Document

> Spec: Project Configuration Amnesia Resolution
> Created: 2025-07-30
> GitHub Issue: #12
> Status: Planning

## Overview

Implement a comprehensive project configuration memory system to eliminate Claude Code's amnesia about project-specific settings (ports, package managers, startup commands), ensuring consistent AI behavior that respects established project patterns and configurations.

## User Stories

### Amnesia-Free Development Experience

As a developer using Agent OS with Claude Code, I want Claude to remember and respect my project's specific configuration choices (ports, package managers, startup commands), so that I don't have to repeatedly correct the same configuration mistakes in every session.

**Current Problem:** Claude consistently forgets project configuration and reverts to defaults:
- Uses default ports (3000/8000) instead of configured ones in .env/.env.local
- Switches from `uv` to `pip`, creates new virtual environments unnecessarily
- Ignores existing `start.sh` scripts and uses different startup commands
- Forgets tech stack choices documented in `@.agent-os/product/tech-stack.md`

**Expected Workflow:** Claude loads project context at session start, validates configuration sources, and maintains consistency throughout the session without manual reminders.

### Configuration Source Hierarchy

As a developer, I want Claude to understand and respect the configuration hierarchy from most specific to most general, so that project-specific settings always override global defaults.

**Configuration Priority (highest to lowest):**
1. Project `.env` and `.env.local` files - Actual environment configuration
2. Project `start.sh` script - Proven startup commands  
3. Project `@.agent-os/product/tech-stack.md` - Project tech decisions
4. Global `@~/.agent-os/standards/tech-stack.md` - User defaults

### Persistent Session Memory

As a developer, I want Claude to maintain configuration awareness throughout an entire session, so that configuration choices made early are remembered and applied consistently in later interactions.

**Example:** If Claude determines my project uses `uv` and port 3001 at the start of a session, it should continue using these settings for all subsequent commands, installations, and suggestions.

## Spec Scope

1. **Project Context Loading System** - Automated detection and loading of project configuration at session start
2. **Configuration Hierarchy Resolution** - Smart precedence handling for conflicting configuration sources  
3. **Session Memory Persistence** - Mechanisms to maintain configuration awareness throughout sessions
4. **Hook Integration** - Integration with existing Claude Code hooks for automatic context injection
5. **Validation and Correction** - Detection and prevention of configuration amnesia incidents

## Out of Scope

- Modifications to external files outside Agent OS control
- Configuration for non-Agent OS projects without minimal setup
- Support for IDEs other than those with Claude Code integration
- Automatic migration of existing project configurations

## Expected Deliverable

1. **Project starts with correct configuration loaded** - Claude immediately knows project ports, package managers, and startup commands
2. **No mid-session configuration amnesia** - Configuration choices remain consistent throughout entire sessions
3. **Smart validation prevents configuration errors** - System catches and corrects attempts to use wrong configuration

## Spec Documentation

- Tasks: @.agent-os/specs/2025-07-30-project-config-amnesia-#12/tasks.md
- Technical Specification: @.agent-os/specs/2025-07-30-project-config-amnesia-#12/sub-specs/technical-spec.md
- Tests Specification: @.agent-os/specs/2025-07-30-project-config-amnesia-#12/sub-specs/tests.md