#!/bin/bash

# Agent OS Quick Init Alias Function
# Add this to your ~/.zshrc or ~/.bashrc file
# Usage: aos [command]

function aos() {
	local AGENT_OS_VERSION="1.0.0"
	local AGENT_OS_REPO="https://github.com/carmandale/agent-os"
	local AGENT_OS_RAW_URL="https://raw.githubusercontent.com/carmandale/agent-os/main"
	
	# Colors for output
	local GREEN='\033[0;32m'
	local YELLOW='\033[1;33m'
	local RED='\033[0;31m'
	local BLUE='\033[0;34m'
	local NC='\033[0m' # No Color
	
	# Function to print colored messages
	print_status() {
		case "$1" in
			"success") echo -e "${GREEN}✅ $2${NC}" ;;
			"warning") echo -e "${YELLOW}⚠️  $2${NC}" ;;
			"error") echo -e "${RED}❌ $2${NC}" ;;
			"info") echo -e "${BLUE}ℹ️  $2${NC}" ;;
			*) echo "$2" ;;
		esac
	}
	
	# Function to check if Agent OS is installed globally
	check_global_installation() {
		if [ -d "$HOME/.agent-os/instructions" ] && [ -d "$HOME/.agent-os/standards" ]; then
			return 0
		else
			return 1
		fi
	}
	
	# Function to detect project type
	detect_project_type() {
		local has_claude=false
		local has_cursor=false
		
		# Check for Claude Code setup
		if [ -f ".claude/claude.json" ] || [ -f "CLAUDE.md" ]; then
			has_claude=true
		fi
		
		# Check for Cursor setup  
		if [ -d ".cursor" ] || [ -f ".cursorrules" ]; then
			has_cursor=true
		fi
		
		# Return appropriate type
		if [ "$has_claude" = true ] && [ "$has_cursor" = true ]; then
			echo "both"
		elif [ "$has_claude" = true ]; then
			echo "claude"
		elif [ "$has_cursor" = true ]; then
			echo "cursor"
		else
			echo "unknown"
		fi
	}
	
	# Function to check for updates
	check_for_updates() {
		print_status "info" "Checking for Agent OS updates..."
		
		# Check if we can reach GitHub
		if ! curl -s -I "$AGENT_OS_REPO" >/dev/null 2>&1; then
			print_status "warning" "Cannot check for updates (no internet connection)"
			return 1
		fi
		
		# Get latest release tag from GitHub
		local latest_tag=$(curl -s "https://api.github.com/repos/carmandale/agent-os/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
		
		if [ -z "$latest_tag" ]; then
			print_status "info" "Using main branch (no releases found)"
			return 0
		fi
		
		# Compare with installed version (if we have a version file)
		if [ -f "$HOME/.agent-os/.version" ]; then
			local installed_version=$(cat "$HOME/.agent-os/.version")
			if [ "$installed_version" != "$latest_tag" ]; then
				print_status "warning" "Update available: $installed_version → $latest_tag"
				return 0
			else
				print_status "success" "Agent OS is up to date (version: $latest_tag)"
				return 0
			fi
		else
			print_status "info" "Version tracking not available"
			return 0
		fi
	}
	
	# Function to install or update Agent OS globally
	install_or_update_global() {
		local flags=""
		
		if check_global_installation; then
			print_status "info" "Agent OS is already installed. Checking for updates..."
			
			echo -e "\nDo you want to update Agent OS? This will:"
			echo "  • Preserve your customized standards by default"
			echo "  • Update instruction files to the latest version"
			echo ""
			echo "Options:"
			echo "  1) Update instructions only (preserve all customizations)"
			echo "  2) Update everything (overwrite all files)"
			echo "  3) Cancel"
			echo -n "Choice [1-3]: "
			read -r choice
			
			case "$choice" in
				"1")
					flags="--overwrite-instructions"
					;;
				"2")
					flags="--overwrite-instructions --overwrite-standards"
					;;
				*)
					print_status "info" "Update cancelled"
					return 1
					;;
			esac
		fi
		
		print_status "info" "Installing/updating Agent OS base files..."
		if curl -sSL "$AGENT_OS_RAW_URL/setup.sh" | bash -s -- $flags; then
			print_status "success" "Agent OS base installation complete"
			return 0
		else
			print_status "error" "Failed to install/update Agent OS"
			return 1
		fi
	}
	
	# Function to setup project-specific files
	setup_project() {
		local project_type=$(detect_project_type)
		
		if [ "$project_type" = "unknown" ]; then
			echo -e "\n${YELLOW}Project type not detected.${NC}"
			echo "Which AI assistant are you using?"
			echo "  1) Claude Code"
			echo "  2) Cursor"
			echo "  3) Other (manual setup)"
			echo -n "Choice [1-3]: "
			read -r choice
			
			case "$choice" in
				"1") project_type="claude" ;;
				"2") project_type="cursor" ;;
				*) 
					print_status "info" "Visit $AGENT_OS_REPO for manual setup instructions"
					return 1
					;;
			esac
		else
			print_status "success" "Detected $project_type project"
		fi
		
		# Run appropriate setup
		case "$project_type" in
			"both")
				print_status "info" "Setting up both Claude Code and Cursor integrations..."
				
				# Check if subagents are already configured
				local skip_subagent_prompt=false
				if [ -f "$HOME/.agent-os/subagent-config.yaml" ] && [ -f "$HOME/.claude/commands/enhance.md" ]; then
					print_status "info" "Subagent integration already configured - will skip prompt"
					skip_subagent_prompt=true
				fi
				
				# For "both" projects, run Claude Code setup
				print_status "info" "Setting up Claude Code..."
				if [ "$skip_subagent_prompt" = true ]; then
					# If subagents already configured, bypass the prompt
					if curl -sSL "$AGENT_OS_RAW_URL/setup-claude-code.sh" | bash -s -- < /dev/null; then
						print_status "success" "Claude Code setup complete (subagents already configured)"
					else
						print_status "error" "Claude Code setup failed"
						return 1
					fi
				else
					# Let it run normally with subagent prompt
					if curl -sSL "$AGENT_OS_RAW_URL/setup-claude-code.sh" | bash; then
						print_status "success" "Claude Code setup complete"
					else
						print_status "error" "Claude Code setup failed"
						return 1
					fi
				fi
				
				# Setup Cursor
				print_status "info" "Setting up Cursor..."
				if curl -sSL "$AGENT_OS_RAW_URL/setup-cursor.sh" | bash; then
					print_status "success" "Cursor setup complete"
				else
					print_status "error" "Cursor setup failed"
					return 1
				fi
				
				echo -e "\n${GREEN}Available commands:${NC}"
				echo "  Claude Code:     /plan-product, /analyze-product, /create-spec, /execute-tasks"
				echo "  Cursor:          @plan-product, @analyze-product, @create-spec, @execute-tasks"
				;;
			"claude")
				print_status "info" "Setting up Claude Code integration..."
				if curl -sSL "$AGENT_OS_RAW_URL/setup-claude-code.sh" | bash; then
					print_status "success" "Claude Code setup complete"
					echo -e "\n${GREEN}Available commands:${NC}"
					echo "  /plan-product    - Initialize new product"
					echo "  /analyze-product - Analyze existing codebase"
					echo "  /create-spec     - Create feature specification"
					echo "  /execute-tasks   - Execute planned tasks"
					echo "  /hygiene-check   - Check workspace status"
				else
					print_status "error" "Claude Code setup failed"
					return 1
				fi
				;;
			"cursor")
				print_status "info" "Setting up Cursor integration..."
				if curl -sSL "$AGENT_OS_RAW_URL/setup-cursor.sh" | bash; then
					print_status "success" "Cursor setup complete"
					echo -e "\n${GREEN}Available commands:${NC}"
					echo "  @plan-product    - Initialize new product"
					echo "  @analyze-product - Analyze existing codebase"
					echo "  @create-spec     - Create feature specification"
					echo "  @execute-tasks   - Execute planned tasks"
					echo "  @hygiene-check   - Check workspace status"
				else
					print_status "error" "Cursor setup failed"
					return 1
				fi
				;;
		esac
		
		# Check if this is an existing project without Agent OS
		if [ -d ".git" ] && [ ! -d ".agent-os" ]; then
			echo -e "\n${YELLOW}This appears to be an existing project.${NC}"
			echo "Would you like to analyze it and set up Agent OS documentation? (y/n)"
			read -r response
			if [[ "$response" == "y" ]]; then
				print_status "info" "Use the analyze-product command in your AI assistant to set up Agent OS for this project"
			fi
		fi
	}
	
	# Function to show help
	show_help() {
		echo "Agent OS Quick Init (aos)"
		echo "========================"
		echo ""
		echo "Usage: aos [command]"
		echo ""
		echo "Commands:"
		echo "  init      Initialize or update Agent OS in current project"
		echo "  update    Update global Agent OS installation"
		echo "  check     Check Agent OS installation status"
		echo "  help      Show this help message"
		echo ""
		echo "Examples:"
		echo "  aos           # Interactive mode"
		echo "  aos init      # Set up Agent OS in current project"
		echo "  aos update    # Update global Agent OS files"
		echo "  aos check     # Check installation and updates"
		echo ""
		echo "Learn more at: $AGENT_OS_REPO"
	}
	
	# Function to check status
	check_status() {
		echo "🔍 Agent OS Status Check"
		echo "========================"
		echo ""
		
		# Check global installation
		if check_global_installation; then
			print_status "success" "Global installation found at ~/.agent-os/"
			
			# Count files
			local std_count=$(ls ~/.agent-os/standards/ 2>/dev/null | wc -l | tr -d ' ')
			local inst_count=$(ls ~/.agent-os/instructions/ 2>/dev/null | wc -l | tr -d ' ')
			echo "   Standards files: $std_count"
			echo "   Instruction files: $inst_count"
		else
			print_status "error" "Global installation not found"
		fi
		
		echo ""
		
		# Check project setup
		local project_type=$(detect_project_type)
		if [ "$project_type" != "unknown" ]; then
			print_status "success" "Project type: $project_type"
			
			# Check for project-specific files
			if [ "$project_type" = "claude" ] || [ "$project_type" = "both" ]; then
				if [ -d "$HOME/.claude/commands" ]; then
					local cmd_count=$(ls ~/.claude/commands/ 2>/dev/null | wc -l | tr -d ' ')
					print_status "success" "Claude commands installed: $cmd_count files"
					
					# Check for subagent integration
					# Check multiple indicators: enhance.md exists and contains subagent references
					if [ -f "$HOME/.claude/commands/enhance.md" ]; then
						if grep -q "subagent" "$HOME/.claude/commands/enhance.md" 2>/dev/null; then
							print_status "success" "Subagent integration: Installed ✓"
						else
							# enhance.md exists but doesn't have subagent content
							print_status "warning" "Subagent integration: Outdated (update recommended)"
							echo "   Update with: curl -sSL $AGENT_OS_RAW_URL/integrations/setup-subagent-integration.sh | bash"
						fi
					else
						print_status "warning" "Subagent integration: Not installed (HIGHLY RECOMMENDED)"
						echo "   Install with: curl -sSL $AGENT_OS_RAW_URL/integrations/setup-subagent-integration.sh | bash"
					fi
				else
					print_status "warning" "Claude commands not installed"
				fi
			fi
			
			if [ "$project_type" = "cursor" ] || [ "$project_type" = "both" ]; then
				if [ -d ".cursor/rules" ]; then
					local rule_count=$(ls .cursor/rules/ 2>/dev/null | wc -l | tr -d ' ')
					print_status "success" "Cursor rules installed: $rule_count files"
				else
					print_status "warning" "Cursor rules not installed in this project"
				fi
			fi
			
			# Check for Agent OS product files
			if [ -d ".agent-os/product" ]; then
				print_status "success" "Agent OS product documentation exists"
			else
				print_status "info" "Agent OS not initialized for this product"
			fi
		else
			print_status "info" "No AI assistant detected in current directory"
		fi
		
		echo ""
		check_for_updates
	}
	
	# Main command logic
	case "${1:-}" in
		"init")
			if ! check_global_installation; then
				print_status "warning" "Agent OS not installed globally. Installing..."
				if ! install_or_update_global; then
					return 1
				fi
			fi
			setup_project
			;;
		"update")
			install_or_update_global
			;;
		"check"|"status")
			check_status
			;;
		"help"|"--help"|"-h")
			show_help
			;;
		"")
			# Interactive mode
			echo "🚀 Agent OS Quick Setup"
			echo "======================="
			echo ""
			
			if ! check_global_installation; then
				print_status "warning" "Agent OS is not installed"
				echo -e "\nWould you like to install it now? (y/n)"
				read -r response
				if [[ "$response" == "y" ]]; then
					if install_or_update_global; then
						setup_project
					fi
				else
					echo -e "\nRun 'aos init' when you're ready to set up Agent OS"
				fi
			else
				print_status "success" "Agent OS is installed"
				check_for_updates
				echo ""
				echo "What would you like to do?"
				echo "  1) Set up Agent OS in current project"
				echo "  2) Update Agent OS installation"
				echo "  3) Check status"
				echo "  4) Exit"
				echo -n "Choice [1-4]: "
				read -r choice
				
				case "$choice" in
					"1") setup_project ;;
					"2") install_or_update_global ;;
					"3") check_status ;;
					*) print_status "info" "Goodbye!" ;;
				esac
			fi
			;;
		*)
			print_status "error" "Unknown command: $1"
			echo "Run 'aos help' for usage information"
			return 1
			;;
	esac
}

# Also provide the shorter alias
alias agentos=aos