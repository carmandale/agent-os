#!/bin/bash
set -euo pipefail

# Flag large/binary/temp files in staged changes and suggest .gitignore updates.

echo "Checking staged files for large/binary/temp artifacts..."

files=$(git diff --cached --name-only)
fail=0
for f in $files; do
  # Skip deleted files
  [[ -e "$f" ]] || continue
  # Large file > 5MB
  if [[ $(stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null) -gt 5000000 ]]; then
    echo "❌ Large file staged: $f (>5MB)"
    fail=1
  fi
  # Common temp/binary patterns
  if echo "$f" | grep -qE '\.(zip|tar|gz|bz2|7z|png|jpg|jpeg|mp4|mov|pdf|exe|dll)$'; then
    echo "⚠️ Potential binary file staged: $f"
  fi
  if echo "$f" | grep -qE '~$|\.swp$|\.DS_Store$|^node_modules/|^dist/|^build/'; then
    echo "⚠️ Temp/build file staged: $f"
  fi
done

if [[ $fail -eq 1 ]]; then
  echo "\nPlease consider adding patterns to .gitignore and commit again."
  exit 1
fi

echo "Staged files check passed."

