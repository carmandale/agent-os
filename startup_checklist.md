# Agent OS Startup Checklist

A setup checklist to ensure Agent OS is properly installed and configured for your existing project.

## ✅ I. Base Installation of Agent OS

### 1. Install Agent OS Base
- [ ] Run the **oneline curl command** for base installation:
  ```bash
  curl -sSL https://raw.githubusercontent.com/example/agent-os/main/install.sh | bash
  ```
  - Creates `~/agent-os/` folder with instructions and standards
- [ ] *Alternative*: Manual installation by copying files from [GitHub repo](https://github.com/example/agent-os)

### 2. Customize Your Standards 🎯
**Important**: These are starter templates - customization is crucial for spec-driven development!

- [ ] **Edit Tech Stack**: `~/agent-os/standards/tech-stack.md`
  - Define your common tech stack (language, framework, hosting, deployment)
  - Can be overridden per project
  
- [ ] **Edit Code Style**: `~/agent-os/standards/code-style.md`
  - Indentation preferences
  - Naming conventions
  - HTML markup structure (e.g., Tailwind CSS organization)
  - Code comment formatting
  
- [ ] **Edit Best Practices**: `~/agent-os/standards/best-practices.md`
  - Strategic development practices
  - Organizational opinions (simplicity, readability, clarity)

---

## ✅ II. Tool-Specific Setup

### For Claude Code
- [ ] Run the **oneline script for Claude Code installation**:
  ```bash
  curl -sSL https://raw.githubusercontent.com/example/agent-os/main/setup-claude-code.sh | bash
  ```
- [ ] Verify installation:
  - `~/Claude/claude.md` - References centralized Agent OS standards
  - Custom slash commands in `~/Claude/`:
    - `/analyze-product` → `~/agent-os/commands/analyze-product.md`
    - `/create-spec` → `~/agent-os/commands/create-spec.md`
    - `/execute-tasks` → `~/agent-os/commands/execute-tasks.md`
    - `/plan-product` → `~/agent-os/commands/plan-product.md`

### For Cursor
- [ ] **Navigate to your project folder** in terminal
- [ ] Run the **oneline setup script for Cursor**:
  ```bash
  curl -sSL https://raw.githubusercontent.com/example/agent-os/main/setup-cursor.sh | bash
  ```
- [ ] Verify installation in your project:
  - `./cursor/rules/` folder created/updated with:
    - `analyze-product` → References `~/agent-os/instructions/analyze-product.md`
    - `create-spec` → References `~/agent-os/instructions/create-spec.md`
    - `execute-tasks` → References `~/agent-os/instructions/execute-tasks.md`
    - `plan-product` → References `~/agent-os/instructions/plan-product.md`

---

## ✅ III. Initialize Agent OS in Existing Codebase

### 1. Analyze Your Current Project
- [ ] Run `/analyze-product` command in your AI agent
  - This analyzes existing code and documents current state
  - Creates product planning documents

### 2. Review Generated Documents
- [ ] Check the new `./product/` folder in your codebase:
  - [ ] `./product/decisions.md` - Key architectural decisions
  - [ ] `./product/mission.md` - Product vision and goals
  - [ ] `./product/roadmap.md` - Feature roadmap
  - [ ] `./product/tech-stack.md` - Project-specific tech stack

- [ ] **Thoroughly review and edit** these documents to ensure accuracy
- [ ] Frontload effort here - quality specs = successful agent execution

---

## ✅ IV. Ongoing Workflow with Agent OS

### 1. Create Feature Specifications
- [ ] Use `/create-spec` command OR ask "what's next?"
- [ ] Agent creates timestamped spec folder: `./agent-os/specs/YYYY-MM-DD-feature-name/`
  - [ ] Review `spec.md` - User stories, scope, deliverables
  - [ ] Review `api-spec.md` - Endpoints, routes, responses
  - [ ] Review `db-schema.md` - Migrations, tables, columns
  - [ ] Review `technical-spec.md` - Design approach, rationale

### 2. Review and Approve Specs
- [ ] Examine all subspecs before proceeding
- [ ] Confirm with "good to go" when satisfied

### 3. Task Planning
- [ ] Review generated `tasks.md` in spec folder
- [ ] Check task breakdown and subtasks
- [ ] Approve task list before execution

### 4. Execute Tasks
- [ ] Instruct agent to proceed (e.g., "do tasks 1-3")
- [ ] Monitor `tasks.md` for progress (✓ marks completed)
- [ ] Agent follows `/execute-tasks` instructions:
  - Commits to Git
  - Creates pull requests
  - Updates task status

### 5. Verify and Test
- [ ] Test functionality in browser/environment
- [ ] Review generated code:
  - Controllers
  - Models
  - Tests
- [ ] Run automated test suite
- [ ] Ensure all tests pass

### 6. Continuous Improvement
- [ ] Note patterns where agent excels/struggles
- [ ] Update standards files accordingly:
  - `~/agent-os/standards/tech-stack.md`
  - `~/agent-os/standards/code-style.md`
  - `~/agent-os/standards/best-practices.md`
- [ ] Refine instructions as needed

---

## 📁 Quick Reference: Key File Locations

### System-Level (Home Directory)
```
~/agent-os/
├── standards/
│   ├── tech-stack.md     # Edit: Your tech preferences
│   ├── code-style.md     # Edit: Your code formatting
│   └── best-practices.md # Edit: Your dev practices
├── instructions/         # Command implementations
└── commands/            # Command definitions
```

### Project-Level (Your Codebase)
```
your-project/
├── product/             # Generated by analyze-product
│   ├── decisions.md
│   ├── mission.md
│   ├── roadmap.md
│   └── tech-stack.md
├── agent-os/
│   └── specs/          # Feature specifications
│       └── YYYY-MM-DD-feature/
│           ├── spec.md
│           ├── tasks.md
│           └── [subspecs]
└── cursor/             # Cursor-specific (if using)
    └── rules/
```

---

## 🚀 Pro Tips

1. **Invest time in standards** - Well-defined standards = better agent output
2. **Review specs thoroughly** - Catch issues before code generation
3. **Start with small features** - Build confidence in the workflow
4. **Keep roadmap.md updated** - Helps agent suggest relevant next steps
5. **Use decisions.md actively** - Document why, not just what

---

*Remember: Agent OS transforms AI coding agents from confused interns into productive developers through structured workflows and clear specifications.* 