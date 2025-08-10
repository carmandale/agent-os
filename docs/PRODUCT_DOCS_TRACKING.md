# Agent OS Product Documentation Tracking

## Problem
By default, many projects add `.agent-os/` to their `.gitignore`, which prevents important product documentation from being tracked in version control.

## Solution

### Recommended .gitignore Configuration

Instead of ignoring all Agent OS files:
```gitignore
# ❌ Don't do this:
.agent-os/
```

Use selective ignoring:
```gitignore
# ✅ Do this instead:
# Ignore temporary Agent OS files
.agent-os/temp/
.agent-os/cache/
.agent-os/logs/

# But track product documentation
!.agent-os/product/
!.agent-os/product/**

# Optionally track active specs
# !.agent-os/specs/
# !.agent-os/specs/**
```

## Why Track Product Documentation?

1. **Version Control** - Track changes to mission, roadmap, tech stack over time
2. **Team Collaboration** - Share product decisions across the team
3. **AI Context** - Claude and other AI tools can reference tracked documentation
4. **Audit Trail** - See how product decisions evolved

## What Should Be Tracked?

### Always Track (in `.agent-os/product/`)
- `mission.md` - Product vision and purpose
- `roadmap.md` - Development phases and progress
- `tech-stack.md` - Technical architecture decisions
- `decisions.md` - Key product and technical decisions

### Optionally Track (in `.agent-os/specs/`)
- Active feature specifications
- Completed spec documentation
- Task breakdowns and progress

### Never Track
- `.agent-os/temp/` - Temporary files
- `.agent-os/cache/` - Cache files
- `.agent-os/logs/` - Log files

## Migration for Existing Projects

If your project already has `.agent-os/` in gitignore:

1. Update your `.gitignore` with the recommended configuration above
2. Force-add the product documentation:
   ```bash
   git add -f .agent-os/product/
   git commit -m "feat: track Agent OS product documentation"
   ```
3. Continue normal development with proper tracking

## Hook Improvements

The v3 workflow enforcement hook includes:
- Smart detection of documentation updates
- Allows doc changes without blocking workflow
- Maintains strict enforcement for code changes
- Better user experience for product planning updates