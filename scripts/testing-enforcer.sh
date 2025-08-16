#!/usr/bin/env bash
# Evidence/Testing Enforcement: blocks completion claims without proof
# Usage:
#   scripts/testing-enforcer.sh < input.txt
#   scripts/testing-enforcer.sh --file path/to/text

set -euo pipefail

INPUT=""
if [[ ${1:-} == "--file" && -n ${2:-} ]]; then
  INPUT=$(cat "$2" 2>/dev/null || true)
else
  # Read from stdin
  if [ -t 0 ]; then
    INPUT=""
  else
    INPUT=$(cat)
  fi
fi

# If there's no input, do nothing (allow pass)
if [[ -z "$INPUT" ]]; then
  echo "No input provided to testing-enforcer; skipping checks."
  exit 0
fi

# Normalize to lowercase for simple word checks alongside emoji checks
LOWER=$(printf "%s" "$INPUT" | tr '[:upper:]' '[:lower:]')

# Completion claim patterns (word-ish + emojis).
# We intentionally keep these conservative to reduce false positives.
completion_regex='(^|[[:space:][:punct:]])(complete|finished|done|ready)([[:punct:][:space:]]|$)|✓|✅'

# Evidence patterns: presence of explicit evidence sections or recognizable test output.
# - Headings: Evidence / Test Results / Verification
# - Test output markers: PASS, All tests passed, pytest, jest, npm test, bats
# - Functional proof hints: curl http, playwright, cypress
evidence_regex='(^|\n)\s{0,3}#{1,3}\s*(evidence|test results|verification)\b|```[a-zA-Z0-9_-]*[\s\S]*?(PASS|All tests passed|pytest|jest|npm test|bats)[\s\S]*?```|curl\s+https?://|playwright|cypress'

has_completion=0
has_evidence=0

if printf "%s" "$INPUT" | grep -Eiq "$completion_regex"; then
  has_completion=1
fi

if printf "%s" "$INPUT" | grep -Eiq "$evidence_regex"; then
  has_evidence=1
fi

if [[ $has_completion -eq 1 && $has_evidence -eq 0 ]]; then
  echo "❌ Completion claim(s) detected without evidence."
  echo "Add an Evidence/Test Results/Verification section with real outputs (tests, curl, screenshots)."
  exit 1
fi

echo "✅ Testing evidence requirements satisfied or no completion claims detected."
exit 0


