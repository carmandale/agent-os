# AGENTS.md - Complete Guide for Code Agents Working on Agent OS

> **🤖 FOR FUTURE AGENTS:** This is your complete playbook for working on Agent OS. Read this FIRST before making any changes to avoid critical sync issues that have caused problems in the past.

## 🚨 CRITICAL RULE: The Three-Context Problem

**NEVER edit installed files directly!** Always work on source code first.

## 📚 QUICK START FOR NEW AGENTS

If you're an AI agent tasked with working on Agent OS, follow this sequence:

1. **🔍 UNDERSTAND THE CONTEXT**: Read this entire file first
2. **🧹 CHECK WORKSPACE**: Run `./check-agent-os.sh` to verify setup
3. **🚀 START FRESH**: Always create a feature branch for changes
4. **✅ FOLLOW THE WORKFLOW**: Source → Commit → Install → Test
5. **📋 VERIFY EVERYTHING**: Use the checklists in this document

### Common Agent Tasks & Quick Commands

| Task | Commands to Run |
|------|----------------|
| **Fix a script bug** | 1. Edit `scripts/filename.sh`<br>2. `./setup.sh --overwrite-instructions`<br>3. Test: `~/.agent-os/scripts/filename.sh` |
| **Add new Claude command** | 1. Create `commands/new-command.md`<br>2. Add to `setup-claude-code.sh`<br>3. `./setup-claude-code.sh --overwrite-commands` |
| **Update instruction file** | 1. Edit `instructions/core/filename.md`<br>2. `./setup.sh --overwrite-instructions`<br>3. Test: Check `~/.agent-os/instructions/core/` |
| **Modify installer** | 1. Edit `setup.sh` or `setup-claude-code.sh`<br>2. Test locally first<br>3. Verify end-to-end |

## The Three-Context Problem

Agent OS operates in three distinct contexts that can get out of sync:

1. **REPO** (`~/Projects/agent-os/`) - **THIS REPOSITORY** - The source code we work on
2. **SYSTEM** (`~/.agent-os/`) - Global framework installation on user machines
3. **PROJECT** (`YourProject/.agent-os/`) - Project-specific configuration

**⚠️ SYNC ISSUE:** Bugs have been fixed in installed versions but not source code, causing future installs to wipe out fixes.

## Installation Flow Mapping

### 1. Base Installation (`setup.sh`)

**Source Location** → **Installation Destination** → **Purpose**

#### Standards (User Customizable)
```bash
standards/tech-stack.md      → ~/.agent-os/standards/tech-stack.md      # Tech stack templates
standards/code-style.md      → ~/.agent-os/standards/code-style.md      # Code style templates
standards/best-practices.md  → ~/.agent-os/standards/best-practices.md  # Best practices templates
```
*Note: These preserve user customizations unless `--overwrite-standards` is used*

#### Core Instructions (Always Updated)
```bash
instructions/core/analyze-product.md  → ~/.agent-os/instructions/core/analyze-product.md
instructions/core/create-spec.md      → ~/.agent-os/instructions/core/create-spec.md
instructions/core/execute-tasks.md    → ~/.agent-os/instructions/core/execute-tasks.md
instructions/core/execute-task.md     → ~/.agent-os/instructions/core/execute-task.md
instructions/core/plan-product.md     → ~/.agent-os/instructions/core/plan-product.md
instructions/meta/pre-flight.md       → ~/.agent-os/instructions/meta/pre-flight.md
```

