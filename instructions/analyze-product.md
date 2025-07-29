---
description: Analyze Current Product & Install Agent OS
globs:
alwaysApply: false
version: 1.0
encoding: UTF-8
---

# Analyze Current Product & Install Agent OS

<ai_meta>
  <parsing_rules>
    - Process XML blocks first for structured data
    - Execute instructions in sequential order
    - Use templates as exact patterns
    - Analyze existing code before generating documentation
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
  - Install Agent OS into an existing codebase
  - Analyze current product state and progress
  - Generate documentation that reflects actual implementation
  - Preserve existing architectural decisions
</purpose>

<context>
  - Part of Agent OS framework
  - Used when retrofitting Agent OS to established products
  - Builds on plan-product.md with codebase analysis
</context>

<prerequisites>
  - Existing product codebase
  - Write access to project root
  - Access to @~/.agent-os/instructions/plan-product.md
</prerequisites>

<process_flow>

<step number="0" name="mandatory_execution_acknowledgment">

### Step 0: Mandatory Execution Acknowledgment

<step_metadata>
  <purpose>ensure this workflow is being executed properly</purpose>
  <blocking>true - prevents casual responses</blocking>
</step_metadata>

<execution_verification>
  <requirement>
    Claude MUST immediately output:
    
    🔍 **EXECUTING /analyze-product WORKFLOW**
    
    I'm now executing the complete Agent OS analyze-product workflow to:
    1. Analyze your existing codebase thoroughly
    2. Gather product context through questions
    3. Install Agent OS with accurate documentation
    4. Set up all required configuration files
    
    This is NOT a casual code review - this is the full Agent OS installation process.
  </requirement>
  <enforcement>
    If Claude catches itself doing casual file listing or exploration instead:
    - STOP immediately
    - State: "I need to properly execute the analyze-product workflow"
    - START this instruction file from the beginning
  </enforcement>
</execution_verification>

<instructions>
  ACTION: Output the execution acknowledgment FIRST
  PREVENT: Casual "let me look at your files" responses
  ENSURE: Full workflow execution
</instructions>

</step>

<step number="1" name="analyze_existing_codebase">

### Step 1: Analyze Existing Codebase

<step_metadata>
  <action>deep codebase analysis</action>
  <purpose>understand current state before documentation</purpose>
</step_metadata>

<analysis_areas>
  <project_structure>
    - Directory organization
    - File naming patterns
    - Module structure
    - Build configuration
  </project_structure>
  <technology_stack>
    - Frameworks in use
    - Dependencies (package.json, Gemfile, requirements.txt, etc.)
    - Database systems
    - Infrastructure configuration
  </technology_stack>
  <implementation_progress>
    - Completed features
    - Work in progress
    - Authentication/authorization state
    - API endpoints
    - Database schema
  </implementation_progress>
  <code_patterns>
    - Coding style in use
    - Naming conventions
    - File organization patterns
    - Testing approach
  </code_patterns>
  <documentation_sources>
    - .cursorrules file content
    - README.md claims
    - CLAUDE.md if present
    - package.json scripts and configs
    - Any setup documentation
  </documentation_sources>
</analysis_areas>

<reality_check>
  <package_manager>
    - Check for: package-lock.json (npm), yarn.lock (yarn), pnpm-lock.yaml (pnpm)
    - Check package.json scripts for manager-specific commands
    - Note actual manager in use vs documented
  </package_manager>
  <language_versions>
    - Python: Check .python-version, pyproject.toml, runtime.txt
    - Node: Check .nvmrc, .node-version, engines in package.json
    - Note actual versions vs documented
  </language_versions>
  <framework_versions>
    - Extract from package.json, requirements.txt, Gemfile.lock
    - Compare major versions with any documentation
  </framework_versions>
</reality_check>

<instructions>
  ACTION: Thoroughly analyze the existing codebase
  DOCUMENT: Current technologies, features, and patterns
  IDENTIFY: Architectural decisions already made
  NOTE: Development progress and completed work
  CAPTURE: Documentation claims from all sources
  VERIFY: What's actually in use vs what's documented
