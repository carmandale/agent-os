# CLAUDE.md

> Agent OS User Standards
> Last Updated: 2025-09-15

## Purpose

This file directs Claude Code to use your personal Agent OS standards for all development work. These global standards define your preferred way of building software across all projects.

## Global Standards

### Development Standards
- **Tech Stack Defaults:** @~/.agent-os/standards/tech-stack.md
- **Code Style Preferences:** @~/.agent-os/standards/code-style.md
- **Best Practices Philosophy:** @~/.agent-os/standards/best-practices.md

### Agent OS Instructions
- **Initialize Products:** @~/.agent-os/instructions/plan-product.md
- **Plan Features:** @~/.agent-os/instructions/create-spec.md
- **Execute Tasks:** @~/.agent-os/instructions/execute-tasks.md
- **Analyze Existing Code:** @~/.agent-os/instructions/analyze-product.md

## How These Work Together

1. **Standards** define your universal preferences that apply to all projects
2. **Instructions** guide the agent through Agent OS workflows
3. **Project-specific files** (if present) override these global defaults

## Using Agent OS Commands

You can invoke Agent OS commands directly:
- `/plan-product` - Start a new product
- `/create-spec` - Plan a new feature
- `/execute-task` - Build and ship code
- `/analyze-product` - Add Agent OS to existing code

### ⚠️ CRITICAL: Slash Command Enforcement

**MANDATORY BEHAVIOR**: When ANY message starts with a forward slash (`/`), you MUST:

1. **IMMEDIATELY STOP** all other processing
2. **RECOGNIZE** this as an Agent OS command that requires executing the corresponding instruction file
3. **EXECUTE** the full workflow from the instruction file WITHOUT shortcuts or casual responses
4. **DO NOT** provide explanations like "I'll help you analyze..." - just execute the command
5. **VERIFY** completion by summarizing what was done according to the instruction file

**Command Mappings** (MANDATORY):
- `/plan-product` → Execute @~/.agent-os/instructions/plan-product.md COMPLETELY
- `/create-spec` → Execute @~/.agent-os/instructions/create-spec.md COMPLETELY  
- `/execute-task` → Execute @~/.agent-os/instructions/execute-tasks.md COMPLETELY
- `/analyze-product` → Execute @~/.agent-os/instructions/analyze-product.md COMPLETELY

**FAILURE TO COMPLY**: If you catch yourself NOT executing a slash command properly:
- STOP immediately
- State: "I apologize, I need to properly execute the [command] workflow"
- START OVER with the correct instruction file

## Important Notes

- These are YOUR standards - customize them to match your preferences
- Project-specific standards in `.agent-os/product/` override these globals
- Update these files as you discover new patterns and preferences

---

*Using Agent OS for structured AI-assisted development. Learn more at [github.com/carmandale/agent-os](https://github.com/carmandale/agent-os)*
