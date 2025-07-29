# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-29-claude-code-hooks-#37/spec.md

> Created: 2025-07-29
> Version: 1.0.0

## Test Coverage

### Unit Tests

**workflow-detector.sh**
- Detect Agent OS spec directories correctly
- Identify incomplete workflows (uncommitted docs, open PRs, dirty workspace)
- Handle missing .agent-os directory gracefully
- Parse git status output correctly for Agent OS files
- Extract GitHub issue numbers from spec folder names
- Return appropriate exit codes for different workflow states

**git-utils.sh**
- Stage and commit Agent OS documentation files with proper messages
- Generate commit messages with GitHub issue references
- Handle git command failures gracefully
- Detect current branch and git repository state
- Check for uncommitted changes in Agent OS directories

**context-builder.sh**
- Parse user prompts for Agent OS workflow keywords
- Build appropriate context for different workflow types (spec, tasks, planning)
- Handle missing Agent OS files gracefully
- Generate efficient context injections without performance impact
- Detect current spec and task states accurately

### Integration Tests

**Stop Hook Workflow**
- Block user when Agent OS workflow is incomplete (open PR, uncommitted docs)
- Allow normal operation when no Agent OS work is in progress
- Provide clear guidance for workflow completion steps
- Handle GitHub CLI availability correctly
- Work correctly in both Agent OS projects and regular repositories

**PostToolUse Hook Workflow**
- Auto-commit spec creation with proper issue reference
- Auto-commit task updates during workflow execution
- Auto-commit technical documentation changes
- Skip auto-commit for non-Agent OS files
- Handle commit failures without blocking user workflow
- Generate appropriate commit messages for different file types

**UserPromptSubmit Hook Workflow**
- Inject context for "/create-spec" commands
- Inject context for "@.agent-os/" file references
- Inject context for "execute-tasks" workflow start
- Skip injection for non-Agent OS prompts
- Maintain performance with large project contexts
- Handle missing context files gracefully

**End-to-End Workflow Tests**
- Complete Agent OS spec creation with hooks enabled
- Execute Agent OS tasks with automatic documentation commits
- Workflow completion enforcement prevents abandoned work
- Context injection improves AI assistance accuracy
- All hooks work together without conflicts

### Mocking Requirements

**GitHub CLI Commands**
- Mock `gh pr list` responses for testing PR detection
- Mock `gh issue list` responses for testing issue state
- Simulate GitHub CLI unavailability for error testing
- Mock successful and failed PR creation scenarios

**Git Command Responses**
- Mock `git status --porcelain` for clean/dirty workspace testing
- Mock `git log` output for recent commit analysis
- Mock `git add` and `git commit` success/failure scenarios
- Simulate different git repository states (no repo, empty repo, etc.)

**File System Operations**
- Mock Agent OS directory structures for testing
- Simulate missing or corrupted spec files
- Mock file permission errors and disk space issues
- Create test environments with different Agent OS configurations

### Performance Tests

**Hook Execution Speed**
- Each hook must execute in under 500ms
- Context injection must not add significant delay to prompt processing
- Auto-commit operations must complete quickly without blocking user
- Workflow detection must be efficient with large project directories

**Resource Usage**
- Hooks must not consume excessive memory during execution
- Log files must not grow unbounded (implement rotation)
- Temporary files must be cleaned up properly
- Network operations (GitHub API) must have appropriate timeouts

### Error Scenario Tests

**Network Failures**
- GitHub API unavailable during PR checks
- Git remote operations failing during auto-commit
- Timeout scenarios for external command execution

**File System Issues**
- Permission denied errors for Agent OS directories
- Disk space exhaustion during auto-commit operations
- Corrupted or malformed Agent OS configuration files
- Missing dependencies (git, gh CLI not installed)

**Concurrency Issues**
- Multiple hooks executing simultaneously
- File locking conflicts during auto-commit
- Race conditions between workflow detection and state changes

## Test Implementation Strategy

### Shell Script Testing Framework
- Use `bats` (Bash Automated Testing System) for shell script testing
- Create test fixtures with known Agent OS project states
- Implement setup and teardown functions for test isolation
- Use temporary directories for safe test execution

### Mock Implementation
- Create mock implementations of `git`, `gh`, and file system operations
- Use environment variables to control mock behavior during tests
- Implement test-specific versions of utility functions
- Ensure mocks can simulate both success and failure scenarios

### Continuous Integration
- Run all tests on multiple platforms (macOS, Linux, WSL)
- Test with different versions of git and GitHub CLI
- Verify compatibility with various Agent OS installation states
- Include performance benchmarks in CI pipeline

### Manual Testing Procedures
- Step-by-step workflow testing with real Claude Code integration
- User experience testing for hook feedback and error messages
- Compatibility testing with existing Agent OS installations
- Performance validation under realistic usage conditions