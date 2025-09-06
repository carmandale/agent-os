# Technical Specification: verify-installation.sh

> **Parent Spec:** 2025-09-06-verify-installation-script-#92  
> **Focus:** Implementation Architecture & Technical Details

## Architecture Overview

The verify-installation.sh script follows Agent OS's shell-first architecture with modular verification functions, comprehensive error reporting, and integration with existing tooling.

### Script Structure
```bash
verify-installation.sh
├── Core verification functions
├── Configuration validation 
├── Hook system testing
├── CLI integration testing
├── Error reporting and recovery suggestions
└── Integration with aos status command
```

## Implementation Approach

### Verification Modules

**1. Directory Structure Validation**
```bash
validate_directory_structure() {
    # Check ~/.agent-os/ structure
    # Verify required subdirectories exist
    # Check file permissions (755 for scripts, 644 for configs)
    # Validate ownership and access rights
}
```

**2. File Integrity Checks**
```bash
validate_file_integrity() {
    # Check core files exist and are readable
    # Validate configuration file syntax (JSON, YAML parsing)
    # Verify script files have proper shebang and permissions
    # Check for template file completeness
}
```

**3. Claude Code Hooks Validation**
```bash
validate_claude_hooks() {
    # Test ~/.claude/settings.json structure
    # Verify hook file references are valid
    # Test hook execution (dry-run mode)
    # Validate hook configuration syntax
}
```

**4. CLI Command Testing**
```bash
validate_cli_commands() {
    # Test aos command availability
    # Verify subcommands respond correctly
    # Test PATH configuration
    # Validate command permissions
}
```

**5. Git Integration Testing**
```bash
validate_git_integration() {
    # Check GitHub CLI installation
    # Verify git configuration
    # Test repository access permissions
    # Validate SSH/HTTPS authentication
}
```

### Error Handling Strategy

**Error Classification:**
- **CRITICAL**: Installation is broken, Agent OS won't function
- **WARNING**: Minor issues that may cause problems
- **INFO**: Suggestions for optimization

**Error Reporting Format:**
```bash
# Colored output with clear action items
print_critical() {
    echo -e "${RED}❌ CRITICAL: $1${NC}"
    echo -e "   Fix: $2"
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
    echo -e "   Suggestion: $2"
}

print_info() {
    echo -e "${BLUE}ℹ️  INFO: $1${NC}"
}
```

## Integration Points

### aos CLI Integration
```bash
# Add to tools/aos script
verify)
    ~/.agent-os/scripts/verify-installation.sh "$@"
    ;;
```

### Health Check Integration
```bash
# Extend check-agent-os.sh to call verify-installation.sh
# Provide unified health status across all components
# Share validation logic between scripts
```

### Setup Script Integration
```bash
# Add post-installation verification to setup.sh
echo "🔍 Verifying installation..."
~/.agent-os/scripts/verify-installation.sh --quick
```

## Command Line Interface

### Usage Patterns
```bash
# Quick verification (5 seconds)
verify-installation.sh --quick

# Comprehensive audit (30 seconds)
verify-installation.sh --full

# Specific component testing
verify-installation.sh --hooks-only
verify-installation.sh --cli-only

# Silent mode for scripting
verify-installation.sh --silent --exit-code

# Verbose debugging
verify-installation.sh --verbose --debug
```

### Exit Codes
- `0` - All verifications passed
- `1` - Critical errors found (installation broken)
- `2` - Warnings found (minor issues)
- `3` - Script error (verification failed to run)

## Testing Strategy

### Unit Testing
- Test each verification function independently
- Mock external dependencies (git, gh, claude commands)
- Validate error message formatting and exit codes
- Test edge cases (missing files, permission issues)

### Integration Testing
- Test full verification workflow end-to-end
- Validate integration with aos CLI
- Test on fresh Agent OS installations
- Verify compatibility with existing health checks

### Performance Testing
- Ensure quick mode completes within 5 seconds
- Validate full mode completes within 30 seconds
- Test with various system loads
- Measure resource usage during verification

## Security Considerations

### File Access
- Only read from Agent OS installation directories
- Don't modify any files during verification
- Respect file permissions and ownership
- Avoid executing untrusted scripts

### Information Disclosure
- Don't log sensitive configuration data
- Sanitize output for sharing in bug reports
- Avoid exposing system internals unnecessarily
- Respect user privacy in validation output

## Compatibility Requirements

### Operating Systems
- macOS 10.15+ (primary target)
- Linux distributions with bash 4.0+
- Windows WSL2 (basic compatibility)

### Shell Requirements
- Bash 4.0+ for associative arrays and modern features
- Standard POSIX utilities (grep, sed, awk, curl)
- No dependency on non-standard tools

### Agent OS Versions
- Compatible with current version (2.4.0+)
- Backward compatible with installations from v2.0+
- Forward compatible design for future versions