# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-08-18-aos-installer-improvements-#65/spec.md

> Created: 2025-08-18
> Version: 1.0.0

## Test Coverage

### Unit Tests

**Hook Detection Functions**
- Test `check_project_currency()` with various hook states (missing, outdated, current)
- Test hook version comparison logic with different version formats
- Test structured issue reporting with multiple simultaneous issues

**Update Functions**
- Test `smart_update()` behavior when hooks need updating but global is current
- Test `update_claude_hooks()` function with various starting states
- Test update feedback reporting with different update scenarios

**Init Command Functions**
- Test `quick_setup_project()` with different project configurations
- Test issue resolution with interactive and non-interactive modes
- Test selective issue fixing when user chooses partial updates

### Integration Tests

**Hook Update Workflow**
- Full workflow: detect outdated hooks → run update → verify hooks updated
- Test update process with existing .claude/settings.json configurations
- Test update process with missing hook directories
- Verify hook installation produces expected settings.json entries

**Project Setup Workflow**
- Test init command in projects with various AI assistant configurations
- Verify comprehensive issue detection and resolution
- Test project setup with both Claude and Cursor configurations

**Update Command Integration**
- Test `aos update` command when global current but project needs updates
- Test `aos init` command with various project issue combinations  
- Verify update commands provide accurate feedback about changes made

### End-to-End Tests

**Complete Update Scenarios**
- Scenario: User with outdated hooks runs `aos status` → `aos update` → `aos status`
- Scenario: User runs `aos init` in project with multiple setup issues
- Scenario: User updates global Agent OS then runs project setup

**Cross-Platform Testing**
- Test hook updates on macOS and Linux environments
- Verify curl-based downloads work with various network configurations
- Test file permission handling across different systems

### Mocking Requirements

- **Network Requests:** Mock curl downloads for hook installation scripts
- **File System Operations:** Mock .claude directory states for various test scenarios
- **User Input:** Mock interactive responses for init command testing
- **External Commands:** Mock GitHub CLI and git commands where hook setup depends on them

### Performance Tests

**Update Speed**
- Verify hook update process completes within 30 seconds
- Test that status checks remain fast (< 2 seconds) after improvements
- Ensure no performance regression in existing update workflows

### Error Handling Tests

**Network Failures**
- Test behavior when hook download fails mid-process
- Verify graceful handling of GitHub connectivity issues
- Test rollback behavior when partial updates fail

**Permission Issues**
- Test behavior when .claude directory is not writable
- Verify appropriate error messages for permission problems
- Test alternative paths when standard directories are inaccessible

**Validation Tests**
- Test detection of corrupted hook installations
- Verify proper validation that hook updates actually succeeded
- Test handling of unexpected .claude/settings.json formats