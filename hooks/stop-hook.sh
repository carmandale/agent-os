#!/bin/bash
# stop-hook.sh
# Agent OS - Claude Code Stop Hook
# Purpose: Prevent workflow abandonment when uncommitted source changes exist with no recent commits.

# Strict mode and safe IFS
set -Eeuo pipefail
IFS=$'\n\t'

# Constants and defaults
HOOKS_DIR="$(cd "$(dirname "$0")" && pwd -P)"
DEDUP_DIR="/tmp/agent-os-stop"
DEFAULT_TTL="${AGENT_OS_STOP_TTL:-300}"  # seconds for rate limiting
RECENT_WINDOW="${AGENT_OS_RECENT_WINDOW:-2 hours ago}"  # git log --since window
USE_JSON="${AGENT_OS_STOP_NO_JSON:-false}"  # if "true", use stderr + exit 2 fallback

# Optional libraries (only source if present to avoid errors in strict mode)
if [ -f "$HOOKS_DIR/lib/workflow-detector.sh" ]; then
  # shellcheck disable=SC1091
  source "$HOOKS_DIR/lib/workflow-detector.sh"
fi
if [ -f "$HOOKS_DIR/lib/git-utils.sh" ]; then
  # shellcheck disable=SC1091
  source "$HOOKS_DIR/lib/git-utils.sh"
fi
if [ -f "$HOOKS_DIR/lib/context-builder.sh" ]; then
  # shellcheck disable=SC1091
  source "$HOOKS_DIR/lib/context-builder.sh"
fi

# Logging
log_debug() {
  if [ "${AGENT_OS_DEBUG:-false}" = "true" ]; then
    echo "[STOP-HOOK DEBUG] $*" >&2
  fi
}

# Utilities
compute_sha256() {
  # Cross-platform SHA256: macOS (shasum), Linux (sha256sum). Fallback to md5/md5sum, then a crude hash.
  local s="$1"
  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$s" | shasum -a 256 | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$s" | sha256sum | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then
    printf '%s' "$s" | md5 | awk '{print $NF}'
  elif command -v md5sum >/dev/null 2>&1; then
    printf '%s' "$s" | md5sum | awk '{print $1}'
  else
    # Crude fallback: alnum-only and truncate
    printf '%s' "$s" | LC_ALL=C tr -cd '[:alnum:]' | cut -c1-64
  fi
}

file_mtime_epoch() {
  # Cross-platform stat mtime -> epoch seconds
  local f="$1"
  stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0
}

file_age_seconds() {
  local f="$1"
  local now
  now="$(date +%s)"
  local mtime
  mtime="$(file_mtime_epoch "$f")"
  if [ -z "$mtime" ] || ! [ "$mtime" -ge 0 ] 2>/dev/null; then
    echo 999999
    return 0
  fi
  echo $(( now - mtime ))
}

acquire_lock() {
  # Non-blocking lock. Prefer flock if available; otherwise use mkdir trick.
  # Returns 0 if acquired, 1 otherwise. Echoes a token used for cleanup in mkdir fallback.
  local lock_file="$1"
  if command -v flock >/dev/null 2>&1; then
    exec {__LOCK_FD__}> "$lock_file" || return 1
    if flock -n "$__LOCK_FD__"; then
      echo "fd:$__LOCK_FD__"
      return 0
    else
      return 1
    fi
  else
    local lock_dir="${lock_file}.d"
    if mkdir "$lock_dir" 2>/dev/null; then
      echo "dir:$lock_dir"
      return 0
    else
      return 1
    fi
  fi
}

release_lock() {
  local token="${1:-}"
  case "$token" in
    fd:*)
      # flock is released automatically on process exit; nothing else needed
      ;;
    dir:*)
      local dir="${token#dir:}"
      rmdir "$dir" 2>/dev/null || true
      ;;
    *)
      ;;
  esac
}

