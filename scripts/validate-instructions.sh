#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CODE=0

# Simple XML-ish tag checks and required subagent attrs
required_tag_files=(
  "$ROOT_DIR/instructions/core/execute-task.md"
  "$ROOT_DIR/instructions/core/execute-tasks.md"
  "$ROOT_DIR/instructions/core/plan-product.md"
  "$ROOT_DIR/instructions/core/create-spec.md"
  "$ROOT_DIR/instructions/core/analyze-product.md"
)

missing=()
for f in "${required_tag_files[@]}"; do
  [[ -f "$f" ]] || missing+=("$f")
  if [[ -f "$f" ]]; then
    if ! grep -q "<pre_flight_check>" "$f"; then
      echo "❌ Missing <pre_flight_check> in $f"; CODE=1
    fi
    if echo "$f" | grep -q "execute-task.md"; then
      if ! grep -q "subagent=\"context-fetcher\"" "$f"; then
        echo "❌ execute-task: missing context-fetcher step in $f"; CODE=1
      fi
      if ! grep -q "subagent=\"test-runner\"" "$f"; then
        echo "❌ execute-task: missing test-runner step in $f"; CODE=1
      fi
    fi
  fi
done

if ((${#missing[@]})); then
  echo "❌ Missing files:"; printf ' - %s\n' "${missing[@]}"; CODE=1
fi

# Ensure core references (no top-level instruction paths remain)
if rg -n "@~/.agent-os/instructions/(plan-product|create-spec|analyze-product|execute-tasks)\.md(?!.*core)" "$ROOT_DIR" -U >/dev/null 2>&1; then
  echo "❌ Found top-level instruction references; expected core/*"; CODE=1
fi

# Ensure pre-flight is referenced
if ! rg -n "@~/.agent-os/instructions/meta/pre-flight.md" "$ROOT_DIR/instructions/core" >/dev/null 2>&1; then
  echo "❌ core/* does not reference meta/pre-flight.md"; CODE=1
fi

if [[ $CODE -eq 0 ]]; then
  echo "✅ Instruction schema checks passed"
fi
exit $CODE