</instructions>

</step>

<step number="2" name="organizational_standards_comparison">

### Step 2: Organizational Standards Comparison

<step_metadata>
  <compares>project reality with organizational standards</step_metadata>
  <reports>discrepancies for user decision</reports>
</step_metadata>

<standards_check>
  <read_standards>
    - @~/.agent-os/standards/tech-stack.md
    - @~/.agent-os/standards/code-style.md  
    - @~/.agent-os/standards/best-practices.md
  </read_standards>
  <compare_against_project>
    - Package manager standards vs project reality
    - Language version standards vs project versions
    - Framework version standards vs project dependencies
    - Code style standards vs project patterns
    - Best practices vs current implementation
  </compare_against_project>
</standards_check>

<discrepancy_detection>
  <package_manager_conflicts>
    <if_standards_specify>yarn</if_standards_specify>
    <but_project_has>package-lock.json (npm)</but_project_has>
    <or_cursorrules_says>npm</or_cursorrules_says>
    <flag_conflict>true</flag_conflict>
  </package_manager_conflicts>
  <language_version_conflicts>
    <if_standards_specify>Python 3.12 with uv</if_standards_specify>
    <but_project_has>requirements.txt (pip) and Python 3.9</but_project_has>
    <flag_conflict>true</flag_conflict>
  </language_version_conflicts>
  <framework_version_conflicts>
    <if_standards_specify>React 18+</if_standards_specify>
    <but_project_has>React 16.8.0</but_project_has>
    <flag_conflict>true</flag_conflict>
  </framework_version_conflicts>
</discrepancy_detection>

<discrepancy_report_template>
  ⚠️  **DISCREPANCY REPORT - Project vs Organization Standards**
  
  {FOR_EACH_CONFLICT}
  
  **{CONFLICT_NUMBER}. {CONFLICT_TITLE}:**
  - **Org Standard** (~/.agent-os): {STANDARD_VALUE}
  - **Project Reality**: {ACTUAL_PROJECT_STATE}
  - **Project Docs say**: {DOCUMENTATION_CLAIMS}
  
  **Options:**
  a) Align project with org standard ({MIGRATION_ACTION})
  b) Keep current project approach ({EXCEPTION_REASON})
  c) Update org standard ({STANDARD_CHANGE})
  
  → **Your choice [a/b/c]:** ___
  
  {END_FOR_EACH}
</discrepancy_report_template>

<issue_creation_offers>
  <when_user_chooses_alignment>
    <offer>Create GitHub issue for migration work?</offer>
    <example_title>"Migrate from npm to yarn per org standards"</example_title>
    <example_title>"Upgrade Python 3.9 → 3.12 and pip → uv"</example_title>
    <example_title>"Upgrade React 16 → 18 per org standards"</example_title>
  </when_user_chooses_alignment>
</issue_creation_offers>

<exception_documentation>
  <when_user_chooses_exception>
    <offer>Document this exception in decisions.md?</offer>
    <example_reason>"Python 3.9 required due to AWS Lambda compatibility"</example_reason>
    <example_reason>"npm required due to legacy CI/CD pipeline constraints"</example_reason>
  </when_user_chooses_exception>
</exception_documentation>

<instructions>
  ACTION: Compare project reality against organizational standards
  DETECT: Mismatches between standards, reality, and documentation
  REPORT: All discrepancies in structured format
  OFFER: Solutions for each conflict (align, except, or update standards)
  CREATE: Issues or document exceptions based on user choices
  PROCEED: Only after all discrepancies are resolved or acknowledged
</instructions>

</step>

<step number="3" name="gather_product_context">

### Step 3: Gather Product Context

<step_metadata>
  <supplements>codebase analysis</supplements>
  <gathers>business context and future plans</gathers>
</step_metadata>

