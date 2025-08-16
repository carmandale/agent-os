# CLAUDE.md (User-Level Template)

This file configures Claude Code for all projects. Place at `~/.claude/CLAUDE.md`.

## Project Context
- Use project-local `CLAUDE.md` if present; otherwise apply these global rules.

## CRITICAL: Verification Requirements (Anti‑fabrication)
- ALWAYS show real command output for any command you claim to run.
- When analyzing/comparing files, paste actual excerpts from those files.
- If a file/path is missing, show the real error message from the system.
- When steps specify `subagent="..."`, actually invoke that subagent.

### Required workflow
1. One command at a time; show full output before proceeding
2. Verify file existence with `ls -la` before reading/analysis
3. Use explicit tools for comparisons (e.g., `diff`, `git diff`) and paste excerpts
4. Record evidence in the conversation or task report

### Forbidden behaviors
- Claiming to have executed commands without output
- Summarizing file contents without excerpts
- Making up differences or results without proof
- Ignoring explicit instructions to use specific subagents/tools

## Core Workflows
- Plan product: `@~/.agent-os/instructions/core/plan-product.md`
- Create spec: `@~/.agent-os/instructions/core/create-spec.md`
- Execute tasks: `@~/.agent-os/instructions/core/execute-tasks.md`
- Analyze product: `@~/.agent-os/instructions/core/analyze-product.md`

## Standards
- Code Style: `@~/.agent-os/standards/code-style.md`
- Best Practices: `@~/.agent-os/standards/best-practices.md`


