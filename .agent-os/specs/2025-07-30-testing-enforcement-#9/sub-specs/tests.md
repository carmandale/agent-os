# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-30-testing-enforcement-#9/spec.md

> Created: 2025-07-30
> Version: 1.0.0

## Test Coverage

### Unit Tests

**testing-enforcer.sh**
- Pattern detection for completion claims (positive and negative cases)
- Evidence pattern validation (all evidence types)
- Work type detection accuracy (frontend/backend/script/general)
- Testing reminder generation for each work type
- Edge cases: mixed case, partial matches, false positives

**Hook Integration Tests**
- Stop hook blocking behavior with testing enforcer
- Context injection in user-prompt-submit
- Error handling and fallback behavior
- Performance impact (<100ms overhead)

### Integration Tests

**Workflow Integration**
- Complete workflow with false completion attempt
- Testing enforcement intervention and recovery
- Multiple completion attempts with/without evidence
- Different work types triggering appropriate responses

**Cross-Hook Communication**
- Testing enforcer availability across all hooks
- Consistent behavior in different workflow phases
- State persistence between hook invocations

### End-to-End Tests

**Frontend Work Scenarios**
- React component completion without browser testing → BLOCKED
- UI changes with Playwright evidence → ALLOWED
- Mixed frontend/backend work → Appropriate guidance

**Backend Work Scenarios**
- API endpoint completion without curl/testing → BLOCKED
- Database changes with pytest output → ALLOWED
- Script creation without execution proof → BLOCKED

**Edge Cases**
- Completion claims in code comments (should ignore)
- Testing evidence in different formats
- Non-English completion phrases
- Partial workflow abandonment

### Mocking Requirements

- **Git State**: Mock clean/dirty states for workflow detection
- **Conversation Content**: Simulate various completion claim patterns
- **Work Context**: Mock different project types and configurations

## Test Execution Strategy

1. **Unit Test Suite**: Run via `bash tests/test-testing-enforcer.sh`
2. **Integration Tests**: Manual validation with real Claude sessions
3. **Performance Tests**: Measure hook overhead with timing
4. **Regression Tests**: Ensure no impact on existing functionality

## Success Criteria

- 100% unit test coverage for pattern detection
- Zero false positives in completion detection
- <100ms performance overhead
- All work types properly classified
- Appropriate testing guidance for each scenario