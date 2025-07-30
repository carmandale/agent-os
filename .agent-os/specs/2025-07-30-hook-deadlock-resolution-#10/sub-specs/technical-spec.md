# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-30-hook-deadlock-resolution-#10/spec.md

> Created: 2025-07-30
> Version: 1.0.0

## Technical Requirements

### Hook Intelligence Enhancement
- Differentiate between read-only and write operations
- Allow investigation commands (ls, cat, grep) when workspace is dirty
- Block only operations that would create more uncommitted changes
- Maintain security by preventing file modifications during dirty state

### Enhanced Error Messaging
- Context-aware messages based on blocked operation type
- Highlight allowed operations in bold/caps
- Provide copy-paste ready commands for common resolutions
- Include examples of successful resolution paths

### Workflow Recovery System
- Detect when Claude is in a loop trying blocked operations
- Provide escalating guidance on subsequent attempts
- Track resolution attempts to provide better help
- Guide through decision tree: commit, stash, or discard

### Debug Mode Implementation
- Read-only mode flag that allows investigation
- Clear indication when in debug mode
- Automatic exit from debug mode after resolution
- Audit trail of debug mode usage

## Approach Options

**Option A: Modify existing hooks to be smarter**
- Pros: Minimal changes, maintains current architecture
- Cons: May not fully resolve all deadlock scenarios

**Option B: Add separate debug mode hooks** (Selected)
- Pros: Clear separation of concerns, easier to test, more flexible
- Cons: Slightly more complex implementation

**Option C: Completely revise hook strategy**
- Pros: Could solve problem comprehensively
- Cons: Major breaking change, requires extensive testing

**Rationale:** Option B provides the best balance of solving the immediate problem while maintaining system stability and providing future flexibility.

## Implementation Details

### 1. Hook Command Classification
```python
READ_ONLY_COMMANDS = [
    "ls", "cat", "head", "tail", "grep", "find", "pwd", "echo",
    "git status", "git diff", "git log", "gh pr list", "gh issue list"
]

WRITE_COMMANDS = [
    "touch", "mkdir", "rm", "mv", "cp", "chmod",
    "npm install", "pip install", "yarn add"
]
```

### 2. Enhanced Decision Logic
```python
def should_block_command(tool_name, command, workspace_state):
    if tool_name == "Bash":
        # Always allow git commands for resolution
        if command.startswith(("git ", "gh ")):
            return False
        
        # In dirty state, check command type
        if workspace_state.has_uncommitted_changes:
            # Allow read-only investigation
            if is_read_only_command(command):
                return False
            # Block write operations
            return True
    
    # Block file modifications in dirty state
    if tool_name in ["Write", "Edit", "MultiEdit"]:
        return workspace_state.has_uncommitted_changes
    
    return False
```

### 3. Progressive Guidance System
```python
def get_guidance_message(attempt_count, operation_type, workspace_issues):
    if attempt_count == 1:
        return standard_guidance(workspace_issues)
    elif attempt_count == 2:
        return detailed_guidance_with_examples(workspace_issues)
    elif attempt_count >= 3:
        return step_by_step_resolution_guide(workspace_issues)
```

### 4. Debug Mode Toggle
```bash
# Enable debug mode for investigation
export AGENT_OS_DEBUG_MODE=true

# Auto-disable after 30 minutes or explicit disable
export AGENT_OS_DEBUG_MODE=false
```

## External Dependencies

**None Required** - Uses only Python standard library and existing shell utilities

## Integration Points

### Claude Instruction Updates
Update execute-tasks.md and workflow modules to include:
- Recognition of new hook messages
- Understanding of allowed vs blocked operations
- Debug mode workflow

### Hook Message Templates
Create standardized templates for:
- Read-only operation allowance
- Write operation blocking
- Debug mode activation
- Resolution success

## Performance Considerations

- Command classification must be fast (<10ms)
- Cache classification results for repeated commands
- Minimal overhead on allowed operations
- Clear logging for debugging hook behavior