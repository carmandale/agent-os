#!/bin/bash

# Agent OS Subagent Integration Setup Script
# Version: 1.0.0
# This script configures Agent OS to work with existing Claude Code subagents

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_OS_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🚀 Agent OS Subagent Integration Setup${NC}"
echo "=============================================="
echo ""

# Check if Claude Code is installed
check_claude_code() {
    echo -e "🔍 Checking Claude Code installation..."
    if ! command -v claude &> /dev/null; then
        echo -e "${RED}❌ Claude Code CLI not found.${NC}"
        echo "Please install Claude Code first: https://claude.ai/code"
        exit 1
    fi
    echo -e "${GREEN}✅ Claude Code CLI found${NC}"
}

# Detect available subagents
detect_subagents() {
    echo -e "\n🔍 Detecting available subagents..."
    
    AGENTS_DIR="$HOME/.claude/agents"
    if [ ! -d "$AGENTS_DIR" ]; then
        echo -e "${YELLOW}⚠️  No subagents directory found at $AGENTS_DIR${NC}"
        echo "You can still use Agent OS, but subagent enhancements won't be available."
        return 1
    fi
    
    # Key agents for Agent OS workflows (Builder Methods architecture)
    declare -a KEY_AGENTS=(
        "context-fetcher"
        "date-checker"
        "file-creator"
        "git-workflow"
        "test-runner"
        "code-refactoring-expert"
        "security-threat-analyst"
        "performance-optimizer"
        "product-manager-orchestrator"
    )
    
    declare -a FOUND_AGENTS=()
    declare -a MISSING_AGENTS=()
    
    for agent in "${KEY_AGENTS[@]}"; do
        if [ -f "$AGENTS_DIR/${agent}.md" ]; then
            FOUND_AGENTS+=("$agent")
            echo -e "  ${GREEN}✅ $agent${NC}"
        else
            MISSING_AGENTS+=("$agent")
            echo -e "  ${YELLOW}⚠️  $agent (not found)${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}Found ${#FOUND_AGENTS[@]} of ${#KEY_AGENTS[@]} key agents${NC}"
    
    if [ ${#FOUND_AGENTS[@]} -eq 0 ]; then
        echo -e "${YELLOW}No key subagents found. Agent OS will work with basic functionality.${NC}"
        return 1
    fi
    
    return 0
}

# Create integration configuration
setup_integration_config() {
    echo -e "\n⚙️  Setting up integration configuration..."
    
    # Copy default config if it doesn't exist
    local config_file="$HOME/.agent-os/subagent-config.yaml"
    
    if [ ! -f "$config_file" ]; then
        mkdir -p "$(dirname "$config_file")"
        cp "$SCRIPT_DIR/subagent-config.yaml" "$config_file"
        echo -e "${GREEN}✅ Created default configuration at $config_file${NC}"
    else
        echo -e "${YELLOW}⚠️  Configuration already exists at $config_file${NC}"
        echo "You can edit it manually or delete it to recreate with defaults."
    fi
}

# Update Agent OS instructions with subagent integration
update_instructions() {
    echo -e "\n📝 Creating enhanced workflow instructions..."
    
    local instructions_dir="$HOME/.agent-os/instructions"
    local enhanced_dir="$instructions_dir/enhanced"
    
    mkdir -p "$enhanced_dir"
    
    # Copy enhanced workflow files
    if [ -d "$SCRIPT_DIR/workflow-enhancements" ]; then
        cp -r "$SCRIPT_DIR/workflow-enhancements/"* "$enhanced_dir/"
        echo -e "${GREEN}✅ Enhanced workflow instructions installed${NC}"
    else
        echo -e "${YELLOW}⚠️  Enhanced workflows not found, will create basic integration${NC}"
        create_basic_enhancements "$enhanced_dir"
    fi
}

# Create enhanced workflow instructions
create_basic_enhancements() {
    local enhanced_dir="$1"
    
    # Create enhanced execute-tasks.md
    cat > "$enhanced_dir/execute-tasks-enhanced.md" << 'EOF'
# Enhanced Task Execution with Subagents

This enhanced version of execute-tasks.md includes subagent integration points.

## Subagent Integration Points

### Step 6.5: Implementation Quality Check
If context retrieval is needed, the context-fetcher agent can be invoked for:
- Architectural guidance
- Code review
- Technical mentorship

### Step 8.5: Comprehensive Quality Pipeline
Multiple agents can be invoked for quality assurance:
- test-runner: Automated test execution across frameworks
- code-refactoring-expert: Code quality improvement
- security-threat-analyst: Security review
- performance-optimizer: Performance validation

## Usage
These enhancements are triggered automatically based on task complexity and risk assessment.
Users can also explicitly request subagent assistance during any step.

EOF

    echo -e "${GREEN}✅ Created basic enhanced instructions${NC}"
}

# Update Claude Code commands to use enhanced workflows
update_claude_commands() {
    echo -e "\n🔧 Updating Claude Code commands..."
    
    local claude_dir="$HOME/.claude"
    local commands_dir="$claude_dir/commands"
    
    if [ ! -d "$commands_dir" ]; then
        mkdir -p "$commands_dir"
    fi
    
    # Create enhanced commands that detect subagent availability
    cat > "$commands_dir/agent-os-enhanced.md" << 'EOF'
# Enhanced Agent OS Commands

These commands automatically detect and use available subagents for improved outcomes.

## /plan-product-enhanced
Execute product planning with subagent enhancements:
- Uses file-creator for structured file generation
- Leverages systems-architect for technical architecture validation

## /create-spec-enhanced  
Create specifications with comprehensive subagent support:
- Automated technical review with systems-architect
- Automated test execution with test-runner agent
- Security analysis with security-threat-analyst (when applicable)

## /execute-tasks-enhanced
Execute tasks with quality pipeline:
- Efficient context retrieval with context-fetcher agent
- Automated quality checks with multiple specialists
- Performance optimization when needed

## Usage
Add "-enhanced" to any standard Agent OS command to use subagent integration.
Falls back to standard workflow if subagents are not available.
EOF

    echo -e "${GREEN}✅ Enhanced commands created${NC}"
}

# Test subagent integration
test_integration() {
    echo -e "\n🧪 Testing subagent integration..."
    
    # Simple test to verify configuration is readable
    local config_file="$HOME/.agent-os/subagent-config.yaml"
    if [ -f "$config_file" ]; then
        echo -e "${GREEN}✅ Configuration file accessible${NC}"
    else
        echo -e "${RED}❌ Configuration file missing${NC}"
        return 1
    fi
    
    # Test Claude Code agent detection
    if command -v claude &> /dev/null; then
        echo -e "${GREEN}✅ Claude Code CLI responsive${NC}"
    else
        echo -e "${YELLOW}⚠️  Claude Code CLI not responding${NC}"
    fi
    
    return 0
}

# Main setup flow
main() {
    echo "This script will configure Agent OS to work with your existing Claude Code subagents."
    echo "Philosophy: Always ask, never assume. All enhancements are completely opt-in."
    echo "Your existing workflows remain unchanged - enhancements are available when YOU want them."
    echo ""
    
    # Skip prompt if running non-interactively (piped input)
    if [ ! -t 0 ]; then
        echo "Running in non-interactive mode - proceeding with setup..."
        echo ""
    else
        read -p "Continue with setup? (y/n): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Setup cancelled."
            exit 0
        fi
        
        echo ""
    fi
    
    # Run setup steps
    check_claude_code
    
    if detect_subagents; then
        setup_integration_config
        update_instructions  
        update_claude_commands
        
        if test_integration; then
            echo -e "\n${GREEN}🎉 Subagent integration setup complete!${NC}"
            echo ""
            echo "What's available now:"
            echo "• Same Agent OS workflows you know and love"
            echo "• Optional subagent enhancements when YOU want them" 
            echo "• Professional-grade analysis available on demand"
            echo "• Zero pressure, complete developer control"
            echo ""
            echo "Try your normal workflows:"
            echo "  /create-spec \"Add user authentication\""
            echo "  → Offers optional security analysis (easily dismissed)"
            echo ""
            echo "Or explicitly request enhancements:"
            echo "  /enhance --security --architecture"
            echo ""
            echo "Configuration file: $HOME/.agent-os/subagent-config.yaml"
            echo "Enhancement command: /enhance (available in all workflows)"
        else
            echo -e "\n${YELLOW}⚠️  Setup completed with warnings${NC}"
            echo "Please check the configuration and try again if needed."
        fi
    else
        echo -e "\n${YELLOW}⚠️  Limited subagents available${NC}"
        echo "Agent OS will work with basic functionality."
        echo "Consider installing more Claude Code subagents for enhanced capabilities."
    fi
}

# Show help if requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Agent OS Subagent Integration Setup"
    echo ""
    echo "This script configures Agent OS to work with existing Claude Code subagents."
    echo "It provides enhanced workflows with professional-grade output quality."
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --test-only    Only test current integration (don't modify files)"
    echo ""
    echo "Requirements:"
    echo "  - Claude Code CLI installed"  
    echo "  - Agent OS already installed"
    echo "  - Claude Code subagents (optional but recommended)"
    echo ""
    exit 0
fi

# Test-only mode
if [[ "$1" == "--test-only" ]]; then
    echo -e "${BLUE}🧪 Testing current subagent integration...${NC}"
    check_claude_code
    detect_subagents
    test_integration
    exit 0
fi

# Run main setup
main