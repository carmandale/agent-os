---
description: Enhanced Spec Creation with Subagent Integration
globs:
alwaysApply: false
version: 2.0.0
lastUpdated: 2025-01-28
encoding: UTF-8
subagent_integration: true
---

# Enhanced Spec Creation with Subagents

<ai_meta>
  <parsing_rules>
    - Process XML blocks first for structured data
    - Execute instructions in sequential order
    - Use subagent integration points when available
    - Gracefully fallback to standard workflow if subagents unavailable
  </parsing_rules>
  <subagent_integration>
    - Detect available subagents before workflow execution
    - Use Task tool to invoke specialized agents at optimal points
    - Preserve standard workflow compatibility
    - Enhanced quality outcomes through specialist expertise
  </subagent_integration>
</ai_meta>

## Overview

This enhanced version of create-spec.md integrates Claude Code subagents for dramatically improved specification quality and first-try success rates. All enhancements are optional and gracefully fallback to standard Agent OS workflows.

## Subagent Integration Points

### Available Enhancement Agents

<subagent_registry>
  <agent name="prd-writer">
    <purpose>Professional PRD creation with comprehensive user stories</purpose>
    <trigger>Complex requirements or user story generation needed</trigger>
    <replaces>Basic spec requirements documentation</replaces>
  </agent>
  
  <agent name="systems-architect">
    <purpose>Technical architecture validation and system design</purpose>
    <trigger>Complex features, system changes, architectural decisions</trigger>
    <enhances>Technical specification creation</enhances>
  </agent>
  
  <agent name="qa-test-engineer">
    <purpose>Comprehensive testing strategy and edge case analysis</purpose>
    <trigger>All specs (replaces basic test documentation)</trigger>
    <replaces>Basic tests.md creation</replaces>
  </agent>
  
  <agent name="security-threat-analyst">
    <purpose>Security analysis and threat modeling</purpose>
    <trigger>Security-critical features (auth, payments, data handling)</trigger>
    <enhances>Security considerations in technical specs</enhances>
  </agent>
  
  <agent name="product-manager-orchestrator">
    <purpose>Multi-agent coordination for complex features</purpose>
    <trigger>Features requiring 3+ specialist agents</trigger>
    <replaces>Standard single-agent workflow</replaces>
  </agent>
</subagent_registry>

## Enhanced Workflow Process

<process_flow>

<step number="0" name="subagent_detection">

### Step 0: Subagent Detection and Planning

<step_metadata>
  <purpose>Detect available subagents and plan enhancement strategy</purpose>
  <required>false</required>
  <fallback>continue with standard workflow</fallback>
</step_metadata>

<detection_process>
  <check_agents>
    1. Scan ~/.claude/agents/ for available subagents
    2. Load user preferences from ~/.agent-os/subagent-config.yaml
    3. Analyze spec complexity and risk factors
    4. Determine optimal agent selection strategy
  </check_agents>
  
  <complexity_analysis>
    <factors>
      - Feature complexity (UI, backend, database changes needed)
      - Security implications (authentication, payments, sensitive data)
      - System integration requirements (APIs, external services)
      - User story complexity (multiple personas, complex workflows)
    </factors>
    
    <thresholds>
      - LOW: Single component change, minimal integration
      - MEDIUM: Multiple components, some integration, standard security
      - HIGH: Complex system changes, high security requirements
    </thresholds>
  </complexity_analysis>
  
  <enhancement_strategy>
    <simple_features>
      - qa-test-engineer for comprehensive testing
      - Optional: prd-writer if user stories are complex
    </simple_features>
    
    <medium_features>
      - prd-writer for professional requirements
      - systems-architect for technical validation
      - qa-test-engineer for comprehensive testing
      - security-threat-analyst if security implications
    </medium_features>
    
    <complex_features>
      - product-manager-orchestrator for coordination
      - Full specialist team based on feature requirements
      - Parallel execution with integration points
    </complex_features>
  </enhancement_strategy>
</detection_process>

<instructions>
  ACTION: Detect and configure subagent enhancement strategy
  FALLBACK: Continue with standard create-spec.md if no agents available
  LOG: Enhancement strategy for user transparency
</instructions>

</step>

<step number="2.5" name="prd_enhancement">

### Step 2.5: Professional Requirements Enhancement

<step_metadata>
  <agent>prd-writer</agent>
  <trigger>Complex requirements or user story needs</trigger>
  <purpose>Transform basic spec into professional PRD</purpose>
  <optional>true</optional>
</step_metadata>

