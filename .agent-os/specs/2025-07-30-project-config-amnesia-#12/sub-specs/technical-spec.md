# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-30-project-config-amnesia-#12/spec.md

> Created: 2025-07-30
> Version: 1.0.0

## Technical Requirements

### Project Context Loading System
- **Automatic Configuration Detection**: Scan for .env, .env.local, start.sh, tech-stack.md at session start
- **Configuration Parsing**: Extract port numbers, package managers, startup commands from various file formats
- **Hierarchy Resolution**: Apply precedence rules to resolve conflicting configuration sources
- **Error Handling**: Graceful fallback when configuration files are malformed or missing

### Session Memory Persistence
- **In-Memory Configuration Cache**: Store resolved configuration in session-persistent variables
- **Context Refresh Triggers**: Re-validate configuration when key files change during session
- **Cross-Tool Communication**: Share configuration state between different Agent OS workflow components
- **Session Validation**: Periodically verify that Claude is still respecting loaded configuration

### Hook Integration Enhancement  
- **Enhanced Context Injection**: Expand existing user-prompt-submit-hook to include project configuration
- **Configuration Validation Hook**: Add pre-command validation to catch configuration violations
- **Auto-Correction**: Automatically adjust commands that violate established project configuration
- **Performance Optimization**: Minimize hook execution time while maximizing configuration awareness

## Approach Options

**Option A:** Extend Existing Hook System
- Pros: Leverages existing Claude Code hooks infrastructure, seamless integration
- Cons: Claude Code specific, requires hook system to be installed

**Option B:** Standalone Configuration Service (Selected)
- Pros: Works with any AI tool, can be called independently, modular design
- Cons: Requires explicit invocation, additional integration work for different tools

**Option C:** Environment Variable Injection
- Pros: Simple implementation, universal compatibility
- Cons: Limited to environment variables, potential conflicts with user environment

**Rationale:** Option B provides the best balance of functionality and compatibility while maintaining Agent OS's tool-agnostic philosophy. It can be integrated with the existing hook system for Claude Code users while remaining available for other tools.

## External Dependencies

**No New Dependencies Required**
- Utilizes existing bash scripting capabilities
- Leverages current Agent OS file structure
- Integrates with existing hook system (optional)

## Implementation Architecture

### Core Components

1. **project-context-loader.sh** - Main configuration detection and loading script
2. **config-resolver.py** - Python script for complex configuration parsing and hierarchy resolution
3. **session-memory.sh** - Session persistence and validation utilities
4. **config-validator.sh** - Pre-command validation and auto-correction

### File Structure
```
~/.agent-os/scripts/
├── project-context-loader.sh          # Main entry point
├── config-resolver.py                 # Configuration parsing logic
├── session-memory.sh                  # Session state management
└── config-validator.sh                # Command validation

~/.agent-os/templates/
└── project-config-template.json       # Configuration schema template
```

### Integration Points

**Hook System Integration:**
- Modify user-prompt-submit-hook.sh to call project-context-loader.sh
- Add config-validator.sh to pre-command execution hooks
- Extend context injection to include resolved configuration

**Workflow Module Integration:**
- Update step-1-hygiene-and-setup.md to include mandatory context loading
- Modify execute-tasks.md to reference loaded configuration
- Enhance project-context-loader references in workflow modules

## Configuration Detection Logic

### Detection Priority (Most Specific to Most General)

1. **Project Environment Files** (.env, .env.local)
   - Port numbers (PORT, API_PORT, FRONTEND_PORT, BACKEND_PORT)
   - Service URLs (REACT_APP_API_URL, VITE_API_URL, etc.)
   - Package manager hints (NODE_PACKAGE_MANAGER, PYTHON_PACKAGE_MANAGER)

2. **Project Startup Scripts** (start.sh, dev.sh, package.json scripts)
   - Actual package manager commands used
   - Server startup commands with port specifications
   - Development environment activation sequences

3. **Agent OS Project Configuration** (@.agent-os/product/tech-stack.md)
   - Documented package manager choices
   - Specified port configuration
   - Startup command definitions

4. **Agent OS Global Standards** (@~/.agent-os/standards/tech-stack.md)
   - User's default tech stack preferences
   - Fallback configuration values

### Configuration Resolution Algorithm

```bash
# Pseudo-code for configuration resolution
function resolve_configuration() {
    local config="{}"
    
    # Load global defaults
    config=$(merge_config "$config" "$(load_global_standards)")
    
    # Override with project Agent OS settings
    if [[ -f ".agent-os/product/tech-stack.md" ]]; then
        config=$(merge_config "$config" "$(parse_tech_stack)")
    fi
    
    # Override with startup script analysis
    if [[ -f "start.sh" ]]; then
        config=$(merge_config "$config" "$(analyze_startup_script)")
    fi
    
    # Override with environment files (highest priority)
    for env_file in .env.local .env; do
        if [[ -f "$env_file" ]]; then
            config=$(merge_config "$config" "$(parse_env_file $env_file)")
        fi
    done
    
    return "$config"
}
```

## Session Memory Implementation

### Memory Storage Strategy
- **Environment Variables**: Store resolved configuration in session environment variables
- **Temporary Files**: Use ~/.agent-os/cache/session-config.json for complex configuration
- **Hook State**: Maintain configuration state in hook execution context

### Validation Checkpoints
- **Pre-Command**: Validate command parameters against stored configuration
- **Mid-Session**: Re-validate when key files are modified
- **Post-Command**: Verify that executed commands respected configuration

### Performance Considerations
- **Lazy Loading**: Only load configuration when needed
- **Caching**: Cache parsed configuration to avoid repeated file system operations
- **Incremental Updates**: Only re-parse files that have changed

## Error Handling and Recovery

### Common Error Scenarios
1. **Malformed Configuration Files**: Graceful parsing with sensible fallbacks
2. **Missing Dependencies**: Clear error messages with resolution steps
3. **Configuration Conflicts**: Automatic resolution using precedence rules
4. **Permission Issues**: Fallback to read-only configuration detection

### Recovery Mechanisms
- **Automatic Fallback**: Revert to higher-level configuration when specific settings fail
- **User Notification**: Clear messaging about configuration issues and resolutions
- **Debug Mode**: Detailed logging for troubleshooting configuration problems
- **Reset Capability**: Option to clear cached configuration and reload from files