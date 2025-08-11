# Agent OS Claude Code Hooks

> Version: 1.0.0
> Status: Ready for Production

The Agent OS Claude Code hooks system provides seamless integration between Agent OS workflows and Claude Code, solving the critical workflow abandonment problem while enhancing AI assistance quality through automatic context injection and documentation management.

## Overview

Agent OS hooks integrate with Claude Code's native hook system to provide three core capabilities:

1. **Workflow Abandonment Prevention** - Automatically detects and prevents users from abandoning Agent OS workflows after quality check summaries
2. **Documentation Auto-Commit** - Maintains Agent OS documentation consistency by automatically committing changes
3. **Context Injection** - Enhances AI assistance by injecting relevant project, git, and workflow context

## Architecture

```
~/.agent-os/hooks/
├── lib/                        # Core utilities
│   ├── workflow-detector.sh    # Detects Agent OS workflows and risk patterns
│   ├── git-utils.sh           # Git operations and status management
│   └── context-builder.sh     # Builds contextual information
├── stop-hook.sh               # Prevents workflow abandonment
├── post-tool-use-hook.sh      # Auto-commits documentation
├── user-prompt-submit-hook.sh # Injects context information
├── pre-bash-hook.sh           # Observes Bash commands (PreToolUse)
├── post-bash-hook.sh          # Reports Bash results (PostToolUse)
├── notify-hook.sh             # Optional notifications
├── install-hooks.sh           # Installation script
├── uninstall-hooks.sh         # Removal script
├── agent-os-bash-hooks.json   # Hook configuration with matchers
└── tests/                     # Comprehensive test suite
    ├── run-tests.sh
    ├── test-workflow-detector.sh
    ├── test-git-utils.sh
    ├── test-hook-integration.sh
    └── test-utilities.sh
```

## Hook Details

### Stop Hook (`stop-hook.sh`)
**Purpose**: Prevents workflow abandonment by detecting completion patterns that typically lead users to abandon Agent OS workflows.

**Triggers**:
- High-risk completion messages (e.g., "Quality checks passed", "Implementation complete")
- Agent OS workflow contexts with abandonment risk

**Actions**:
- Displays workflow continuation reminders
- Auto-commits uncommitted Agent OS documentation
- Provides next step guidance

**Example Output**:
```
⚠️ **Workflow Abandonment Prevention Active**

This appears to be a completion summary that may lead to workflow abandonment. 
Remember that Agent OS workflows require full integration (commit → PR → merge) to be considered complete.

**Required Next Steps:**
1. Commit changes with proper issue reference
2. Create pull request  
3. Complete integration workflow
```

### Post Tool Use Hook (`post-tool-use-hook.sh`)
**Purpose**: Maintains documentation consistency by automatically committing Agent OS file changes after tool use.

**Triggers**:
- Edit/Write operations on `.agent-os/` files
- Agent OS workflow contexts

**Actions**:
- Detects uncommitted Agent OS documentation changes
- Creates automatic commits with standardized messages
- Maintains git history cleanliness

**Commit Message Format**:
```
docs: update Agent OS documentation

🤖 Auto-committed by Agent OS hooks to maintain documentation consistency

Co-Authored-By: Claude <noreply@anthropic.com>
```

### User Prompt Submit Hook (`user-prompt-submit-hook.sh`)
**Purpose**: Enhances AI assistance by injecting relevant contextual information before processing user prompts.

**Triggers**:
- Agent OS workflow conversations
- Agent OS project directories
- Agent OS-related user messages

**Context Injection**:
- Project information (mission, tech stack, active specs)
- Git status (branch, workspace state, issues)
- Workflow state (phase, abandonment risk, suggestions)
- Development standards (global and project-specific)
- Current task progress

### Pre-Bash Hook (`pre-bash-hook.sh`)
**Purpose**: Observes and classifies Bash commands before execution without blocking.

**Triggers**:
- PreToolUse event with Bash matcher
- Any Bash command executed through Claude Code

**Actions**:
- Classifies command intent (server/test/build/other)
- Logs command to `observed-bash.jsonl`
- Provides brief status message (e.g., "🚀 Starting development server...")
- Never blocks execution

