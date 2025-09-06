# Agent OS Maintenance Checklist

> **CRITICAL:** This checklist MUST be followed after ANY source code changes to prevent broken installations

## The Problem

Agent OS has multiple installation paths and configuration files that can get out of sync:
- Local repo files vs GitHub
- Setup scripts downloading from GitHub (404 errors)
- Missing hook files in installations
- Inconsistent command registrations

## Pre-Change Verification

Before making ANY changes to Agent OS:

### 1. Repository State Check
```bash
# Check current branch and status
git status
git branch --show-current

# Verify all changes are committed
git diff --name-only
git diff --cached --name-only

# Check if local is ahead of origin
git log --oneline origin/main..HEAD
```

### 2. Installation State Check
```bash
# Run the verification script  
./scripts/verify-installation.sh

# Manual checks if script doesn't exist yet:
ls -la ~/.agent-os/hooks/
ls -la ~/.claude/commands/
ls -la ~/.claude/agents/
```

## Post-Change Mandatory Steps

After ANY change to source code, follow ALL these steps:

### 1. Update All Setup Scripts
When adding new files, update EVERY setup script:

**Files to check and update:**
- [ ] `setup.sh` - Base installation
- [ ] `setup-claude-code.sh` - Claude Code integration
- [ ] `setup-cursor.sh` - Cursor integration (if exists)
- [ ] `hooks/install-hooks.sh` - Hook installation
- [ ] Any other setup scripts

**What to update:**
- [ ] Add new files to download lists
- [ ] Update file paths in curl commands
- [ ] Add new files to permission/chmod commands
- [ ] Update validation checks

### 2. Test Local Installation
```bash
# Test the setup scripts work locally
./setup.sh --overwrite-instructions
./setup-claude-code.sh --overwrite-commands

# Verify all expected files exist
./scripts/verify-installation.sh
```

### 3. Commit and Push Changes
```bash
# Commit ALL changes (source + setup scripts)
git add .
git commit -m "feat: [description] - includes setup script updates"

# CRITICAL: Push to GitHub immediately
git push origin main
```

### 4. Test GitHub Installation
```bash
# Test the actual GitHub installation path
# (This is what users will experience)

# Backup current installation
mv ~/.agent-os ~/.agent-os.backup
mv ~/.claude/commands ~/.claude/commands.backup

# Test fresh install from GitHub
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash
./setup-claude-code.sh

# Verify everything works
./scripts/verify-installation.sh
```

### 5. Fix Any Issues Found
If GitHub installation fails:
- [ ] Check for 404 errors in setup script output
- [ ] Verify all files exist on GitHub at expected paths
- [ ] Update setup scripts if paths are wrong
- [ ] Commit and push fixes
- [ ] Re-test GitHub installation

## Common Issues and Fixes

### Issue: "404: Not Found" in command files
**Cause:** Setup script downloads from GitHub but files aren't pushed yet
**Fix:** 
1. Push local commits to GitHub first
2. Re-run setup script

### Issue: "No such file or directory" hook errors  
**Cause:** Hook files missing from installation
**Fix:**
1. Check which hooks are referenced in Claude settings
2. Ensure all referenced hooks are included in setup scripts
3. Update `hooks/install-hooks.sh` to install missing files

### Issue: Command not recognized by Claude Code
**Cause:** Command file corrupted or empty during download
**Fix:**
1. Check file contents: `cat ~/.claude/commands/[command].md`
2. If corrupted, copy directly: `cp commands/[command].md ~/.claude/commands/`
3. Fix setup script to prevent future corruption

## Verification Script Requirements

Create `verify-installation.sh` that checks:
- [ ] All expected directories exist
- [ ] All command files exist and have content (not just "404: Not Found")
- [ ] All hook files exist and are executable
- [ ] All agent files exist and have content
- [ ] Claude Code settings are valid JSON
- [ ] No missing dependencies

## File Inventory

### Core Files That Must Always Sync:
- `commands/*.md` → `~/.claude/commands/*.md`
- `claude-code/agents/*.md` → `~/.claude/agents/*.md`
- `hooks/*.sh` → `~/.agent-os/hooks/*.sh`
- `hooks/*.py` → `~/.agent-os/hooks/*.py`
- `instructions/*.md` → `~/.agent-os/instructions/*.md`
- `standards/*.md` → `~/.agent-os/standards/*.md`

### Setup Scripts That Must Stay Updated:
- `setup.sh` - Downloads from instructions/ and standards/
- `setup-claude-code.sh` - Downloads from commands/ and claude-code/agents/
- `hooks/install-hooks.sh` - Downloads from hooks/

## Emergency Recovery

If installation is completely broken:
```bash
# Full reset
rm -rf ~/.agent-os ~/.claude/commands ~/.claude/agents

# Fresh install from local repo
./setup.sh
./setup-claude-code.sh

# If that fails, copy files directly
cp -r instructions/ ~/.agent-os/instructions/
cp -r standards/ ~/.agent-os/standards/
cp -r commands/* ~/.claude/commands/
cp -r claude-code/agents/* ~/.claude/agents/
cp -r hooks/* ~/.agent-os/hooks/
chmod +x ~/.agent-os/hooks/*.sh
```

## Success Criteria

Installation is successful when:
- [ ] No "404: Not Found" errors
- [ ] No "No such file or directory" errors  
- [ ] All commands work: `/plan-product`, `/create-spec`, etc.
- [ ] All hooks run without errors
- [ ] `./scripts/verify-installation.sh` passes all checks

---

**REMEMBER: Every time you change Agent OS code, you're changing a system that installs itself. You MUST test the installation process, not just the code changes.**