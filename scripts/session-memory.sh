#!/usr/bin/env bash
# Session memory utilities for project configuration

set -euo pipefail

CACHE_DIR="$HOME/.agent-os/cache"
CACHE_FILE="$CACHE_DIR/session-config.json"

mkdir -p "$CACHE_DIR"

refresh_cache() {
  local json
  json=$(python3 scripts/config-resolver.py)
  printf "%s" "$json" > "$CACHE_FILE"
}

export_session_vars() {
  if [[ -f "$CACHE_FILE" ]]; then
    local py js fport bport scmd
    py=$(jq -r '.python_package_manager // empty' "$CACHE_FILE" 2>/dev/null || true)
    js=$(jq -r '.javascript_package_manager // empty' "$CACHE_FILE" 2>/dev/null || true)
    fport=$(jq -r '.frontend_port // empty' "$CACHE_FILE" 2>/dev/null || true)
    bport=$(jq -r '.backend_port // empty' "$CACHE_FILE" 2>/dev/null || true)
    scmd=$(jq -r '.startup_command // empty' "$CACHE_FILE" 2>/dev/null || true)
    [[ -n "$py" ]] && export AGENT_OS_PYPM="$py"
    [[ -n "$js" ]] && export AGENT_OS_JSPM="$js"
    [[ -n "$fport" ]] && export AGENT_OS_FRONTEND_PORT="$fport"
    [[ -n "$bport" ]] && export AGENT_OS_BACKEND_PORT="$bport"
    [[ -n "$scmd" ]] && export AGENT_OS_START_CMD="$scmd"
  fi
}

case "${1:-}" in
  refresh)
    refresh_cache
    ;;
  export)
    export_session_vars
    ;;
  refresh-and-export)
    refresh_cache
    export_session_vars
    ;;
  *)
    echo "Usage: $0 {refresh|export|refresh-and-export}"
    ;;
esac