#### Scripts (Always Updated)
```bash
scripts/workspace-hygiene-check.sh              → ~/.agent-os/scripts/workspace-hygiene-check.sh
scripts/project-context-loader.sh               → ~/.agent-os/scripts/project-context-loader.sh
scripts/task-validator.sh                       → ~/.agent-os/scripts/task-validator.sh
scripts/update-documentation.sh                 → ~/.agent-os/scripts/update-documentation.sh
scripts/update-documentation-wrapper.sh         → ~/.agent-os/scripts/update-documentation-wrapper.sh
scripts/lib/update-documentation-lib.sh         → ~/.agent-os/scripts/lib/update-documentation-lib.sh
scripts/lib/spec-creator.sh                     → ~/.agent-os/scripts/lib/spec-creator.sh
scripts/lib/roadmap-sync.sh                     → ~/.agent-os/scripts/lib/roadmap-sync.sh
scripts/config-resolver.py                      → ~/.agent-os/scripts/config-resolver.py
scripts/session-memory.sh                       → ~/.agent-os/scripts/session-memory.sh
scripts/config-validator.sh                     → ~/.agent-os/scripts/config-validator.sh
scripts/pre-command-guard.sh                    → ~/.agent-os/scripts/pre-command-guard.sh
scripts/intent-analyzer.sh                      → ~/.agent-os/scripts/intent-analyzer.sh
scripts/workspace-state.sh                      → ~/.agent-os/scripts/workspace-state.sh
scripts/context-aware-wrapper.sh                → ~/.agent-os/scripts/context-aware-wrapper.sh
scripts/testing-enforcer.sh                     → ~/.agent-os/scripts/testing-enforcer.sh
scripts/workflow-validator.sh                   → ~/.agent-os/scripts/workflow-validator.sh
scripts/work-session-manager.sh                 → ~/.agent-os/scripts/work-session-manager.sh
scripts/commit-boundary-manager.sh              → ~/.agent-os/scripts/commit-boundary-manager.sh
scripts/session-auto-start.sh                   → ~/.agent-os/scripts/session-auto-start.sh
scripts/check-updates.sh                        → ~/.agent-os/scripts/check-updates.sh
scripts/validate-instructions.sh                → ~/.agent-os/scripts/validate-instructions.sh
scripts/project_root_resolver.py                → ~/.agent-os/scripts/project_root_resolver.py
```

#### Workflow Modules (Always Updated)
```bash
workflow-modules/step-1-hygiene-and-setup.md    → ~/.agent-os/workflow-modules/step-1-hygiene-and-setup.md
workflow-modules/step-2-planning-and-execution.md → ~/.agent-os/workflow-modules/step-2-planning-and-execution.md
workflow-modules/step-3-quality-assurance.md    → ~/.agent-os/workflow-modules/step-3-quality-assurance.md
workflow-modules/step-4-git-integration.md      → ~/.agent-os/workflow-modules/step-4-git-integration.md
```

#### Tools (Always Updated)
```bash
tools/aos                                        → ~/.agent-os/tools/aos                # Unified CLI tool
```

#### Version Tracking
```bash
VERSION                                          → ~/.agent-os/VERSION                  # Version tracking
```

### 2. Claude Code Installation (`setup-claude-code.sh`)

**Source Location** → **Installation Destination** → **Purpose**

#### Commands (Claude Code Slash Commands)
```bash
commands/plan-product.md         → ~/.claude/commands/plan-product.md
commands/create-spec.md          → ~/.claude/commands/create-spec.md
commands/execute-tasks.md        → ~/.claude/commands/execute-tasks.md
commands/analyze-product.md      → ~/.claude/commands/analyze-product.md
commands/hygiene-check.md        → ~/.claude/commands/hygiene-check.md
commands/update-documentation.md → ~/.claude/commands/update-documentation.md
commands/workflow-status.md      → ~/.claude/commands/workflow-status.md
commands/workflow-complete.md    → ~/.claude/commands/workflow-complete.md
```

#### Agent Definitions (Builder Methods Subagents)
```bash
claude-code/agents/context-fetcher.md → ~/.claude/agents/context-fetcher.md
claude-code/agents/date-checker.md    → ~/.claude/agents/date-checker.md
claude-code/agents/file-creator.md    → ~/.claude/agents/file-creator.md
claude-code/agents/git-workflow.md    → ~/.claude/agents/git-workflow.md
claude-code/agents/test-runner.md     → ~/.claude/agents/test-runner.md
```

