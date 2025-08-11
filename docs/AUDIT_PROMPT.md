# Agent OS System Audit and Cleanup Prompt

## Context
The Agent OS installation and update system has become messy due to rushed implementation without proper verification. Multiple version files, cached shell functions, and inconsistent implementations have created confusion. This audit will systematically document the current state and create a cleanup plan.

## Critical Issues to Address
1. **Version file confusion**: Both `.version` and `VERSION` files exist
2. **Shell function caching**: Old aos functions cached by Claude Code and shell
3. **Update system failures**: Updates install but don't register correctly
4. **Project vs Global confusion**: Unclear what "project setup needs updates" means
5. **Duplicate installations**: Scripts can append duplicate entries to config files

## Audit Tasks

### Phase 1: Complete System Inventory
Document EVERYTHING that exists:

```bash
# 1. Find all aos-related files
find ~/.agent-os -name "*aos*" -o -name "*alias*" -o -name "*version*" | sort

# 2. Check all version files
ls -la ~/.agent-os/.version ~/.agent-os/VERSION 2>/dev/null
cat ~/.agent-os/.version 2>/dev/null
cat ~/.agent-os/VERSION 2>/dev/null

# 3. Check shell configuration
grep -n "aos\|Agent OS" ~/.zshrc ~/.bashrc 2>/dev/null

# 4. Identify all aos commands/functions
type aos
which aos
command -v aos-v4

# 5. Check what's on GitHub
curl -s https://raw.githubusercontent.com/carmandale/agent-os/main/VERSION
curl -s https://api.github.com/repos/carmandale/agent-os/releases/latest | grep tag_name
```

### Phase 2: Trace Execution Paths
Map exactly what happens when user runs commands:

1. **When user types `aos`**:
   - What gets executed? (function, alias, or script?)
   - What version checking occurs?
   - What files are read?

2. **When user runs update**:
   - What script downloads?
   - Where does it write version info?
   - What files get updated?

3. **When checking for updates**:
   - What version files are compared?
   - What's the source of truth?

### Phase 3: Document Intended Behavior

Create a clear specification:
```markdown
## How It SHOULD Work

### Version Management
- Single version file: ~/.agent-os/VERSION (uppercase)
- Format: Semantic versioning (2.2.0) without 'v' prefix
- Updated by: setup.sh only
- Read by: All aos tools

### Command Structure
- `aos` -> Shell alias pointing to ~/.agent-os/tools/aos-v4
- No shell functions (to avoid caching issues)
- Direct execution path, no intermediaries

### Update Flow
1. Check local VERSION against GitHub VERSION
2. If outdated, download and run setup.sh
3. setup.sh updates VERSION file
4. Next check shows "up to date"

### Project vs Global
- Global: ~/.agent-os/ installation
- Project: .agent-os/ in current directory
- Clear separation of concerns
```

### Phase 4: Identify All Problems

Create a definitive list:
```markdown
## Problems Found

1. **Problem**: [Description]
   - **Current State**: [What exists now]
   - **Desired State**: [What should exist]
   - **Impact**: [What this breaks]
   - **Fix Required**: [Specific changes needed]
```

### Phase 5: Create Cleanup Plan

Systematic fixes with verification:
```markdown
## Cleanup Steps

### Step 1: Remove Redundancies
- [ ] Delete ~/.agent-os/.version (keep only VERSION)
- [ ] Remove duplicate entries from ~/.zshrc
- [ ] Verify: Only one version file exists

### Step 2: Standardize Version Checking
- [ ] Update all scripts to use VERSION (uppercase)
- [ ] Ensure consistent format (no 'v' prefix internally)
- [ ] Verify: All tools read same file

### Step 3: Fix Shell Integration
- [ ] Replace function with simple alias
- [ ] Ensure no caching issues
- [ ] Verify: aos command works in new shells

### Step 4: Test Complete Workflow
- [ ] Fresh installation
- [ ] Update from old version
- [ ] Project setup
- [ ] All background task features
```

## Verification Requirements

**EVERY change must be verified:**
1. Make the change
2. Test it works
3. Test it doesn't break anything else
4. Document the verification
5. Only then proceed to next change

## Output Format

Create `/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/agent-os/docs/AUDIT_RESULTS.md` with:

1. **Current State Inventory** - Everything that exists
2. **Execution Flow Diagram** - How commands actually work
3. **Problem Analysis** - Each issue documented
4. **Cleanup Plan** - Ordered steps to fix
5. **Verification Checklist** - How to verify each fix
6. **Testing Plan** - End-to-end user scenarios

## Success Criteria

The audit is complete when:
- [ ] Every aos-related file is documented
- [ ] Every execution path is mapped
- [ ] Every problem has a solution
- [ ] Every fix has verification steps
- [ ] The complete user workflow is tested

## Remember

- **No quick fixes** - Understand before changing
- **No assumptions** - Verify everything
- **No rushing** - Better to be thorough than fast
- **Document everything** - Future reference is critical
- **Test like a user** - Not just individual components

This is Agent OS working on Agent OS - we must exemplify our own standards.