**Intent Classification**:
- **Server**: npm run dev, python manage.py runserver, etc.
- **Test**: pytest, jest, npm test, etc.
- **Build**: npm build, make, cargo build, etc.
- **Other**: All other commands

### Post-Bash Hook (`post-bash-hook.sh`)
**Purpose**: Reports Bash command execution results and provides helpful suggestions.

**Triggers**:
- PostToolUse event with Bash matcher
- After any Bash command completes

**Actions**:
- Parses stdin JSON for command details and exit code
- Logs results to `observed-bash.jsonl`
- Displays 1-3 line summary in transcript
- Suggests next actions based on command intent

**Output Example**:
```
📊 Bash command: npm run dev
   Status: ✅ Completed successfully
   💡 Say 'aos dashboard' to view running processes or 'tail server logs' to monitor output.
```

### Notify Hook (`notify-hook.sh`)
**Purpose**: Provides optional, gentle reminders based on recent Bash activity.

**Triggers**:
- Notification event
- Periodic Claude Code checks

**Actions**:
- Checks recent observed Bash activity
- Identifies patterns (running servers, test failures, frequent builds)
- Displays minimal, helpful reminders (max 3 lines)

**Example Notifications**:
- "🚀 Development server appears to be running. You can ask me to check logs."
- "⚠️ Recent test failures detected. Say 'grep error' to find issues."

**Example Context**:
```
---

🤖 Agent OS Context Injection

🏗️ **Agent OS Project Context:**
- **Product:** User Authentication System
- **Tech Stack:** React 18, FastAPI, PostgreSQL
- **Active Spec:** 2025-01-29-user-auth-#123
- **Current Feature:** User Authentication Flow

📋 **Repository Context:**
- **Branch:** feature-auth-#123
- **GitHub Issue:** #123
- **Workspace:** 2 modified, 0 untracked files

⚙️ **Workflow Context:**
- **Current Phase:** task-execution
- **Abandonment Risk:** medium
- **Suggestion:** Continue with current task implementation

---
```

## Installation

### Automatic Installation (Recommended)
Agent OS hooks are automatically offered during Claude Code setup:

```bash
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup-claude-code.sh | bash
```

When prompted, choose "y" to install Claude Code hooks.

### Manual Installation
```bash
# Install hooks directly
~/.agent-os/hooks/install-hooks.sh

# Or download and install
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/hooks/install-hooks.sh | bash
```

### Installation Verification
```bash
# Check hook configuration
ls -la ~/.claude/hooks/

# Check hook scripts
ls -la ~/.agent-os/hooks/

# Run test suite
~/.agent-os/hooks/tests/run-tests.sh
```

## Usage

Agent OS hooks operate **completely transparently** - no manual intervention required:

- **Automatic Detection**: Hooks detect Agent OS workflows automatically
- **Seamless Integration**: Works with normal Claude Code interactions  
- **Zero Configuration**: No settings to adjust after installation
- **Background Operation**: Runs invisibly during conversations

## Hook Matchers and JSON Parsing

### Claude Code Hook Events
Agent OS uses Claude Code's native hook events with matchers:

- **PreToolUse**: Triggered before tool execution with tool-specific matchers
- **PostToolUse**: Triggered after tool execution with results
- **Notification**: Periodic notifications
- **UserPromptSubmit**: Before processing user prompts
- **Stop**: When Claude is about to stop responding

### Stdin JSON Parsing
Hooks receive JSON payloads via stdin (not command-line arguments):

```bash
#!/usr/bin/env bash
# Read stdin JSON
payload="$(cat)"

# Parse with jq
tool_name="$(jq -r '.hookMetadata.toolName // empty' <<<"$payload")"
cmd="$(jq -r '.tool_input.command // empty' <<<"$payload")"
exit_code="$(jq -r '.tool_response.exit_code // empty' <<<"$payload")"
```

### Hook Matcher Configuration
```json
{
  "PreToolUse": [{
    "matcher": "Bash",
    "hooks": [{
      "type": "command",
      "command": "~/.agent-os/hooks/pre-bash-hook.sh"
    }]
  }],
  "PostToolUse": [{
    "matcher": "Bash|Write|Edit",
    "hooks": [{
      "type": "command", 
      "command": "~/.agent-os/hooks/post-tool-use-hook.sh"
    }]
  }]
}
```

