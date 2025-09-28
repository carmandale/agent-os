#!/bin/bash

# Agent OS Setup Script
# This script installs Agent OS files to your system

set -euo pipefail
trap 'echo "❌ Agent OS setup failed at line $LINENO." >&2' ERR

# Base URL for raw GitHub content
# Updated to use carmandale/agent-os fork with custom GitHub Issues workflow,
# tabs indentation, and Python/React tech stack preferences
BASE_URL="https://raw.githubusercontent.com/carmandale/agent-os/main"

require_cmd() {
	local cmd="$1"
	local hint="$2"
	if ! command -v "$cmd" >/dev/null 2>&1; then
	echo "❌ Required command '$cmd' not found. $hint" >&2
	exit 1
	fi
}

safe_curl() {
	local dest="$1"
	local url="$2"
	if ! curl -fSL --retry 3 --retry-delay 1 -o "$dest" "$url"; then
	echo "❌ Failed to download $url" >&2
	exit 1
	fi
}

# Initialize flags - always update instructions to get latest versions
OVERWRITE_INSTRUCTIONS=true
OVERWRITE_STANDARDS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --overwrite-instructions)
            OVERWRITE_INSTRUCTIONS=true
            shift
            ;;
        --overwrite-standards)
            OVERWRITE_STANDARDS=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --overwrite-instructions    Overwrite existing instruction files"
            echo "  --overwrite-standards       Overwrite existing standards files"
            echo "  -h, --help                  Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

require_cmd curl "Install curl to download Agent OS components."
require_cmd chmod "System chmod utility is required."

echo "🚀 Agent OS Setup Script"
echo "========================"
echo ""

# Version tracking - get version from VERSION file or fallback to repo
if [ -f "VERSION" ]; then
    AGENT_OS_VERSION=$(cat VERSION)
else
	if ! AGENT_OS_VERSION=$(curl -fSL --retry 3 --retry-delay 1 "${BASE_URL}/VERSION" 2>/dev/null | head -n1); then
		AGENT_OS_VERSION="4.0.2"
	fi
    if [ -z "$AGENT_OS_VERSION" ]; then
		AGENT_OS_VERSION="4.0.2"
    fi
fi

# Create directories
echo "📁 Creating directories..."
mkdir -p "$HOME/.agent-os/standards"
mkdir -p "$HOME/.agent-os/instructions"
mkdir -p "$HOME/.agent-os/instructions/core"
mkdir -p "$HOME/.agent-os/instructions/meta"
mkdir -p "$HOME/.agent-os/scripts"
mkdir -p "$HOME/.agent-os/workflow-modules"
mkdir -p "$HOME/.agent-os/hooks"

# Download standards files
echo ""
echo "📥 Downloading standards files to ~/.agent-os/standards/"

