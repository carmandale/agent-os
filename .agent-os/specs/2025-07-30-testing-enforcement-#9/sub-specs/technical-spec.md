# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-30-testing-enforcement-#9/spec.md

> Created: 2025-07-30
> Version: 1.0.0

## Technical Requirements

- **Testing Detection System**: Implement pattern-based detection for completion claims without testing evidence
- **Evidence Validation**: Create comprehensive patterns to identify testing evidence in Claude's responses
- **Work Type Classification**: Detect frontend/backend/script work to provide appropriate testing guidance
- **Hook Integration**: Seamlessly integrate with existing Claude Code hooks infrastructure
- **Real-time Blocking**: Prevent completion claims at the moment they're made, not after
- **Context-aware Reminders**: Inject testing requirements based on detected work type

## Approach Options

**Option A:** Post-processing in stop hook only
- Pros: Simple implementation, single integration point
- Cons: Only catches at conversation end, may miss mid-conversation claims

**Option B:** Multi-hook integration (Selected)
- Pros: Real-time detection, multiple intervention points, comprehensive coverage
- Cons: More complex implementation, requires coordination between hooks

**Option C:** Standalone validation tool
- Pros: Independent of hooks, could work with other tools
- Cons: Requires manual invocation, doesn't prevent false claims

**Rationale:** Multi-hook integration provides the best user experience by catching false completion claims immediately and providing contextual guidance throughout the workflow.

## External Dependencies

- **No new external dependencies required**
- Uses existing bash scripting capabilities
- Leverages current hook infrastructure
- Pattern matching via grep/bash built-ins

## Implementation Architecture

### Core Components

1. **testing-enforcer.sh** - Main detection and validation logic
   - Pattern arrays for completion and evidence detection
   - Work type classification system
   - Testing reminder generation

2. **Hook Integrations**
   - stop-hook.sh - Block completion without evidence
   - user-prompt-submit-hook.sh - Inject testing reminders
   - post-tool-use-hook.sh - Monitor for completion claims

3. **Workflow Module Updates**
   - step-3-quality-assurance.md - Enforce testing requirements
   - Completion templates with mandatory evidence sections

### Pattern Design

**Completion Patterns**: Space-prefixed to avoid false positives
- " complete", " finished", " done", " ready"
- Emoji indicators: ✓, ✅, 🎉

**Evidence Patterns**: Regex-based for flexibility
- Test execution: "test.*pass", "npm.*test"
- Browser validation: "browser.*test", "verified.*in.*browser"
- API testing: "curl.*http", "api.*call"

### Integration Points

1. **Stop Hook**: Primary enforcement point
2. **User Prompt Submit**: Proactive guidance injection
3. **Post Tool Use**: Real-time monitoring
4. **Workflow Modules**: Documentation updates