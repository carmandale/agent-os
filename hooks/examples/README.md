# Hook Configuration Examples (Not Installed Automatically)

This directory contains example Claude Code hook configuration files that demonstrate how Agent OS integrates with Claude Code's hook system.

Important facts:
- These JSON files are examples only and are not used directly by the installer.
- The authoritative hook configuration is written to your user settings at:
  - ~/.claude/settings.json
- To install/update hooks properly, always run:
  - ~/.agent-os/hooks/install-hooks.sh

What these files show:
- claude-code-hooks.json
  - Minimal example of defining Stop and UserPromptSubmit hooks
- agent-os-bash-hooks.json
  - Example configuration for Bash PreToolUse/PostToolUse observers and other events

Why keep examples?
- They serve as reference templates for advanced customization.
- They help document supported events, matchers, and structure.
- They provide starting points if you need to generate project- or org-specific configurations.

How to use safely:
1) Prefer the installer for most users:
   - ~/.agent-os/hooks/install-hooks.sh
   - This ensures settings are merged correctly and validated.
2) If you must customize:
   - Edit ~/.claude/settings.json manually with extreme care.
   - Keep a backup of your settings file before changes.
   - Validate JSON syntax and restart Claude Code for changes to take effect.

Troubleshooting:
- If hooks do not appear to run:
  - Re-run the installer: ~/.agent-os/hooks/install-hooks.sh
  - Verify ~/.claude/settings.json is valid JSON
  - Restart Claude Code to reload hooks
  - Enable debug if available and check logs under ~/.agent-os/logs/

Note on legacy configs:
- Historically, some repositories shipped full hook JSON under hooks/.
- Agent OS now standardizes on an installation script that writes to the user settings file to prevent drift and confusion.