#### Hooks (Workflow Enforcement)
```bash
hooks/workflow-enforcement-hook.py     → ~/.agent-os/hooks/workflow-enforcement-hook.py
hooks/stop-hook.sh                     → ~/.agent-os/hooks/stop-hook.sh
hooks/user-prompt-submit-hook.sh       → ~/.agent-os/hooks/user-prompt-submit-hook.sh
hooks/pre-bash-hook.sh                 → ~/.agent-os/hooks/pre-bash-hook.sh
hooks/post-bash-hook.sh                → ~/.agent-os/hooks/post-bash-hook.sh
hooks/task-status-sync.sh              → ~/.agent-os/hooks/task-status-sync.sh
hooks/notify-hook.sh                   → ~/.agent-os/hooks/notify-hook.sh
hooks/install-hooks.sh                 → ~/.agent-os/hooks/install-hooks.sh
hooks/claude-code-hooks.json           → ~/.agent-os/hooks/claude-code-hooks.json

# Hook utilities
hooks/lib/workflow-detector.sh         → ~/.agent-os/hooks/lib/workflow-detector.sh
hooks/lib/git-utils.sh                 → ~/.agent-os/hooks/lib/git-utils.sh
hooks/lib/context-builder.sh           → ~/.agent-os/hooks/lib/context-builder.sh
hooks/lib/evidence-standards.sh        → ~/.agent-os/hooks/lib/evidence-standards.sh
hooks/lib/project-config-injector.sh   → ~/.agent-os/hooks/lib/project-config-injector.sh
hooks/lib/testing-enforcer.sh          → ~/.agent-os/hooks/lib/testing-enforcer.sh
hooks/lib/testing-reminder.sh          → ~/.agent-os/hooks/lib/testing-reminder.sh
hooks/lib/workflow-reminder.sh         → ~/.agent-os/hooks/lib/workflow-reminder.sh
```

### 3. Cursor Installation (`setup-cursor.sh`)

**Source Location** → **Installation Destination** → **Purpose**

#### Project-Specific Rules (Created in each project)
```bash
commands/plan-product.md     → .cursor/rules/plan-product.mdc     # Cursor rule format
commands/create-spec.md      → .cursor/rules/create-spec.mdc      # with front-matter
commands/execute-tasks.md    → .cursor/rules/execute-tasks.mdc
commands/analyze-product.md  → .cursor/rules/analyze-product.mdc
commands/hygiene-check.md    → .cursor/rules/hygiene-check.mdc
commands/update-documentation.md → .cursor/rules/update-documentation.mdc
commands/workflow-status.md      → .cursor/rules/workflow-status.mdc
commands/workflow-complete.md    → .cursor/rules/workflow-complete.mdc
```

### 4. Codex Installation (via `setup.sh`)

**Source Location** → **Installation Destination** → **Purpose**

#### Slash Prompts (Codex CLI)
```bash
commands/analyze-product.md      → $CODEX_HOME/prompts/analyze-product.md      # Default: ~/.codex/prompts/
commands/create-spec.md          → $CODEX_HOME/prompts/create-spec.md
commands/execute-tasks.md        → $CODEX_HOME/prompts/execute-tasks.md
commands/hygiene-check.md        → $CODEX_HOME/prompts/hygiene-check.md
commands/plan-product.md         → $CODEX_HOME/prompts/plan-product.md
commands/update-documentation.md → $CODEX_HOME/prompts/update-documentation.md
commands/workflow-status.md      → $CODEX_HOME/prompts/workflow-status.md
commands/workflow-complete.md    → $CODEX_HOME/prompts/workflow-complete.md
```

> ℹ️ Set `CODEX_HOME` before running `setup.sh` to install into a non-default Codex configuration directory. Use `--skip-codex-commands` if you need to bypass Codex prompt installation.

## ⚠️ CRITICAL GAPS IDENTIFIED

### Files NOT Installed by Any Script

These source files exist but are NOT installed anywhere:

