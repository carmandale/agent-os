#!/bin/bash

# Agent OS Setup Script
# This script installs Agent OS files to your system

set -e  # Exit on error

# Initialize flags
OVERWRITE_INSTRUCTIONS=false
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

echo "🚀 Agent OS Setup Script"
echo "========================"
echo ""

# Version tracking - get version from VERSION file or fallback to repo
if [ -f "VERSION" ]; then
    AGENT_OS_VERSION=$(cat VERSION)
else
    # Fallback to downloading version from repo
    AGENT_OS_VERSION=$(curl -sSL "${BASE_URL}/VERSION" 2>/dev/null | head -n1)
    if [ -z "$AGENT_OS_VERSION" ]; then
        AGENT_OS_VERSION="4.0.2"  # Fallback if curl fails
    fi
fi

# Base URL for raw GitHub content
# Updated to use carmandale/agent-os fork with custom GitHub Issues workflow,
# tabs indentation, and Python/React tech stack preferences
BASE_URL="https://raw.githubusercontent.com/carmandale/agent-os/main"

# Create directories
echo "📁 Creating directories..."
mkdir -p "$HOME/.agent-os/standards"
mkdir -p "$HOME/.agent-os/instructions"
mkdir -p "$HOME/.agent-os/instructions/core"
mkdir -p "$HOME/.agent-os/instructions/meta"
mkdir -p "$HOME/.agent-os/scripts"
mkdir -p "$HOME/.agent-os/workflow-modules"
mkdir -p "$HOME/.agent-os/hooks"
mkdir -p "$HOME/.agent-os/hooks"

# Download standards files
echo ""
echo "📥 Downloading standards files to ~/.agent-os/standards/"

