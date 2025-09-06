# Implementation Tasks: verify-installation.sh

> **Spec:** 2025-09-06-verify-installation-script-#92  
> **Issue:** #92  
> **Priority:** High  
> **Estimated Effort:** Medium (M)

## Task Overview

Implementation of comprehensive installation verification script following Agent OS TDD workflow and quality standards.

## Phase 1: Foundation & Testing Framework

### Task 1.1: Create Test Framework Structure
- [ ] Create `tests/test-verify-installation.bats` test file
- [ ] Create `tests/helpers/verification-helpers.bash` utility functions
- [ ] Create `tests/fixtures/` directory with mock installation structures
- [ ] Setup basic test harness for verification functions

**Acceptance Criteria:**
- Test framework runs without errors
- Mock installation fixtures are realistic
- Helper functions support common test patterns
- Tests can be executed via `bats tests/test-verify-installation.bats`

**Estimated Time:** 4 hours

---

### Task 1.2: Implement Core Unit Tests
- [ ] Write tests for directory structure validation
- [ ] Write tests for file integrity checking
- [ ] Write tests for permission validation
- [ ] Write tests for error handling and reporting

**Acceptance Criteria:**
- All unit tests are written following Bats patterns
- Tests cover both success and failure scenarios
- Error message formatting is validated
- Edge cases are covered with specific test cases

**Estimated Time:** 6 hours

---

## Phase 2: Core Verification Functions

### Task 2.1: Create Main Script Structure
- [ ] Create `scripts/verify-installation.sh` with proper shebang and permissions
- [ ] Implement command-line argument parsing (--quick, --full, --hooks-only, etc.)
- [ ] Setup colored output functions and error reporting framework
- [ ] Implement exit code handling and logging structure

**Acceptance Criteria:**
- Script accepts all specified command-line options
- Colored output works correctly on supported terminals
- Exit codes match specification (0=success, 1=critical, 2=warnings, 3=script error)
- Help text is comprehensive and accurate

**Estimated Time:** 4 hours

---

### Task 2.2: Implement Directory Structure Validation
- [ ] Write `validate_directory_structure()` function
- [ ] Check ~/.agent-os/ directory exists and has correct permissions
- [ ] Validate required subdirectories (instructions/, standards/, hooks/, etc.)
- [ ] Check file ownership and access rights

**Acceptance Criteria:**
- Function detects missing directories and reports specific issues
- Permission problems are identified with actionable fix suggestions
- Function passes all unit tests
- Performance is optimized for quick execution

**Estimated Time:** 3 hours

---

### Task 2.3: Implement File Integrity Validation
- [ ] Write `validate_file_integrity()` function
- [ ] Check core script files exist and are executable
- [ ] Validate configuration files have correct syntax (JSON, YAML parsing)
- [ ] Verify template files are complete and properly formatted

**Acceptance Criteria:**
- Missing files are detected and reported clearly
- Configuration syntax errors are caught and explained
- Script executability is validated
- Function handles edge cases gracefully

**Estimated Time:** 4 hours

---

## Phase 3: Advanced Verification Features

### Task 3.1: Implement Claude Code Hooks Validation
- [ ] Write `validate_claude_hooks()` function
- [ ] Check ~/.claude/settings.json exists and is valid JSON
- [ ] Verify all hook file references point to existing, executable scripts
- [ ] Test hook configuration syntax and structure

**Acceptance Criteria:**
- Hook configuration validation is comprehensive
- Missing or broken hook references are detected
- Function provides specific guidance for hook issues
- Dry-run testing of hooks works without side effects

**Estimated Time:** 5 hours

---

### Task 3.2: Implement CLI Command Validation
- [ ] Write `validate_cli_commands()` function
- [ ] Test aos command availability and basic functionality
- [ ] Verify PATH configuration includes Agent OS tools
- [ ] Test subcommands respond correctly (aos status, aos update, etc.)

**Acceptance Criteria:**
- CLI command availability is accurately detected
- PATH issues are identified and fixable
- Subcommand testing is thorough but fast
- Function integrates with existing aos CLI structure

