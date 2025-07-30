# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-30-intelligent-workspace-cleanup-#11/spec.md

> Created: 2025-07-30
> Version: 1.0.0

## Test Coverage

### Unit Tests

**WorkspaceAnalyzer Class**
- Test file categorization for known patterns (valuable, temporary, sensitive, unknown)
- Test pattern matching engine with various file extensions and paths
- Test security scanner with known secret patterns and false positives
- Test edge cases: empty files, binary files, very large files
- Test configuration loading and rule precedence (global vs project-specific)

**CleanupActionsEngine Class**
- Test appropriate action selection for each file category
- Test gitignore pattern generation and updates  
- Test safe file deletion and temporary storage
- Test user prompt generation for unknown/sensitive files
- Test rollback mechanisms for failed cleanup operations

**PatternDatabase Class**
- Test pattern loading from JSON configuration
- Test pattern matching performance with large file sets
- Test custom pattern addition and override functionality
- Test pattern validation and error handling

### Integration Tests

**Hook Integration Workflow**
- Test complete workflow from dirty workspace to clean state
- Test hook behavior modification (before/after workspace analyzer integration)
- Test user interaction flows for different cleanup scenarios
- Test fallback behavior when workspace analyzer fails
- Test integration with existing git operations (status, add, commit)

**Git Repository Scenarios**
- Test with various repository states: clean, dirty, conflicted, detached HEAD
- Test with different file change types: new files, modifications, deletions, renames
- Test with nested .gitignore files and existing ignore patterns
- Test with symlinks, submodules, and other git edge cases

**Security Pattern Detection**
- Test detection of real-world secret patterns in various file formats
- Test handling of false positives (code examples, documentation)
- Test with encrypted/encoded secrets that shouldn't trigger detection
- Test with mixed content files (some sensitive, some not)

### Feature Tests

**End-to-End Workspace Cleanup**
- User starts with dirty workspace containing mixed file types
- System correctly categorizes all changes
- User can review and approve suggested actions
- Cleanup completes with appropriate git state (valuable files committed, temp files ignored/deleted)
- Workspace is clean and ready for new work

**Security Protection Workflow**
- User has uncommitted changes including a file with API keys
- System detects sensitive content and blocks automatic commit
- User is guided through secure cleanup options
- Sensitive data is safely handled (moved to .env.example, added to .gitignore)
- No secrets are committed to repository

**Progressive Cleanup for Large Workspaces**
- Workspace has 50+ changed files across all categories
- System processes files in logical groups (temporary first, then valuable, then sensitive)
- User can approve actions incrementally without being overwhelmed
- All files are properly handled without timeouts or memory issues

### Mocking Requirements

**Git Commands**: Mock git status, git add, git commit operations for controlled testing
**File System Operations**: Mock file deletion, movement, and .gitignore updates
**User Input**: Mock user responses for interactive cleanup decisions
**Pattern Database**: Mock configuration loading to test different rule sets
**Security Scanner**: Mock secret detection to test various sensitive content scenarios

## Performance Testing

**Large Repository Handling**
- Test with repositories containing 1000+ files in working directory
- Verify analysis completes within 10 seconds
- Ensure memory usage stays reasonable (< 100MB)

**Pattern Matching Efficiency**  
- Test pattern matching against large numbers of files
- Verify no significant performance regression from current hook behavior
- Benchmark different pattern matching approaches

## Error Handling Tests

**Graceful Degradation**
- Test behavior when workspace analyzer fails (should fall back to current hook behavior)
- Test with corrupted configuration files
- Test with insufficient file system permissions
- Test with git repository corruption

**User Experience**
- Test clear error messages for all failure scenarios
- Test recovery suggestions for common problems
- Test ability to bypass intelligent cleanup in emergency situations

## Mock Strategy

### Development Environment Mocking
- **Temporary Git Repository**: Create isolated git repos for testing
- **File System Sandbox**: Use temporary directories for file operations
- **Configuration Override**: Test-specific configuration files
- **User Input Simulation**: Automated responses for interactive prompts

### CI/CD Testing
- **Containerized Testing**: Run tests in clean container environments
- **Multiple OS Testing**: Verify compatibility across Linux, macOS, and Windows (WSL)
- **Git Version Testing**: Test with different git versions and configurations