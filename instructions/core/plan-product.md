---
description: Product Planning Rules for Agent OS
globs:
alwaysApply: false
version: 4.0
encoding: UTF-8
---

# Pre-Flight

<pre_flight_check>
  EXECUTE: @~/.agent-os/instructions/meta/pre-flight.md
</pre_flight_check>

# Product Planning Rules

<ai_meta>
  <parsing_rules>
    - Process XML blocks first for structured data
    - Execute instructions in sequential order
    - Use templates as exact patterns
    - Request missing data rather than assuming
  </parsing_rules>
  <file_conventions>
    - encoding: UTF-8
    - line_endings: LF
    - indent: 2 spaces
    - markdown_headers: no indentation
  </file_conventions>
</ai_meta>

## Overview

<purpose>
  - Generate comprehensive product documentation for new projects
  - Create structured files for AI agent consumption
  - Establish consistent project initialization
</purpose>

<context>
  - Part of Agent OS framework
  - Triggered during project initialization
  - Output used by AI agents throughout development
</context>

<prerequisites>
  - Write access to project root
  - Git initialized (recommended)
  - User has product requirements
  - Access to @~/.claude/CLAUDE.md and Cursor rules
</prerequisites>

<process_flow>

<step number="1" subagent="context-fetcher" name="gather_user_input">

### Step 1: Gather User Input

<step_metadata>
  <required_inputs>
    - main_idea: string
    - key_features: array[string] (minimum: 3)
    - target_users: array[string] (minimum: 1)
    - tech_stack: object
  </required_inputs>
  <validation>blocking</validation>
</step_metadata>

<data_sources>
  <primary>user_direct_input</primary>
  <fallback_sequence>
    1. @~/.agent-os/standards/tech-stack.md
    2. @~/.claude/CLAUDE.md
    3. Cursor User Rules
  </fallback_sequence>
</data_sources>

<error_template>
  Please provide the following missing information:
  1. Main idea for the product
  2. List of key features (minimum 3)
  3. Target users and use cases (minimum 1)
  4. Tech stack preferences
  5. Has the new application been initialized yet and we're inside the project folder? (yes/no)
</error_template>

<instructions>
  SUBAGENT: Use the context-fetcher subagent for this step
  ACTION: Collect all required inputs from user
  VALIDATION: Ensure all 4 inputs provided before proceeding
  FALLBACK: Check configuration files for tech stack defaults
  ERROR: Use error_template if inputs missing
</instructions>

</step>

<step number="2" name="create_documentation_structure">

### Step 2: Create Documentation Structure

<step_metadata>
  <creates>
    - directory: .agent-os/product/
    - files: 4
  </creates>
</step_metadata>

<file_structure>
  .agent-os/
  └── product/
      ├── mission.md          # Product vision and purpose
      ├── tech-stack.md       # Technical architecture
      ├── roadmap.md          # Development phases
      └── decisions.md        # Decision log
</file_structure>

<git_config>
  <commit_message>Initialize Agent OS product documentation</commit_message>
  <tag>v0.1.0-planning</tag>
  <gitignore_consideration>true</gitignore_consideration>
</git_config>

<instructions>
  ACTION: Create directory structure as specified
  VALIDATION: Verify write permissions before creating
  PROTECTION: Confirm before overwriting existing files
</instructions>

</step>

<step number="3" subagent="file-creator" name="create_mission_md">

### Step 3: Create mission.md

<step_metadata>
  <creates>
    - file: .agent-os/product/mission.md
  </creates>
</step_metadata>

<file_template>
  <header>
    # Product Mission

    > Last Updated: [CURRENT_DATE]
    > Version: 1.0.0
  </header>
  <required_sections>
    - Pitch
    - Users
    - The Problem
    - Differentiators
    - Key Features
  </required_sections>
</file_template>

<section name="pitch">
  <template>
    ## Pitch

    [PRODUCT_NAME] is a [PRODUCT_TYPE] that helps [TARGET_USERS] [SOLVE_PROBLEM] by providing [KEY_VALUE_PROPOSITION].
  </template>
  <constraints>
    - length: 1-2 sentences
    - style: elevator pitch
  </constraints>
</section>

