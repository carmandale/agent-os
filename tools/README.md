# Agent OS Tools

This directory contains helpful tools and utilities for Agent OS users.

## Quick Init Alias (`aos`)

The `aos` command is a shell alias that provides a streamlined way to manage Agent OS installations and updates.

### Features

- **Auto-detection**: Automatically detects whether you're in a Claude Code or Cursor project
- **Update checking**: Checks for available Agent OS updates
- **Smart installation**: Installs or updates Agent OS with customization preservation options
- **Project setup**: Sets up the appropriate AI assistant integration based on project type
- **Interactive mode**: Guides you through the setup process when run without arguments

### Installation

Install the `aos` alias to your shell:

```bash
curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/tools/install-aos-alias.sh | bash
```

Then reload your shell configuration:
```bash
source ~/.zshrc  # For zsh
# or
source ~/.bashrc # For bash
```

### Usage

#### Interactive Mode
Simply run `aos` without any arguments for an interactive setup experience:
```bash
aos
```

#### Commands

- **`aos init`** - Initialize or update Agent OS in the current project directory
  - Checks for global Agent OS installation (installs if missing)
  - Detects project type (Claude Code or Cursor)
  - Runs appropriate setup scripts
  - Offers to analyze existing codebases

- **`aos update`** - Update the global Agent OS installation
  - Preserves your customized standards by default
  - Option to overwrite everything for a clean update

- **`aos check`** or **`aos status`** - Check Agent OS installation status
  - Shows global installation status
  - Detects project type and setup
  - Checks for available updates
  - Lists installed files and configurations

- **`aos help`** - Display help information

### Examples

#### Setting up a new project
```bash
cd my-new-project
aos init
# Detects project type and sets up appropriate AI assistant integration
```

#### Updating Agent OS
```bash
aos update
# Choose to preserve customizations or do a full update
```

#### Quick status check
```bash
aos check
# Shows installation status, project detection, and available updates
```

### Alternative Alias

You can also use `agentos` as an alternative to `aos`:
```bash
agentos init
agentos check
# etc.
```

### How It Works

1. **Global Installation Check**: First checks if Agent OS is installed in `~/.agent-os/`
2. **Project Detection**: Looks for Claude Code (`.claude/`, `CLAUDE.md`) or Cursor (`.cursor/`, `.cursorrules`) files
3. **Smart Setup**: Runs the appropriate setup script based on detected project type
4. **Update Management**: Can check for updates and preserve your customizations during updates

### Customization

The alias function is stored in `~/.agent-os/tools/agentos-alias.sh` after installation. You can modify it to add custom functionality or change default behaviors.

### Troubleshooting

If the alias doesn't work after installation:

1. Make sure you've reloaded your shell configuration
2. Check that the alias was added to your shell config file (`~/.zshrc` or `~/.bashrc`)
3. Verify the alias file exists: `ls ~/.agent-os/tools/agentos-alias.sh`

### Uninstalling

To remove the alias:

1. Remove the source line from your shell configuration file
2. Delete the alias file: `rm ~/.agent-os/tools/agentos-alias.sh`
3. Reload your shell configuration