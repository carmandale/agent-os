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
  maybe-refresh-and-export)
    # If cache missing or any source newer than cache, refresh
    # Helper to get mtime portable across macOS/Linux
    stat_mtime() {
      if stat -f %m "$1" >/dev/null 2>&1; then stat -f %m "$1"; else stat -c %Y "$1"; fi
    }
    latest_src=0
    for src in .env .env.local .agent-os/product/tech-stack.md start.sh; do
      if [[ -f "$src" ]]; then
        mt=$(stat_mtime "$src" || echo 0)
        [[ "$mt" -gt "$latest_src" ]] && latest_src="$mt"
      fi
    done
    cache_mtime=0
    if [[ -f "$CACHE_FILE" ]]; then
      cache_mtime=$(stat_mtime "$CACHE_FILE" || echo 0)
    fi
    if [[ ! -f "$CACHE_FILE" || "$latest_src" -gt "$cache_mtime" ]]; then
      refresh_cache
    fi
    export_session_vars
    ;;
  *)
    echo "Usage: $0 {refresh|export|refresh-and-export|maybe-refresh-and-export}"
    ;;
esac


