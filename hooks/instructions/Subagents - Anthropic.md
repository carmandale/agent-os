# Subagents - Anthropic
![](Subagents%20-%20Anthropic/image.jpg) 

Custom subagents in Claude Code are specialized AI assistants that can be invoked to handle specific types of tasks. They enable more efficient problem-solving by providing task-specific configurations with customized system prompts, tools and a separate context window.

Subagents are pre-configured AI personalities that Claude Code can delegate tasks to. Each subagent:

* Has a specific purpose and expertise area
* Uses its own context window separate from the main conversation
* Can be configured with specific tools it’s allowed to use
* Includes a custom system prompt that guides its behavior
When Claude Code encounters a task that matches a subagent’s expertise, it can delegate that task to the specialized subagent, which works independently and returns results.

## Key benefits

## Quick start

To create your first subagent:

### File locations

Subagents are stored as Markdown files with YAML frontmatter in two possible locations:

| Type | Location | Scope | Priority |
|---|---|---|---|
| **Project subagents** | `.claude/agents/` | Available in current project | Highest | 
| **User subagents** | `~/.claude/agents/` | Available across all projects | Lower | 
When subagent names conflict, project-level subagents take precedence over user-level subagents.

### File format

Each subagent is defined in a Markdown file with this structure:

#### Configuration fields

| Field | Required | Description |
|---|---|---|
| `name` | Yes | Unique identifier using lowercase letters and hyphens | 
| `description` | Yes | Natural language description of the subagent’s purpose | 
| `tools` | No | Comma-separated list of specific tools. If omitted, inherits all tools from the main thread | 
Subagents can be granted access to any of Claude Code’s internal tools. See the [tools documentation](https://docs.anthropic.com/en/docs/claude-code/settings#tools-available-to-claude) for a complete list of available tools.

You have two options for configuring tools:

* **Omit the `tools`field** to inherit all tools from the main thread (default), including MCP tools
* **Specify individual tools** as a comma-separated list for more granular control (can be edited manually or via `/agents`)
**MCP Tools**: Subagents can access MCP tools from configured MCP servers. When the `tools` field is omitted, subagents inherit all MCP tools available to the main thread.

### Using the /agents command (Recommended)

The `/agents` command provides a comprehensive interface for subagent management:

This opens an interactive menu where you can:

* View all available subagents (built-in, user, and project)
* Create new subagents with guided setup
* Edit existing custom subagents, including their tool access
* Delete custom subagents
* See which subagents are active when duplicates exist
* **Easily manage tool permissions** with a complete list of available tools
### Direct file management

You can also manage subagents by working directly with their files:

### Automatic delegation

Claude Code proactively delegates tasks based on:

* The task description in your request
* The `description` field in subagent configurations
* Current context and available tools
### Explicit invocation

Request a specific subagent by mentioning it in your command:

### Code reviewer

### Debugger

### Data scientist

## Best practices

* **Start with Claude-generated agents**: We highly recommend generating your initial subagent with Claude and then iterating on it to make it personally yours. This approach gives you the best results - a solid foundation that you can customize to your specific needs.

* **Design focused subagents**: Create subagents with single, clear responsibilities rather than trying to make one subagent do everything. This improves performance and makes subagents more predictable.

* **Write detailed prompts**: Include specific instructions, examples, and constraints in your system prompts. The more guidance you provide, the better the subagent will perform.

* **Limit tool access**: Only grant tools that are necessary for the subagent’s purpose. This improves security and helps the subagent focus on relevant actions.

* **Version control**: Check project subagents into version control so your team can benefit from and improve them collaboratively.

## Advanced usage

For complex workflows, you can chain multiple subagents:

Claude Code intelligently selects subagents based on context. Make your `description` fields specific and action-oriented for best results.

* **Context efficiency**: Agents help preserve main context, enabling longer overall sessions
* **Latency**: Subagents start off with a clean slate each time they are invoked and may add latency as they gather context that they require to do their job effectively.
* [Slash commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands) - Learn about other built-in commands
* [Settings](https://docs.anthropic.com/en/docs/claude-code/settings) - Configure Claude Code behavior
* [Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) - Automate workflows with event handlers

Was this page helpful?

[Subagents - Anthropic](https://docs.anthropic.com/en/docs/claude-code/sub-agents)