<context_questions>
  Based on my analysis of your codebase, I can see you're building [OBSERVED_PRODUCT_TYPE].

  To properly set up Agent OS, I need to understand:

  1. **Product Vision**: What problem does this solve? Who are the target users?

  2. **Current State**: Are there features I should know about that aren't obvious from the code?

  3. **Roadmap**: What features are planned next? Any major refactoring planned?

  4. **Decisions**: Are there important technical or product decisions I should document?

  5. **Team Preferences**: Any coding standards or practices the team follows that I should capture?
</context_questions>

<instructions>
  ACTION: Ask user for product context
  COMBINE: Merge user input with codebase analysis
  PREPARE: Information for plan-product.md execution
</instructions>

</step>

<step number="4" name="execute_plan_product">

### Step 4: Execute Plan-Product with Context

<step_metadata>
  <uses>@~/.agent-os/instructions/plan-product.md</uses>
  <modifies>standard flow for existing products</modifies>
</step_metadata>

<execution_parameters>
  <main_idea>[DERIVED_FROM_ANALYSIS_AND_USER_INPUT]</main_idea>
  <key_features>[IDENTIFIED_IMPLEMENTED_AND_PLANNED_FEATURES]</key_features>
  <target_users>[FROM_USER_CONTEXT]</target_users>
  <tech_stack>[DETECTED_FROM_CODEBASE]</tech_stack>
</execution_parameters>

<execution_prompt>
  @~/.agent-os/instructions/plan-product.md

  I'm installing Agent OS into an existing product. Here's what I've gathered:

  **Main Idea**: [SUMMARY_FROM_ANALYSIS_AND_CONTEXT]

  **Key Features**:
  - Already Implemented: [LIST_FROM_ANALYSIS]
  - Planned: [LIST_FROM_USER]

  **Target Users**: [FROM_USER_RESPONSE]

  **Tech Stack**: [DETECTED_STACK_WITH_VERSIONS]
</execution_prompt>

<instructions>
  ACTION: Execute plan-product.md with gathered information
  PROVIDE: All context as structured input
  ALLOW: plan-product.md to create .agent-os/product/ structure
</instructions>

</step>

<step number="5" name="customize_generated_files">

### Step 5: Customize Generated Documentation

<step_metadata>
  <refines>generated documentation</refines>
  <ensures>accuracy for existing product</ensures>
</step_metadata>

<customization_tasks>
  <roadmap_adjustment>
    - Mark completed features as done
    - Move implemented items to "Phase 0: Already Completed"
    - Adjust future phases based on actual progress
  </roadmap_adjustment>
  <tech_stack_verification>
    - Verify detected versions are correct
    - Add any missing infrastructure details  
    - Document actual deployment setup
    - Configure development server ports
  </tech_stack_verification>
  
  <port_configuration_prompt>
    ## Development Port Configuration
    
    I've analyzed your project. Let's set up development server ports:
    
    **Detected Services:**
    [LIST_DETECTED_FRONTEND_AND_BACKEND]
    
    **Recommended Ports:**
    - Frontend dev server: 3000 (or 3001, 3002... if you have multiple projects)
    - Backend API server: 8000 (or 8001, 8002... if you have multiple projects)
    
    What ports should this project use? (Enter for defaults: 3000 frontend, 8000 backend)
    
    **Note**: This will create/update environment files:
    - Frontend: `.env.local` with PORT and API_URL
    - Backend: `.env` with API_PORT
  </port_configuration_prompt>
  <decisions_documentation>
    - Add historical decisions that shaped current architecture
    - Document why certain technologies were chosen
    - Capture any pivots or major changes
  </decisions_documentation>
</customization_tasks>

<roadmap_template>
  ## Phase 0: Already Completed

  The following features have been implemented:

  - [x] [FEATURE_1] - [DESCRIPTION_FROM_CODE]
  - [x] [FEATURE_2] - [DESCRIPTION_FROM_CODE]
  - [x] [FEATURE_3] - [DESCRIPTION_FROM_CODE]

  ## Phase 1: Current Development

  - [ ] [IN_PROGRESS_FEATURE] - [DESCRIPTION]

  [CONTINUE_WITH_STANDARD_PHASES]