<section name="users">
  <template>
    ## Users

    ### Primary Customers

    - [CUSTOMER_SEGMENT_1]: [DESCRIPTION]
    - [CUSTOMER_SEGMENT_2]: [DESCRIPTION]

    ### User Personas

    **[USER_TYPE]** ([AGE_RANGE])
    - **Role:** [JOB_TITLE]
    - **Context:** [BUSINESS_CONTEXT]
    - **Pain Points:** [PAIN_POINT_1], [PAIN_POINT_2]
    - **Goals:** [GOAL_1], [GOAL_2]
  </template>
  <schema>
    - name: string
    - age_range: "XX-XX years old"
    - role: string
    - context: string
    - pain_points: array[string]
    - goals: array[string]
  </schema>
</section>

<section name="problem">
  <template>
    ## The Problem

    ### [PROBLEM_TITLE]

    [PROBLEM_DESCRIPTION]. [QUANTIFIABLE_IMPACT].

    **Our Solution:** [SOLUTION_DESCRIPTION]
  </template>
  <constraints>
    - problems: 2-4
    - description: 1-3 sentences
    - impact: include metrics
    - solution: 1 sentence
  </constraints>
</section>

<section name="differentiators">
  <template>
    ## Differentiators

    ### [DIFFERENTIATOR_TITLE]

    Unlike [COMPETITOR_OR_ALTERNATIVE], we provide [SPECIFIC_ADVANTAGE]. This results in [MEASURABLE_BENEFIT].
  </template>
  <constraints>
    - count: 2-3
    - focus: competitive advantages
    - evidence: required
  </constraints>
</section>

<section name="features">
  <template>
    ## Key Features

    ### Core Features

    - **[FEATURE_NAME]:** [USER_BENEFIT_DESCRIPTION]

    ### Collaboration Features

    - **[FEATURE_NAME]:** [USER_BENEFIT_DESCRIPTION]
  </template>
  <constraints>
    - total: 8-10 features
    - grouping: by category
    - description: user-benefit focused
  </constraints>
</section>

<instructions>
  SUBAGENT: Use the file-creator subagent for this step
  ACTION: Create mission.md using all section templates
  FILL: Use data from Step 1 user inputs
  FORMAT: Maintain exact template structure
</instructions>

</step>

<step number="4" subagent="file-creator" name="create_tech_stack_md">

### Step 4: Create tech-stack.md

<step_metadata>
  <creates>
    - file: .agent-os/product/tech-stack.md
  </creates>
</step_metadata>

<file_template>
  <header>
    # Technical Stack

    > Last Updated: [CURRENT_DATE]
    > Version: 1.0.0
  </header>
</file_template>

<required_items>
  - application_framework: string + version
  - database_system: string
  - javascript_framework: string
  - import_strategy: ["importmaps", "node"]
  - css_framework: string + version
  - ui_component_library: string
  - fonts_provider: string
  - icon_library: string
  - application_hosting: string
  - database_hosting: string
  - asset_hosting: string
  - deployment_solution: string
  - code_repository_url: string
  - frontend_port: number (default: 3000)
  - backend_port: number (default: 8000)
  - python_package_manager: ["uv", "pip", "poetry", "pipenv"]
  - javascript_package_manager: ["npm", "yarn", "pnpm", "bun"]
  - frontend_startup_command: string
  - backend_startup_command: string
  - project_structure: ["monorepo", "separate_repos", "frontend_only", "backend_only"]
  - testing_framework_frontend: string
  - testing_framework_backend: string
  - e2e_testing_tool: ["playwright", "cypress", "selenium", "none"]
</required_items>

<port_configuration>
  <port_prompt>
    ## Development Port Configuration
    
    This project will need development server ports. Please specify:
    
    1. **Frontend dev server port** (default: 3000)
    2. **Backend API server port** (default: 8000)
    
    **Port Pattern**: For multiple projects use incremental ports:
    - Project A: Frontend 3000, Backend 8000  
    - Project B: Frontend 3001, Backend 8001
    - Project C: Frontend 3002, Backend 8002
    
    What ports should this project use? (Enter for defaults)
  </port_prompt>
  <default_behavior>
    <if_empty_response>use defaults (3000, 8000)</if_empty_response>
    <if_partial_response>use provided + defaults for missing</if_partial_response>
  </default_behavior>
