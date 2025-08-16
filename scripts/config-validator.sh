#!/usr/bin/env bash
# Fast pre-command validator for package manager and port consistency
set -euo pipefail

# Load session vars if present
if [[ -f "$HOME/.agent-os/cache/session-config.json" ]]; then
  PYPM=$(jq -r '.python_package_manager // empty' "$HOME/.agent-os/cache/session-config.json" 2>/dev/null || true)
  JSPM=$(jq -r '.javascript_package_manager // empty' "$HOME/.agent-os/cache/session-config.json" 2>/dev/null || true)
  FPORT=$(jq -r '.frontend_port // empty' "$HOME/.agent-os/cache/session-config.json" 2>/dev/null || true)
  BPORT=$(jq -r '.backend_port // empty' "$HOME/.agent-os/cache/session-config.json" 2>/dev/null || true)
else
  PYPM=""; JSPM=""; FPORT=""; BPORT=""
fi

CMDLINE="${*:-}"

# Block tool switches
if [[ -n "$PYPM" ]]; then
  case "$PYPM" in
    uv)
      if echo "$CMDLINE" | grep -Eq '\bpip( |$)'; then
        echo "❌ Use uv, not pip (per project config)."; exit 1; fi ;;
    pip)
      : ;; # allow
    poetry)
      if echo "$CMDLINE" | grep -Eq '\bpip( |$)'; then
        echo "❌ Use poetry, not pip (per project config)."; exit 1; fi ;;
  esac
fi

if [[ -n "$JSPM" ]]; then
  case "$JSPM" in
    yarn)
      if echo "$CMDLINE" | grep -Eq '\bnpm( |$)'; then
        echo "❌ Use yarn, not npm (per project config)."; exit 1; fi ;;
    npm)
      : ;; # allow
    pnpm)
      if echo "$CMDLINE" | grep -Eq '\bnpm( |$)'; then
        echo "❌ Use pnpm, not npm (per project config)."; exit 1; fi ;;
  esac
fi

echo "✅ Config validation passed"
exit 0


