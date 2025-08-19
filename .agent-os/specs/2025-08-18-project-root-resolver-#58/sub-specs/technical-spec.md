# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-18-project-root-resolver-#58/spec.md

> Created: 2025-08-18
> Version: 1.0.0

## Technical Requirements

### Core Project Root Resolver Module

- **Language**: Python 3.8+ for consistency with existing hooks
- **Location**: `scripts/project-root-resolver.py` (new file)
- **Interface**: Both CLI and importable module
- **Error Handling**: Graceful fallbacks with clear error messages
- **Logging**: Compatible with existing Agent OS logging patterns

### Resolution Order Implementation

**Priority 1: CLAUDE_PROJECT_DIR Environment Variable**
- Check for `CLAUDE_PROJECT_DIR` environment variable
- Validate path exists and is accessible
- Use as-is if valid (no additional validation needed)

**Priority 2: Hook Payload Fields** 
- Extract from Claude Code hook payload: `workspaceDir`, `projectRoot`, `rootDir`
- Try each field in order, validate path exists
- Prefer more specific over generic fields

**Priority 3: File System Ascent**
- Start from current working directory or provided path
- Walk up directory tree looking for markers: `.agent-os/`, `.git/`, `.hg/`, `.svn/`
- Stop at first marker found or filesystem root
- Return directory containing the marker

**Priority 4: Current Working Directory Fallback**
- If all other methods fail, return current working directory
- Log warning about fallback usage

### Integration Points

**Hook Updates Required:**
- `hooks/workflow-enforcement-hook.py` - Replace current root detection
- `hooks/pre-bash-hook.sh` - Add resolver call for project context
- `hooks/post-bash-hook.sh` - Add resolver call for project context  
- `hooks/user-prompt-submit-hook.sh` - Add resolver call for project context

**Script Updates Required:**
- `scripts/config-resolver.py` - Replace current root detection logic
- Any other scripts that currently implement ad-hoc root detection

## Approach

**Option A: Pure Python Module** (Selected)
- Create standalone Python module with both CLI and import interfaces
- Hooks call via subprocess for shell compatibility
- Scripts import directly for efficiency
- Single source of truth for all root resolution

**Rationale:** This approach provides maximum reusability across both Python scripts and shell hooks while maintaining a single implementation that's easy to test and maintain.

## External Dependencies

- **None** - Use only Python standard library
- **Justification:** Avoiding external dependencies reduces installation complexity and ensures compatibility across different environments

## Implementation Details

### API Design

```python
def find_project_root(start_path=None, hook_payload=None):
    """
    Find project root using standardized resolution order.
    
    Args:
        start_path: Optional starting path (defaults to cwd)
        hook_payload: Optional Claude Code hook payload dict
    
    Returns:
        str: Absolute path to project root
        
    Raises:
        ProjectRootNotFoundError: If no valid root can be determined
    """
```

### CLI Interface

```bash
# Basic usage
python scripts/project-root-resolver.py

# With starting path
python scripts/project-root-resolver.py --start-path /path/to/subdir

# With hook payload (JSON)
python scripts/project-root-resolver.py --hook-payload '{"workspaceDir": "/path"}'

# Quiet mode (just return path)
python scripts/project-root-resolver.py --quiet
```

### Caching Strategy

- Simple in-memory cache keyed by start path
- Cache TTL of 60 seconds to handle path changes
- No persistent caching to avoid stale data issues