# Agent OS Update Guide

## Overview
Agent OS components are split between global (computer-wide) and project-specific files. Understanding what to update and when is crucial for maintaining consistency.

## Update Categories

### 1. Global Updates (Computer-wide)
**Location:** `~/.agent-os/`
**Frequency:** As needed when Agent OS releases updates
**Impact:** Affects all projects on your machine

#### What Gets Updated:
- **Workflow Instructions** (`~/.agent-os/instructions/`)
  - `plan-product.md`
  - `create-spec.md`
  - `execute-tasks.md`
  - `analyze-product.md`
- **Hooks** (`~/.agent-os/hooks/`)
  - `workflow-enforcement-hook-v2.py`
  - Hook utilities and libraries
- **Scripts** (`~/.agent-os/scripts/`)
  - Health checks
  - Validation scripts
- **Global Standards** (`~/.agent-os/standards/`)
  - Only if you want to adopt new best practices

#### How to Update Global Components:
```bash
# Option 1: Full update (recommended)
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash

# Option 2: Update specific components
# Update hooks only
~/.agent-os/hooks/install-hooks.sh

# Update a specific instruction file
curl -s -o ~/.agent-os/instructions/execute-tasks.md \
  https://raw.githubusercontent.com/carmandale/agent-os/main/instructions/execute-tasks.md
```

### 2. Project-Specific Files (No Updates Needed)
**Location:** `.agent-os/product/` in your project
**Frequency:** Never automatically updated
**Impact:** Project-specific, should not be overwritten

#### These Are Your Files:
- `.agent-os/product/mission.md` - Your product vision
- `.agent-os/product/roadmap.md` - Your development plan
- `.agent-os/product/tech-stack.md` - Your technical choices
- `.agent-os/product/decisions.md` - Your decision log
- `.agent-os/specs/` - Your feature specifications

**⚠️ IMPORTANT:** These files are never updated by Agent OS updates. They contain your project-specific information.

## Update Detection

### Check Current Version
```bash
# Check Agent OS installation health
~/.agent-os/scripts/check-agent-os.sh

# Check hook version
grep "^# Version:" ~/.agent-os/hooks/workflow-enforcement-hook-v2.py

# Check instruction file dates
ls -la ~/.agent-os/instructions/
```

### Check for Available Updates
```bash
# Compare with latest on GitHub
curl -s https://api.github.com/repos/carmandale/agent-os/releases/latest | grep tag_name

# See recent changes
curl -s https://api.github.com/repos/carmandale/agent-os/commits?per_page=10 | grep message
```

## Update Workflow

### Step 1: Check What Changed
Before updating, review what has changed:
```bash
# View Agent OS changelog
curl -s https://raw.githubusercontent.com/carmandale/agent-os/main/CHANGELOG.md | head -50

# Or visit
# https://github.com/carmandale/agent-os/releases
```

### Step 2: Backup Current Installation (Optional)
```bash
# Backup your current installation
cp -r ~/.agent-os ~/.agent-os.backup-$(date +%Y%m%d)

# Backup your global standards if customized
cp -r ~/.agent-os/standards ~/.agent-os-standards.backup
```

### Step 3: Run Update
```bash
# Run the update
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup.sh | bash

# Follow prompts for:
# - Keeping your customized standards
# - Installing new hooks
# - Updating Claude Code configuration
```

### Step 4: Verify Update
```bash
# Run health check
~/.agent-os/scripts/check-agent-os.sh

# Test in a project
cd your-project
claude "check project status"
```

## Update Best Practices

### For Individual Developers

1. **Update Regularly**: Check for updates monthly or when experiencing issues
2. **Read Release Notes**: Understand what's changing before updating
3. **Test After Updates**: Verify workflows still function in your projects
4. **Keep Standards**: Your customized standards are preserved during updates

### For Teams

1. **Coordinate Updates**: Team members should update together
2. **Test First**: One team member should test updates before team-wide rollout
3. **Document Changes**: Note any workflow changes in team documentation
4. **Version Pin**: Consider pinning to specific Agent OS versions for stability

```bash
# Pin to specific version
git clone https://github.com/carmandale/agent-os.git
cd agent-os
git checkout v1.2.0  # specific version
./setup.sh
```

## Handling Breaking Changes

### Minor Updates (v1.0.x)
- Bug fixes and improvements
- Safe to update immediately
- No workflow changes required

### Minor Feature Updates (v1.x.0)
- New features and improvements
- Review changelog for new capabilities
- May include new optional features

### Major Updates (vX.0.0)
- Potential breaking changes
- Read migration guide carefully
- Test in non-critical project first
- May require workflow adjustments

## Rollback Procedure

If an update causes issues:

```bash
# Restore from backup
mv ~/.agent-os ~/.agent-os.broken
mv ~/.agent-os.backup-$(date +%Y%m%d) ~/.agent-os

# Or reinstall previous version
git clone https://github.com/carmandale/agent-os.git
cd agent-os
git checkout v1.1.0  # previous version
./setup.sh
```

## FAQ

### Q: Will updating overwrite my project files?
**A:** No. Files in `.agent-os/product/` and `.agent-os/specs/` are never touched by updates.

### Q: Will updating change my global standards?
**A:** The installer asks if you want to keep your customized standards. Choose "keep" to preserve them.

### Q: How often should I update?
**A:** Check monthly, or when:
- You encounter bugs
- New features are announced
- Team members update

### Q: Can different projects use different Agent OS versions?
**A:** No. Agent OS is installed globally. All projects on a machine use the same version.

### Q: What if I have custom modifications?
**A:** 
- Store custom scripts in a separate location
- Document your modifications
- Consider contributing them back to Agent OS

## Getting Help

- **Issues**: https://github.com/carmandale/agent-os/issues
- **Discussions**: https://github.com/carmandale/agent-os/discussions
- **Changelog**: https://github.com/carmandale/agent-os/releases

## Update Notifications

To get notified of new releases:
1. Watch the Agent OS repository on GitHub
2. Subscribe to releases only
3. You'll get email notifications for new versions

---

*Last Updated: 2025-01-10*
*Agent OS Version: 1.2.0*