# tech-stack.md
if [ -f "$HOME/.agent-os/standards/tech-stack.md" ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "  ⚠️  ~/.agent-os/standards/tech-stack.md already exists - skipping"
else
    curl -s -o "$HOME/.agent-os/standards/tech-stack.md" "${BASE_URL}/standards/tech-stack.md"
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
    curl -s -o "$HOME/.agent-os/standards/code-style.md" "${BASE_URL}/standards/code-style.md"
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
    curl -s -o "$HOME/.agent-os/standards/best-practices.md" "${BASE_URL}/standards/best-practices.md"
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
    curl -s -o "$dest_path" "$src_path"
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
    curl -s -o "$HOME/.agent-os/instructions/core/execute-task.md" "${BASE_URL}/instructions/core/execute-task.md"
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
    curl -s -o "$HOME/.agent-os/instructions/meta/pre-flight.md" "${BASE_URL}/instructions/meta/pre-flight.md"
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

# workspace-hygiene-check.sh
curl -s -o "$HOME/.agent-os/scripts/workspace-hygiene-check.sh" "${BASE_URL}/scripts/workspace-hygiene-check.sh"
chmod +x "$HOME/.agent-os/scripts/workspace-hygiene-check.sh"
echo "  ✓ ~/.agent-os/scripts/workspace-hygiene-check.sh"

# project-context-loader.sh
curl -s -o "$HOME/.agent-os/scripts/project-context-loader.sh" "${BASE_URL}/scripts/project-context-loader.sh"
chmod +x "$HOME/.agent-os/scripts/project-context-loader.sh"
echo "  ✓ ~/.agent-os/scripts/project-context-loader.sh"

# task-validator.sh
curl -s -o "$HOME/.agent-os/scripts/task-validator.sh" "${BASE_URL}/scripts/task-validator.sh"
chmod +x "$HOME/.agent-os/scripts/task-validator.sh"
echo "  ✓ ~/.agent-os/scripts/task-validator.sh"

# update-documentation.sh (deterministic docs updater)
curl -s -o "$HOME/.agent-os/scripts/update-documentation.sh" "${BASE_URL}/scripts/update-documentation.sh"
chmod +x "$HOME/.agent-os/scripts/update-documentation.sh"
echo "  ✓ ~/.agent-os/scripts/update-documentation.sh"

# update-documentation-wrapper.sh (Claude Code friendly exit code translation)
curl -s -o "$HOME/.agent-os/scripts/update-documentation-wrapper.sh" "${BASE_URL}/scripts/update-documentation-wrapper.sh"
chmod +x "$HOME/.agent-os/scripts/update-documentation-wrapper.sh"
echo "  ✓ ~/.agent-os/scripts/update-documentation-wrapper.sh"

# config-resolver.py
curl -s -o "$HOME/.agent-os/scripts/config-resolver.py" "${BASE_URL}/scripts/config-resolver.py"
echo "  ✓ ~/.agent-os/scripts/config-resolver.py"

# session-memory.sh
curl -s -o "$HOME/.agent-os/scripts/session-memory.sh" "${BASE_URL}/scripts/session-memory.sh"
chmod +x "$HOME/.agent-os/scripts/session-memory.sh"
echo "  ✓ ~/.agent-os/scripts/session-memory.sh"

# config-validator.sh
curl -s -o "$HOME/.agent-os/scripts/config-validator.sh" "${BASE_URL}/scripts/config-validator.sh"
chmod +x "$HOME/.agent-os/scripts/config-validator.sh"
echo "  ✓ ~/.agent-os/scripts/config-validator.sh"

# pre-command-guard.sh
curl -s -o "$HOME/.agent-os/scripts/pre-command-guard.sh" "${BASE_URL}/scripts/pre-command-guard.sh"
chmod +x "$HOME/.agent-os/scripts/pre-command-guard.sh"
echo "  ✓ ~/.agent-os/scripts/pre-command-guard.sh"

# intent-analyzer.sh
curl -s -o "$HOME/.agent-os/scripts/intent-analyzer.sh" "${BASE_URL}/scripts/intent-analyzer.sh"
chmod +x "$HOME/.agent-os/scripts/intent-analyzer.sh"
echo "  ✓ ~/.agent-os/scripts/intent-analyzer.sh"

# workspace-state.sh
curl -s -o "$HOME/.agent-os/scripts/workspace-state.sh" "${BASE_URL}/scripts/workspace-state.sh"
chmod +x "$HOME/.agent-os/scripts/workspace-state.sh"
echo "  ✓ ~/.agent-os/scripts/workspace-state.sh"

# context-aware-wrapper.sh
curl -s -o "$HOME/.agent-os/scripts/context-aware-wrapper.sh" "${BASE_URL}/scripts/context-aware-wrapper.sh"
chmod +x "$HOME/.agent-os/scripts/context-aware-wrapper.sh"
echo "  ✓ ~/.agent-os/scripts/context-aware-wrapper.sh"

# testing-enforcer.sh
curl -s -o "$HOME/.agent-os/scripts/testing-enforcer.sh" "${BASE_URL}/scripts/testing-enforcer.sh"
chmod +x "$HOME/.agent-os/scripts/testing-enforcer.sh"
echo "  ✓ ~/.agent-os/scripts/testing-enforcer.sh"

# Transparent work sessions scripts
for script in workflow-validator.sh work-session-manager.sh commit-boundary-manager.sh session-auto-start.sh; do
    curl -s -o "$HOME/.agent-os/scripts/$script" "${BASE_URL}/scripts/$script"
    chmod +x "$HOME/.agent-os/scripts/$script"
    echo "  ✓ ~/.agent-os/scripts/$script"
done

# Additional utility scripts
for script in check-updates.sh validate-instructions.sh; do
    curl -s -o "$HOME/.agent-os/scripts/$script" "${BASE_URL}/scripts/$script"
    chmod +x "$HOME/.agent-os/scripts/$script"
    echo "  ✓ ~/.agent-os/scripts/$script"
done

# Python scripts
curl -s -o "$HOME/.agent-os/scripts/project_root_resolver.py" "${BASE_URL}/scripts/project_root_resolver.py"
echo "  ✓ ~/.agent-os/scripts/project_root_resolver.py"

# Download workflow modules
echo ""
echo "📥 Downloading workflow modules to ~/.agent-os/workflow-modules/"

# step-1-hygiene-and-setup.md
curl -s -o "$HOME/.agent-os/workflow-modules/step-1-hygiene-and-setup.md" "${BASE_URL}/workflow-modules/step-1-hygiene-and-setup.md"
echo "  ✓ ~/.agent-os/workflow-modules/step-1-hygiene-and-setup.md"

# step-2-planning-and-execution.md
curl -s -o "$HOME/.agent-os/workflow-modules/step-2-planning-and-execution.md" "${BASE_URL}/workflow-modules/step-2-planning-and-execution.md"
echo "  ✓ ~/.agent-os/workflow-modules/step-2-planning-and-execution.md"

# step-3-quality-assurance.md
curl -s -o "$HOME/.agent-os/workflow-modules/step-3-quality-assurance.md" "${BASE_URL}/workflow-modules/step-3-quality-assurance.md"
echo "  ✓ ~/.agent-os/workflow-modules/step-3-quality-assurance.md"

# step-4-git-integration.md
curl -s -o "$HOME/.agent-os/workflow-modules/step-4-git-integration.md" "${BASE_URL}/workflow-modules/step-4-git-integration.md"
echo "  ✓ ~/.agent-os/workflow-modules/step-4-git-integration.md"

# Note: Subagents are now installed as Claude Code agents via setup-claude-code.sh
# The Python subagent system has been deprecated in favor of native Claude Code agents

# Download background task tools
echo ""
echo "📥 Downloading background task tools to ~/.agent-os/tools/"
mkdir -p "$HOME/.agent-os/tools"

# aos unified CLI
curl -s -o "$HOME/.agent-os/tools/aos" "${BASE_URL}/tools/aos"
chmod +x "$HOME/.agent-os/tools/aos" 2>/dev/null || true
echo "  ✓ ~/.agent-os/tools/aos"

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
if [ "$OVERWRITE_INSTRUCTIONS" = false ] && [ "$OVERWRITE_STANDARDS" = false ]; then
    echo "💡 Note: Existing files were skipped to preserve your customizations"
    echo "   Use --overwrite-instructions or --overwrite-standards to update specific files"
else
    echo "💡 Note: Some files were overwritten based on your flags"
    if [ "$OVERWRITE_INSTRUCTIONS" = false ]; then
        echo "   Existing instruction files were preserved"
    fi
    if [ "$OVERWRITE_STANDARDS" = false ]; then
        echo "   Existing standards files were preserved"
    fi
fi
echo ""
echo "Next steps:"
echo ""
echo "1. Customize your coding standards in ~/.agent-os/standards/"
echo ""
echo "2. Install commands for your AI coding assistant(s):"
echo ""
echo "   - Using Claude Code? Install the Claude Code commands with:"
echo "     curl -sSL https://raw.githubusercontent.com/carmandale/agent-os/main/setup-claude-code.sh | bash"
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
