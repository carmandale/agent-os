# Agent OS Architecture

> Last Updated: 2025-01-20
> Version: 4.0.2

## Critical Distinction: Three Agent OS Contexts

Agent OS exists in three distinct contexts that MUST NOT be confused:

### 1. Agent OS REPO (Source Code)
**Location:** `~/Projects/dev/agent-os/` (or wherever you cloned it)
**Purpose:** The source code repository for Agent OS framework development
**Contains:**
- Source code for all Agent OS tools and scripts
- Master templates for instructions and standards
- The framework's own `.agent-os/` directory (uses Agent OS for its own development)
- VERSION file for framework versioning
- Git repository with tags and releases

**When to use:** 
- Developing new Agent OS features
- Fixing bugs in the framework
- Updating installation scripts
- Creating new releases

### 2. Agent OS SYSTEM (Installed Files)
**Location:** `~/.agent-os/` (user's home directory)
**Purpose:** The globally installed Agent OS framework files
**Contains:**
- `/instructions/` - Core workflow instruction files
- `/standards/` - User's global development standards
- `/workflow-modules/` - Modular workflow components
- `/hooks/` - Claude Code hooks
- `/tools/` - CLI tools including `aos` command
- `/scripts/` - Various utility scripts
- `VERSION` - Installed version number

**When to use:**
- Running Agent OS commands (`aos status`, `aos update`)
- Customizing global standards
- Installing hooks or tools
- Checking installed version

### 3. Agent OS PROJECT (Live Usage)
**Location:** `~/Projects/YourProject/.agent-os/` (in each project using Agent OS)
**Purpose:** Project-specific Agent OS configuration and documentation
**Contains:**
- `/product/` - Project-specific documentation
  - `mission.md` - Product mission and vision
  - `roadmap.md` - Development roadmap
  - `decisions.md` - Technical decisions log
  - `tech-stack.md` - Project tech stack choices
- `/specs/` - Feature specifications
  - Individual spec directories with tasks.md files

**When to use:**
- Planning a new product (`/plan-product`)
- Creating feature specs (`/create-spec`)
- Executing development tasks (`/execute-tasks`)
- Analyzing existing code (`/analyze-product`)

## Critical Rules

### Never Confuse Contexts

1. **REPO Changes:** When fixing Agent OS itself, you're working in the REPO
   - Changes here don't affect SYSTEM until you run update scripts
   - Must update VERSION file and create git tags
   - Push to GitHub for others to receive updates

2. **SYSTEM Changes:** When customizing standards or preferences
   - Edit files in `~/.agent-os/standards/` for personal preferences
   - These override defaults but are preserved during updates
   - Run `aos update` to get latest framework changes

3. **PROJECT Changes:** When developing your actual product
   - Edit files in `.agent-os/product/` for project-specific docs
   - Create specs in `.agent-os/specs/` for features
   - These are checked into your project's repository

## Installation Flow

```
REPO (GitHub) 
    ↓ (curl/setup.sh)
SYSTEM (~/.agent-os/)
    ↓ (aos init)
PROJECT (.agent-os/)
```

## Update Flow

```
REPO (develop fix) 
    → (git push) 
    → GitHub 
    → (aos update) 
    → SYSTEM 
    → (aos init) 
    → PROJECT
```

## Common Mistakes to Avoid

❌ **DON'T** edit files in the REPO thinking they'll affect your PROJECT
❌ **DON'T** run `/plan-product` in the Agent OS REPO itself
❌ **DON'T** confuse `~/.agent-os/` (SYSTEM) with `.agent-os/` (PROJECT)
❌ **DON'T** edit SYSTEM files expecting them to update the REPO
❌ **DON'T** forget to update VERSION and create tags when releasing

✅ **DO** develop Agent OS features in the REPO
✅ **DO** customize your preferences in SYSTEM
✅ **DO** use Agent OS workflows in your PROJECT
✅ **DO** run `aos update` to sync SYSTEM with REPO
✅ **DO** keep contexts mentally separated

## Directory Structure Reference

### REPO Structure
```
agent-os/                   # The framework source
├── setup.sh               # Main installer
├── tools/
│   └── aos               # CLI tool source
├── instructions/          # Master instruction templates
├── standards/            # Default standards templates
├── .agent-os/            # Agent OS's own project usage
│   ├── product/         # Framework's product docs
│   └── specs/           # Framework's feature specs
└── VERSION              # Framework version
```

### SYSTEM Structure
```
~/.agent-os/               # Global installation
├── instructions/         # Your instruction files
├── standards/           # Your customized standards
├── workflow-modules/    # Workflow components
├── hooks/              # Claude Code hooks
├── tools/
│   └── aos            # Installed CLI tool
└── VERSION            # Installed version
```

### Codex CLI Prompts
- **Default Location:** `$CODEX_HOME/prompts/` (defaults to `~/.codex/prompts/`)
- **Installed By:** `setup.sh` (can be skipped with `--skip-codex-commands`)
- **Contents:** Mirrors `commands/*.md` so Codex CLI exposes the same slash prompts as Claude Code and Cursor
- **Customization:** Set `CODEX_HOME` before running the installer to target a different Codex profile directory

### PROJECT Structure
```
YourProject/
├── .agent-os/           # Project-specific Agent OS
│   ├── product/        # Project documentation
│   │   ├── mission.md
│   │   ├── roadmap.md
│   │   ├── decisions.md
│   │   └── tech-stack.md
│   └── specs/          # Feature specifications
│       └── 2025-01-20-feature-name/
│           └── tasks.md
├── .claude/            # Claude Code config (if used)
├── .cursor/            # Cursor config (if used)
└── [your project files]
```
