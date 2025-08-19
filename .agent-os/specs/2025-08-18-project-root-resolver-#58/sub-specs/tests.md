# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-08-18-project-root-resolver-#58/spec.md

> Created: 2025-08-18
> Version: 1.0.0

## Test Coverage

### Unit Tests

**ProjectRootResolver Class**
- Test CLAUDE_PROJECT_DIR environment variable resolution
- Test hook payload field resolution (workspaceDir, projectRoot, rootDir)
- Test file system ascent with various marker types (.agent-os, .git, .hg, .svn)
- Test fallback to current working directory
- Test resolution order priority enforcement
- Test error handling for invalid paths
- Test caching behavior and TTL expiration

**CLI Interface**
- Test command line argument parsing
- Test hook payload JSON input parsing
- Test quiet mode output formatting
- Test error handling and exit codes

### Integration Tests

**Hook Integration**
- Test workflow-enforcement-hook.py with resolver from subdirectories
- Test pre-bash-hook.sh project context detection
- Test post-bash-hook.sh project context detection
- Test user-prompt-submit-hook.sh project context detection
- Verify existing hook functionality is preserved

**Script Integration**
- Test config-resolver.py integration with new resolver
- Verify configuration loading works from subdirectories
- Test backwards compatibility with existing behavior

**File System Scenarios**
- Test from project root directory
- Test from nested subdirectories (2-3 levels deep)
- Test from symbolic link paths
- Test with multiple project markers in parent directories
- Test behavior at filesystem root
- Test with non-existent starting paths

### End-to-End Tests

**Real Project Scenarios**
- Create temporary project structure with Agent OS markers
- Test Claude Code hook triggers from various subdirectories  
- Verify consistent project root detection across all components
- Test with real hook payloads from Claude Code
- Verify no regression in existing workflow enforcement

## Mocking Requirements

**File System Operations**
- Mock `os.path.exists()` for path validation testing
- Mock `os.getcwd()` for current directory testing
- Mock `os.walk()` for directory traversal testing
- Mock environment variable access for CLAUDE_PROJECT_DIR testing

**Hook Payload Simulation**
- Create mock Claude Code hook payload structures
- Test with various combinations of payload fields
- Test with malformed or missing payload data

**Edge Case Simulation**
- Mock permission denied scenarios
- Mock filesystem errors during traversal
- Mock network drive or remote filesystem behavior