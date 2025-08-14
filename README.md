<img width="1280" height="640" alt="agent-os-og" src="https://github.com/user-attachments/assets/e897628e-7063-4bab-a69a-7bb6d7ac8403" />

## Your system for spec-driven agentic development.

[Agent OS](https://buildermethods.com/agent-os) transforms AI coding agents from confused interns into productive developers. With structured workflows that capture your standards, your stack, and the unique details of your codebase, Agent OS gives your agents the specs they need to ship quality code on the first try—not the fifth.

---

### About This Fork

This is an enhanced fork of the original [Agent OS by Builder Methods](https://github.com/buildermethods/agent-os). We're building on Brian Casel's excellent foundation to add:

- **🤖 Specialized Subagents System**: 5 optimized AI agents for common tasks with 25% context reduction and sub-millisecond detection
- **Background Task Management**: Run development tasks (builds, tests, servers) in background without blocking AI workflows
- **GitHub Issues Workflow Enforcement**: Strict requirement for issue-based development with automated tracking
- **Enhanced CLI Tools**: Unified `aos` command with comprehensive project management and task monitoring
- **Tab Indentation**: Preference for tabs over spaces in all generated code
- **Python/React Stack Defaults**: Updated tech stack templates for Python backend (FastAPI/Django) and React frontend development
- **Enhanced Workflow Automation**: Additional hooks and integrations for Claude Code and other AI assistants
- **Improved Error Handling**: More robust workspace hygiene checks and recovery mechanisms

All core Agent OS functionality remains intact, with these enhancements making it even more powerful for professional development teams.

Use it with:

✅ Claude Code, Cursor, or any other AI coding tool.

✅ New products or established codebases.

✅ Big features, small fixes, or anything in between.

✅ Any language or framework.

---

## Quick Start

### Installation
```bash
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash
```

### Background Task Management (New!)
```bash
# Install the aos CLI tool
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/tools/install-aos-alias.sh | bash

# Run dev server in background
aos run "npm run dev"

# List running tasks
aos tasks

# Monitor task output
aos monitor <task-id>

# View logs
aos logs <task-id>

# Stop a task
aos stop <task-id>
```

### AI Assistant Setup
```bash
# For Claude Code
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup-claude-code.sh | bash

# For Cursor
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup-cursor.sh | bash
```

---

### Features

#### 🤖 Specialized Subagents System (NEW!)
- **5 Optimized AI Agents**: Specialized agents for common development tasks
  - `context-fetcher`: Codebase search and analysis
  - `date-checker`: Accurate date determination for specs
  - `file-creator`: Template-based file generation
  - `git-workflow`: Complete git operations and GitHub integration
  - `test-runner`: Multi-framework test execution
- **Performance**: Sub-millisecond detection (0.01ms average)
- **Context Reduction**: 25% less token usage through intelligent routing
- **Zero Configuration**: Works automatically without setup

#### 🚀 Background Task Management
- **Non-blocking development**: Keep working while builds/tests run
- **Task monitoring**: Real-time log viewing and process management  
- **Error debugging**: Automatic detection and troubleshooting
- **Unified CLI**: All functionality through single `aos` command

#### 📋 Structured Workflows
- **Product Planning**: Initialize projects with mission, roadmap, and tech stack
- **Feature Specification**: Create detailed specs with tasks and acceptance criteria
- **Task Execution**: TDD-focused implementation with quality gates
- **Git Integration**: Automatic PR creation with issue linking

#### 🛡️ Quality Assurance
- **Workflow Enforcement**: Hooks prevent incomplete work and ensure testing
- **Reality Checking**: Validation of task status against actual implementation
- **Testing Requirements**: Mandatory verification before completion claims

---

### Documentation & Installation

Docs, installation, useage, & best practices 👉 [It's all here](https://buildermethods.com/agent-os)

---

### Created by Brian Casel @ Builder Methods

Created by Brian Casel, the creator of [Builder Methods](https://buildermethods.com), where Brian helps professional software developers and teams build with AI.

Get Brian's free resources on building with AI:
- [Builder Briefing newsletter](https://buildermethods.com)
- [YouTube](https://youtube.com/@briancasel)
