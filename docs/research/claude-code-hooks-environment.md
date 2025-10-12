# Claude Code Hooks System and Environment Handling

> Research Document
> Date: 2025-10-12
> Version: 1.0.0
> Purpose: Comprehensive reference for Claude Code hook system, execution context, and environment handling

## Table of Contents

1. [Hook Execution Context](#hook-execution-context)
2. [Hook Types and Timing](#hook-types-and-timing)
3. [JSON Payload Structure](#json-payload-structure)
4. [Environment Variables](#environment-variables)
5. [Session and State Management](#session-and-state-management)
6. [Hook Input and Output](#hook-input-and-output)
7. [Best Practices](#best-practices)
8. [Official Documentation Links](#official-documentation-links)
9. [Agent OS Implementation Patterns](#agent-os-implementation-patterns)

---

## Hook Execution Context

### How Hooks Execute

Claude Code hooks are **shell commands** that execute at predetermined points in Claude Code's workflow. Key characteristics:

- **Environment**: Hooks run in the current directory with Claude Code's environment
- **Input Method**: JSON data via **stdin** (NOT command-line arguments)
- **Timeout**: 60-second default execution limit (configurable per command)
- **Parallelization**: All matching hooks run in parallel
- **Shell**: Uses user's default shell (typically bash)

### Configuration Locations

Hooks are configured in settings files with hierarchical precedence:

1. **User Settings**: `~/.claude/settings.json` (global defaults)
2. **Project Settings**: `.claude/settings.json` (shared with team)
3. **Local Project Settings**: `.claude/settings.local.json` (gitignored, personal)
4. **Enterprise Policies**: System-wide managed settings

### Configuration Structure

```json
{
	"hooks": {
		"EventName": [
			{
				"matcher": "ToolPattern",
				"hooks": [
					{
						"type": "command",
						"command": "/absolute/path/to/script.sh",
						"timeout": 60
					}
				]
			}
		]
	}
}
```

**Key Points**:
- **matcher**: Case-sensitive pattern matching (only for PreToolUse/PostToolUse)
	- Simple string: `"Write"` matches only Write tool
	- Regex: `"Edit|Write"` or `"Notebook.*"`
	- Wildcard: `"*"` or `""` matches all tools
- **command**: Full path to executable (can use `$CLAUDE_PROJECT_DIR`)
- **timeout**: Optional per-command timeout in seconds

---

## Hook Types and Timing

### Available Hook Events

| Hook Event | When It Fires | Has Matcher | Use Cases |
|------------|---------------|-------------|-----------|
| `PreToolUse` | Before tool execution | Yes | Validation, security, blocking unsafe operations |
| `PostToolUse` | After tool completes | Yes | Auto-formatting, result validation, logging |
| `UserPromptSubmit` | Before processing user prompt | No | Context injection, prompt validation |
| `Notification` | System notifications | No | User awareness, reminders |
| `Stop` | Agent finishes responding | No | Workflow enforcement, completion checks |
| `SubagentStop` | Subagent finishes | No | Subagent-specific completion |
| `PreCompact` | Before compaction | Yes (`manual`/`auto`) | Context preservation |
| `SessionStart` | Session starts/resumes | Yes (`startup`/`resume`/`clear`) | Context loading |

### Stop Hook Timing

**When `Stop` fires**:
- Main Claude Code agent has finished responding
- All tool calls have completed
- Before displaying final response to user

**When `Stop` does NOT fire**:
- User interrupts with Ctrl-C
- Session is manually stopped
- Error or timeout occurs

**Important**: The `stop_hook_active` field in payload prevents infinite loops if Stop hook blocks and continues conversation.

### Hook Event Examples

#### PreToolUse - Security Validation
```bash
#!/usr/bin/env bash
payload="$(cat)"
tool_name="$(jq -r '.hookMetadata.toolName' <<<"$payload")"
tool_input="$(jq -r '.tool_input' <<<"$payload")"

# Block dangerous Bash commands
if [[ "$tool_name" == "Bash" ]]; then
	cmd="$(jq -r '.tool_input.command' <<<"$payload")"
	if [[ "$cmd" =~ rm.*-rf ]]; then
		echo '{"permissionDecision":"deny","permissionDecisionReason":"Dangerous rm -rf detected"}'
		exit 0
	fi
fi

exit 0  # Allow
```

#### PostToolUse - Auto-formatting
```bash
#!/usr/bin/env bash
payload="$(cat)"
tool_name="$(jq -r '.hookMetadata.toolName' <<<"$payload")"

if [[ "$tool_name" =~ ^(Write|Edit)$ ]]; then
	# Format the file that was just modified
	file="$(jq -r '.tool_input.file_path' <<<"$payload")"
	if [[ "$file" =~ \.py$ ]]; then
		black "$file" >/dev/null 2>&1
	fi
fi

exit 0
```

#### Stop - Workflow Enforcement
```bash
#!/usr/bin/env bash
payload="$(cat)"

# Check if stop hook is already active (prevent loops)
stop_active="$(jq -r '.stop_hook_active // false' <<<"$payload")"
if [[ "$stop_active" == "true" ]]; then
	exit 0
fi

# Check for uncommitted changes in Agent OS projects
if [[ -d .agent-os ]] && [[ -n "$(git status --porcelain)" ]]; then
	reason="Uncommitted changes detected. Please commit your work before completing."
	echo "{\"decision\":\"block\",\"reason\":\"$reason\"}"
	exit 0
fi

exit 0
```

---

## JSON Payload Structure

### Common Fields (All Hooks)

```json
{
	"hookMetadata": {
		"sessionId": "uuid-string",
		"projectDir": "/absolute/path/to/project",
		"toolName": "Bash",
		"timestamp": "2025-10-12T14:30:00Z"
	},
	"cwd": "/current/working/directory",
	"projectRoot": "/absolute/path/to/project"
}
```

### PreToolUse Input

```json
{
	"hookMetadata": {
		"sessionId": "uuid",
		"projectDir": "/path/to/project",
		"toolName": "Bash"
	},
	"tool_input": {
		"command": "npm run dev",
		"timeout": 120000,
		"description": "Start development server"
	},
	"cwd": "/current/directory"
}
```

**Tool-specific fields**:
- **Bash**: `command`, `timeout`, `run_in_background`
- **Write**: `file_path`, `content`
- **Edit**: `file_path`, `old_string`, `new_string`, `replace_all`
- **Read**: `file_path`, `offset`, `limit`

### PostToolUse Input

```json
{
	"hookMetadata": {
		"sessionId": "uuid",
		"projectDir": "/path/to/project",
		"toolName": "Bash"
	},
	"tool_input": {
		"command": "npm test"
	},
	"tool_response": {
		"exit_code": 0,
		"output": "All tests passed\n",
		"success": true
	},
	"cwd": "/current/directory"
}
```

### UserPromptSubmit Input

```json
{
	"hookMetadata": {
		"sessionId": "uuid",
		"projectDir": "/path/to/project"
	},
	"prompt": "User's submitted text",
	"conversationHistory": [...],
	"cwd": "/current/directory"
}
```

### Stop Input

```json
{
	"hookMetadata": {
		"sessionId": "uuid",
		"projectDir": "/path/to/project"
	},
	"stop_hook_active": false,
	"transcript_path": "/path/to/transcript.md",
	"cwd": "/current/directory"
}
```

**Critical Field**: `stop_hook_active` - Prevents infinite loops when Stop hook blocks and continues conversation.

### Notification Input

```json
{
	"hookMetadata": {
		"sessionId": "uuid",
		"projectDir": "/path/to/project"
	},
	"notification_type": "permission_required" | "idle_timeout",
	"notification_message": "Claude needs your permission to use Bash",
	"stop_hook_active": false
}
```

### SessionStart Input

```json
{
	"hookMetadata": {
		"sessionId": "uuid",
		"projectDir": "/path/to/project",
		"matcher": "startup" | "resume" | "clear"
	},
	"custom_instructions": "Optional instructions from /compact"
}
```

---

## Environment Variables

### Claude Code Provided Variables

Available in all hooks:

| Variable | Description | Example |
|----------|-------------|---------|
| `CLAUDE_PROJECT_DIR` | Absolute project root path | `/home/user/my-project` |
| `CLAUDE_PLUGIN_ROOT` | Plugin directory path | `~/.claude/plugins/agent-os` |
| `CLAUDE_FILE_PATHS` | Space-separated relevant file paths | `src/app.py tests/test_app.py` |
| `CLAUDE_NOTIFICATION` | Notification message content | `Claude needs permission...` |
| `CLAUDE_TOOL_OUTPUT` | Tool execution output | `Command output here` |

### Configuration Through settings.json

Environment variables can be set automatically for all sessions:

```json
{
	"env": {
		"AGENT_OS_VERSION": "1.0.0",
		"NODE_ENV": "development",
		"PYTHONPATH": "${CLAUDE_PROJECT_DIR}/src"
	}
}
```

**Key Points**:
- Variables support interpolation (`${CLAUDE_PROJECT_DIR}`)
- Set once, available in all hooks and Claude sessions
- Useful for team-wide configuration
- Overrides can be in `.claude/settings.local.json`

### Agent OS Custom Variables

Agent OS defines additional environment variables for hook behavior:

| Variable | Purpose | Default | Values |
|----------|---------|---------|--------|
| `AGENT_OS_DEBUG` | Enable debug logging | `false` | `true`/`false` |
| `AGENT_OS_HOOKS_QUIET` | Suppress hook output | `false` | `true`/`false` |
| `AGENT_OS_STOP_TTL` | Stop hook rate limit | `300` | seconds |
| `AGENT_OS_RECENT_WINDOW` | Git commit window | `2 hours ago` | git date format |
| `AGENT_OS_STOP_NO_JSON` | Use stderr + exit 2 | `false` | `true`/`false` |

---

## Session and State Management

### Session Identification

Claude Code provides session information through:

```bash
session_id="$(jq -r '.hookMetadata.sessionId // .sessionId // .threadId // empty' <<<"$payload")"
```

**Session ID Uses**:
- Deduplicate messages within same session
- Track state across multiple hook invocations
- Identify conversation threads
- Rate limiting per session

### File-Based State Patterns

Agent OS uses file-based state management compatible with Claude Code hooks:

#### 1. TTL Cache Pattern

```bash
CACHE_DIR="/tmp/agent-os-cache"
CACHE_FILE="$CACHE_DIR/$(echo -n "$key" | shasum -a 256 | cut -d' ' -f1).cache"
TTL=300  # 5 minutes

# Check if cache is valid
if [ -f "$CACHE_FILE" ]; then
	age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0) ))
	if [ "$age" -lt "$TTL" ]; then
		cat "$CACHE_FILE"
		exit 0
	fi
fi

# Generate new data and cache it
generate_data > "$CACHE_FILE"
cat "$CACHE_FILE"
```

#### 2. Lock Pattern (Deduplication)

```bash
LOCK_DIR="/tmp/agent-os-locks"
LOCK_FILE="$LOCK_DIR/$(echo -n "$key" | shasum -a 256 | cut -d' ' -f1).lock"

# Non-blocking lock with flock
if command -v flock >/dev/null 2>&1; then
	exec {lock_fd}> "$LOCK_FILE"
	if flock -n "$lock_fd"; then
		# Critical section
		trap "flock -u $lock_fd" EXIT
	else
		echo "Already running" >&2
		exit 0
	fi
else
	# Fallback: mkdir-based lock
	if mkdir "$LOCK_FILE.d" 2>/dev/null; then
		trap "rmdir '$LOCK_FILE.d'" EXIT
		# Critical section
	else
		echo "Already running" >&2
		exit 0
	fi
fi
```

#### 3. JSONL Event Log Pattern

```bash
LOG_FILE="${CLAUDE_PROJECT_DIR}/.agent-os/observed-bash.jsonl"
timestamp="$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")"

# Append structured event
jq -n \
	--arg ts "$timestamp" \
	--arg event "bash" \
	--arg cmd "$command" \
	--arg exit "$exit_code" \
	'{ts: $ts, event: $event, cmd: $cmd, exit: $exit}' >> "$LOG_FILE"
```

### hookMetadata Contents

The `hookMetadata` object provides reliable hook context:

```json
{
	"hookMetadata": {
		"sessionId": "550e8400-e29b-41d4-a716-446655440000",
		"projectDir": "/Users/user/project",
		"toolName": "Bash",
		"timestamp": "2025-10-12T14:30:00Z",
		"matcher": "startup"
	}
}
```

**Accessing in bash**:
```bash
session_id="$(jq -r '.hookMetadata.sessionId' <<<"$payload")"
project_dir="$(jq -r '.hookMetadata.projectDir' <<<"$payload")"
tool_name="$(jq -r '.hookMetadata.toolName' <<<"$payload")"
```

**Fallback Pattern** (for older versions):
```bash
session_id="$(jq -r '.hookMetadata.sessionId // .sessionId // .threadId // empty' <<<"$payload")"
project_dir="$(jq -r '.hookMetadata.projectDir // .projectRoot // .cwd // empty' <<<"$payload")"
```

---

## Hook Input and Output

### Input: Reading JSON via stdin

**Correct Pattern**:
```bash
#!/usr/bin/env bash
# Read entire JSON payload from stdin
payload="$(cat)"

# Parse with jq
tool_name="$(jq -r '.hookMetadata.toolName // empty' <<<"$payload")"
command="$(jq -r '.tool_input.command // empty' <<<"$payload")"
```

**Important**:
- Never use command-line arguments for payload data
- Always read from stdin with `cat` or `read`
- Use `jq` for reliable JSON parsing
- Provide fallback with `// empty` for missing fields

### Output: Simple Exit Codes

```bash
exit 0  # Success - stdout shown to user (or added to context for UserPromptSubmit/SessionStart)
exit 2  # Blocking error - stderr fed to Claude automatically
exit 1  # Non-blocking error - stderr shown to user, execution continues
```

#### Exit Code 2 Behavior by Hook Type

| Hook Event | Exit Code 2 Behavior |
|------------|---------------------|
| `PreToolUse` | Blocks tool call, shows stderr to Claude |
| `PostToolUse` | Shows stderr to Claude (tool already ran) |
| `UserPromptSubmit` | Blocks prompt, erases it, shows stderr to user |
| `Stop` | Blocks stoppage, shows stderr to Claude |
| `SubagentStop` | Blocks stoppage, shows stderr to subagent |
| `Notification` | N/A, shows stderr to user only |
| `PreCompact` | N/A, shows stderr to user only |
| `SessionStart` | N/A, shows stderr to user only |

### Output: Advanced JSON Control

#### Common JSON Fields

```json
{
	"continue": true | false,
	"stopReason": "Human-readable reason",
	"suppressOutput": true | false
}
```

- **continue**: If `false`, Claude stops processing after hooks run
- **stopReason**: Shown to user (not Claude) when `continue: false`
- **suppressOutput**: Hide hook output from transcript

#### PreToolUse Decision Control

```json
{
	"permissionDecision": "allow" | "deny" | "ask",
	"permissionDecisionReason": "Explanation text",
	"continue": true
}
```

- **allow**: Bypasses permission system, reason shown to user
- **deny**: Prevents execution, reason shown to Claude
- **ask**: Prompts user for confirmation

**Deprecated but still works**:
```json
{
	"decision": "approve" | "block",
	"reason": "Explanation"
}
```

#### PostToolUse Decision Control

```json
{
	"decision": "block",
	"reason": "Tool failed validation. Please retry with...",
	"continue": true
}
```

- **block**: Automatically prompts Claude with reason
- **undefined**: Does nothing, reason ignored

#### UserPromptSubmit Decision Control

```json
{
	"decision": "block",
	"reason": "Prompt validation failed",
	"hookSpecificOutput": {
		"additionalContext": "Extra context to add if not blocked"
	}
}
```

#### Stop Decision Control

```json
{
	"decision": "block",
	"reason": "Uncommitted changes detected. Please commit your work.",
	"continue": true,
	"hookSpecificOutput": {
		"stopHook": {
			"source": "agent-os",
			"projectRoot": "/path/to/project",
			"sessionId": "uuid"
		}
	}
}
```

- **block**: Prevents Claude from stopping, reason must be provided
- **undefined**: Allows Claude to stop normally

#### SessionStart Decision Control

```json
{
	"hookSpecificOutput": {
		"additionalContext": "Context loaded at session start"
	}
}
```

---

## Best Practices

### Security Best Practices

1. **Validate and sanitize inputs** - Never trust payload data blindly
	```bash
	# Sanitize file paths
	file="$(jq -r '.tool_input.file_path' <<<"$payload")"
	if [[ "$file" =~ \.\. ]]; then
		echo "Path traversal detected" >&2
		exit 2
	fi
	```

2. **Always quote shell variables** - Prevents injection attacks
	```bash
	# Good
	git -C "$project_dir" status

	# Bad - allows command injection
	git -C $project_dir status
	```

3. **Block path traversal** - Check for `..` in file paths
	```bash
	if [[ "$file" =~ \.\. ]] || [[ "$file" =~ ^/ ]]; then
		echo "Invalid path" >&2
		exit 2
	fi
	```

4. **Use absolute paths** - Specify full paths for scripts
	```bash
	# Good
	"$CLAUDE_PROJECT_DIR/scripts/format.sh"

	# Bad - depends on PATH
	format.sh
	```

5. **Skip sensitive files** - Never process `.env`, keys, credentials
	```bash
	if [[ "$file" =~ \.(env|key|pem|crt)$ ]]; then
		exit 0  # Skip silently
	fi
	```

### Performance Best Practices

1. **Use caching** - Cache expensive operations with TTL
	```bash
	CACHE_FILE="/tmp/agent-os-cache-$$.json"
	CACHE_TTL=60

	if [ -f "$CACHE_FILE" ]; then
		age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE") ))
		if [ "$age" -lt "$CACHE_TTL" ]; then
			cat "$CACHE_FILE"
			exit 0
		fi
	fi
	```

2. **Fail fast** - Exit early for non-applicable hooks
	```bash
	# Early exit for non-Agent OS projects
	if [ ! -d "$CLAUDE_PROJECT_DIR/.agent-os" ]; then
		exit 0
	fi
	```

3. **Limit output** - Keep stdout/stderr concise
	```bash
	# Limit output to 100 lines
	output="$(some_command | head -n 100)"
	```

4. **Use background jobs sparingly** - Avoid blocking operations
	```bash
	# Background expensive operations
	expensive_task &
	disown
	exit 0
	```

5. **Optimize JSON parsing** - Minimize jq calls
	```bash
	# Good - single jq call
	read -r tool_name command exit_code < <(jq -r '
		.hookMetadata.toolName,
		.tool_input.command,
		.tool_response.exit_code
	' <<<"$payload")

	# Bad - multiple jq calls
	tool_name="$(jq -r '.hookMetadata.toolName' <<<"$payload")"
	command="$(jq -r '.tool_input.command' <<<"$payload")"
	exit_code="$(jq -r '.tool_response.exit_code' <<<"$payload")"
	```

### Hook Development Best Practices

1. **Always handle missing fields** - Use `// empty` or `// false`
	```bash
	session_id="$(jq -r '.hookMetadata.sessionId // empty' <<<"$payload")"
	stop_active="$(jq -r '.stop_hook_active // false' <<<"$payload")"
	```

2. **Implement debug logging** - Controlled by environment variable
	```bash
	log_debug() {
		if [ "${AGENT_OS_DEBUG:-false}" = "true" ]; then
			echo "[DEBUG] $*" >&2
		fi
	}
	```

3. **Use strict mode** - Catch errors early
	```bash
	#!/usr/bin/env bash
	set -euo pipefail
	IFS=$'\n\t'
	```

4. **Provide user suppression** - Allow users to disable hooks
	```bash
	if [ "${AGENT_OS_HOOKS_QUIET:-false}" = "true" ]; then
		exit 0
	fi
	```

5. **Implement rate limiting** - Prevent spammy messages
	```bash
	rate_file="/tmp/agent-os-rate-$key"
	if [ -f "$rate_file" ]; then
		age=$(( $(date +%s) - $(stat -f %m "$rate_file") ))
		if [ "$age" -lt 300 ]; then
			exit 0  # Rate limited
		fi
	fi
	touch "$rate_file"
	```

### Testing Best Practices

1. **Test with mock payloads** - Create test JSON files
	```bash
	# test-payload.json
	{
		"hookMetadata": {"sessionId": "test", "toolName": "Bash"},
		"tool_input": {"command": "npm test"}
	}

	# Test hook
	cat test-payload.json | ./hook-script.sh
	```

2. **Test exit codes** - Verify all paths
	```bash
	# Should exit 0
	echo '{}' | ./hook.sh
	echo "Exit code: $?"  # Should be 0

	# Should exit 2
	echo '{"dangerous":"command"}' | ./hook.sh
	echo "Exit code: $?"  # Should be 2
	```

3. **Test JSON output** - Validate structure
	```bash
	output="$(echo '{}' | ./hook.sh)"
	echo "$output" | jq . >/dev/null || echo "Invalid JSON"
	```

---

## Official Documentation Links

### Claude Code Documentation

- **Hooks Reference**: https://docs.claude.com/en/docs/claude-code/hooks
- **Settings Documentation**: https://docs.claude.com/en/docs/claude-code/settings
- **Best Practices**: https://www.anthropic.com/engineering/claude-code-best-practices
- **Plugins Guide**: https://www.anthropic.com/news/claude-code-plugins
- **Subagents Documentation**: https://docs.anthropic.com/en/docs/claude-code/sub-agents

### Community Resources

- **claude-code-hooks-mastery**: https://github.com/disler/claude-code-hooks-mastery
	- Comprehensive examples and patterns
	- Security validation examples
	- Advanced hook patterns

- **johnlindquist/claude-hooks**: https://github.com/johnlindquist/claude-hooks
	- Community hook examples
	- Integration patterns

- **GitButler Hooks Guide**: https://docs.gitbutler.com/features/ai-integration/claude-code-hooks
	- GitButler-specific integration
	- Real-world usage examples

### Blog Posts and Guides

- **"Cooking with Claude Code: The Complete Guide"**: https://www.siddharthbharath.com/claude-code-the-complete-guide/
- **"Automate Your AI Workflows with Claude Code Hooks"**: https://blog.gitbutler.com/automate-your-ai-workflows-with-claude-code-hooks
- **"Claude Code Hooks: The Secret Sauce for Bulletproof Dev Automation"**: https://garysvenson09.medium.com/claude-code-hooks-the-secret-sauce-for-bulletproof-dev-automation-e18eadb09ad6

---

## Agent OS Implementation Patterns

### Pattern 1: Stop Hook with Rate Limiting

Agent OS's `stop-hook.sh` implements comprehensive workflow abandonment prevention:

```bash
#!/bin/bash
set -Eeuo pipefail
IFS=$'\n\t'

DEDUP_DIR="/tmp/agent-os-stop"
DEFAULT_TTL="${AGENT_OS_STOP_TTL:-300}"  # 5 minutes

# Read payload
payload="$(cat)"

# Check if stop hook is already active (prevent loops)
stop_active="$(jq -r '.stop_hook_active // false' <<<"$payload")"
if [ "$stop_active" = "true" ]; then
	exit 0
fi

# Get project root
project_root="$(jq -r '.hookMetadata.projectDir // empty' <<<"$payload")"
if [ -z "$project_root" ] && [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
	project_root="$CLAUDE_PROJECT_DIR"
fi

# Only run in Agent OS projects
if [ ! -d "$project_root/.agent-os" ]; then
	exit 0
fi

# Check for uncommitted changes
if uncommitted_files="$(git -C "$project_root" status --porcelain)"; then
	if [ -n "$uncommitted_files" ]; then
		# Rate limiting
		key="$(echo -n "$project_root" | shasum -a 256 | cut -d' ' -f1)"
		rate_file="$DEDUP_DIR/$key.rate"

		if [ -f "$rate_file" ]; then
			age=$(( $(date +%s) - $(stat -f %m "$rate_file") ))
			if [ "$age" -lt "$DEFAULT_TTL" ]; then
				# Still block, but concise message
				echo '{"decision":"block","reason":"Uncommitted changes"}'
				exit 0
			fi
		fi

		touch "$rate_file"

		# Full message
		reason="Agent OS: Uncommitted source code detected. Please commit or stash."
		echo "{\"decision\":\"block\",\"reason\":\"$reason\"}"
		exit 0
	fi
fi

exit 0
```

**Key Features**:
- Loop prevention with `stop_hook_active`
- Project root resolution with fallbacks
- Rate limiting to prevent spam
- JSON output for blocking

### Pattern 2: Bash Command Observation (Pre + Post)

Agent OS observes Bash commands without blocking:

**pre-bash-hook.sh**:
```bash
#!/usr/bin/env bash
payload="$(cat)"
tool_name="$(jq -r '.hookMetadata.toolName // empty' <<<"$payload")"

if [ "$tool_name" != "Bash" ]; then
	exit 0
fi

cmd="$(jq -r '.tool_input.command // empty' <<<"$payload")"

# Classify intent
if echo "$cmd" | grep -qE "npm.*dev|python.*runserver"; then
	intent="server"
	echo "🚀 Starting development server..."
elif echo "$cmd" | grep -qE "pytest|npm test"; then
	intent="test"
	echo "🧪 Running tests..."
else
	intent="other"
fi

# Log to JSONL
log_file="${CLAUDE_PROJECT_DIR}/.agent-os/observed-bash.jsonl"
jq -n \
	--arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
	--arg event "pre" \
	--arg cmd "$cmd" \
	--arg intent "$intent" \
	'{ts: $ts, event: $event, cmd: $cmd, intent: $intent}' >> "$log_file"

# Never block
exit 0
```

**post-bash-hook.sh**:
```bash
#!/usr/bin/env bash
payload="$(cat)"
tool_name="$(jq -r '.hookMetadata.toolName // empty' <<<"$payload")"

if [ "$tool_name" != "Bash" ]; then
	exit 0
fi

cmd="$(jq -r '.tool_input.command // empty' <<<"$payload")"
exit_code="$(jq -r '.tool_response.exit_code // unknown' <<<"$payload")"

# Log result
log_file="${CLAUDE_PROJECT_DIR}/.agent-os/observed-bash.jsonl"
jq -n \
	--arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
	--arg event "post" \
	--arg cmd "$cmd" \
	--arg exit "$exit_code" \
	'{ts: $ts, event: $event, cmd: $cmd, exit: $exit}' >> "$log_file"

# Show concise summary
if [ "$exit_code" = "0" ]; then
	echo "📊 Bash command: ${cmd:0:60}"
	echo "   Status: ✅ Completed successfully"
else
	echo "📊 Bash command: ${cmd:0:60}"
	echo "   Status: ❌ Failed with exit code: $exit_code"
fi

exit 0  # Never block
```

**Key Features**:
- Non-blocking observation (exit 0)
- Intent classification for smart suggestions
- JSONL event log for history
- Concise output (max 3 lines)

### Pattern 3: Context Injection with Caching

Agent OS's `user-prompt-submit-hook.sh` implements efficient context injection:

```bash
#!/bin/bash
CACHE_FILE="/tmp/agent-os-context-$$"
CACHE_TTL=60

# Read user prompt from payload
payload="$(cat)"
user_prompt="$(jq -r '.prompt // empty' <<<"$payload")"

# Check cache validity
is_cache_valid() {
	if [ ! -f "$CACHE_FILE" ]; then
		return 1
	fi
	age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE") ))
	[ "$age" -lt "$CACHE_TTL" ]
}

# Get or build context
if is_cache_valid; then
	context="$(cat "$CACHE_FILE")"
else
	# Build fresh context
	context="$(build_context_for_claude)"
	echo "$context" > "$CACHE_FILE"
fi

# Output with additionalContext
cat <<EOF
{
	"hookSpecificOutput": {
		"additionalContext": "<system-reminder>\n$context\n\nUser's request: $user_prompt\n</system-reminder>"
	}
}
EOF

exit 0
```

**Key Features**:
- TTL-based caching (60s)
- Context building only when needed
- JSON output with additionalContext
- Cleanup on exit

---

## Summary

### Hook System Key Takeaways

1. **Hooks execute as shell commands** with JSON via stdin
2. **Environment variables** from Claude Code and custom settings
3. **Session state** managed with file-based patterns (TTL cache, locks, JSONL logs)
4. **Exit codes** control blocking (0=allow, 2=block)
5. **JSON output** provides advanced control over Claude's behavior
6. **Stop hook** requires `stop_hook_active` check to prevent loops

### Agent OS Hook Architecture

- **stop-hook.sh**: Workflow abandonment prevention with rate limiting
- **pre-bash-hook.sh**: Non-blocking command observation with intent classification
- **post-bash-hook.sh**: Result reporting with concise summaries
- **user-prompt-submit-hook.sh**: Context injection with TTL caching
- **notify-hook.sh**: Gentle reminders based on recent activity

All hooks follow best practices:
- Security: input validation, quoting, path sanitization
- Performance: caching, early exits, minimal output
- Reliability: error handling, debug logging, user suppression

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2025-10-12 | 1.0.0 | Initial comprehensive research document |

---

**End of Document**
