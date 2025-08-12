# Context-Aware Hook Wrapper

## Overview

The Context-Aware Hook Wrapper (`context_aware_hook.py`) provides intelligent workflow enforcement that distinguishes between maintenance work and new development work based on user intent analysis.

## Key Features

- **Maintenance Work**: Allowed even with dirty workspace/open PRs (bug fixes, debugging, CI fixes)
- **New Development Work**: Requires clean workspace following Agent OS workflow (new features, components)
- **Ambiguous Intent**: Interactive prompts for user clarification
- **Manual Override**: Environment variable support for forcing work type
- **Performance Optimized**: <10% overhead compared to original hook (measured at 8.5%)

## Usage

### Basic Usage

The context-aware hook can be used as a drop-in replacement for the original workflow enforcement hook:

```bash
# Via Claude Code hooks (recommended)
echo '{"tool_name": "Edit", "tool_input": {"file_path": "/test/file.py"}, "user_message": "fix failing tests"}' | python3 context_aware_hook.py pretool
```

### Manual Override

Force work type classification using environment variables:

```bash
# Force maintenance behavior (allows work regardless of workspace state)
AGENT_OS_WORK_TYPE=maintenance python3 context_aware_hook.py pretool

# Force new work behavior (requires clean workspace)
AGENT_OS_WORK_TYPE=new_work python3 context_aware_hook.py pretool
```

### Debug Mode

Enable detailed logging for troubleshooting:

```bash
AGENT_OS_DEBUG=true python3 context_aware_hook.py pretool
```

Logs are written to: `~/.agent-os/logs/context-aware-hook-debug.log`

## Intent Classification Examples

### Maintenance Work (Always Allowed)
- "fix the failing tests"
- "debug CI pipeline issue"  
- "resolve merge conflicts"
- "fix broken functionality"
- "update dependencies"

### New Development Work (Requires Clean Workspace)
- "implement user authentication feature"
- "create dashboard component"
- "add search functionality"
- "build user profile interface"

### Ambiguous Intent (User Prompted)
- "refactor the code"
- "update the interface"
- "change the behavior"

## Integration with Existing Workflow

The context-aware hook preserves all existing workflow enforcement behavior while adding intelligence:

1. **Investigation Tools**: Always allowed (Read, Glob, Grep, LS)
2. **Git Commands**: Always allowed (git status, git commit, etc.)
3. **Subagent Enforcement**: Maintained for Task tool usage
4. **User Prompt Context**: Enhanced with intent analysis information

## Testing

Run the comprehensive test suite:

```bash
# Unit tests
python3 test_context_aware_hook.py

# Integration tests  
python3 integration_test.py

# Intent analyzer tests
python3 test_intent_analyzer.py
```

## Performance

Performance benchmark results:
- Original hook: ~0.46s average
- Context-aware hook: ~0.50s average
- Overhead: 8.5% (meets <10% requirement)

## Architecture

The Context-Aware Hook Wrapper integrates:

1. **Intent Analysis Engine** (`intent_analyzer.py`): Pattern-based message classification
2. **Workspace State Detection**: Git status and PR checking
3. **Original Hook Behavior**: Preserved for backward compatibility
4. **User Interaction**: Prompts for ambiguous cases

## Exit Codes

- `0`: Allow work to proceed
- `2`: Block work with user guidance
- `1`: Error condition

## Troubleshooting

### Common Issues

1. **False Intent Detection**: Use manual override with `AGENT_OS_WORK_TYPE`
2. **Performance Concerns**: Enable debug mode to identify bottlenecks
3. **Integration Issues**: Verify original hook functionality first

### Debug Information

Enable debug logging to see:
- Intent analysis results
- Workspace state detection
- Decision-making process
- Performance timing

## Implementation Status

✅ **Task 2 Complete**: Context-Aware Hook Wrapper fully implemented

- [x] Comprehensive test suite (18 tests)
- [x] Integration with Intent Analysis Engine
- [x] Workspace state evaluation
- [x] Manual override system
- [x] Backward compatibility preserved
- [x] Performance requirements met (<10% overhead)
- [x] Integration testing passed

Ready for integration with existing Agent OS workflows.