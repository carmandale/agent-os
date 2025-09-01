#!/bin/bash

# project-config-injector.sh
# Simple project configuration injection for Claude Code
# Prevents amnesia by injecting config on EVERY prompt

# Function to detect package manager from lock files
detect_package_manager() {
    local type="$1"
    
    if [[ "$type" == "python" ]]; then
        if [[ -f "uv.lock" ]]; then echo "uv"
        elif [[ -f "poetry.lock" ]]; then echo "poetry"
        elif [[ -f "Pipfile.lock" ]]; then echo "pipenv"
        elif [[ -f "requirements.txt" ]]; then echo "pip"
        else echo "pip"
        fi
    elif [[ "$type" == "javascript" ]]; then
        if [[ -f "bun.lockb" ]]; then echo "bun"
        elif [[ -f "pnpm-lock.yaml" ]]; then echo "pnpm"
        elif [[ -f "yarn.lock" ]]; then echo "yarn"
        elif [[ -f "package-lock.json" ]]; then echo "npm"
        elif [[ -f "package.json" ]]; then echo "npm"
        else echo "npm"
        fi
    fi
}

# Function to detect ports from env files
detect_ports() {
    local frontend_port="3000"
    local backend_port="8000"
    
    # Check .env.local for frontend
    if [[ -f ".env.local" ]]; then
        local port=$(grep -E "^PORT=" ".env.local" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        if [[ -n "$port" ]]; then
            frontend_port="$port"
        fi
    fi
    
    # Check .env for backend
    if [[ -f ".env" ]]; then
        local api_port=$(grep -E "^API_PORT=" ".env" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        if [[ -n "$api_port" ]]; then
            backend_port="$api_port"
        fi
        # Also check PORT in .env if API_PORT not found
        if [[ "$backend_port" == "8000" ]]; then
            local port=$(grep -E "^PORT=" ".env" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
            if [[ -n "$port" ]]; then
                backend_port="$port"
            fi
        fi
    fi
    
    echo "$frontend_port:$backend_port"
}

# Function to build configuration reminder
build_config_reminder() {
    local reminder=""
    
    # Only show if we're in a project with actual config
    if [[ -f "package.json" ]] || [[ -f "requirements.txt" ]] || [[ -f ".env" ]] || [[ -f ".env.local" ]]; then
        reminder+="**🔧 PROJECT CONFIGURATION REMINDER:**\n\n"
        
        # Package managers
        local py_mgr=$(detect_package_manager "python")
        local js_mgr=$(detect_package_manager "javascript")
        
        if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "Pipfile" ]]; then
            reminder+="**Python:** Use \`$py_mgr\` (NOT pip if $py_mgr specified)\n"
            if [[ "$py_mgr" == "uv" ]]; then
                reminder+="  • Install: \`uv add package\` (NOT pip install)\n"
                reminder+="  • Activate: \`source .venv/bin/activate\`\n"
            fi
        fi
        
        if [[ -f "package.json" ]]; then
            reminder+="**JavaScript:** Use \`$js_mgr\` (NOT npm if $js_mgr specified)\n"
            reminder+="  • Install: \`$js_mgr install\` or \`$js_mgr add package\`\n"
        fi
        
        # Ports
        local ports=$(detect_ports)
        local frontend_port=$(echo $ports | cut -d':' -f1)
        local backend_port=$(echo $ports | cut -d':' -f2)
        
        if [[ -f ".env.local" ]] || [[ -f ".env" ]]; then
            reminder+="\n**Ports:**\n"
            reminder+="  • Frontend: $frontend_port\n"
            reminder+="  • Backend: $backend_port\n"
        fi
        
        # Startup
        if [[ -f "start.sh" ]]; then
            reminder+="\n**Startup:** Use \`./start.sh\` (configured startup script)\n"
        elif [[ -f "dev.sh" ]]; then
            reminder+="\n**Startup:** Use \`./dev.sh\` (configured startup script)\n"
        fi
        
        reminder+="\n"
    fi
    
    echo -e "$reminder"
}

# Export functions
export -f detect_package_manager
export -f detect_ports
export -f build_config_reminder