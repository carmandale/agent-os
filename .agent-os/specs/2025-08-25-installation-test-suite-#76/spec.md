# Spec Requirements Document

> Spec: Installation Test Suite
> Created: 2025-08-25
> Status: Planning

## Overview

Agent OS needs a comprehensive installation test suite to prevent installation gaps and ensure reliable setup across all environments. Recent discoveries of missing referenced files (aos-background references, missing scripts, missing hook files) highlight the need for systematic installation validation.

This spec creates an automated testing framework that validates installation completeness, clarifies source vs install vs project contexts, and provides pre-release validation to prevent deployment of incomplete installations.

## User Stories

### As a new Agent OS user
- I want installation to work completely on first try without missing files
- I want clear error messages if installation fails, telling me exactly what went wrong
- I want confidence that all referenced features will actually be available after installation

### As an Agent OS maintainer  
- I want automated detection of installation gaps before they reach users
- I want validation that all setup scripts reference files that actually exist
- I want pre-release checks that catch missing components

### As a power user
- I want to audit my current installation for completeness
- I want to verify that updates don't break existing functionality
- I want clear understanding of what files exist where (source vs install vs project)

## Spec Scope

### Installation Completeness Testing
- **File Reference Validation**: Verify all files referenced in setup scripts exist and get installed
- **Dependency Chain Testing**: Ensure all dependencies are properly installed and functional
- **Cross-Platform Validation**: Test installation on macOS and Linux environments
- **Update Path Testing**: Verify updates don't break existing installations

### Source vs Install vs Project Context Clarity
- **Mental Model Documentation**: Clear explanation of Agent OS's three-context architecture
- **File Location Mapping**: Automated generation of "what files live where" documentation
- **Context Validation**: Ensure files are installed to correct locations
- **Reference Resolution**: Validate all file references resolve correctly in each context

### Pre-Release Validation Pipeline
- **Automated Installation Testing**: Run full installation on clean environments
- **Reference Auditing**: Scan all scripts for file references and validate existence
- **Hook System Validation**: Verify Claude Code hooks are properly installed and functional
- **Integration Testing**: End-to-end workflow testing with fresh installations

### Installation Architecture Documentation
- **Three-Context Model**: Document source repo, user install, and project contexts clearly
- **Installation Flow Diagrams**: Visual representation of what gets installed where
- **Troubleshooting Guides**: Common installation issues and resolution steps
- **File Dependency Maps**: Clear visualization of which files depend on others

### Automated Installation Auditing
- **Continuous Validation**: Ongoing checks that installations remain complete
- **Drift Detection**: Identify when installed files become outdated or corrupted
- **Health Check Integration**: Add installation validation to existing health checks
- **User Self-Service Auditing**: Tools for users to validate their own installations

## Out of Scope

- Fixing existing installation issues (separate from testing them)
- Complete rewrite of setup scripts (enhancement, not replacement)
- Windows native support (WSL testing is in scope)
- GUI installation tools
- Package manager distribution (brew, npm, etc.)

## Expected Deliverable

A comprehensive installation test suite that:

1. **Prevents installation gaps** through automated pre-release validation
2. **Provides clear diagnostics** when installation issues occur
3. **Documents installation architecture** clearly for users and maintainers
4. **Enables self-service auditing** for users to validate their installations
5. **Integrates with existing workflows** without disrupting current processes

Success criteria:
- Zero installation gaps in next release
- All file references validated automatically
- Clear documentation of three-context architecture
- Users can self-diagnose installation issues
- Maintainers have confidence in release quality

## Spec Documentation

- Tasks: @.agent-os/specs/2025-08-25-installation-test-suite-#76/tasks.md
- Technical Specification: @.agent-os/specs/2025-08-25-installation-test-suite-#76/sub-specs/technical-spec.md
- Test Coverage: @.agent-os/specs/2025-08-25-installation-test-suite-#76/sub-specs/tests.md