**Estimated Time:** 3 hours

---

### Task 3.3: Implement Git Integration Validation
- [ ] Write `validate_git_integration()` function  
- [ ] Check GitHub CLI installation and authentication
- [ ] Verify git configuration is present and valid
- [ ] Test repository access permissions where applicable

**Acceptance Criteria:**
- Git and GitHub CLI availability is verified
- Authentication issues are detected and reported
- Basic git configuration is validated
- Function handles cases where git integration is optional

**Estimated Time:** 3 hours

---

## Phase 4: Integration & Performance

### Task 4.1: Integrate with Existing Tools
- [ ] Add verification command to `tools/aos` CLI script
- [ ] Integrate with existing `check-agent-os.sh` health check
- [ ] Update `setup.sh` to run post-installation verification
- [ ] Ensure compatibility with MAINTENANCE-CHECKLIST.md workflow

**Acceptance Criteria:**
- `aos verify` command works correctly with all options
- Health check integration doesn't break existing functionality
- Setup script verification is optional but recommended
- MAINTENANCE-CHECKLIST.md reference is now functional

**Estimated Time:** 4 hours

---

### Task 4.2: Optimize Performance and User Experience
- [ ] Implement quick verification mode (< 5 seconds)
- [ ] Optimize full verification mode (< 30 seconds)
- [ ] Add progress indicators for long-running operations
- [ ] Implement caching for expensive operations

**Acceptance Criteria:**
- Quick mode meets performance requirements
- Full mode provides comprehensive coverage within time limits
- User experience is smooth with clear progress indication
- Resource usage is minimal and appropriate

**Estimated Time:** 3 hours

---

## Phase 5: Documentation & Quality Assurance

### Task 5.1: Create Comprehensive Integration Tests
- [ ] Write end-to-end test scenarios
- [ ] Test integration with aos CLI
- [ ] Create performance benchmark tests
- [ ] Test error recovery scenarios

**Acceptance Criteria:**
- Integration tests cover realistic user workflows
- Performance tests validate timing requirements
- Error scenarios are tested comprehensively
- Tests can run in CI/CD environment

**Estimated Time:** 5 hours

---

### Task 5.2: Create Documentation and Usage Examples
- [ ] Write usage documentation in script header
- [ ] Create troubleshooting guide for common issues
- [ ] Add examples to MAINTENANCE-CHECKLIST.md
- [ ] Document integration with existing Agent OS tools

**Acceptance Criteria:**
- Documentation is complete and accurate
- Troubleshooting guide covers common installation issues
- Examples are tested and working
- Integration documentation helps users understand the full workflow

**Estimated Time:** 3 hours

---

### Task 5.3: Final Testing and Quality Validation
- [ ] Run complete test suite and achieve >95% coverage
- [ ] Test on clean systems to validate functionality
- [ ] Perform security review of script implementation
- [ ] Validate cross-platform compatibility (macOS/Linux)

**Acceptance Criteria:**
- All tests pass consistently
- Script works correctly on fresh installations
- Security review finds no vulnerabilities
- Cross-platform compatibility is verified

**Estimated Time:** 4 hours

---

## Summary

**Total Estimated Time:** 54 hours  
**Phases:** 5 phases with 11 tasks  
**Dependencies:** Agent OS core installation, Claude Code hooks system, existing CLI tools  
**Risk Areas:** Claude Code hooks complexity, cross-platform compatibility, performance optimization

### Critical Path Items
1. Test framework creation (enables TDD approach)
2. Core verification functions (primary functionality)  
3. Claude Code hooks validation (most complex component)
4. Integration with existing tools (ensures usability)

### Definition of Done Checklist
- [ ] All unit tests pass
- [ ] All integration tests pass  
- [ ] Performance requirements are met
- [ ] Script works on clean installations
- [ ] Documentation is complete
- [ ] MAINTENANCE-CHECKLIST.md reference is functional
- [ ] aos verify command is available and working
- [ ] Security review is complete