#### Scripts Not Installed
```bash
scripts/pre-commit-docs-guard.sh    # ❌ NOT INSTALLED BY ANY SCRIPT
scripts/verify-installation.sh      # ❌ NOT INSTALLED BY ANY SCRIPT
```

#### Hook Files Not Installed
```bash
hooks/uninstall-hooks.sh            # ❌ NOT INSTALLED BY ANY SCRIPT
hooks/agent-os-bash-hooks.json      # ❌ NOT INSTALLED BY ANY SCRIPT
hooks/context_aware_hook.py         # ❌ NOT INSTALLED BY ANY SCRIPT
hooks/intent_analyzer.py            # ❌ NOT INSTALLED BY ANY SCRIPT
hooks/bash_command_validator_example.py # ❌ NOT INSTALLED BY ANY SCRIPT
```

#### Test Files (Intentionally Not Installed)
```bash
hooks/test_*.py                      # ✓ Test files - correctly excluded
hooks/tests/                         # ✓ Test directory - correctly excluded
```

### Files Installed but Not in Source

These files are downloaded but don't exist in source:

```bash
# From integrations/setup-subagent-integration.sh (downloaded by setup-claude-code.sh)
# This may not exist in the repository but is referenced in the installer
```

## MANDATORY DEVELOPMENT WORKFLOW

### ⚠️ THE SYNC PROBLEM

**Problem:** Developers fix bugs in installed files (`~/.agent-os/`, `~/.claude/`) but don't update source code. Future installs wipe out the fixes.

**Solution:** ALWAYS work on source code first, then install.

### ✅ CORRECT WORKFLOW

1. **EDIT SOURCE CODE** (in this repository)
   ```bash
   # Work on files in:
   # - commands/
   # - scripts/
   # - hooks/
   # - instructions/
   # - standards/
   # - claude-code/agents/
   ```

2. **COMMIT CHANGES** to repository
   ```bash
   git add .
   git commit -m "Fix: Description of the fix"
   git push
   ```

3. **INSTALL FROM SOURCE**
   ```bash
   # Install base system from updated source
   ./setup.sh --overwrite-instructions --overwrite-standards

   # Install Claude Code components from updated source
   ./setup-claude-code.sh --overwrite-commands

   # Or install from remote repository
   curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash -s -- --overwrite-instructions
   ```

4. **TEST THE INSTALLATION**
   ```bash
   # Test the aos CLI
   aos status

   # Test Claude Code commands
   # Use /hygiene-check or /plan-product in Claude Code

   # Test scripts directly
   ~/.agent-os/scripts/workspace-hygiene-check.sh
   ```

5. **VERIFY CHANGES TOOK EFFECT**
   ```bash
   # Compare source and installed files
   diff scripts/workspace-hygiene-check.sh ~/.agent-os/scripts/workspace-hygiene-check.sh
   diff commands/plan-product.md ~/.codex/prompts/plan-product.md

   # Check installed file timestamps
   ls -la ~/.agent-os/scripts/workspace-hygiene-check.sh
   ls -la ~/.codex/prompts/plan-product.md
   ```

### ❌ WRONG WORKFLOW (DO NOT DO THIS)

```bash
# DON'T edit installed files directly
nano ~/.agent-os/scripts/workspace-hygiene-check.sh  # ❌ WRONG
nano ~/.claude/commands/plan-product.md              # ❌ WRONG

# DON'T skip source code updates
# Fix bug in installed file but not source = future installs break  # ❌ WRONG
```

## VERIFICATION CHECKLIST

Before claiming any fix is complete:

### 📋 Source Code Verification
- [ ] Changes made to source files in repository
- [ ] Source code committed and pushed to main branch
- [ ] Version bumped if needed (in `VERSION` file)

### 📋 Installation Verification
- [ ] Ran installer script(s) with overwrite flags
- [ ] Verified installed files match source files
- [ ] Checked file timestamps to confirm update