</port_configuration>

<data_resolution>
  <for_each item="required_items">
    <if_not_in>user_input</if_not_in>
    <then_check>
      1. @~/.agent-os/standards/tech-stack.md
      2. @~/.claude/CLAUDE.md
      3. Cursor User Rules
    </then_check>
    <else>add_to_missing_list</else>
  </for_each>
</data_resolution>

<missing_items_template>
  Please provide the following technical stack details:
  [NUMBERED_LIST_OF_MISSING_ITEMS]

  You can respond with the technology choice or "n/a" for each item.
</missing_items_template>

<tech_stack_template>
  <complete_template>
# Technical Stack

> Last Updated: [CURRENT_DATE]
> Version: 1.0.0

## Core Technologies

**Application Framework:** [APPLICATION_FRAMEWORK]
**Database System:** [DATABASE_SYSTEM]
**JavaScript Framework:** [JAVASCRIPT_FRAMEWORK]
**CSS Framework:** [CSS_FRAMEWORK]

## Package Managers (CRITICAL - DO NOT CHANGE)

**Python Package Manager:** [PYTHON_PACKAGE_MANAGER]
**JavaScript Package Manager:** [JAVASCRIPT_PACKAGE_MANAGER]

⚠️ **IMPORTANT**: Always use the package managers specified above. 
- Python: Use `[PYTHON_PACKAGE_MANAGER]` (NOT pip if uv is specified)
- JavaScript: Use `[JAVASCRIPT_PACKAGE_MANAGER]` (NOT npm if yarn is specified)

## Development Environment

**Project Structure:** [PROJECT_STRUCTURE]
**Frontend Port:** [FRONTEND_PORT]
**Backend Port:** [BACKEND_PORT]

### Startup Commands

**Frontend:** `[FRONTEND_STARTUP_COMMAND]`
**Backend:** `[BACKEND_STARTUP_COMMAND]`

**Quick Start:** Run `./start.sh` to start both services

### Environment Files

- **Frontend:** `.env.local` (contains PORT=[FRONTEND_PORT])
- **Backend:** `.env` (contains API_PORT=[BACKEND_PORT])

## Testing Strategy

**Frontend Testing:** [TESTING_FRAMEWORK_FRONTEND]
**Backend Testing:** [TESTING_FRAMEWORK_BACKEND]
**E2E Testing:** [E2E_TESTING_TOOL]

## Additional Configuration

**UI Component Library:** [UI_COMPONENT_LIBRARY]
**Font Provider:** [FONTS_PROVIDER]
**Icon Library:** [ICON_LIBRARY]

## Deployment

**Application Hosting:** [APPLICATION_HOSTING]
**Database Hosting:** [DATABASE_HOSTING]
**Asset Hosting:** [ASSET_HOSTING]
**Deployment Solution:** [DEPLOYMENT_SOLUTION]

## Repository

**Code Repository:** [CODE_REPOSITORY_URL]

---

**⚠️ AGENT OS REMINDER**: Before making ANY changes to package management, startup commands, or environment configuration, ALWAYS check this file first to maintain consistency.
  </complete_template>
</tech_stack_template>

<instructions>
  SUBAGENT: Use the file-creator subagent for this step
  ACTION: Document all tech stack choices using complete template
  RESOLUTION: Check user input first, then config files
  REQUEST: Ask for any missing items using template
  EMPHASIZE: Package manager consistency and startup command preservation
</instructions>

</step>

<step number="5" subagent="file-creator" name="create_roadmap_md">

### Step 5: Create roadmap.md

<step_metadata>
  <creates>
    - file: .agent-os/product/roadmap.md
  </creates>
</step_metadata>

<file_template>
  <header>
    # Product Roadmap

    > Last Updated: [CURRENT_DATE]
    > Version: 1.0.0
    > Status: Planning
  </header>
</file_template>

