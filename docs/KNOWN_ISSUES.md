# Known Issues and Solutions

## Claude Code Shell Function Caching

### Problem
Claude Code aggressively caches shell functions and aliases, preventing updates from taking effect even after:
- Sourcing ~/.zshrc
- Using `unset -f FUNCTION_NAME`
- Reloading the shell configuration

### Symptoms
- Old version of `aos` command persists despite updates
- `which aos` shows cached function from `/Users/dalecarman/.claude/shell-snapshots/`
- Updates to alias files don't take effect

### Solution for Users

#### Option 1: Direct Execution (Immediate)
```bash
# Use the tool directly instead of the alias
~/.agent-os/tools/aos-v4 [command]

# Example:
~/.agent-os/tools/aos-v4 run "npm run dev"
~/.agent-os/tools/aos-v4 tasks
```

#### Option 2: Force Reload in New Terminal
1. Open a NEW terminal window (not in Claude Code)
2. Run: `source ~/.zshrc`
3. Test: `aos help`

#### Option 3: Manual Alias Override
```bash
# Add this to your ~/.zshrc AFTER the Agent OS alias line
alias aos='~/.agent-os/tools/aos-v4'
```

### Root Cause
Claude Code creates shell snapshots that override normal shell function loading. These snapshots persist across sessions and ignore standard shell reload commands.

## Installation Script Duplication

### Problem
The install-aos-alias.sh script can append duplicate entries to ~/.zshrc if run multiple times.

### Symptoms
- Multiple "Agent OS Quick Init Alias" blocks in ~/.zshrc
- Duplicate PATH exports
- Shell configuration becomes messy

### Solution
Manually clean ~/.zshrc by removing duplicate entries, keeping only one:
```bash
# Agent OS Quick Init Alias
if [ -f "$HOME/.agent-os/tools/agentos-alias.sh" ]; then
    source "$HOME/.agent-os/tools/agentos-alias.sh"
fi
```

## Update Command Failure

### Problem
The old aos shell function tries to pass multiple flags as a single string to setup.sh, causing "Unknown option" errors.

### Symptoms
```
Unknown option: --overwrite-instructions --overwrite-standards
```

### Solution
Use aos-v4 which handles arguments correctly, or run setup.sh directly:
```bash
bash setup.sh --overwrite-instructions --overwrite-standards
```

## Version File Standardization (v4.0.0)

### Context
Historically both `~/.agent-os/.version` and `~/.agent-os/VERSION` existed, leading to confusion.

### Current Standard
- Canonical file: `~/.agent-os/VERSION` (uppercase, no `v` prefix)
- The installer removes legacy `~/.agent-os/.version` if present.

### Verify
```bash
cat ~/.agent-os/VERSION
```