json_escape() {
  # Minimal JSON string escape (quotes and backslashes)
  # Avoids dependency on jq for emitting JSON
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

resolve_project_root() {
  # Resolve project root from payload (.hookMetadata.projectDir | .projectRoot | .cwd), env, or git toplevel.
  # If cannot resolve confidently, return empty to avoid false positives.
  local payload="$1"
  local pr=""

  if command -v jq >/dev/null 2>&1; then
    pr="$(printf '%s' "$payload" | jq -r '.hookMetadata.projectDir // .projectRoot // .cwd // empty' 2>/dev/null || true)"
  fi

  if [ -z "${pr:-}" ] && [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR:-}" ]; then
    pr="$CLAUDE_PROJECT_DIR"
  fi

  # Try git toplevel from current working dir (best effort; may be hooks dir, which we want to avoid using if .agent-os is missing)
  if [ -z "${pr:-}" ]; then
    if git rev-parse --git-dir >/dev/null 2>&1; then
      pr="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    fi
  fi

  # As a last resort, use PWD
  if [ -z "${pr:-}" ]; then
    pr="$PWD"
  fi

  # Normalize to absolute real path if possible
  if [ -d "$pr" ]; then
    (cd "$pr" 2>/dev/null && pwd -P) || echo "$pr"
  else
    echo ""
  fi
}

is_git_repo() {
  local dir="$1"
  git -C "$dir" rev-parse --git-dir >/dev/null 2>&1
}

list_uncommitted_files() {
  # Echo a list of uncommitted files (one per line) in the given git repo directory
  local dir="$1"
  local porcelain
  porcelain="$(git -C "$dir" status --porcelain 2>/dev/null || true)"
  if [ -z "$porcelain" ]; then
    echo ""
    return 0
  fi
  # Cut status flags, handle renames (R? "old -> new"): prefer the new path after ' -> '
  local files
  files="$(printf '%s\n' "$porcelain" | cut -c4- | sed -E 's/.* -> //')"
  printf '%s\n' "$files" | sed '/^$/d'
}

filter_noise_files() {
  # Filter out config, generated, build artifacts, and common noise
  # Reads file list on stdin, outputs filtered list on stdout
  grep -v -E '\.DS_Store$|\.env(\..*)?$|\.(local|temp|tmp)\..*$|\.xcodeproj/|\.xcworkspace/|xcuserdata/|\.swiftpm/|Package\.resolved$|package-lock\.json$|yarn\.lock$|Podfile\.lock$|\.gitignore$|\.pbxproj$|node_modules/|\.next/|dist/|build/|out/|\.(log|pid|seed|lock)$|\.vscode/|\.idea/|__pycache__/|\.pyc$|\.gradle/|target/' || true
}

filter_to_code_files() {
  # Keep only files that look like source code
  # Extendable; conservative selection to avoid false positives
  grep -E '\.(swift|js|jsx|ts|tsx|py|go|rs|java|kt|kts|php|rb|c|cpp|cc|cxx|h|hpp|cs|scala|sc|clj|cljs|edn|sh|bash|zsh|fish|lua|dart|m|mm|sql|pl|pm|r|jl)$' || true
}

recent_commit_count() {
  local dir="$1"
  git -C "$dir" log --oneline --since="$RECENT_WINDOW" 2>/dev/null | wc -l | tr -d '[:space:]'
}

generate_stop_message() {
  local project_root="$1"
  local num_changed="$2"
  local sample_list="$3"

  # Extract context using sourced helper functions
  # These functions are available from lib/git-utils.sh and lib/workflow-detector.sh
  local current_branch=""
  local issue_num=""
  local spec_folder=""

  # Extract current branch (supports feature branches, main, detached HEAD)
  if command -v get_current_branch >/dev/null 2>&1; then
    current_branch=$(cd "$project_root" && get_current_branch 2>/dev/null || echo "")
  fi

  # Extract issue number from branch name (supports patterns: #123, feature-#123-desc)
  if [ -n "$current_branch" ] && command -v extract_github_issue >/dev/null 2>&1; then
    issue_num=$(cd "$project_root" && extract_github_issue "branch" 2>/dev/null || echo "")
  fi

  # Detect active spec folder (most recent date-prefixed folder in .agent-os/specs/)
  if [ -d "$project_root/.agent-os/specs" ] && command -v detect_current_spec >/dev/null 2>&1; then
    spec_folder=$(cd "$project_root" && detect_current_spec 2>/dev/null || echo "")
  fi

  # Build context lines conditionally (only show what's available)
  local context_lines=""
  if [ -n "$current_branch" ]; then
    context_lines="${context_lines}Branch: $current_branch\n"
  fi
  if [ -n "$issue_num" ]; then
    context_lines="${context_lines}GitHub Issue: #$issue_num\n"
  fi
  if [ -n "$spec_folder" ]; then
    context_lines="${context_lines}Active Spec: $spec_folder\n"
  fi

  # Generate smart commit suggestion with issue number if available
  local commit_suggestion=""
  if [ -n "$issue_num" ]; then
    commit_suggestion="  git commit -m \"feat: describe changes #${issue_num}\""
  else
    commit_suggestion="  git commit -m \"describe your work\""
  fi

  cat <<EOF
Agent OS: Uncommitted source code detected

Project: $(basename "$project_root")
${context_lines}Detected $num_changed modified source file(s) with no recent commits (within ${RECENT_WINDOW}).

Suggested commit:
$commit_suggestion

Next steps:
  1. Review changes: git -C "$project_root" status
  2. Commit work with suggested format above
  3. Or stash:      git -C "$project_root" stash
  4. Suppress temporarily: export AGENT_OS_HOOKS_QUIET=true

Changed files (sample):
$sample_list
EOF
}

output_json_block() {
  local reason="$1"
  local project_root="$2"
  local session_id="${3:-}"

  # Escape fields for JSON
  local reason_json project_json session_json
  reason_json="$(printf '%s' "$reason" | json_escape)"
  project_json="$(printf '%s' "$project_root" | json_escape)"
  session_json="$(printf '%s' "$session_id" | json_escape)"

  cat <<EOF
{"decision":"block","reason":"$reason_json","continue":true,"hookSpecificOutput":{"stopHook":{"source":"agent-os","projectRoot":"$project_json","sessionId":"$session_json"}}}
EOF
}

should_block_interaction() {
  # Decide if we should block. Returns 0 to block, 1 to allow.
  # Sets global variables: BLOCK_REASON, BLOCK_FILES_SAMPLE, BLOCK_FILE_COUNT
  local project_root="$1"
  BLOCK_REASON=""
  BLOCK_FILES_SAMPLE=""
  BLOCK_FILE_COUNT=0

  # Gather uncommitted files
  local uncommitted
  uncommitted="$(list_uncommitted_files "$project_root")"
  if [ -z "$uncommitted" ]; then
    log_debug "No uncommitted changes in project: $project_root"
    return 1
  fi

  # Filter noise and keep only code files
  local filtered code_files
  filtered="$(printf '%s\n' "$uncommitted" | filter_noise_files || true)"
  if [ -z "$filtered" ]; then
    log_debug "Only noise/config files changed, allowing"
    return 1
  fi

  code_files="$(printf '%s\n' "$filtered" | filter_to_code_files || true)"
  if [ -z "$code_files" ]; then
    log_debug "No source code files changed after filtering, allowing"
    return 1
  fi

  # Recent commits heuristic
  local recent_count
  recent_count="$(recent_commit_count "$project_root")"
  if [ "${recent_count:-0}" -gt 0 ]; then
    log_debug "Recent commits found ($recent_count) in window '$RECENT_WINDOW' - allowing"
    return 1
  fi

  # Prepare reason and sample list (limit to 5 files)
  local sample_lines
  sample_lines="$(printf '%s\n' "$code_files" | head -n 5)"
  local sample_display
  sample_display="$(printf '%s\n' "$sample_lines" | sed 's/^/  - /')"

  BLOCK_FILE_COUNT="$(printf '%s\n' "$code_files" | wc -l | tr -d '[:space:]')"
  BLOCK_FILES_SAMPLE="$sample_display"
  BLOCK_REASON="Agent OS: Uncommitted source code detected in $(basename "$project_root") with no recent commits (window: $RECENT_WINDOW). $BLOCK_FILE_COUNT file(s) changed."

  log_debug "Blocking due to uncommitted source code: count=$BLOCK_FILE_COUNT"
  return 0
}

main() {
  log_debug "Stop hook triggered"

  # Read JSON payload from stdin (may be empty)
  local payload=""
  if [ ! -t 0 ]; then
    payload="$(cat || true)"
  fi

  # Loop guard from payload (if present)
  local stop_active="false"
  if command -v jq >/dev/null 2>&1 && [ -n "$payload" ]; then
    stop_active="$(printf '%s' "$payload" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
  fi
  if [ "$stop_active" = "true" ]; then
    log_debug "Stop hook already active per payload - exiting"
    exit 0
  fi

  # Allow users to suppress all hooks
  if [ "${AGENT_OS_HOOKS_QUIET:-false}" = "true" ]; then
    log_debug "Agent OS hooks suppressed via AGENT_OS_HOOKS_QUIET"
    exit 0
  fi

  # Resolve project root
  local project_root
  project_root="$(resolve_project_root "${payload:-}")"
  if [ -z "$project_root" ] || [ ! -d "$project_root" ]; then
    log_debug "Could not resolve a valid project root; exiting"
    exit 0
  fi
  log_debug "Resolved project root: $project_root"

  # Only run in Agent OS projects
  if [ ! -d "$project_root/.agent-os" ]; then
    log_debug "Not an Agent OS project at $project_root (.agent-os missing), exiting"
    exit 0
  fi

  # Only run inside a git repository
  if ! is_git_repo "$project_root"; then
    log_debug "Not a git repository at $project_root, exiting"
    exit 0
  fi

  # Session and dedup keys
  local session_id=""
  if command -v jq >/dev/null 2>&1 && [ -n "$payload" ]; then
    session_id="$(printf '%s' "$payload" | jq -r '.hookMetadata.sessionId // .sessionId // .threadId // empty' 2>/dev/null || echo "")"
  fi
  local project_key
  project_key="$(compute_sha256 "$project_root")"
  local session_key="${session_id:-global}"
  mkdir -p "$DEDUP_DIR" 2>/dev/null || true

  # Acquire non-blocking lock per project+session to avoid duplicate messages in concurrent calls
  local lock_file="$DEDUP_DIR/${project_key}-${session_key}.lock"
  local lock_token=""
  if lock_token="$(acquire_lock "$lock_file")"; then
    # Ensure cleanup for mkdir-based lock
    trap 'release_lock "'"$lock_token"'"' EXIT
    log_debug "Acquired lock for project_key=$project_key session_key=$session_key"
  else
    log_debug "Another stop-hook instance is active for this project+session; skipping duplicate"
    exit 0
  fi

  # Determine whether to block
  if should_block_interaction "$project_root"; then
    # Build reason and apply rate limiting (project + message key)
    local message_key_input="${project_root}|uncommitted_source_no_recent_commits"
    local message_key
    message_key="$(compute_sha256 "$message_key_input")"
    local rate_file="$DEDUP_DIR/${project_key}-${message_key}.rate"

    local age=999999
    if [ -f "$rate_file" ]; then
      age="$(file_age_seconds "$rate_file")"
    fi
    if [ "$age" -lt "$DEFAULT_TTL" ]; then
      log_debug "Rate limit active for this message (age=${age}s < ttl=${DEFAULT_TTL}s). Will still block but avoid noisy output."
      # Still block but keep the message concise
      local concise_reason="Agent OS: Uncommitted source code detected in $(basename "$project_root"). Please commit or stash."
      if [ "$USE_JSON" != "true" ]; then
        printf '%s\n' "$(generate_stop_message "$project_root" "$BLOCK_FILE_COUNT" "$BLOCK_FILES_SAMPLE")" >&2
        exit 2
      else
        output_json_block "$concise_reason" "$project_root" "$session_id"
        exit 0
      fi
    fi

    # Touch/update rate file
    : > "$rate_file" || true

    # Produce full message
    if [ "$USE_JSON" != "true" ]; then
      printf '%s\n' "$(generate_stop_message "$project_root" "$BLOCK_FILE_COUNT" "$BLOCK_FILES_SAMPLE")" >&2
      exit 2
    else
      # Compose a compact reason (details shown in UI may be limited)
      local reason="$BLOCK_REASON"
      output_json_block "$reason" "$project_root" "$session_id"
      exit 0
    fi
  else
    log_debug "Allowing interaction to proceed"
    exit 0
  fi
}

# Run main
main "$@"