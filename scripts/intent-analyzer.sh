#!/usr/bin/env bash
# Classify user intent: MAINTENANCE | NEW | AMBIGUOUS
# Usage:
#   scripts/intent-analyzer.sh --text "fix failing tests"
#   scripts/intent-analyzer.sh --file msg.txt
#   echo "implement new feature" | scripts/intent-analyzer.sh

set -euo pipefail

TEXT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --text)
      TEXT="${2:-}"; shift 2 ;;
    --file)
      TEXT="$(cat "${2:-}" 2>/dev/null || true)"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$TEXT" && ! -t 0 ]]; then
  TEXT="$(cat)"
fi

lower() { printf "%s" "$1" | tr '[:upper:]' '[:lower:]'; }

L=$(lower "$TEXT")

# Maintenance patterns
MAINT_PAT='\bfix\b.*\btests?\b|\baddress\b.*\bci\b|\bdebug\b|\bresolve\b.*\bconflict|\bfix\b.*\bbug|\bupdate\b.*\bdependenc'
# New work patterns
NEW_PAT='\bimplement\b.*\bfeature\b|\bbuild\b.*\bnew\b|\bcreate\b.*\b(feature|component|system)\b|\badd\b.*\b(feature|functionality)\b'

is_maint=0
is_new=0
if grep -Eiq "$MAINT_PAT" <<< "$L"; then is_maint=1; fi
if grep -Eiq "$NEW_PAT" <<< "$L"; then is_new=1; fi

if [[ $is_maint -eq 1 && $is_new -eq 0 ]]; then
  echo "MAINTENANCE"; exit 0
elif [[ $is_new -eq 1 && $is_maint -eq 0 ]]; then
  echo "NEW"; exit 0
else
  echo "AMBIGUOUS"; exit 0
fi