## Configuration

Hook behavior is controlled by `~/.claude/hooks/agent-os-hooks.json`:

```json
{
  "hooks": {
    "stop": {
      "enabled": true,
      "priority": 1
    },
    "postToolUse": {
      "enabled": true, 
      "priority": 1
    },
    "userPromptSubmit": {
      "enabled": true,
      "priority": 1
    }
  },
  "settings": {
    "logLevel": "info",
    "autoCommitDocumentation": true,
    "contextInjection": true,
    "workflowEnforcement": true
  }
}
```

## Logging and Debugging

### Log Files
- `~/.agent-os/logs/stop-hook.log` - Stop hook execution log
- `~/.agent-os/logs/post-tool-use-hook.log` - Documentation commit log  
- `~/.agent-os/logs/user-prompt-submit-hook.log` - Context injection log

### Debug Mode
```bash
# Run individual hook tests
~/.agent-os/hooks/tests/run-tests.sh -t workflow-detector
~/.agent-os/hooks/tests/run-tests.sh -t git-utils
~/.agent-os/hooks/tests/run-tests.sh -t hook-integration

# Verbose test output
~/.agent-os/hooks/tests/run-tests.sh -v

# Test specific hook manually
~/.agent-os/hooks/stop-hook.sh "test conversation with Agent OS indicators"
```

### Common Issues

**Issue**: Hooks not triggering
- **Solution**: Verify installation with `ls ~/.claude/hooks/agent-os-hooks.json`
- **Check**: Ensure Claude Code is restarted after installation

**Issue**: Documentation not auto-committing  
- **Solution**: Verify git repository and permissions
- **Check**: Look for errors in `~/.agent-os/logs/post-tool-use-hook.log`

**Issue**: Context not injecting
- **Solution**: Ensure you're in an Agent OS project directory
- **Check**: Verify `.agent-os/` directory exists in project

## Testing

### Comprehensive Test Suite
```bash
# Run all tests
~/.agent-os/hooks/tests/run-tests.sh

# Run specific test suites
~/.agent-os/hooks/tests/run-tests.sh -t workflow-detector
~/.agent-os/hooks/tests/run-tests.sh -t git-utils  
~/.agent-os/hooks/tests/run-tests.sh -t hook-integration

# Verbose output for debugging
~/.agent-os/hooks/tests/run-tests.sh -v
```

### Test Coverage
- **Workflow Detection**: 11 test cases covering Agent OS workflow identification and risk assessment
- **Git Operations**: 17 test cases covering repository operations and Agent OS file management  
- **Hook Integration**: 16 test cases covering end-to-end hook functionality
- **Configuration**: Validation of all configuration files and installation scripts

## Uninstallation

```bash
# Remove hooks from Claude Code (preserves scripts)
~/.agent-os/hooks/uninstall-hooks.sh

# Completely remove all hook files
rm -rf ~/.agent-os/hooks/
rm -rf ~/.agent-os/logs/
```

## Compatibility

- **Claude Code**: Version 1.0.0+
- **Agent OS**: Version 1.0.0+
- **Operating Systems**: macOS, Linux, Windows (WSL)
- **Shell**: Bash 4.0+

## Development

### Contributing
1. Fork the repository
2. Create feature branch with issue reference
3. Run test suite: `~/.agent-os/hooks/tests/run-tests.sh`  
4. Submit pull request with test coverage

### Adding New Hooks
1. Create hook script in `hooks/`
2. Add configuration to `claude-code-hooks.json`
3. Add tests in `hooks/tests/`
4. Update installation script
5. Update documentation

## Support

- **GitHub Issues**: https://github.com/carmandale/agent-os/issues
- **Documentation**: https://github.com/carmandale/agent-os
- **Log Files**: Check `~/.agent-os/logs/` for detailed execution logs

---

**🚀 Agent OS Claude Code hooks transform AI-assisted development from error-prone to deterministic, ensuring your workflows reach completion with professional integration.**