<phase_structure>
  <phase_count>5</phase_count>
  <features_per_phase>3-7</features_per_phase>
  <phase_template>
    ## Phase [NUMBER]: [NAME] ([DURATION])

    **Goal:** [PHASE_GOAL]
    **Success Criteria:** [MEASURABLE_CRITERIA]

    ### Must-Have Features

    - [ ] [FEATURE] - [DESCRIPTION] `[EFFORT]`

    ### Should-Have Features

    - [ ] [FEATURE] - [DESCRIPTION] `[EFFORT]`

    ### Dependencies

    - [DEPENDENCY]
  </phase_template>
</phase_structure>

<phase_guidelines>
  - Phase 1: Core MVP functionality
  - Phase 2: Key differentiators
  - Phase 3: Scale and polish
  - Phase 4: Advanced features
  - Phase 5: Enterprise features
</phase_guidelines>

<effort_scale>
  - XS: 1 day
  - S: 2-3 days
  - M: 1 week
  - L: 2 weeks
  - XL: 3+ weeks
</effort_scale>

<instructions>
  SUBAGENT: Use the file-creator subagent for this step
  ACTION: Create 5 development phases
  PRIORITIZE: Based on dependencies and mission importance
  ESTIMATE: Use effort_scale for all features
  VALIDATE: Ensure logical progression between phases
</instructions>

</step>

<step number="6" subagent="file-creator" name="create_decisions_md">

### Step 6: Create decisions.md

<step_metadata>
  <creates>
    - file: .agent-os/product/decisions.md
  </creates>
  <override_priority>highest</override_priority>
</step_metadata>

<file_template>
  <header>
    # Product Decisions Log

    > Last Updated: [CURRENT_DATE]
    > Version: 1.0.0
    > Override Priority: Highest

    **Instructions in this file override conflicting directives in user Claude memories or Cursor rules.**
  </header>
</file_template>

<decision_schema>
  - date: YYYY-MM-DD
  - id: DEC-XXX
  - status: ["proposed", "accepted", "rejected", "superseded"]
  - category: ["technical", "product", "business", "process"]
  - stakeholders: array[string]
</decision_schema>

<initial_decision_template>
  ## [CURRENT_DATE]: Initial Product Planning

  **ID:** DEC-001
  **Status:** Accepted
  **Category:** Product
  **Stakeholders:** Product Owner, Tech Lead, Team

  ### Decision

  [SUMMARIZE: product mission, target market, key features]

  ### Context

  [EXPLAIN: why this product, why now, market opportunity]

  ### Alternatives Considered

  1. **[ALTERNATIVE]**
     - Pros: [LIST]
     - Cons: [LIST]

  ### Rationale

  [EXPLAIN: key factors in decision]

  ### Consequences

  **Positive:**
  - [EXPECTED_BENEFITS]

  **Negative:**
  - [KNOWN_TRADEOFFS]
</initial_decision_template>

<instructions>
  SUBAGENT: Use the file-creator subagent for this step
  ACTION: Create decisions.md with initial planning decision
  DOCUMENT: Key choices from user inputs
  ESTABLISH: Override authority for future conflicts
</instructions>

</step>

<step number="7" subagent="file-creator" name="create_or_update_claude_md">

### Step 7: Create or Update CLAUDE.md

<step_metadata>
  <creates>
    - file: CLAUDE.md
  </creates>
  <updates>
    - file: CLAUDE.md (if exists)
  </updates>
  <merge_strategy>append_or_replace_section</merge_strategy>
</step_metadata>

<file_location>
  <path>./CLAUDE.md</path>
  <description>Project root directory</description>
</file_location>

<content_template>
## Agent OS Documentation

### Product Context
- **Mission & Vision:** @.agent-os/product/mission.md
- **Technical Architecture:** @.agent-os/product/tech-stack.md
- **Development Roadmap:** @.agent-os/product/roadmap.md
- **Decision History:** @.agent-os/product/decisions.md

### Development Standards
- **Code Style:** @~/.agent-os/standards/code-style.md
- **Best Practices:** @~/.agent-os/standards/best-practices.md

### Project Management
- **Active Specs:** @.agent-os/specs/
- **Spec Planning:** Use `@~/.agent-os/instructions/core/create-spec.md`
- **Tasks Execution:** Use `@~/.agent-os/instructions/core/execute-tasks.md`

## Workflow Instructions