</roadmap_template>

<instructions>
  ACTION: Update generated files to reflect reality
  MODIFY: Roadmap to show completed work
  VERIFY: Tech stack matches actual implementation
  ADD: Historical context to decisions.md
</instructions>

</step>

<step number="6" name="final_verification">

### Step 6: Final Verification and Summary

<step_metadata>
  <verifies>installation completeness</verifies>
  <provides>next steps for user</provides>
</step_metadata>

<verification_checklist>
  - [ ] .agent-os/product/ directory created
  - [ ] All product documentation reflects actual codebase
  - [ ] Roadmap shows completed and planned features accurately
  - [ ] Tech stack matches installed dependencies
  - [ ] CLAUDE.md or .cursorrules configured (if applicable)
</verification_checklist>

<summary_template>
  ## ✅ Agent OS Successfully Installed

  I've analyzed your [PRODUCT_TYPE] codebase, reconciled discrepancies with organizational standards, and set up Agent OS with documentation that reflects your actual implementation.

  ### What I Found

  - **Tech Stack**: [SUMMARY_OF_DETECTED_STACK]
  - **Completed Features**: [COUNT] features already implemented
  - **Code Style**: [DETECTED_PATTERNS]
  - **Current Phase**: [IDENTIFIED_DEVELOPMENT_STAGE]

  ### Discrepancies Resolved

  [IF_ANY_DISCREPANCIES_FOUND]
  - **Resolved**: [COUNT] conflicts between org standards and project reality
  - **Issues Created**: [LIST_OF_MIGRATION_ISSUES]
  - **Exceptions Documented**: [LIST_OF_DOCUMENTED_EXCEPTIONS]
  [ELSE]
  - ✅ Project aligns perfectly with organizational standards
  [END_IF]

  ### What Was Created

  - ✓ Product documentation in `.agent-os/product/`
  - ✓ Roadmap with completed work in Phase 0
  - ✓ Tech stack reflecting actual dependencies
  - ✓ Decision log with discrepancy resolutions

  ### Next Steps

  1. Review the generated documentation in `.agent-os/product/`
  2. Address any migration issues created during reconciliation
  3. See the Agent OS README for usage instructions: https://github.com/carmandale/agent-os
  4. Start using Agent OS for your next feature:
     ```
     @~/.agent-os/instructions/create-spec.md
     ```

  Your codebase is now Agent OS-enabled with organizational alignment! 🚀
</summary_template>

<instructions>
  ACTION: Verify all files created correctly
  SUMMARIZE: What was found and created
  PROVIDE: Clear next steps for user
</instructions>

</step>

</process_flow>

## Error Handling

<error_scenarios>
  <scenario name="no_clear_structure">
    <condition>Cannot determine project type or structure</condition>
    <action>Ask user for clarification about project</action>
  </scenario>
  <scenario name="conflicting_patterns">
    <condition>Multiple coding styles detected</condition>
    <action>Ask user which pattern to document</action>
  </scenario>
  <scenario name="missing_dependencies">
    <condition>Cannot determine full tech stack</condition>
    <action>List detected technologies and ask for missing pieces</action>
  </scenario>
</error_scenarios>

## Execution Summary

<final_checklist>
  <verify>
    - [ ] Codebase analyzed thoroughly
    - [ ] Organizational standards compared with project reality
    - [ ] All discrepancies detected and resolved or documented
    - [ ] Migration issues created for alignment work (if applicable)
    - [ ] Exceptions documented in decisions.md (if applicable)
    - [ ] User context gathered
    - [ ] plan-product.md executed with proper context
    - [ ] Documentation customized for existing product
    - [ ] Team can adopt Agent OS workflow with clear standards
  </verify>
</final_checklist>
