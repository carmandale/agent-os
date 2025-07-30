# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-30-hook-deadlock-resolution-#10/spec.md

> Created: 2025-07-30
> Version: 1.0.0

## Test Coverage

### Unit Tests

**Hook Command Classification**
- Test read-only command detection (ls, cat, grep, git status)
- Test write command detection (touch, mkdir, npm install)
- Test git command allowance (all git/gh commands allowed)
- Test edge cases (commands with arguments, complex pipes)

**Workspace State Detection**
- Test uncommitted changes detection via git status
- Test open PR detection via gh pr list
- Test clean workspace detection
- Test mixed state scenarios (uncommitted + open PR)

**Message Generation**
- Test context-aware message creation
- Test progressive guidance escalation
- Test specific guidance for different scenarios
- Test message formatting and clarity

### Integration Tests

**Hook Behavior with Tools**
- Test Bash tool blocking/allowing with different commands
- Test Write/Edit tool blocking during dirty state
- Test Read tool allowance during dirty state
- Test Task tool subagent guidance integration

**Workflow Recovery Scenarios**
- Test Claude guidance following for git status checks
- Test commit workflow completion after investigation
- Test stash workflow for temporary resolution
- Test debug mode activation and deactivation

**Error Handling**
- Test hook behavior when git commands fail
- Test hook behavior in non-git repositories
- Test hook behavior with permissions issues
- Test graceful degradation when tools unavailable

### Feature Tests

**End-to-End Deadlock Resolution**
- Start with dirty workspace and broken feature
- Claude attempts to debug and gets blocked
- Claude follows hook guidance to check git status
- Claude resolves workspace issue (commit/stash)
- Claude successfully debugs original issue

**Debug Mode Workflow**
- User reports issue with uncommitted changes
- Hook blocks investigation attempts
- Debug mode gets activated for read-only investigation
- Investigation completes successfully
- Normal workflow resumes after cleanup

**Progressive Guidance Testing**
- First block: Standard guidance message
- Second block: Detailed guidance with examples
- Third block: Step-by-step resolution guide
- Verify escalation works correctly

### Mocking Requirements

**Git Command Simulation**
- Mock git status output for various states
- Mock git diff output for change review
- Mock gh pr list for PR detection
- Mock successful/failed git operations

**Tool Input/Output Mocking**
- Mock Claude Code tool input format
- Mock hook execution environment
- Mock file system states for testing
- Mock command execution results

### Performance Tests

**Hook Execution Speed**
- Measure hook response time (<50ms target)
- Test with large repositories
- Test with many uncommitted files
- Verify no performance degradation

**Memory Usage**
- Monitor hook memory consumption
- Test for memory leaks in long sessions
- Verify efficient command classification
- Test cleanup after resolution

### Regression Tests

**Existing Functionality Preservation**
- Verify git workflow enforcement still works
- Verify PR review process unchanged
- Verify subagent encouragement still functions
- Verify original hook behaviors maintained

**Edge Case Coverage**
- Test in repositories without GitHub integration
- Test with unusual git configurations
- Test with special characters in paths
- Test with very long command lines