### 📋 Functionality Verification
- [ ] Tested the specific fix in action
- [ ] Verified no regression in other functionality
- [ ] Tested via appropriate interface (CLI, Claude Code commands, etc.)

### 📋 Gap Verification
- [ ] Confirmed fix addresses identified gaps in this document
- [ ] No orphaned files in source that aren't installed
- [ ] No references to non-existent files in installers

## INSTALLER MODIFICATION WORKFLOW

When modifying the installers themselves:

1. **Edit installer scripts** in repository root:
   - `setup.sh` - Base installation
   - `setup-claude-code.sh` - Claude Code installation
   - `setup-cursor.sh` - Cursor installation

2. **Test installer locally**:
   ```bash
   # Test base installer
   ./setup.sh --overwrite-instructions --overwrite-standards

   # Test Claude Code installer
   ./setup-claude-code.sh --overwrite-commands
   ```

3. **Verify via remote install** (after pushing changes):
   ```bash
   # Test remote installation
   curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash
   ```

## DEBUGGING INSTALLATION ISSUES

### Common Issues and Solutions

#### Issue: "File not found" during installation
**Diagnosis:** Installer references file that doesn't exist in source
**Solution:**
1. Check if file exists in source repository
2. If missing, either create it or remove reference from installer
3. Update this AGENTS.md document

#### Issue: Changes not taking effect after installation
**Diagnosis:** Source file not updated or installer not grabbing latest
**Solution:**
1. Verify changes exist in source file
2. Check file is listed in installer script
3. Run installer with overwrite flags
4. Check file timestamps in installed location

#### Issue: Installation succeeds but functionality broken
**Diagnosis:** Dependency missing or file permissions wrong
**Solution:**
1. Check all referenced files exist
2. Verify script permissions (`chmod +x` needed)
3. Test scripts individually before testing full workflow

## MAINTENANCE NOTES

### When Adding New Files

1. **Add to appropriate installer** (`setup.sh`, `setup-claude-code.sh`, or `setup-cursor.sh`)
2. **Update this AGENTS.md** mapping section
3. **Test installation** end-to-end
4. **Document any new gaps** in the verification checklist

### When Removing Files

1. **Remove from installer scripts**
2. **Update this AGENTS.md** mapping section
3. **Consider migration/cleanup** for existing installations
4. **Test that removal doesn't break** dependent functionality

### Version Management

- **Source of truth:** `VERSION` file in repository root
- **Installed version:** `~/.agent-os/VERSION` (copied from source)
- **Update process:** Increment version in source, commit, then install

## 🤖 AGENT-SPECIFIC GUIDANCE

### AI Agent Safety Guards

**🚨 BEFORE MAKING ANY CHANGES:**

1. **Read the entire AGENTS.md file** (this file) - don't skip sections
2. **Check existing issues and PRs** to avoid duplicate work
3. **Verify you understand the three-context problem**
4. **Always test your changes** before claiming completion

### Common Agent Mistakes to Avoid

❌ **DON'T:** Edit files in `~/.agent-os/` or `~/.claude/` directly
✅ **DO:** Edit source files in the repository, then install

❌ **DON'T:** Assume installation worked without testing
✅ **DO:** Run verification commands after installation

❌ **DON'T:** Mix multiple unrelated changes in one commit
✅ **DO:** Create focused commits for specific fixes

❌ **DON'T:** Skip the feature branch workflow
✅ **DO:** Always work on feature branches, never commit directly to main

### Testing Patterns for Common Changes

#### When Modifying Scripts
```bash
# 1. Edit source file
nano scripts/workspace-hygiene-check.sh

# 2. Install with overwrite
./setup.sh --overwrite-instructions

# 3. Test directly
~/.agent-os/scripts/workspace-hygiene-check.sh

# 4. Verify it matches source
diff scripts/workspace-hygiene-check.sh ~/.agent-os/scripts/workspace-hygiene-check.sh
```

