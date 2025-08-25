# Agent OS Context Troubleshooting Guide

> Last Updated: 2025-08-25
> Version: 1.0.0

## Overview

Agent OS uses a three-context architecture to organize files and functionality. This guide helps you diagnose and resolve common context-related issues.

## Three-Context Architecture Quick Reference

| Context | Location | Purpose | Example Files |
|---------|----------|---------|---------------|
| **Source** | Repository root | Development files | `setup.sh`, `CLAUDE.md`, source code |
| **Install** | `~/.agent-os/` | User's global Agent OS installation | Standards, instructions, tools |
| **Project** | `.agent-os/` | Project-specific overrides | `mission.md`, `roadmap.md`, specs |

## Common Issues and Solutions

### 1. "Install context directory not found" Error

**Symptoms:**
- Context validator reports missing `~/.agent-os/` directory
- Commands like `aos status` fail
- References to `@~/.agent-os/` files don't resolve

**Diagnosis:**
```bash
ls -la ~/.agent-os/
# If directory doesn't exist or is empty
```

**Solutions:**
```bash
# Run Agent OS setup from repository
cd /path/to/agent-os
./setup.sh

# Or run setup with overwrite to fix corrupted installation
./setup.sh --overwrite-instructions
```

**Prevention:**
- Don't manually delete `~/.agent-os/` directory
- Use `aos update` for updates instead of manual file modifications

### 2. "Source file missing" Errors

**Symptoms:**
- Context validator reports missing core files in source context
- Setup scripts fail to find required files
- Agent OS features don't work properly

**Diagnosis:**
```bash
# Run context validator from repository root
./tools/context-validator.sh --source-only
```

**Solutions:**
```bash
# Ensure you're in the correct repository directory
cd /path/to/agent-os

# Verify git repository integrity  
git status
git fsck

# Pull latest changes if repository is incomplete
git pull origin main
```

**Prevention:**
- Always run Agent OS tools from the repository root
- Keep your repository up to date with `git pull`
- Don't delete core Agent OS files

### 3. Reference Resolution Failures

**Symptoms:**
- Warnings about references not resolving
- Instructions reference files that don't exist
- Features fail because they can't find referenced files

**Diagnosis:**
```bash
# Check specific reference patterns
grep -r "@~/.agent-os/" ~/.agent-os/
grep -r "@.agent-os/" .agent-os/

# Run full reference validation
./tools/validate-references.sh
```

**Solutions:**
```bash
# Fix install context references
./setup.sh --overwrite-instructions

# Fix project context references  
# Manually verify .agent-os/ files exist or inherit from install context

# For broken script references
chmod +x ~/.agent-os/scripts/*.sh
```

**Prevention:**
- Use the context validator before making changes: `./tools/context-validator.sh`
- Don't manually edit reference paths
- Use setup scripts for installations/updates

### 4. Context Violations (Files in Wrong Places)

**Symptoms:**
- Context validator reports violations
- Duplicate files in multiple contexts
- Inconsistent behavior across environments

**Diagnosis:**
```bash
# Check for files that shouldn't be in install context
ls -la ~/.agent-os/setup.sh    # Should NOT exist
ls -la ~/.agent-os/README.md   # Should NOT exist
ls -la ~/.agent-os/.git        # Should NOT exist
```

**Solutions:**
```bash
# Remove source-only files from install context
rm -f ~/.agent-os/setup.sh
rm -f ~/.agent-os/README.md  
rm -rf ~/.agent-os/.git
rm -rf ~/.agent-os/tests

# Reinstall clean install context
./setup.sh --overwrite-instructions
```

**Prevention:**
- Never copy entire repository to `~/.agent-os/`
- Use setup scripts for installation
- Don't manually move files between contexts

### 5. Project Context Issues

**Symptoms:**
- Project-specific settings not taking effect
- Agent OS workflows not finding project files
- Context validator can't find project context

**Diagnosis:**
```bash
# Check if you're in a project directory
pwd
ls -la .agent-os/

# Verify project context detection
./tools/context-validator.sh --project-only
```

**Solutions:**
```bash
# Create project context if missing (and needed)
mkdir -p .agent-os/product

# Initialize project with Agent OS
# (Follow Agent OS product planning workflow)

# Verify project files exist
ls -la .agent-os/product/
```

