#!/bin/bash

# install-hooks.sh
# Agent OS Claude Code hooks installation script
# Installs and configures Claude Code hooks for Agent OS workflow integration

set -e

# Configuration
HOOKS_DIR="$HOME/.agent-os/hooks"
CLAUDE_CODE_CONFIG_DIR="$HOME/.claude"
HOOKS_CONFIG_FILE="$CLAUDE_CODE_CONFIG_DIR/settings.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

log_error() {
    echo -e "${RED}❌ $*${NC}"
}

# Check if Claude Code is installed
check_claude_code() {
    if ! command -v claude &> /dev/null; then
        log_error "Claude Code is not installed or not in PATH"
        log_info "Please install Claude Code first: https://claude.ai/code"
        return 1
    fi
    
    log_success "Claude Code is installed"
    return 0
}

# Check if we're in an Agent OS project
check_agent_os_project() {
    if [ ! -d ".agent-os" ] && [ ! -f "CLAUDE.md" ]; then
        log_warning "This doesn't appear to be an Agent OS project"
        log_info "Hooks will be installed globally but may not function optimally"
        log_info "Consider running this from an Agent OS project directory"
        return 1
    fi
    
    log_success "Agent OS project detected"
    return 0
}

# Verify hook utilities exist
verify_utilities() {
    local missing_utils=()
    
    for util in workflow-detector.sh git-utils.sh context-builder.sh; do
        if [ ! -f "$HOOKS_DIR/lib/$util" ]; then
            missing_utils+=("$util")
        fi
    done
    
    if [ ${#missing_utils[@]} -gt 0 ]; then
        log_error "Missing required utilities: ${missing_utils[*]}"
        log_info "Please ensure Agent OS hooks are properly installed"
        return 1
    fi
    
    log_success "All hook utilities found"
    return 0
}

# Create Claude Code config directory
create_config_dir() {
    if [ ! -d "$CLAUDE_CODE_CONFIG_DIR" ]; then
        log_info "Creating Claude Code configuration directory"
        mkdir -p "$CLAUDE_CODE_CONFIG_DIR"
    fi
    
    log_success "Claude Code configuration directory ready"
}

# Backup existing hooks configuration
backup_existing_config() {
    if [ -f "$HOOKS_CONFIG_FILE" ]; then
        local backup_file="${HOOKS_CONFIG_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
        log_info "Backing up existing hooks configuration to: $backup_file"
        cp "$HOOKS_CONFIG_FILE" "$backup_file"
        log_success "Backup created"
    fi
}

# Generate Claude Code hooks configuration
generate_hooks_config() {
    log_info "Generating Claude Code hooks configuration"
    
    cat > "$HOOKS_CONFIG_FILE" << EOF
{
  "hooks": {
    "stop": {
      "enabled": true,
      "command": "$HOOKS_DIR/stop-hook.sh",
      "description": "Agent OS workflow abandonment prevention"
    },
    "postToolUse": {
      "enabled": true,
      "command": "$HOOKS_DIR/post-tool-use-hook.sh",
      "description": "Agent OS documentation auto-commit"
    },
    "userPromptSubmit": {
      "enabled": true,
      "command": "$HOOKS_DIR/user-prompt-submit-hook.sh",
      "description": "Agent OS context injection"
    }
  },
  "global": {
    "debug": false,
    "maxExecutionTime": 500,
    "errorHandling": "log"
  },
  "metadata": {
    "version": "1.0.0",
    "installedBy": "Agent OS",
    "installedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  }
}
EOF
    
    log_success "Claude Code hooks configuration generated"
}

# Test hook functionality
test_hooks() {
    log_info "Testing hook functionality"
    
    # Test utilities can be sourced
    if ! bash -c "source '$HOOKS_DIR/lib/workflow-detector.sh' && source '$HOOKS_DIR/lib/git-utils.sh' && source '$HOOKS_DIR/lib/context-builder.sh'"; then
        log_error "Hook utilities failed to load"
        return 1
    fi
    
    # Test hook scripts are executable
    for hook in stop-hook.sh post-tool-use-hook.sh user-prompt-submit-hook.sh; do
        if [ ! -x "$HOOKS_DIR/$hook" ]; then
            log_error "Hook script not executable: $hook"
            return 1
        fi
    done
    
    log_success "Hook functionality tests passed"
    return 0
}

# Display installation summary
show_summary() {
    log_success "Agent OS Claude Code hooks installation complete!"
    echo
    log_info "Installed hooks:"
    echo "  • stop: Prevents workflow abandonment"
    echo "  • postToolUse: Auto-commits Agent OS documentation"  
    echo "  • userPromptSubmit: Injects contextual information"
    echo
    log_info "Configuration file: $HOOKS_CONFIG_FILE"
    echo
    log_info "To verify installation:"
    echo "  claude --version"
    echo "  cat $HOOKS_CONFIG_FILE"
    echo
    log_info "To enable debug logging:"
    echo "  export AGENT_OS_DEBUG=true"
    echo
    log_warning "Note: You may need to restart Claude Code for hooks to take effect"
}

# Handle errors
error_handler() {
    local line_no=$1
    log_error "Installation failed at line $line_no"
    log_info "Check the error messages above for details"
    exit 1
}
trap 'error_handler $LINENO' ERR

# Main installation flow
main() {
    echo "🤖 Agent OS Claude Code Hooks Installation"
    echo "=========================================="
    echo
    
    # Pre-installation checks
    log_info "Performing pre-installation checks..."
    check_claude_code || exit 1
    check_agent_os_project  # Warning only, don't exit
    verify_utilities || exit 1
    echo
    
    # Installation steps
    log_info "Installing Claude Code hooks..."
    create_config_dir
    backup_existing_config
    generate_hooks_config
    echo
    
    # Post-installation verification
    log_info "Verifying installation..."
    test_hooks || exit 1
    echo
    
    # Summary
    show_summary
}

# Run main function
main "$@"