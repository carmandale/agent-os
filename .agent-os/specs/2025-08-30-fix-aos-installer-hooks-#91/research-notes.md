# Research Notes

Research findings for the spec detailed in @.agent-os/specs/2025-08-30-fix-aos-installer-hooks-#91/spec.md

> Created: 2025-08-30
> Version: 1.0.0
> GitHub Issue: #91

## Problem Analysis

### Current Hook Installation Issues

The aos installer currently fails to properly configure Claude Code hooks, leading to:

1. **Missing Hook Files**: Hook scripts may not be copied to correct locations
2. **Incorrect Permissions**: Hook files may not be executable
3. **Registration Failure**: Claude Code may not recognize installed hooks
4. **Validation Gap**: No verification that hooks are working after installation

### Hook Requirements Research

Based on Agent OS architecture and Claude Code documentation:

**Hook File Locations:**
- Hooks should be installed in `~/.claude/hooks/` directory
- Each hook requires specific naming convention
- Hook files must be executable (`chmod +x`)

**Hook Types in Agent OS:**
- `pre-bash.sh` - Command interception and validation
- `post-bash.sh` - Command result processing and logging
- `workflow-enforcement.sh` - Workflow completion validation
- `context-injection.sh` - Automatic context loading

**Claude Code Integration:**
- Hooks must be registered in Claude Code configuration
- Hook loading happens at Claude Code startup
- Failed hooks may prevent Claude Code from functioning

## Installation Process Analysis

### Current Setup Scripts

**setup.sh responsibilities:**
- Install core Agent OS components
- Set up directory structure
- Copy instruction files and standards

**setup-claude-code.sh responsibilities:**
- Install Claude Code specific components
- Configure Claude Code settings
- Set up hooks and commands

### Identified Gaps

1. **Hook File Handling**: Scripts may not properly handle hook file permissions
2. **Directory Creation**: Hook directories may not be created before copying files
3. **Error Handling**: Limited error checking for hook installation steps
4. **Validation**: No verification that hooks are successfully installed and working

## Testing Strategy

### Installation Testing Approach

1. **Clean Environment Testing**: Test on systems without existing Agent OS installation
2. **Permission Testing**: Verify hook files have correct executable permissions
3. **Claude Code Integration**: Test that Claude Code loads and uses hooks
4. **Functional Testing**: Verify hooks perform expected behavior

### Validation Requirements

- Hook files exist in correct locations
- Hook files are executable
- Claude Code recognizes and loads hooks
- Hooks trigger during normal AI interactions
- Hook functionality matches expected behavior

## Implementation Recommendations

### Setup Script Improvements

1. **Explicit Directory Creation**: Ensure `~/.claude/hooks/` directory exists
2. **Permission Setting**: Explicitly set executable permissions on hook files
3. **Validation Steps**: Add checks to verify hook installation success
4. **Error Handling**: Provide clear error messages for hook setup failures

### Health Check Integration

1. **Hook Status Verification**: Add hook checks to `check-agent-os.sh`
2. **Diagnostic Commands**: Provide troubleshooting tools for hook issues
3. **Repair Functionality**: Allow hook reinstallation if problems detected

### Documentation Updates

1. **Installation Guide**: Document hook requirements and troubleshooting
2. **Troubleshooting Section**: Common hook problems and solutions
3. **Validation Steps**: How to verify hooks are working correctly

## Technical Considerations

### Cross-Platform Compatibility

- Ensure hook installation works on macOS and Linux
- Handle different shell environments appropriately
- Account for varying permission systems

### Error Recovery

- Provide options to reinstall hooks if initial setup fails
- Allow partial installation recovery
- Clear error messages for common failure scenarios

### Performance Impact

- Minimize installation time impact
- Ensure hook validation doesn't slow down setup significantly
- Balance thorough checking with installation speed