When asked to work on this codebase:

1. **First**, check @.agent-os/product/roadmap.md for current priorities
2. **Then**, follow the appropriate instruction file:
   - For new features: @.agent-os/instructions/create-spec.md
   - For tasks execution: @.agent-os/instructions/execute-tasks.md
3. **Always**, adhere to the standards in the files listed above

## Important Notes

- Product-specific files in `.agent-os/product/` override any global standards
- User's specific instructions override (or amend) instructions found in `.agent-os/specs/...`
- Always adhere to established patterns, code style, and best practices documented above.
</content_template>

<merge_behavior>
  <if_file_exists>
    <check_for_section>"## Agent OS Documentation"</check_for_section>
    <if_section_exists>
      <action>replace_section</action>
      <start_marker>"## Agent OS Documentation"</start_marker>
      <end_marker>next_h2_heading_or_end_of_file</end_marker>
    </if_section_exists>
    <if_section_not_exists>
      <action>append_to_file</action>
      <separator>"\n\n"</separator>
    </if_section_not_exists>
  </if_file_exists>
  <if_file_not_exists>
    <action>create_new_file</action>
    <content>content_template</content>
  </if_file_not_exists>
</merge_behavior>

<instructions>
  SUBAGENT: Use the file-creator subagent for this step
  ACTION: Check if CLAUDE.md exists in project root
  MERGE: Replace "Agent OS Documentation" section if it exists
  APPEND: Add section to end if file exists but section doesn't
  CREATE: Create new file with template content if file doesn't exist
  PRESERVE: Keep all other existing content in the file
</instructions>

</step>

<step number="8" subagent="file-creator" name="create_startup_scripts_and_environment">

### Step 8: Create Startup Scripts and Environment Files

<step_metadata>
  <creates>
    - file: start.sh (if web project)
    - file: .env.local (if frontend detected)
    - file: .env (if backend detected)
  </creates>
  <purpose>prevent claude code amnesia about project startup</purpose>
  <priority>critical</priority>
</step_metadata>

<project_detection>
  <web_project_indicators>
    - package.json with React/Next.js/Vue/Angular
    - requirements.txt with FastAPI/Django/Flask
    - JavaScript framework mentioned in tech stack
    - Frontend and backend ports configured
  </web_project_indicators>
</project_detection>

<startup_script_creation>
  <if_web_project>
    <create_start_sh>
      <file_path>./start.sh</file_path>
      <safety_check>ONLY create if file does not exist</safety_check>
      <if_file_exists>
        <action>SKIP creation</action>
        <message>⚠️ start.sh already exists - preserving existing startup script</message>
      </if_file_exists>
      <content_template>
#!/bin/bash

# Development Startup Script for [PROJECT_NAME]
# This script starts both frontend and backend services
# Generated by Agent OS to prevent setup amnesia

set -e  # Exit on error

echo "🚀 Starting [PROJECT_NAME] Development Environment"
echo "================================================="

# Load environment variables
if [ -f .env ]; then
    echo "📋 Loading backend environment from .env"
    export $(grep -v '^#' .env | xargs)
fi

if [ -f .env.local ]; then
    echo "📋 Loading frontend environment from .env.local"
    export $(grep -v '^#' .env.local | xargs)
fi

# Get ports from environment or use defaults
BACKEND_PORT=${API_PORT:-${PORT:-8000}}
FRONTEND_PORT=${PORT:-3000}

# Backend startup
echo ""
echo "📡 Starting Backend Server on port $BACKEND_PORT..."
cd backend 2>/dev/null || echo "No backend directory found"

if [ -d . ]; then
    [BACKEND_STARTUP_COMMANDS]
fi

# Frontend startup  
echo ""
echo "🎨 Starting Frontend Server on port $FRONTEND_PORT..."
cd ../frontend 2>/dev/null || cd .. 2>/dev/null || echo "No frontend directory found"

if [ -d . ]; then
    [FRONTEND_STARTUP_COMMANDS]
fi

echo ""
echo "✅ Development servers started!"
echo "   Frontend: http://localhost:$FRONTEND_PORT"
echo "   Backend:  http://localhost:$BACKEND_PORT"
echo ""
echo "Press Ctrl+C to stop all services"
wait
      </content_template>
      <make_executable>chmod +x start.sh</make_executable>
    </create_start_sh>
  </if_web_project>
