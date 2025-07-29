# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-29-claude-code-hooks-#37/spec.md

> Created: 2025-07-29
> Version: 1.0.0

## Technical Requirements

### Claude Code Hooks Integration
- Implement three Claude Code hook types: stop, postToolUse, and userPromptSubmit
- Create JSON configuration files that Claude Code can read for hook registration
- Ensure hooks work across all Agent OS workflows (create-spec, execute-tasks, plan-product)
- Maintain compatibility with existing Agent OS shell script architecture

### Workflow State Detection
- Implement intelligent detection of Agent OS workflow completion states
- Track workflow progress through filesystem markers and git status
- Detect incomplete workflows (PRs not merged, issues not closed, workspace dirty)
- Provide clear feedback when workflows are abandoned or incomplete

### Automatic Documentation Management
- Auto-commit spec creation and updates with proper commit messages
- Reference GitHub issues in all automated commits
- Preserve existing manual commit workflows while adding automation
- Handle merge conflicts gracefully in documentation files

### Context Injection System
- Analyze user prompts to detect Agent OS workflow intentions  
- Inject relevant project context based on detected workflow type
- Include current specs, active tasks, and project standards automatically
- Maintain performance while adding context injection overhead

## Approach Options

**Option A: Single Monolithic Hook Script**
- Pros: Simple to implement, single file management
- Cons: Complex logic mixing, difficult to maintain, poor separation of concerns

**Option B: Modular Hook System with Shared Utilities** (Selected)
- Pros: Clear separation of concerns, reusable utilities, easier testing and maintenance
- Cons: More files to manage, slightly more complex setup

**Option C: Claude Code Extension Integration**
- Pros: Deep integration, potential for enhanced features
- Cons: Requires Claude Code extension development, dependency on Anthropic roadmap

**Rationale:** Option B provides the best balance of maintainability and functionality while staying within Agent OS's shell script architecture and avoiding external dependencies.

## Implementation Architecture

### File Structure
```
~/.agent-os/hooks/
├── claude-code-hooks.json        # Hook registration config
├── stop-hook.sh                  # Workflow completion enforcement
├── post-tool-use-hook.sh         # Auto-commit documentation
├── user-prompt-submit-hook.sh    # Context injection
├── lib/
│   ├── workflow-detector.sh      # Shared workflow detection logic
│   ├── git-utils.sh              # Git operation utilities
│   └── context-builder.sh        # Context injection utilities
└── install-hooks.sh              # Hook installation script
```

### Hook Registration Configuration
```json
{
  "version": "1.0.0",
  "hooks": {
    "stop": {
      "script": "~/.agent-os/hooks/stop-hook.sh",
      "description": "Enforce Agent OS workflow completion",
      "enabled": true
    },
    "postToolUse": {
      "script": "~/.agent-os/hooks/post-tool-use-hook.sh", 
      "description": "Auto-commit Agent OS documentation",
      "enabled": true
    },
    "userPromptSubmit": {
      "script": "~/.agent-os/hooks/user-prompt-submit-hook.sh",
      "description": "Inject Agent OS context",
      "enabled": true
    }
  }
}
```

### Workflow Detection Logic
- Parse git status to identify uncommitted Agent OS documentation
- Check for open PRs created by Agent OS workflows
- Detect Agent OS spec folders and task completion states
- Analyze user prompts for Agent OS workflow keywords and patterns

### Performance Considerations
- Minimize hook execution time to avoid user experience delays
- Cache workflow state information to reduce filesystem operations
- Implement efficient pattern matching for prompt analysis
- Use exit codes and early returns to optimize execution paths

## External Dependencies

**None Required** - Implementation uses only built-in shell utilities and Git
- **Justification:** Maintains Agent OS philosophy of minimal dependencies and broad compatibility
- **Git dependency:** Already required by Agent OS core functionality
- **Shell utilities:** Standard across all supported platforms (macOS, Linux, WSL)

## Integration Points

### Claude Code Hook System
- Hooks must conform to Claude Code's expected interface and response format
- Error handling must not break Claude Code functionality
- Logging and debugging output must be properly managed

### Agent OS Workflow Scripts  
- Hooks must detect and interact properly with existing workflow scripts
- Maintain backward compatibility with current Agent OS installations
- Preserve existing command-line interfaces and behaviors

### GitHub Integration
- Auto-commit functionality must integrate with existing GitHub workflows
- Issue referencing must follow Agent OS conventions
- PR creation and management must remain consistent with current practices