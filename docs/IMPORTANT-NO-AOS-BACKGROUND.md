# IMPORTANT: aos-background Does Not Exist

## Critical Information for AI Agents and Developers

The `aos-background` tool **DOES NOT EXIST** and should **NEVER BE CREATED**.

### History
- Originally planned as part of v2.2.0 for background task management
- Replaced by Claude Code's native backgrounding capabilities (Issue #19)
- Agent OS now observes rather than manages background processes

### Current Architecture

Agent OS uses hooks to observe Claude Code's native backgrounding:

- **`pre-bash-hook.sh`** - Classifies command intent before execution
- **`post-bash-hook.sh`** - Reports execution results
- **`aos dashboard`** - Shows observed command history
- **`aos notify`** - Sends notifications to transcript

### DO NOT:
- ❌ Create aos-background tool
- ❌ Implement process management in Agent OS
- ❌ Try to wrap or replace Claude Code's backgrounding
- ❌ Add background task management commands to `aos` CLI

### DO:
- ✅ Use Claude Code's ENABLE_BACKGROUND_TASKS environment variable
- ✅ Let Claude Code handle all process management
- ✅ Use hooks only for observation and reporting
- ✅ Implement dashboard and notification features only

### Architectural Philosophy

**Agent OS observes, Claude Code manages.**

This design ensures:
- No conflicts with Claude Code's native functionality
- Seamless integration without duplication
- Proper separation of concerns
- Better reliability and performance

### If You See References to aos-background

They are outdated and should be removed:
1. Remove from documentation
2. Remove from code references
3. Update help text and examples
4. Point to this file for explanation

### Background Task Commands That Were Removed

These commands were removed from `aos` because they relied on the non-existent aos-background:
- `aos run <command>`
- `aos tasks`
- `aos monitor <id>`
- `aos logs <id>`
- `aos stop <id>`
- `aos debug`
- `aos clean`

### Alternative Approach

Instead of managing processes, Agent OS now:
1. **Observes** commands via hooks
2. **Records** execution history
3. **Reports** on command results
4. **Notifies** about important events

This approach is more reliable and doesn't interfere with Claude Code's native capabilities.

---

**For Developers**: If an AI agent suggests creating aos-background, please point them to this document and the background task philosophy in Issue #19.