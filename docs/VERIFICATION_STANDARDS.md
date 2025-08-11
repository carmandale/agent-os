# Agent OS Verification Standards

> MANDATORY: All work must be verified before claiming completion
> Created: 2025-01-10
> Priority: CRITICAL

## Core Principle: Trust But Verify

**NEVER** claim work is complete without verification. **ALWAYS** check that:
1. The code actually runs
2. The feature actually works
3. The files are actually correct
4. The user can actually use it

## Verification Checklist for Every Change

### 1. File Changes
- [ ] Read the file after editing to confirm changes
- [ ] Check for duplicates or append errors
- [ ] Verify file permissions if executable
- [ ] Test the file works as intended

### 2. Shell Scripts
- [ ] Run the script with test data
- [ ] Check exit codes
- [ ] Verify output matches expectations
- [ ] Test error conditions

### 3. Configuration Changes
- [ ] Reload configurations after changes
- [ ] Verify no duplicates were created
- [ ] Check that old cached versions are cleared
- [ ] Test the new configuration works

### 4. Installation/Setup Scripts
- [ ] Run on clean environment
- [ ] Run on existing installation (update scenario)
- [ ] Verify no duplicate entries
- [ ] Check all files are created correctly
- [ ] Test the installed tools actually work

### 5. CLI Tools
- [ ] Test every command documented
- [ ] Verify help text is accurate
- [ ] Check error handling
- [ ] Test with real-world scenarios

### 6. Git Operations
- [ ] Verify commits contain intended changes
- [ ] Check branch status
- [ ] Verify pushes succeeded
- [ ] Confirm GitHub releases are accessible

### 7. Documentation
- [ ] Verify examples actually work
- [ ] Check that paths are correct
- [ ] Test installation instructions
- [ ] Confirm version numbers match

## Verification Commands

### Check for Duplicate Entries
```bash
# Check for duplicate lines in config files
sort FILE | uniq -d

# Check for duplicate function definitions
grep -c "function aos" ~/.zshrc
```

### Test Script Execution
```bash
# Always test scripts before claiming they work
bash -n script.sh  # Syntax check
bash -x script.sh  # Debug execution
```

### Verify Installation
```bash
# Check what was actually installed
ls -la ~/.agent-os/
find ~/.agent-os -type f -name "*.sh" -exec ls -l {} \;
```

### Clear Shell Cache
```bash
# Clear cached functions and aliases
unset -f FUNCTION_NAME
hash -r
```

## Red Flags That Require Immediate Verification

1. **Multiple installations/updates** - Check for duplicates
2. **Appending to files** - Verify no duplicates created
3. **Shell functions/aliases** - Test after cache clearing
4. **"Should work"** - NO! Test that it DOES work
5. **Complex operations** - Break down and verify each step

## Enforcement Mechanism

### Pre-Completion Checklist
Before marking ANY task complete:
1. Run the actual command/script
2. Check the actual output
3. Verify the actual result
4. Test edge cases
5. Document evidence of testing

### Evidence Template
```markdown
### Verification Evidence for [FEATURE]

**What I tested:**
- [Specific command or action]

**Actual output:**
```
[Paste actual terminal output]
```

**Confirmation:**
- [ ] Feature works as intended
- [ ] No errors or warnings
- [ ] User can use it successfully
```

## The Golden Rule

> If you haven't tested it, it doesn't work.
> If you haven't verified it, it's not complete.
> If you haven't checked for side effects, you've created bugs.

**ALWAYS VERIFY YOUR WORK!**