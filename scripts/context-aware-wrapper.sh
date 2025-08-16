#!/usr/bin/env bash
# Decide whether to allow operation based on intent and workspace state
# Usage: context-aware-wrapper.sh --intent-text "..." --action-type read|write

set -euo pipefail

INTENT_TEXT=""
ACTION_TYPE="read"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --intent-text)
      INTENT_TEXT="${2:-}"; shift 2 ;;
    --action-type)
      ACTION_TYPE="${2:-read}"; shift 2 ;;
    *) shift ;;
  esac
done

# Defaults
ACTION_TYPE=${ACTION_TYPE:-read}

# Helper: workspace dirty?
is_dirty() {
  [[ -n "$(git status --porcelain 2>/dev/null || true)" ]]
}

# Helper: open PRs?
has_open_prs() {
  if command -v gh >/dev/null 2>&1; then
    local count
    count=$(gh pr list --json number 2>/dev/null | jq 'length' 2>/dev/null || echo 0)
    [[ ${count:-0} -gt 0 ]]
  else
    return 1
  fi
}

INTENT=$(bash scripts/intent-analyzer.sh --text "$INTENT_TEXT" || echo "AMBIGUOUS")

# Environment override to force new work
if [[ "${AGENT_OS_NEW_WORK:-}" == "1" ]]; then
  INTENT="NEW"
fi

case "$INTENT" in
  MAINTENANCE)
    # Always allow maintenance regardless of workspace state
    echo "ALLOW"; exit 0 ;;
  NEW)
    # For new work, require clean workspace
    if is_dirty || has_open_prs; then
      echo "BLOCK: New work requires clean workspace (commit/merge/close outstanding work)."; exit 1
    else
      echo "ALLOW"; exit 0
    fi ;;
  AMBIGUOUS|*)
    # Allow read-only, block writes unless overridden
    if [[ "$ACTION_TYPE" == "read" ]]; then
      echo "ALLOW"; exit 0
    else
      echo "BLOCK: Ambiguous intent; write operations blocked. Set AGENT_OS_NEW_WORK=1 to proceed as NEW or rephrase."; exit 1
    fi ;;
esac