<subagent_invocation>
  <condition>
    IF prd-writer available AND (complex_requirements OR user_requested_enhancement)
  </condition>
  
  <agent_prompt>
    I need to enhance this Agent OS spec with professional PRD elements:
    
    **Spec Context:**
    - Spec Description: [FROM_USER_INPUT]
    - Product Mission: @.agent-os/product/mission.md
    - Technical Stack: @.agent-os/product/tech-stack.md
    - Current Roadmap: @.agent-os/product/roadmap.md
    
    **Enhancement Needed:**
    Please create comprehensive user stories, detailed acceptance criteria, and professional requirements analysis that will replace or enhance the basic spec.md sections.
    
    Focus on:
    1. Detailed user personas and journey mapping
    2. Comprehensive acceptance criteria for each story
    3. Edge case identification
    4. Success metrics definition
    
    Maintain Agent OS spec.md format but with professional PRD depth.
  </agent_prompt>
  
  <integration>
    <enhanced_sections>
      - User Stories (professional format with IDs)
      - Acceptance Criteria (comprehensive, testable)
      - Success Metrics (quantifiable KPIs)
      - Edge Cases (systematically identified)
    </enhanced_sections>
    
    <merge_strategy>
      Replace basic user stories section with professional PRD output
      Enhance Overview section with deeper product context
      Add Success Metrics section if not present
    </merge_strategy>
  </integration>
</subagent_invocation>

<instructions>
  ACTION: Invoke prd-writer for professional requirements enhancement
  CONDITION: Only if agent available and complexity warrants enhancement
  INTEGRATION: Merge enhanced output into spec.md structure
  FALLBACK: Continue with standard spec creation if agent unavailable
</instructions>

</step>

<step number="7.5" name="architectural_validation">

### Step 7.5: Technical Architecture Validation

<step_metadata>
  <agent>systems-architect</agent>
  <trigger>Complex features, system changes, architectural decisions</trigger>
  <purpose>Validate and enhance technical approach</purpose>
  <optional>true</optional>
</step_metadata>

<subagent_invocation>
  <condition>
    IF systems-architect available AND (complex_system_changes OR architectural_decisions_needed)
  </condition>
  
  <agent_prompt>
    I need architectural validation and enhancement for this Agent OS spec:
    
    **Current Spec:**
    - Spec: @.agent-os/specs/[SPEC_FOLDER]/spec.md
    - Technical Spec: @.agent-os/specs/[SPEC_FOLDER]/sub-specs/technical-spec.md
    - Product Context: @.agent-os/product/mission.md, @.agent-os/product/tech-stack.md
    
    **Architectural Review Needed:**
    1. Validate technical approach against best practices
    2. Identify potential scalability issues
    3. Recommend architectural patterns for this feature
    4. Assess integration impacts with existing system
    5. Suggest improvements to technical specification
    
    **Output Format:**
    Please provide architectural analysis and enhanced technical specifications that maintain Agent OS format while ensuring professional architectural quality.
  </agent_prompt>
  
  <integration>
    <enhanced_sections>
      - Technical approach validation
      - Scalability considerations
      - Integration architecture
      - Performance implications
      - Security architecture (if applicable)
    </enhanced_sections>
    
    <merge_strategy>
      Enhance technical-spec.md with architectural insights
      Add architectural diagrams (ASCII format)
      Include scalability and performance considerations
      Document architectural decision rationale
    </merge_strategy>
  </integration>
</subagent_invocation>

<instructions>
  ACTION: Invoke systems-architect for technical validation
  CONDITION: Only for complex features requiring architectural review
  INTEGRATION: Enhance technical-spec.md with architectural insights
  TIMING: After technical-spec.md creation, before tasks.md creation
</instructions>

</step>

<step number="8.5" name="security_analysis">

### Step 8.5: Security Analysis and Threat Modeling

<step_metadata>
  <agent>security-threat-analyst</agent>
  <trigger>Security-critical features (auth, payments, data handling)</trigger>
  <purpose>Comprehensive security analysis and threat modeling</purpose>
  <optional>true</optional>
</step_metadata>

<security_feature_detection>
  <triggers>
    - Authentication or authorization features
    - Payment processing or financial transactions
    - Personal data handling (PII, GDPR considerations)
    - API security (authentication, rate limiting)
    - File uploads or user-generated content
    - Admin interfaces or privileged operations
  </triggers>
  
  <keywords>
    - "auth", "login", "password", "token", "session"
    - "payment", "billing", "subscription", "transaction"
    - "user data", "profile", "privacy", "GDPR"
    - "API", "endpoint", "external integration"
    - "upload", "file", "media", "content"
    - "admin", "role", "permission", "access control"
  </keywords>