# tech-stack.md
if [ -f "$HOME/.agent-os/standards/tech-stack.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.agent-os/standards/tech-stack.md already exists - skipping"
else
	safe_curl "$HOME/.agent-os/standards/tech-stack.md" "${BASE_URL}/standards/tech-stack.md"
    if [ -f "$HOME/.agent-os/standards/tech-stack.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.agent-os/standards/tech-stack.md (overwritten)"
    else
        echo "  ✓ ~/.agent-os/standards/tech-stack.md"
    fi
fi

# code-style.md
if [ -f "$HOME/.agent-os/standards/code-style.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.agent-os/standards/code-style.md already exists - skipping"
else
	safe_curl "$HOME/.agent-os/standards/code-style.md" "${BASE_URL}/standards/code-style.md"
    if [ -f "$HOME/.agent-os/standards/code-style.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.agent-os/standards/code-style.md (overwritten)"
    else
        echo "  ✓ ~/.agent-os/standards/code-style.md"
    fi
fi

# best-practices.md
if [ -f "$HOME/.agent-os/standards/best-practices.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.agent-os/standards/best-practices.md already exists - skipping"
else
	safe_curl "$HOME/.agent-os/standards/best-practices.md" "${BASE_URL}/standards/best-practices.md"
    if [ -f "$HOME/.agent-os/standards/best-practices.md" ] && [ "$OVERWRITE_STANDARDS" = true ]; then
        echo "  ✓ ~/.agent-os/standards/best-practices.md (overwritten)"
    else
        echo "  ✓ ~/.agent-os/standards/best-practices.md"
    fi
fi

# Download instruction files
echo ""
echo "📥 Downloading instruction files to ~/.agent-os/instructions/"

# core mirrors
for core_file in analyze-product.md create-spec.md execute-tasks.md plan-product.md; do
  src_path="${BASE_URL}/instructions/core/${core_file}"
  dest_path="$HOME/.agent-os/instructions/core/${core_file}"
  if [ -f "$dest_path" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "  ⚠️  $dest_path already exists - skipping"
  else
	safe_curl "$dest_path" "$src_path"
    if [ -f "$dest_path" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
      echo "  ✓ $dest_path (overwritten)"
    else
      echo "  ✓ $dest_path"
    fi
  fi
done

# core/execute-task.md (single-task executor)
if [ -f "$HOME/.agent-os/instructions/core/execute-task.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "  ⚠️  ~/.agent-os/instructions/core/execute-task.md already exists - skipping"
else
	safe_curl "$HOME/.agent-os/instructions/core/execute-task.md" "${BASE_URL}/instructions/core/execute-task.md"
    if [ -f "$HOME/.agent-os/instructions/core/execute-task.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "  ✓ ~/.agent-os/instructions/core/execute-task.md (overwritten)"
    else
        echo "  ✓ ~/.agent-os/instructions/core/execute-task.md"
    fi
fi

# meta/pre-flight.md (shared pre-flight rules)
if [ -f "$HOME/.agent-os/instructions/meta/pre-flight.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
    echo "  ⚠️  ~/.agent-os/instructions/meta/pre-flight.md already exists - skipping"
else
	safe_curl "$HOME/.agent-os/instructions/meta/pre-flight.md" "${BASE_URL}/instructions/meta/pre-flight.md"
    if [ -f "$HOME/.agent-os/instructions/meta/pre-flight.md" ] && [ "$OVERWRITE_INSTRUCTIONS" = true ]; then
        echo "  ✓ ~/.agent-os/instructions/meta/pre-flight.md (overwritten)"
    else
        echo "  ✓ ~/.agent-os/instructions/meta/pre-flight.md"
    fi
fi

## Note: Top-level instruction files are deprecated. Only core/* is installed.

# Download script files
echo ""
echo "📥 Downloading script files to ~/.agent-os/scripts/"

safe_curl "$HOME/.agent-os/scripts/workspace-hygiene-check.sh" "${BASE_URL}/scripts/workspace-hygiene-check.sh"
chmod +x "$HOME/.agent-os/scripts/workspace-hygiene-check.sh"
echo "  ✓ ~/.agent-os/scripts/workspace-hygiene-check.sh"

safe_curl "$HOME/.agent-os/scripts/project-context-loader.sh" "${BASE_URL}/scripts/project-context-loader.sh"
chmod +x "$HOME/.agent-os/scripts/project-context-loader.sh"
echo "  ✓ ~/.agent-os/scripts/project-context-loader.sh"

safe_curl "$HOME/.agent-os/scripts/task-validator.sh" "${BASE_URL}/scripts/task-validator.sh"
chmod +x "$HOME/.agent-os/scripts/task-validator.sh"
echo "  ✓ ~/.agent-os/scripts/task-validator.sh"

safe_curl "$HOME/.agent-os/scripts/update-documentation.sh" "${BASE_URL}/scripts/update-documentation.sh"
chmod +x "$HOME/.agent-os/scripts/update-documentation.sh"
echo "  ✓ ~/.agent-os/scripts/update-documentation.sh"

safe_curl "$HOME/.agent-os/scripts/update-documentation-wrapper.sh" "${BASE_URL}/scripts/update-documentation-wrapper.sh"
chmod +x "$HOME/.agent-os/scripts/update-documentation-wrapper.sh"
echo "  ✓ ~/.agent-os/scripts/update-documentation-wrapper.sh"

# Create lib directory and download library files
mkdir -p "$HOME/.agent-os/scripts/lib"

safe_curl "$HOME/.agent-os/scripts/lib/update-documentation-lib.sh" "${BASE_URL}/scripts/lib/update-documentation-lib.sh"
chmod +x "$HOME/.agent-os/scripts/lib/update-documentation-lib.sh"
echo "  ✓ ~/.agent-os/scripts/lib/update-documentation-lib.sh"

safe_curl "$HOME/.agent-os/scripts/lib/spec-creator.sh" "${BASE_URL}/scripts/lib/spec-creator.sh"
chmod +x "$HOME/.agent-os/scripts/lib/spec-creator.sh"
echo "  ✓ ~/.agent-os/scripts/lib/spec-creator.sh"

safe_curl "$HOME/.agent-os/scripts/lib/roadmap-sync.sh" "${BASE_URL}/scripts/lib/roadmap-sync.sh"
chmod +x "$HOME/.agent-os/scripts/lib/roadmap-sync.sh"
echo "  ✓ ~/.agent-os/scripts/lib/roadmap-sync.sh"

safe_curl "$HOME/.agent-os/scripts/config-resolver.py" "${BASE_URL}/scripts/config-resolver.py"
echo "  ✓ ~/.agent-os/scripts/config-resolver.py"

safe_curl "$HOME/.agent-os/scripts/session-memory.sh" "${BASE_URL}/scripts/session-memory.sh"
chmod +x "$HOME/.agent-os/scripts/session-memory.sh"
echo "  ✓ ~/.agent-os/scripts/session-memory.sh"

safe_curl "$HOME/.agent-os/scripts/config-validator.sh" "${BASE_URL}/scripts/config-validator.sh"
chmod +x "$HOME/.agent-os/scripts/config-validator.sh"
echo "  ✓ ~/.agent-os/scripts/config-validator.sh"

safe_curl "$HOME/.agent-os/scripts/pre-command-guard.sh" "${BASE_URL}/scripts/pre-command-guard.sh"
chmod +x "$HOME/.agent-os/scripts/pre-command-guard.sh"
echo "  ✓ ~/.agent-os/scripts/pre-command-guard.sh"

safe_curl "$HOME/.agent-os/scripts/intent-analyzer.sh" "${BASE_URL}/scripts/intent-analyzer.sh"
chmod +x "$HOME/.agent-os/scripts/intent-analyzer.sh"
echo "  ✓ ~/.agent-os/scripts/intent-analyzer.sh"

safe_curl "$HOME/.agent-os/scripts/workspace-state.sh" "${BASE_URL}/scripts/workspace-state.sh"
chmod +x "$HOME/.agent-os/scripts/workspace-state.sh"
echo "  ✓ ~/.agent-os/scripts/workspace-state.sh"

safe_curl "$HOME/.agent-os/scripts/context-aware-wrapper.sh" "${BASE_URL}/scripts/context-aware-wrapper.sh"
chmod +x "$HOME/.agent-os/scripts/context-aware-wrapper.sh"
echo "  ✓ ~/.agent-os/scripts/context-aware-wrapper.sh"

safe_curl "$HOME/.agent-os/scripts/testing-enforcer.sh" "${BASE_URL}/scripts/testing-enforcer.sh"
chmod +x "$HOME/.agent-os/scripts/testing-enforcer.sh"
echo "  ✓ ~/.agent-os/scripts/testing-enforcer.sh"

# Transparent work sessions scripts
for script in workflow-validator.sh work-session-manager.sh commit-boundary-manager.sh session-auto-start.sh; do
	safe_curl "$HOME/.agent-os/scripts/$script" "${BASE_URL}/scripts/$script"
    chmod +x "$HOME/.agent-os/scripts/$script"
    echo "  ✓ ~/.agent-os/scripts/$script"
done

# Additional utility scripts
for script in check-updates.sh validate-instructions.sh; do
	safe_curl "$HOME/.agent-os/scripts/$script" "${BASE_URL}/scripts/$script"
    chmod +x "$HOME/.agent-os/scripts/$script"
    echo "  ✓ ~/.agent-os/scripts/$script"
done

# Python scripts
safe_curl "$HOME/.agent-os/scripts/project_root_resolver.py" "${BASE_URL}/scripts/project_root_resolver.py"
echo "  ✓ ~/.agent-os/scripts/project_root_resolver.py"

# Download workflow modules
echo ""
echo "📥 Downloading workflow modules to ~/.agent-os/workflow-modules/"

# step-1-hygiene-and-setup.md
safe_curl "$HOME/.agent-os/workflow-modules/step-1-hygiene-and-setup.md" "${BASE_URL}/workflow-modules/step-1-hygiene-and-setup.md"
echo "  ✓ ~/.agent-os/workflow-modules/step-1-hygiene-and-setup.md"

# step-2-planning-and-execution.md
safe_curl "$HOME/.agent-os/workflow-modules/step-2-planning-and-execution.md" "${BASE_URL}/workflow-modules/step-2-planning-and-execution.md"
echo "  ✓ ~/.agent-os/workflow-modules/step-2-planning-and-execution.md"

# step-3-quality-assurance.md
safe_curl "$HOME/.agent-os/workflow-modules/step-3-quality-assurance.md" "${BASE_URL}/workflow-modules/step-3-quality-assurance.md"
echo "  ✓ ~/.agent-os/workflow-modules/step-3-quality-assurance.md"

# step-4-git-integration.md
safe_curl "$HOME/.agent-os/workflow-modules/step-4-git-integration.md" "${BASE_URL}/workflow-modules/step-4-git-integration.md"
echo "  ✓ ~/.agent-os/workflow-modules/step-4-git-integration.md"

# Note: Subagents are now installed as Claude Code agents via setup-claude-code.sh
# The Python subagent system has been deprecated in favor of native Claude Code agents

# Download background task tools
echo ""
echo "📥 Downloading background task tools to ~/.agent-os/tools/"
mkdir -p "$HOME/.agent-os/tools"

# aos unified CLI
safe_curl "$HOME/.agent-os/tools/aos" "${BASE_URL}/tools/aos"
chmod +x "$HOME/.agent-os/tools/aos" 2>/dev/null || true
echo "  ✓ ~/.agent-os/tools/aos"

# install-aos-alias.sh helper
safe_curl "$HOME/.agent-os/tools/install-aos-alias.sh" "${BASE_URL}/tools/install-aos-alias.sh"
chmod +x "$HOME/.agent-os/tools/install-aos-alias.sh" 2>/dev/null || true
echo "  ✓ ~/.agent-os/tools/install-aos-alias.sh"

echo ""
echo "🔧 Configuring quick-init alias..."
if "$HOME/.agent-os/tools/install-aos-alias.sh" --non-interactive >/dev/null 2>&1; then
	echo "  ✓ Alias configured via install-aos-alias.sh"
else
	echo "  ⚠️  Alias installer encountered issues; run tools/install-aos-alias.sh --non-interactive manually." >&2
fi

# Track version (use uppercase VERSION for consistency)
echo "$AGENT_OS_VERSION" > "$HOME/.agent-os/VERSION"
echo "  ✓ Version $AGENT_OS_VERSION tracked"

# Remove deprecated lowercase version file if present
rm -f "$HOME/.agent-os/.version" 2>/dev/null || true

# Context validation hook - validate installation integrity
echo ""
echo "🔍 Validating installation context..."
if [ -f "tools/context-validator.sh" ]; then
	# Run context validation if we're in the source repository
	if ./tools/context-validator.sh --install-only >/dev/null 2>&1; then
		echo "  ✅ Context validation passed"
	else
		echo "  ⚠️  Context validation warnings detected"
		echo "     Run './tools/context-validator.sh' for details"
	fi
else
	# Basic validation if context-validator not available
	if [ -d "$HOME/.agent-os/instructions/core" ] && [ -f "$HOME/.agent-os/VERSION" ]; then
		echo "  ✅ Basic installation structure validated"
	else
		echo "  ⚠️  Installation may be incomplete"
	fi
fi

echo ""
echo "✅ Agent OS base installation complete!"
echo ""
echo "📍 Files installed to:"
echo "   ~/.agent-os/standards/        - Your development standards"
echo "   ~/.agent-os/instructions/     - Agent OS instructions"
echo "   ~/.agent-os/scripts/          - Dynamic workflow scripts"
echo "   ~/.agent-os/workflow-modules/ - Modular workflow components"
echo "   ~/.agent-os/tools/            - Agent OS CLI tools (aos)"
echo "   ~/.agent-os/VERSION           - Version $AGENT_OS_VERSION"
echo ""
echo "💡 Note: Instructions are always updated to latest versions"
echo "   Standards files preserve your customizations unless --overwrite-standards is used"
if [ "$OVERWRITE_STANDARDS" = true ]; then
    echo "   Standards files were overwritten with latest versions"
fi
# Check for existing Claude Code commands and offer update
if [ -d "$HOME/.claude/commands" ] && [ "$(ls -A $HOME/.claude/commands 2>/dev/null)" ]; then
	echo ""
	echo "🔄 Claude Code commands detected. Would you like to update them to match the latest Agent OS? (y/n)"

	# Skip prompt if running non-interactively (piped input)
	if [ ! -t 0 ]; then
		echo "Running in non-interactive mode - updating Claude Code commands automatically..."
		response="y"
	else
		read -r -p "Update Claude commands? " response
	fi

	echo ""
	if [[ $response =~ ^[Yy]$ ]]; then
		echo "📦 Updating Claude Code commands..."
		curl -sSL "${BASE_URL}/setup-claude-code.sh" | bash -s -- --overwrite-commands
		if [ $? -eq 0 ]; then
			echo "✅ Claude Code commands updated successfully!"
		else
			echo "⚠️  Command update had issues, but Agent OS base installation is complete"
		fi
	else
		echo "ℹ️  Claude Code commands not updated. You can update them later with:"
		echo "   curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup-claude-code.sh | bash -s -- --overwrite-commands"
	fi
fi

echo ""
echo "Next steps:"
echo ""
echo "1. Customize your coding standards in ~/.agent-os/standards/"
echo ""
echo "2. Install commands for your AI coding assistant(s):"
echo ""
if [ ! -d "$HOME/.claude/commands" ] || [ -z "$(ls -A $HOME/.claude/commands 2>/dev/null)" ]; then
	echo "   - Using Claude Code? Install the Claude Code commands with:"
	echo "     curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup-claude-code.sh | bash"
else
	echo "   - Claude Code commands are installed. To update them:"
	echo "     curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup-claude-code.sh | bash -s -- --overwrite-commands"
fi
echo ""
echo "   - Using Cursor? Install the Cursor commands with:"
echo "     curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup-cursor.sh | bash"
echo ""
echo "   - Using something else? See instructions at https://github.com/carmandale/agent-os"
echo ""
echo "💡 Pro tip: Install the 'aos' quick init alias for easier Agent OS management:"
echo "   curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/tools/install-aos-alias.sh | bash"
echo ""
echo "Learn more at https://github.com/carmandale/agent-os"
echo ""
