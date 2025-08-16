#!/usr/bin/env bash
# Cached workspace state with TTL and graceful gh handling
# Outputs JSON: {"dirty":true|false,"open_prs":N}

set -euo pipefail

CACHE_DIR="${HOME}/.agent-os/cache"
CACHE_FILE="${CACHE_DIR}/workspace-state.json"
TTL="${AGENT_OS_STATE_TTL:-5}"
SKIP_GH="${AGENT_OS_SKIP_GH:-}"

mkdir -p "$CACHE_DIR"

stat_mtime() {
  if stat -f %m "$1" >/dev/null 2>&1; then stat -f %m "$1"; else stat -c %Y "$1"; fi
}

now_ts() { date +%s; }

is_fresh() {
  [[ -f "$CACHE_FILE" ]] || return 1
  local ct ts
  ct=$(stat_mtime "$CACHE_FILE" 2>/dev/null || echo 0)
  ts=$(now_ts)
  local age=$(( ts - ct ))
  [[ "$age" -lt "$TTL" ]]
}

compute_dirty() {
  [[ -n "$(git status --porcelain 2>/dev/null || true)" ]] && echo true || echo false
}

compute_open_prs() {
  # If skip or gh missing, report 0
  if [[ -n "$SKIP_GH" ]] || ! command -v gh >/dev/null 2>&1; then
    echo 0; return
  fi
  local out
  # Try with a short timeout if available; otherwise direct
  if command -v timeout >/dev/null 2>&1; then
    out=$(timeout 0.8s gh pr list --json number 2>/dev/null || echo "[]")
  else
    out=$(gh pr list --json number 2>/dev/null || echo "[]")
  fi
  # Count occurrences of "number":
  { printf "%s" "$out" | grep -o '"number"' 2>/dev/null || true; } | wc -l | tr -d ' '
}

emit_json() {
  local dirty="$1" prs="$2"
  printf '{"dirty":%s,"open_prs":%s}\n' "$dirty" "$prs"
}

if is_fresh; then
  cat "$CACHE_FILE"
  exit 0
fi

dirty=$(compute_dirty)
prs=$(compute_open_prs)

emit_json "$dirty" "$prs" | tee "$CACHE_FILE" >/dev/null
emit_json "$dirty" "$prs"