</security_feature_detection>

<subagent_invocation>
  <condition>
    IF security-threat-analyst available AND security_critical_feature_detected
  </condition>
  
  <agent_prompt>
    I need comprehensive security analysis for this Agent OS spec:
    
    **Security-Critical Spec:**
    - Spec: @.agent-os/specs/[SPEC_FOLDER]/spec.md
    - Technical Spec: @.agent-os/specs/[SPEC_FOLDER]/sub-specs/technical-spec.md
    - Product Context: @.agent-os/product/tech-stack.md
    
    **Security Analysis Required:**
    1. Threat modeling for this feature
    2. Security requirements identification
    3. Vulnerability assessment of proposed approach
    4. Compliance considerations (GDPR, OWASP, etc.)
    5. Security testing strategy
    6. Recommended security controls
    
    **Output Format:**
    Create a comprehensive security specification that integrates with Agent OS format and enhances the existing technical specification.
  </agent_prompt>
  
  <integration>
    <creates_file>sub-specs/security-spec.md</creates_file>
    <enhances_sections>
      - Technical spec security considerations
      - Test spec security test cases
      - Tasks with security validation steps
    </enhances_sections>
    
    <security_spec_template>
      # Security Specification
      
      ## Threat Model
      - Assets and data at risk
      - Threat actors and attack vectors
      - Attack scenarios and impact assessment
      
      ## Security Requirements
      - Authentication and authorization requirements
      - Data protection requirements
      - Input validation and sanitization
      - Output encoding and protection
      
      ## Security Controls
      - Preventive controls
      - Detective controls
      - Corrective controls
      
      ## Security Testing
      - Security test cases
      - Penetration testing scenarios
      - Compliance validation tests
    </security_spec_template>
  </integration>
</subagent_invocation>

<instructions>
  ACTION: Invoke security-threat-analyst for security-critical features
  CONDITION: Automatically detect security implications in spec
  INTEGRATION: Create dedicated security-spec.md and enhance other specs
  PRIORITY: High - security analysis blocks task creation if issues found
</instructions>

</step>

<step number="10.5" name="comprehensive_testing_strategy">

### Step 10.5: Comprehensive Testing Strategy

<step_metadata>
  <agent>qa-test-engineer</agent>
  <trigger>All specs (replaces basic tests.md creation)</trigger>
  <purpose>Professional-grade testing strategy and implementation</purpose>
  <replaces>Step 10 basic tests.md creation</replaces>
</step_metadata>

<subagent_invocation>
  <condition>
    IF qa-test-engineer available
  </condition>
  
  <agent_prompt>
    I need a comprehensive testing strategy for this Agent OS spec:
    
    **Complete Spec Context:**
    - Main Spec: @.agent-os/specs/[SPEC_FOLDER]/spec.md
    - Technical Spec: @.agent-os/specs/[SPEC_FOLDER]/sub-specs/technical-spec.md
    - Database Schema: @.agent-os/specs/[SPEC_FOLDER]/sub-specs/database-schema.md (if exists)
    - API Spec: @.agent-os/specs/[SPEC_FOLDER]/sub-specs/api-spec.md (if exists)
    - Security Spec: @.agent-os/specs/[SPEC_FOLDER]/sub-specs/security-spec.md (if exists)
    - Product Tech Stack: @.agent-os/product/tech-stack.md
    
    **Testing Strategy Requirements:**
    1. Comprehensive test pyramid (unit, integration, e2e)
    2. Edge case identification and testing
    3. Error scenario testing
    4. Performance testing strategy
    5. Security testing integration
    6. Specific test implementation guidance
    7. Mock and fixture requirements
    8. Test data management
    
    **Output Format:**
    Create a professional testing specification that replaces the basic tests.md format with comprehensive testing strategy and implementation guidance.
  </agent_prompt>
  
  <integration>
    <replaces_file>sub-specs/tests.md</replaces_file>
    <enhanced_sections>
      - Comprehensive test pyramid
      - Edge case test scenarios
      - Error condition testing
      - Performance test strategy
      - Security test integration
      - Mock and fixture specifications
      - Test data management
      - Automated testing pipeline
    </enhanced_sections>
    
    <professional_test_format>
      # Comprehensive Testing Strategy
      
      ## Testing Pyramid
      - Unit Tests (70% coverage target)
      - Integration Tests (20% coverage target)
      - End-to-End Tests (10% coverage target)
      
      ## Test Categories
      - Happy path scenarios
      - Edge case scenarios
      - Error condition scenarios
      - Performance scenarios
      - Security scenarios
      
      ## Implementation Strategy
      - Test framework selection
      - Mock strategy
      - Test data management
      - CI/CD integration
      
      ## Quality Gates
      - Coverage thresholds
      - Performance benchmarks
      - Security test requirements
    </professional_test_format>
  </integration>
