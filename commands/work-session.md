# Work Session Management

Agent OS work session commands for batched development workflows.

## Usage

Start a work session to batch multiple changes without forced commits:

```bash
/work-session start "Optimize IntroViewModel performance"
```

Create logical commits during the session:

```bash  
/work-session commit "Remove force unwraps and add dependency injection"
/work-session commit "Add animation configuration constants"
/work-session commit "Implement enum-based state management"
```

End the session and validate workflow:

```bash
/work-session end
```

## Commands

- `/work-session start [description]` - Begin batched work mode
- `/work-session status` - Show current session information  
- `/work-session commit "message"` - Create a logical commit with context
- `/work-session end` - Finish session and validate workflow
- `/work-session abort` - Cancel current session

## Environment

Work sessions set `AGENT_OS_WORK_SESSION=true` which:
- Allows multiple file operations without forced commits
- Maintains workflow quality checks at session boundaries
- Enables logical grouping of related changes
- Reduces commit noise while preserving traceability

## Example Workflow

```bash
# Start focused work session
/work-session start "Fix authentication bugs"

# Make multiple changes without commit spam
# Edit auth service
# Update tests  
# Fix configuration

# Create logical commits
/work-session commit "Fix OAuth token refresh logic"
/work-session commit "Add comprehensive auth tests"
/work-session commit "Update auth configuration for new endpoints"

# End session
/work-session end
```

This approach maintains Agent OS quality standards while eliminating excessive commit noise.