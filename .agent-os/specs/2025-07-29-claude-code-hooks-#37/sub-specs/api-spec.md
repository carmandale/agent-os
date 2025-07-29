# API Specification

This is the API specification for the spec detailed in @.agent-os/specs/2025-07-29-claude-code-hooks-#37/spec.md

> Created: 2025-07-29
> Version: 1.0.0

## Hook Interfaces

### Stop Hook Interface

**Purpose:** Detect Agent OS workflow completion and enforce cleanup
**Trigger:** Claude Code conversation end or stop command
**Script:** `~/.agent-os/hooks/stop-hook.sh`

**Input Parameters:** None (hook detects state from filesystem and git)

**Execution Logic:**
1. Detect if current directory contains Agent OS specs (.agent-os/specs/)
2. Check git status for uncommitted Agent OS documentation changes
3. Check for open PRs created by current workflow using `gh pr list`
4. Verify task completion states in active specs
5. If workflow incomplete, block with user guidance

**Response Format:**
```bash
# Success - workflow complete or no Agent OS work detected
exit 0

# Block - incomplete workflow detected  
echo "⚠️ Agent OS workflow incomplete. Complete these steps:"
echo "1. Merge PR #123: Feature implementation"
echo "2. Close issue #37 when PR is merged"
echo "3. Clean workspace with 'git checkout main && git pull'"
exit 1
```

**Error Handling:**
- Git command failures: Continue with warning, don't block user
- GitHub CLI unavailable: Skip PR checks, warn user
- Permission issues: Log error, allow user to continue

### PostToolUse Hook Interface

**Purpose:** Auto-commit Agent OS documentation changes after tool usage
**Trigger:** After any Claude Code tool execution (Write, Edit, MultiEdit)
**Script:** `~/.agent-os/hooks/post-tool-use-hook.sh`

**Input Parameters:**
- `$1`: Tool name that was executed
- `$2`: File path that was modified (if applicable)
- `$3`: Operation type (create, edit, delete)

**Execution Logic:**
1. Check if modified file is Agent OS documentation (.agent-os/, CLAUDE.md, .cursorrules)
2. Extract GitHub issue number from current spec folder or recent commits
3. Generate appropriate commit message based on file type and operation
4. Stage and commit changes with issue reference
5. Continue normal Claude Code operation

**Response Format:**
```bash
# Success - changes committed
echo "✅ Auto-committed Agent OS documentation: $commit_message"
exit 0

# No action needed - not Agent OS documentation
exit 0

# Error - commit failed
echo "⚠️ Failed to auto-commit: $error_message"
echo "Please commit manually: git add . && git commit -m 'docs: $suggested_message'"
exit 0  # Don't block user workflow
```

**Commit Message Patterns:**
```bash
# Spec creation
"docs: create spec for $feature_name #$issue_number"

# Task updates  
"docs: update tasks for $spec_name #$issue_number"

# Technical documentation
"docs: add technical spec for $feature_name #$issue_number"

# General Agent OS documentation
"docs: update Agent OS documentation #$issue_number"
```

### UserPromptSubmit Hook Interface

**Purpose:** Inject relevant Agent OS context based on user prompt analysis
**Trigger:** Before user prompt is sent to Claude Code
**Script:** `~/.agent-os/hooks/user-prompt-submit-hook.sh` 

**Input Parameters:**
- `$1`: User prompt text
- `$2`: Current working directory
- `$3`: Conversation context (if available)

**Execution Logic:**
1. Analyze prompt for Agent OS workflow keywords (@.agent-os/, /create-spec, etc.)
2. Detect workflow type (spec creation, task execution, product planning)
3. Build relevant context injection based on detected workflow
4. Output context to be prepended to user prompt
5. Allow normal prompt processing to continue

**Response Format:**
```bash
# Context injection - output goes to stdout
cat << 'EOF'
<agent-os-context>
Current spec: @.agent-os/specs/2025-07-29-claude-code-hooks-#37/spec.md
Active tasks: 3 pending, 2 completed
Project standards: @.agent-os/product/tech-stack.md
</agent-os-context>

User prompt: $original_prompt
EOF

exit 0
```

**Context Injection Patterns:**

**For Spec Creation:**
```bash
echo "Current roadmap: @.agent-os/product/roadmap.md"
echo "Project mission: @.agent-os/product/mission.md"  
echo "Tech stack: @.agent-os/product/tech-stack.md"
echo "Recent specs: $(ls -t .agent-os/specs/ | head -3)"
```

**For Task Execution:**
```bash
echo "Active spec: @$current_spec_path/spec.md"
echo "Task list: @$current_spec_path/tasks.md"
echo "Technical spec: @$current_spec_path/sub-specs/technical-spec.md"
echo "Code style: @~/.agent-os/standards/code-style.md"
```

**For Product Planning:**
```bash
echo "Global standards: @~/.agent-os/standards/"
echo "Existing product docs: @.agent-os/product/"
echo "Planning instructions: @~/.agent-os/instructions/plan-product.md"
```

## Error Handling Standards

### Graceful Degradation
- All hooks must continue normal operation if Agent OS detection fails
- Network failures (GitHub API) should not block user workflows  
- File system errors should log warnings but allow continuation

### Logging Requirements
- Log all hook executions to `~/.agent-os/logs/hooks.log`
- Include timestamp, hook type, action taken, and any errors
- Rotate logs when they exceed 10MB to prevent disk usage issues

### User Communication
- Success messages should be brief and informative
- Error messages must provide clear next steps for manual resolution
- Use consistent emoji and formatting for recognizability

## Integration Requirements

### Claude Code Compatibility
- Hooks must not interfere with existing Claude Code functionality
- Execution time must be minimal (< 500ms per hook)
- Must handle concurrent hook execution gracefully

### Agent OS Workflow Integration
- Maintain compatibility with all existing Agent OS commands
- Preserve current command-line interfaces unchanged
- Support both interactive and automated usage patterns