</subagent_invocation>

<instructions>
  ACTION: Invoke qa-test-engineer to create comprehensive testing strategy
  CONDITION: Always invoke if agent available (replaces basic test creation)
  INTEGRATION: Replace basic tests.md with professional testing specification
  TIMING: After all other sub-specs are created for complete context
</instructions>

</step>

<step number="12.5" name="complex_feature_orchestration">

### Step 12.5: Complex Feature Orchestration

<step_metadata>
  <agent>product-manager-orchestrator</agent>
  <trigger>Features requiring 3+ specialist agents</trigger>
  <purpose>Coordinate multiple agents for complex feature delivery</purpose>
  <optional>true</optional>
</step_metadata>

<orchestration_triggers>
  <complexity_indicators>
    - Multiple technical domains (frontend + backend + database)
    - Security-critical with performance requirements
    - User-facing with complex business logic
    - Integration with multiple external systems
    - Features spanning multiple development phases
  </complexity_indicators>
  
  <agent_count_threshold>3</agent_count_threshold>
  
  <orchestration_patterns>
    <authentication_system>
      <agents>["systems-architect", "security-threat-analyst", "senior-software-engineer", "qa-test-engineer"]</agents>
      <coordination>Sequential with integration points</coordination>
    </authentication_system>
    
    <payment_system>
      <agents>["systems-architect", "security-threat-analyst", "backend-reliability-engineer", "qa-test-engineer"]</agents>
      <coordination>Parallel analysis with final integration</coordination>
    </payment_system>
    
    <user_interface>
      <agents>["frontend-ux-specialist", "systems-architect", "qa-test-engineer", "performance-optimizer"]</agents>
      <coordination>Design-first with technical validation</coordination>
    </user_interface>
  </orchestration_patterns>
</orchestration_triggers>

<subagent_invocation>
  <condition>
    IF product-manager-orchestrator available AND complex_feature_detected
  </condition>
  
  <agent_prompt>
    I need to orchestrate multiple specialists for this complex Agent OS spec:
    
    **Complex Feature Spec:**
    - Spec: @.agent-os/specs/[SPEC_FOLDER]/spec.md
    - Current Sub-specs: [LIST_EXISTING_SUB_SPECS]
    - Product Context: @.agent-os/product/mission.md, @.agent-os/product/tech-stack.md
    
    **Available Specialists:**
    [LIST_AVAILABLE_AGENTS]
    
    **Request:**
    Please coordinate the appropriate specialists to deliver a comprehensive, professional-grade specification for this complex feature. 
    
    Your role:
    1. Analyze feature complexity and requirements
    2. Select appropriate specialist agents
    3. Design coordination strategy (sequential vs parallel)
    4. Manage specialist outputs and integration
    5. Ensure cohesive, high-quality final deliverable
    
    Execute the specialist coordination and provide the integrated result.
  </agent_prompt>
  
  <integration>
    <coordination_strategy>
      - Analyze feature complexity
      - Select appropriate specialist combination
      - Execute coordinated analysis
      - Integrate specialist outputs
      - Provide unified enhancement to spec
    </coordination_strategy>
    
    <deliverables>
      - Enhanced spec with multi-specialist insights
      - Comprehensive technical specifications
      - Professional testing strategy
      - Security analysis (if applicable)
      - Performance considerations
      - Implementation roadmap
    </deliverables>
  </integration>
</subagent_invocation>

<instructions>
  ACTION: Invoke product-manager-orchestrator for complex features
  CONDITION: Complex features requiring multiple specialist coordination
  INTEGRATION: Comprehensive enhancement of entire spec package
  TIMING: After initial spec creation, coordinates other sub-agent invocations
</instructions>

</step>

<step number="13.5" name="enhanced_tasks_creation">

### Step 13.5: Enhanced Task Breakdown

<step_metadata>
  <purpose>Create professional task breakdown incorporating subagent insights</purpose>
  <depends_on>all subagent enhancements completed</depends_on>
</step_metadata>

