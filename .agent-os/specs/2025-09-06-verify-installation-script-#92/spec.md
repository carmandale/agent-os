# Verify Installation Script

> **Issue:** #92  
> **Created:** 2025-09-06  
> **Status:** Planning  
> **Priority:** High  
> **Effort:** Medium (M)

## Overview

Create a comprehensive installation verification script (`verify-installation.sh`) that validates Agent OS installation integrity, component functionality, and configuration correctness. This script addresses the critical gap identified in MAINTENANCE-CHECKLIST.md where installation verification is referenced but the script doesn't exist.

## Problem Statement

Agent OS currently lacks a comprehensive way to verify that an installation is complete, properly configured, and functional. Users experience issues like:
- Broken hook configurations after installation
- Missing required files or permissions
- Incomplete Claude Code integration
- Silent configuration failures

The MAINTENANCE-CHECKLIST.md references `verify-installation.sh` as a critical verification step, but this script doesn't exist, creating a broken maintenance workflow.

## User Stories

**As a new Agent OS user**, I want to verify my installation is complete and functional so that I can trust the system will work reliably.

**As a developer maintaining Agent OS**, I want automated verification of installation integrity so that I can quickly identify and fix installation issues.

**As a team lead adopting Agent OS**, I want to validate installations across team members so that everyone has a consistent, working setup.

## Success Criteria

- ✅ Script validates all Agent OS components are present and functional
- ✅ Script verifies Claude Code hooks integration works correctly  
- ✅ Script checks file permissions and directory structure
- ✅ Script validates configuration files are correctly formatted
- ✅ Script provides clear, actionable error messages for any issues
- ✅ Script supports both quick check and comprehensive audit modes
- ✅ Script integrates with existing Agent OS CLI (aos command)

## Scope

### In Scope
- Complete installation verification (files, directories, permissions)
- Claude Code hooks validation and testing
- Configuration file integrity checks
- CLI command availability verification
- Git integration validation
- Health check integration with existing check-agent-os.sh
- Integration with aos status command

### Out of Scope
- Automatic repair of broken installations (separate feature)
- Network connectivity testing to external services
- Performance benchmarking of installation
- Cross-platform compatibility beyond macOS/Linux

## Technical Requirements

### Core Functionality
- Validate ~/.agent-os directory structure and permissions
- Check all required files exist with correct content
- Verify Claude Code hooks are properly installed and functional
- Test aos CLI command availability and basic operations
- Validate Git configuration and GitHub CLI setup

### Integration Points
- Integrate with existing check-agent-os.sh health check
- Support aos status command for quick verification
- Work with setup.sh for post-installation validation
- Compatible with MAINTENANCE-CHECKLIST.md workflow

### Performance Requirements
- Complete verification in under 30 seconds
- Quick check mode completes in under 5 seconds
- Minimal resource usage during verification

## Dependencies

### External Dependencies
- Existing Agent OS installation structure
- Claude Code with hooks support
- Git and GitHub CLI
- Standard Unix utilities (bash, curl, grep, etc.)

### Internal Dependencies
- check-agent-os.sh (existing health check script)
- aos CLI command structure
- Claude Code hooks configuration
- Agent OS directory standards

## Deliverables

1. **verify-installation.sh** - Main verification script
2. **Integration with aos CLI** - Add verify command to aos toolkit
3. **Test Suite** - Comprehensive tests for verification logic
4. **Documentation** - Usage guide and troubleshooting section
5. **MAINTENANCE-CHECKLIST.md Update** - Fix broken reference

## Definition of Done

- [ ] verify-installation.sh script exists and is executable
- [ ] Script passes all comprehensive verification tests
- [ ] Integration with aos status command works correctly
- [ ] MAINTENANCE-CHECKLIST.md reference is functional
- [ ] Documentation includes usage examples and troubleshooting
- [ ] Test suite covers all major verification scenarios
- [ ] Script handles edge cases gracefully with helpful error messages