#### When Adding Claude Commands
```bash
# 1. Create source file
nano commands/new-command.md

# 2. Add to installer
nano setup-claude-code.sh  # Add to the commands loop

# 3. Install with overwrite
./setup-claude-code.sh --overwrite-commands

# 4. Verify installation
ls -la ~/.claude/commands/new-command.md
```

#### When Fixing Installer Issues
```bash
# 1. Edit installer
nano setup.sh

# 2. Test locally
./setup.sh --overwrite-instructions --overwrite-standards

# 3. Check status
aos status

# 4. Test remote install (after pushing)
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash
```

### Quality Assurance Commands

Always run these before claiming work is complete:

```bash
# Syntax validation
bash -n setup.sh
bash -n setup-claude-code.sh
bash -n setup-cursor.sh

# Installation test
./check-agent-os.sh

# Status verification
~/.agent-os/tools/aos status

# File comparison (for changed files)
diff scripts/filename.sh ~/.agent-os/scripts/filename.sh
```

### Emergency Recovery

If you accidentally edit installed files instead of source:

```bash
# 1. STOP - don't commit anything yet
# 2. Copy your changes to the source files manually
# 3. Reinstall from source to verify
./setup.sh --overwrite-instructions --overwrite-standards
# 4. Test that your changes work
# 5. Then commit the source changes
```

### Agent Success Checklist

Before completing any task:

- [ ] **Understanding**: I read this AGENTS.md file completely
- [ ] **Source First**: I edited source files, not installed files
- [ ] **Installation**: I ran the appropriate installer with overwrite flags
- [ ] **Testing**: I verified the changes work as expected
- [ ] **Verification**: I compared source and installed files to ensure sync
- [ ] **Quality**: I ran syntax checks and status commands
- [ ] **Documentation**: I updated relevant docs if needed
- [ ] **Branch**: I worked on a feature branch, not main
- [ ] **Commit**: I made focused commits with clear messages

### Quick Reference Commands

```bash
# Check overall status
./check-agent-os.sh
~/.agent-os/tools/aos status

# Reinstall everything
./setup.sh --overwrite-instructions --overwrite-standards
./setup-claude-code.sh --overwrite-commands

# Verify file sync
diff commands/plan-product.md ~/.claude/commands/plan-product.md
diff scripts/workspace-hygiene-check.sh ~/.agent-os/scripts/workspace-hygiene-check.sh

# Syntax checks
bash -n setup.sh
bash -n setup-claude-code.sh

# Create feature branch
git checkout -b feature/your-change-description
```

## 📊 METRICS FOR AGENTS

Track these to ensure quality:

- **Files Changed**: List all source files modified
- **Installation Commands Run**: Document which installers were executed
- **Tests Passed**: Show output of verification commands
- **Sync Verified**: Prove source and installed files match
- **Quality Checks**: Show syntax validation results

### Evidence Template for Agent Work

```markdown
## Evidence/Test Results/Verification

### Files Modified
- scripts/workspace-hygiene-check.sh (fixed bug in line 42)
- commands/new-feature.md (added new command)

### Installation Process
```bash
$ ./setup.sh --overwrite-instructions
✅ Script installed successfully

$ ./setup-claude-code.sh --overwrite-commands
✅ Commands installed successfully
```

### Verification Results
```bash
$ diff scripts/workspace-hygiene-check.sh ~/.agent-os/scripts/workspace-hygiene-check.sh
# No output = files match ✅

$ ~/.agent-os/scripts/workspace-hygiene-check.sh
✅ Script executes successfully

$ aos status
✅ All components current
```

### Quality Assurance
```bash
$ bash -n setup.sh
✅ Syntax valid

$ ./check-agent-os.sh
🚀 Agent OS is ready to use!
```
```

---

**Last Updated:** 2025-01-27
**Document Version:** 2.0.0 - Enhanced for AI Agents
**Next Review:** When source-to-installation mappings change

*🤖 This document is specifically designed for AI agents working on Agent OS. Follow it religiously to avoid sync issues.*