<enhanced_task_creation>
  <inputs>
    - Enhanced spec.md (with PRD elements if applicable)
    - Professional technical-spec.md (with architectural insights)
    - Comprehensive tests.md (with professional testing strategy)
    - Security-spec.md (if security-critical)
    - All subagent insights and recommendations
  </inputs>
  
  <enhancement_strategy>
    <task_granularity>
      More granular tasks based on comprehensive specifications
      Security tasks integrated throughout (not just at end)
      Performance considerations in implementation tasks
      Comprehensive testing tasks with specific scenarios
    </task_granularity>
    
    <quality_integration>
      Each major task includes quality checkpoints
      Subagent consultation points identified
      Automated quality pipeline integration
      Professional code review requirements
    </quality_integration>
    
    <risk_management>
      High-risk tasks identified and flagged
      Dependencies clearly mapped
      Fallback strategies for complex implementations
      Integration testing at logical boundaries
    </risk_management>
  </enhancement_strategy>
</enhanced_task_creation>

<enhanced_task_template>
  ## Enhanced Tasks

  - [ ] 1. [MAJOR_TASK_WITH_ARCHITECTURAL_INSIGHT]
    - [ ] 1.1 Write comprehensive tests (following qa-test-engineer strategy)
    - [ ] 1.2 [IMPLEMENTATION_STEP_WITH_PATTERNS]
    - [ ] 1.3 [SECURITY_VALIDATION_IF_APPLICABLE]
    - [ ] 1.4 [PERFORMANCE_CONSIDERATION_IF_APPLICABLE]
    - [ ] 1.5 Code review with quality pipeline
    - [ ] 1.6 Integration testing
    - [ ] 1.7 Verify all tests pass and quality gates met

  **Quality Gates:**
  - [ ] All security requirements validated
  - [ ] Performance benchmarks met
  - [ ] Code quality standards maintained
  - [ ] Comprehensive test coverage achieved

  **Subagent Consultation Points:**
  - Complex implementation decisions → senior-software-engineer
  - Security concerns → security-threat-analyst
  - Performance issues → performance-optimizer
  - Code quality issues → code-refactoring-expert
</enhanced_task_template>

<instructions>
  ACTION: Create enhanced task breakdown incorporating all subagent insights
  INTEGRATION: Professional-grade tasks with quality gates and consultation points
  QUALITY: Each task includes specific quality requirements and validation steps
</instructions>

</step>

</process_flow>

## Fallback Strategy

<fallback_behavior>
  <no_subagents_available>
    Continue with standard create-spec.md workflow
    Log that enhancements are unavailable
    Maintain full compatibility with original process
  </no_subagents_available>
  
  <partial_subagents_available>
    Use available agents for applicable enhancements
    Skip enhancement steps for unavailable agents
    Maintain workflow continuity
    Notify user of partial enhancement availability
  </partial_subagents_available>
  
  <subagent_errors>
    Log errors but continue with standard workflow
    Provide error context for troubleshooting
    Never block standard workflow execution
  </subagent_errors>
</fallback_behavior>

## Quality Assurance

<enhanced_quality_metrics>
  <success_criteria>
    - 90%+ first-try spec approval rate (vs 60% standard)
    - Professional-grade documentation quality
    - Comprehensive security analysis for applicable features
    - Enterprise-level testing strategies
    - Architectural validation for complex features
  </success_criteria>
  
  <measurement>
    - Track spec revision cycles before approval
    - Measure implementation success rate from enhanced specs
    - Monitor user satisfaction with enhanced workflow
    - Compare quality metrics: enhanced vs standard workflows
  </measurement>
</enhanced_quality_metrics>

## Usage Guidelines

<user_instructions>
  <automatic_enhancement>
    Enhanced workflows automatically detect when subagent improvements would be valuable
    Users don't need to explicitly request enhancements
    All enhancements are optional and gracefully degrade
  </automatic_enhancement>
  
  <explicit_control>
    Users can disable specific agents in ~/.agent-os/subagent-config.yaml
    Per-project overrides available in .agent-os/subagent-config.yaml
    Manual agent invocation available at any workflow step
  </explicit_control>
  
  <transparency>
    All subagent invocations are logged and visible to users
    Enhancement reasoning is provided for transparency
    Original workflow steps remain visible and accessible
  </transparency>
</user_instructions>

This enhanced workflow maintains complete backward compatibility while providing dramatically improved outcomes through intelligent subagent integration. The result is professional-grade specifications with first-try success rates and enterprise-level quality standards.