**Prevention:**
- Initialize projects properly using Agent OS workflows
- Don't manually create `.agent-os/` directories without content
- Use Agent OS commands for project management

### 6. Version Mismatch Issues

**Symptoms:**
- Different behavior than expected
- Features available in source but not in install
- Outdated instruction files

**Diagnosis:**
```bash
# Check versions
cat VERSION                    # Source version
cat ~/.agent-os/VERSION        # Install version

# Compare timestamps
ls -la ~/.agent-os/instructions/core/
ls -la instructions/core/
```

**Solutions:**
```bash
# Update install context to match source
./setup.sh --overwrite-instructions

# Verify versions match
cat VERSION
cat ~/.agent-os/VERSION
```

**Prevention:**
- Regularly update with `aos update`
- Always use setup scripts for updates
- Check versions when troubleshooting

### 7. Permission Issues

**Symptoms:**
- Scripts fail to execute
- Context validator reports non-executable scripts
- "Permission denied" errors

**Diagnosis:**
```bash
# Check script permissions
ls -la ~/.agent-os/scripts/
ls -la tools/
```

**Solutions:**
```bash
# Fix script permissions in install context
chmod +x ~/.agent-os/scripts/*.sh

# Fix permissions in source context
chmod +x tools/*.sh
chmod +x scripts/*.sh

# Re-run setup to ensure correct permissions
./setup.sh
```

**Prevention:**
- Don't manually change file permissions
- Use setup scripts which set correct permissions
- Keep repository permissions intact with git

## Diagnostic Commands Reference

### Quick Health Check
```bash
# Run full context validation
./tools/context-validator.sh

# Check Agent OS installation status
aos status

# Verify specific context
./tools/context-validator.sh --install-only
```

### Deep Diagnostics  
```bash
# Generate context map
./tools/generate-context-map.sh

# Validate all references
./tools/validate-references.sh  

# Check file contexts
python3 tools/check-file-contexts.py
```

### System Information
```bash
# Version information
cat VERSION
cat ~/.agent-os/VERSION

# Directory structure
ls -la ~/.agent-os/
ls -la .agent-os/

# Git status (if in repository)
git status
git log --oneline -5
```

## Recovery Procedures

### Complete Reinstallation
```bash
# 1. Backup any custom configurations
cp -r ~/.agent-os/product ~/agent-os-backup-product 2>/dev/null || true

# 2. Remove existing install context  
rm -rf ~/.agent-os/

# 3. Fresh installation
cd /path/to/agent-os
./setup.sh

# 4. Restore custom configurations
cp -r ~/agent-os-backup-product ~/.agent-os/product 2>/dev/null || true
```

### Partial Repair
```bash
# Fix only instructions
./setup.sh --overwrite-instructions

# Fix only standards
./setup.sh --overwrite-standards

# Verify repair
./tools/context-validator.sh
```

## When to Seek Help

Contact Agent OS maintainers if you experience:

1. **Persistent validation failures** after following troubleshooting steps
2. **Context validator bugs** or incorrect error messages  
3. **Setup script failures** that don't match known issues
4. **Data loss** from context operations
5. **Performance issues** with context validation

## Preventing Context Issues

### Best Practices
1. **Always use setup scripts** for installation and updates
2. **Run context validator regularly** during development
3. **Don't manually edit install context** files
4. **Keep repositories up to date** with `git pull`
5. **Use Agent OS commands** instead of manual file operations

### Development Workflow
```bash
# Before starting work
./tools/context-validator.sh

# After making changes
./tools/context-validator.sh
git status

# Before releasing changes
./tools/context-validator.sh
./scripts/pre-release-validator.sh  # If available
```

### Regular Maintenance
```bash
# Weekly health check
aos status
./tools/context-validator.sh

# Update when needed
aos update
# or
./setup.sh --overwrite-instructions
```

## Additional Resources

- **Context Validator Tool**: `./tools/context-validator.sh --help`
- **Context Map Generator**: `./tools/generate-context-map.sh`
- **Agent OS Installation Guide**: `README.md`
- **GitHub Issues**: Report context bugs at the Agent OS repository

---

*This guide is part of the Agent OS Installation Test Suite (#76). For additional troubleshooting resources, see the main Agent OS documentation.*