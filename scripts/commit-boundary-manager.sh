#!/bin/bash

# Commit Boundary Manager for Transparent Work Sessions
# Automatically creates logical commits at natural workflow boundaries

set -e

# Configuration
WORK_SESSION_FILE="$HOME/.agent-os/cache/work-session"
DEBUG=${AGENT_OS_DEBUG:-false}

# Logging
log_debug() {
    if [ "$DEBUG" = "true" ]; then
        echo "[BOUNDARY DEBUG] $*" >&2
    fi
}

# Check if work session is active
is_work_session_active() {
    # Check environment variable
    if [ "${AGENT_OS_WORK_SESSION:-false}" = "true" ]; then
        return 0
    fi
    
    # Check session file
    if [ -f "$WORK_SESSION_FILE" ]; then
        return 0
    fi
    
    return 1
}

# Detect if this is a commit boundary
detect_boundary() {
    local context="$1"
    local custom_message="$2"
    
    case "$context" in
        "discovery_complete"|"phase_0_complete")
            echo "phase_0"
            return 0
            ;;
        "setup_complete"|"phase_1_complete"|"hygiene_complete")
            echo "phase_1"
            return 0
            ;;
        "reality_check_complete"|"phase_15_complete")
            echo "phase_15"
            return 0
            ;;
        "subtask_complete")
            echo "subtask"
            return 0
            ;;
        "task_complete"|"implementation_complete"|"phase_2_complete")
            echo "phase_2"
            return 0
            ;;
        "quality_complete"|"tests_pass"|"phase_3_complete")
            echo "phase_3"
            return 0
            ;;
        "git_integration_complete"|"phase_4_complete")
            echo "phase_4"
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Generate commit message for boundary
generate_commit_message() {
    local boundary_type="$1"
    local custom_context="$2"
    local session_description=""
    
    # Extract session description if available
    if [ -f "$WORK_SESSION_FILE" ]; then
        session_description=$(grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' "$WORK_SESSION_FILE" 2>/dev/null | sed 's/.*"description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || echo "")
    fi
    
    case "$boundary_type" in
        "phase_0")
            echo "feat: complete repository discovery and analysis

Phase 0 - Repository Discovery Complete
$custom_context

🔍 Transparent work session: ${session_description:-Auto-batched execution}"
            ;;
        "phase_1")
            echo "setup: complete workspace hygiene and project setup

Phase 1 - Hygiene and Setup Complete
$custom_context

🧹 Transparent work session: ${session_description:-Auto-batched execution}"
            ;;
        "phase_15")
            echo "verify: complete deep reality check and validation

Phase 1.5 - Deep Reality Check Complete
$custom_context

✅ Transparent work session: ${session_description:-Auto-batched execution}"
            ;;
        "subtask")
            echo "implement: complete subtask implementation

Subtask Implementation Complete
$custom_context

⚡ Transparent work session: ${session_description:-Auto-batched execution}"
            ;;
        "phase_2")
            echo "feat: complete task implementation and development

Phase 2 - Task Implementation Complete  
$custom_context

🚀 Transparent work session: ${session_description:-Auto-batched execution}"
            ;;
        "phase_3")
            echo "test: complete quality assurance and verification

Phase 3 - Quality Assurance Complete
$custom_context

🧪 Transparent work session: ${session_description:-Auto-batched execution}"
            ;;
        "phase_4")
            echo "docs: complete git integration and finalization

Phase 4 - Git Integration Complete
$custom_context

📦 Transparent work session: ${session_description:-Auto-batched execution}"
            ;;
        *)
            echo "update: transparent work session commit

$custom_context

🔄 Transparent work session: ${session_description:-Auto-batched execution}"
            ;;
    esac
}

# Create automatic commit at boundary
create_boundary_commit() {
    local context="$1"
    local custom_message="$2"
    
    log_debug "Checking boundary for context: $context"
    
    # Only create commits during work sessions
    if ! is_work_session_active; then
        log_debug "No work session active, skipping boundary commit"
        return 0
    fi
    
    # Check if there are changes to commit
    if [ -z "$(git status --porcelain)" ]; then
        log_debug "No changes to commit"
        return 0
    fi
    
    # Detect boundary type
    local boundary_type
    if boundary_type=$(detect_boundary "$context" "$custom_message"); then
        log_debug "Detected boundary: $boundary_type"
        
        # Generate commit message
        local commit_message=$(generate_commit_message "$boundary_type" "$custom_message")
        
        # Stage changes and create commit with error handling
        if git add . && git commit -m "$commit_message"; then
            echo "✅ Automatic commit created at $boundary_type boundary"
            return 0
        else
            log_debug "Git commit failed for boundary: $boundary_type"
            echo "❌ Failed to create automatic commit at $boundary_type boundary" >&2
            return 1
        fi
    else
        log_debug "No boundary detected for context: $context"
        return 1
    fi
}

# Main execution
main() {
    local command="${1:-detect}"
    local context="${2:-}"
    local message="${3:-}"
    
    case "$command" in
        "detect")
            if boundary_type=$(detect_boundary "$context" "$message"); then
                echo "BOUNDARY: $boundary_type"
                exit 0
            else
                echo "NO_BOUNDARY"
                exit 1
            fi
            ;;
        "commit")
            create_boundary_commit "$context" "$message"
            ;;
        "generate-message")
            if boundary_type=$(detect_boundary "$context" "$message"); then
                generate_commit_message "$boundary_type" "$message"
            else
                echo "Error: No boundary detected for context '$context'" >&2
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 {detect|commit|generate-message} <context> [message]"
            echo ""
            echo "Commands:"
            echo "  detect          - Check if context represents a commit boundary"
            echo "  commit          - Create commit if at boundary (work session only)"
            echo "  generate-message - Generate commit message for boundary type"
            echo ""
            echo "Boundary contexts:"
            echo "  discovery_complete, phase_0_complete"
            echo "  setup_complete, phase_1_complete, hygiene_complete"
            echo "  reality_check_complete, phase_15_complete"
            echo "  subtask_complete"
            echo "  task_complete, implementation_complete, phase_2_complete"
            echo "  quality_complete, tests_pass, phase_3_complete"
            echo "  git_integration_complete, phase_4_complete"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"