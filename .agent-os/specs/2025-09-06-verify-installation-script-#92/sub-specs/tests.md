# Test Specification: verify-installation.sh

> **Parent Spec:** 2025-09-06-verify-installation-script-#92  
> **Focus:** Comprehensive Testing Strategy & Test Cases

## Testing Strategy

### Testing Levels

**Unit Tests**: Individual verification functions  
**Integration Tests**: Full workflow with real Agent OS installation  
**End-to-End Tests**: Complete user scenarios from installation to verification  
**Performance Tests**: Response times and resource usage validation  

### Test Framework

Using **Bats** (Bash Automated Testing System) for consistency with existing Agent OS tests:
- `tests/test-verify-installation.bats` - Main test suite
- `tests/helpers/verification-helpers.bash` - Shared test utilities
- `tests/fixtures/` - Mock installation structures for testing

## Unit Test Cases

### Directory Structure Validation Tests

```bash
@test "validate_directory_structure: detects missing ~/.agent-os directory" {
    # Setup: Remove ~/.agent-os temporarily
    # Execute: Run validation function
    # Assert: Returns error code 1, reports missing directory
}

@test "validate_directory_structure: validates correct permissions" {
    # Setup: Create directory with wrong permissions
    # Execute: Run validation function  
    # Assert: Reports permission issues with specific fix suggestions
}

@test "validate_directory_structure: accepts valid installation" {
    # Setup: Ensure proper Agent OS installation
    # Execute: Run validation function
    # Assert: Returns success, no error messages
}
```

### File Integrity Tests

```bash
@test "validate_file_integrity: detects missing core files" {
    # Test missing setup.sh, check-agent-os.sh, etc.
}

@test "validate_file_integrity: validates JSON configuration syntax" {
    # Test with malformed ~/.claude/settings.json
}

@test "validate_file_integrity: checks script executability" {
    # Test with non-executable scripts
}
```

### Claude Code Hooks Tests

```bash
@test "validate_claude_hooks: detects missing hooks configuration" {
    # Remove ~/.claude/settings.json
    # Verify error reporting and recovery suggestions
}

@test "validate_claude_hooks: validates hook file references" {
    # Create settings.json with invalid hook paths
    # Verify broken reference detection
}

@test "validate_claude_hooks: tests hook execution safety" {
    # Verify hooks can be tested without side effects
}
```

### CLI Command Tests

```bash
@test "validate_cli_commands: detects missing aos command" {
    # Remove aos from PATH temporarily
    # Verify detection and recovery guidance
}

@test "validate_cli_commands: validates subcommand availability" {
    # Test aos status, aos update, etc.
}
```

## Integration Test Cases

### Full Verification Workflow Tests

```bash
@test "full verification: passes on clean installation" {
    # Setup: Fresh Agent OS installation
    # Execute: Complete verification workflow
    # Assert: All checks pass, exit code 0
}

@test "full verification: reports multiple issues correctly" {
    # Setup: Installation with several issues
    # Execute: Full verification
    # Assert: All issues detected and reported with priorities
}

@test "quick verification: completes within time limit" {
    # Execute: Quick verification mode
    # Assert: Completes within 5 seconds
}
```

### aos CLI Integration Tests

```bash
@test "aos verify: integrates with CLI correctly" {
    # Execute: aos verify command
    # Assert: Calls verify-installation.sh with correct parameters
}

@test "aos status: includes verification results" {
    # Execute: aos status command
    # Assert: Shows installation verification status
}
```

## End-to-End Test Scenarios

### New User Installation Tests

```bash
@test "e2e: fresh installation verification" {
    # Simulate new user installation flow
    # Run setup.sh followed by verification
    # Verify complete success path
}

@test "e2e: broken installation recovery guidance" {
    # Simulate partially failed installation
    # Run verification to get recovery steps
    # Verify actionable guidance provided
}
```

### Maintenance Workflow Tests

```bash
@test "e2e: MAINTENANCE-CHECKLIST.md workflow" {
    # Follow complete maintenance checklist
    # Verify verify-installation.sh step works
    # Validate integration with other checklist steps
}
```

## Error Condition Tests

### File System Issue Tests

```bash
@test "error handling: permission denied on ~/.agent-os" {
    # Setup: Remove read permissions on ~/.agent-os
    # Execute: Verification
    # Assert: Clear error message with fix instructions
}

@test "error handling: disk full during verification" {
    # Mock disk full condition
    # Verify graceful error handling
}
```

### Configuration Error Tests

```bash
@test "error handling: malformed JSON configuration" {
    # Create invalid JSON in settings files
    # Verify parsing error detection and reporting
}

@test "error handling: missing required configuration keys" {
    # Remove required configuration elements
    # Verify detection and specific guidance
}
```

## Performance Test Cases

### Response Time Tests

```bash
@test "performance: quick mode completes under 5 seconds" {
    # Execute quick verification multiple times
    # Measure and validate response times
}

@test "performance: full mode completes under 30 seconds" {
    # Execute comprehensive verification
    # Validate complete workflow timing
}
```

### Resource Usage Tests

```bash
@test "performance: memory usage stays reasonable" {
    # Monitor memory usage during verification
    # Ensure no memory leaks or excessive usage
}

@test "performance: minimal disk I/O impact" {
    # Measure disk operations during verification
    # Validate efficient file access patterns
}
```

## Edge Case Tests

### Unusual Installation States

```bash
@test "edge case: partial installation from interrupted setup" {
    # Simulate interrupted setup.sh execution
    # Verify verification detects and reports partial state
}

@test "edge case: manual configuration modifications" {
    # Modify standard installation manually
    # Verify verification handles non-standard configurations
}

@test "edge case: multiple Agent OS versions installed" {
    # Setup overlapping version installations
    # Verify verification handles version conflicts
}
```

## Test Data & Fixtures

### Mock Installation Structures

```
tests/fixtures/
├── valid-installation/          # Complete, correct installation
├── missing-files/              # Installation with missing components
├── broken-permissions/         # Permission issues
├── invalid-configs/            # Malformed configuration files
└── partial-installation/       # Incomplete setup
```

### Test Configuration Files

```bash
# tests/helpers/verification-helpers.bash
setup_mock_installation() {
    # Create temporary Agent OS installation for testing
}

teardown_mock_installation() {
    # Clean up test installation
}

assert_verification_output() {
    # Helper for validating verification script output
}
```

## Continuous Integration Tests

### GitHub Actions Integration

```yaml
# .github/workflows/verify-installation-tests.yml
name: Verify Installation Tests
on: [push, pull_request]
jobs:
  test-verification:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Bats
        run: npm install -g bats
      - name: Run verification tests
        run: bats tests/test-verify-installation.bats
```

### Cross-Platform Testing

```bash
@test "cross-platform: works on Ubuntu 20.04" {
    # Platform-specific verification testing
}

@test "cross-platform: works on macOS Big Sur+" {
    # macOS-specific verification testing
}
```

## Test Coverage Requirements

### Minimum Coverage Targets
- **Function Coverage**: 100% (all verification functions tested)
- **Branch Coverage**: 95% (all error paths tested)
- **Integration Coverage**: 90% (major workflows tested)
- **Edge Case Coverage**: 80% (unusual scenarios covered)

### Coverage Validation
```bash
# Generate coverage report for bash scripts
# Validate coverage meets minimum requirements
# Report coverage gaps for improvement
```