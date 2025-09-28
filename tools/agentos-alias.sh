#!/bin/bash
# Agent OS Alias Definitions (hardened and idempotent)
# - Defines 'aos' alias pointing to the Agent OS CLI binary if present and executable
# - Removes any conflicting aliases/functions before defining new ones
# - Defines 'agentos' as a backwards-compatibility alias to 'aos' (only if 'aos' is defined)

# Target CLI binary
AOS_BINARY="$HOME/.agent-os/tools/aos"

# If the CLI binary is missing or not executable, warn and skip alias creation
if [ ! -x "$AOS_BINARY" ]; then
  echo "[Agent OS] Warning: CLI not found or not executable at $AOS_BINARY; skipping alias installation." >&2
else
  # Remove any existing alias or function named 'aos'
  if alias aos >/dev/null 2>&1; then
    unalias aos >/dev/null 2>&1 || true
  fi
  if [ "$(type -t aos 2>/dev/null)" = "function" ]; then
    unset -f aos >/dev/null 2>&1 || true
  fi

  # Define primary alias to Agent OS CLI
  alias aos="$AOS_BINARY"

  # Remove any existing alias or function named 'agentos'
  if alias agentos >/dev/null 2>&1; then
    unalias agentos >/dev/null 2>&1 || true
  fi
  if [ "$(type -t agentos 2>/dev/null)" = "function" ]; then
    unset -f agentos >/dev/null 2>&1 || true
  fi

  # Backwards compatibility alias points to 'aos' (only if 'aos' was just defined)
  alias agentos="aos"
fi