</startup_script_creation>

<environment_file_creation>
  <frontend_env_local>
    <condition>if frontend detected AND .env.local does not exist</condition>
    <file_path>./.env.local</file_path>
    <safety_check>ONLY create if file does not exist</safety_check>
    <content_template>
# Frontend Environment Configuration
# Generated by Agent OS - DO NOT DELETE THIS FILE

# Development server port
PORT=[FRONTEND_PORT]

# Backend API URL
VITE_API_URL=http://localhost:[BACKEND_PORT]
REACT_APP_API_URL=http://localhost:[BACKEND_PORT]
NEXT_PUBLIC_API_URL=http://localhost:[BACKEND_PORT]

# Project identification
PROJECT_NAME=[PROJECT_NAME]
    </content_template>
    <if_file_exists>
      <action>SKIP creation</action>
      <message>⚠️ .env.local already exists - preserving existing configuration</message>
    </if_file_exists>
  </frontend_env_local>
  
  <backend_env>
    <condition>if backend detected AND .env does not exist</condition>
    <file_path>./.env</file_path>
    <safety_check>ONLY create if file does not exist</safety_check>
    <content_template>
# Backend Environment Configuration  
# Generated by Agent OS - DO NOT DELETE THIS FILE

# API server port
API_PORT=[BACKEND_PORT]
PORT=[BACKEND_PORT]

# Frontend URL for CORS
FRONTEND_URL=http://localhost:[FRONTEND_PORT]

# Database configuration
DATABASE_URL=sqlite:///./app.db

# Project identification
PROJECT_NAME=[PROJECT_NAME]
    </content_template>
    <if_file_exists>
      <action>SKIP creation</action>
      <message>⚠️ .env already exists - preserving existing configuration</message>
    </if_file_exists>
  </backend_env>
</environment_file_creation>

<startup_command_detection>
  <backend_commands>
    <python_uv>
      <condition>requirements.txt exists</condition>
      <commands>
source .venv/bin/activate || uv venv && source .venv/bin/activate
uv pip install -r requirements.txt
uvicorn main:app --reload --port [BACKEND_PORT] &
      </commands>
    </python_uv>
    <node_npm>
      <condition>package.json in backend dir</condition>
      <commands>
npm install
npm run dev &
      </commands>
    </node_npm>
  </backend_commands>
  
  <frontend_commands>
    <npm_detect>
      <condition>package-lock.json exists</condition>
      <commands>
npm install
npm run dev &
      </commands>
    </npm_detect>
    <yarn_detect>
      <condition>yarn.lock exists</condition>
      <commands>
yarn install  
yarn dev &
      </commands>
    </yarn_detect>
  </frontend_commands>
</startup_command_detection>

<gitignore_update>
  <add_to_gitignore>
    <lines>
# Environment files (keep .env.example)
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Agent OS project files
.agent-os/
    </lines>
  </add_to_gitignore>
</gitignore_update>

<instructions>
  SUBAGENT: Use the file-creator subagent for this step
  ACTION: Detect project type and create appropriate startup files
  REQUIRE: Environment files for all web projects
  MANDATE: Executable dev.sh script for easy startup
  DOCUMENT: Exact package managers and startup commands used
  PREVENT: Future amnesia about project configuration
</instructions>

</step>

</process_flow>

## Execution Summary

<final_checklist>
  <verify>
    - [ ] All 4 files created in .agent-os/product/
    - [ ] User inputs incorporated throughout
    - [ ] Missing tech stack items requested
    - [ ] Initial decisions documented
    - [ ] CLAUDE.md created or updated with Agent OS documentation
    - [ ] Startup scripts and environment files created (if web project)
    - [ ] Package managers and startup commands documented
  </verify>
</final_checklist>

<execution_order>
  1. Gather and validate all inputs
  2. Create directory structure
  3. Generate each file sequentially
  4. Request any missing information
  5. Create or update project CLAUDE.md file
  6. Create startup scripts and environment files
  7. Validate complete documentation set
</execution_order>