---
description: Enhanced Task Execution with Subagent Integration
globs:
alwaysApply: false
version: 2.0.0
lastUpdated: 2025-01-28
encoding: UTF-8
subagent_integration: true
---

# Enhanced Task Execution with Subagents

<ai_meta>
  <parsing_rules>
    - Process XML blocks first for structured data
    - Execute instructions in sequential order
    - Integrate subagent quality pipeline throughout execution
    - Maintain backward compatibility with standard workflow
  </parsing_rules>
  <subagent_integration>
    - Quality pipeline with multiple specialist agents
    - Architectural guidance for complex implementations
    - Continuous code review and improvement
    - Performance optimization integration
    - Security validation throughout development
  </subagent_integration>
</ai_meta>

## Overview

This enhanced version of execute-tasks.md integrates Claude Code subagents throughout the development process, providing continuous quality assurance, architectural guidance, and professional-grade implementation support. All enhancements gracefully fallback to standard workflows when subagents are unavailable.

## Subagent Integration Architecture

### Quality Pipeline Agents

<quality_pipeline>
  <agent name="senior-software-engineer">
    <purpose>Architectural guidance and complex feature implementation</purpose>
    <trigger>Complex implementation tasks, architectural decisions</trigger>
    <timing>During development execution (Step 6)</timing>
  </agent>
  
  <agent name="qa-test-engineer">
    <purpose>Comprehensive testing implementation and validation</purpose>
    <trigger>Test creation and validation steps</trigger>
    <timing>Test implementation and Step 8 quality checks</timing>
  </agent>
  
  <agent name="code-refactoring-expert">
    <purpose>Code quality improvement and technical debt prevention</purpose>
    <trigger>Code quality issues detected</trigger>
    <timing>During and after implementation</timing>
  </agent>
  
  <agent name="security-threat-analyst">
    <purpose>Security validation and threat prevention</purpose>
    <trigger>Security-critical implementations</trigger>
    <timing>Throughout development for security features</timing>
  </agent>
  
  <agent name="performance-optimizer">
    <purpose>Performance analysis and optimization</purpose>
    <trigger>Performance-critical features or issues detected</trigger>
    <timing>After implementation, before quality assurance</timing>
  </agent>
</quality_pipeline>

## Enhanced Workflow Process

<process_flow>

<step number="0" name="quality_pipeline_initialization">

### Step 0: Quality Pipeline Initialization

<step_metadata>
  <purpose>Initialize subagent quality pipeline for enhanced development</purpose>
  <required>false</required>
  <fallback>continue with standard workflow</fallback>
</step_metadata>

<pipeline_initialization>
  <detection>
    1. Check available subagents in ~/.claude/agents/
    2. Load quality pipeline configuration
    3. Analyze task complexity and requirements
    4. Initialize appropriate quality agents
  </detection>
  
  <task_analysis>
    <complexity_factors>
      - Implementation complexity (algorithms, integrations)
      - Security implications (authentication, data handling)
      - Performance requirements (scale, response times)
      - Code quality factors (refactoring, technical debt)
    </complexity_factors>
    
    <agent_selection>
      <simple_tasks>
        - qa-test-engineer for comprehensive testing
        - Optional quality checks based on code changes
      </simple_tasks>
      
      <complex_tasks>
        - senior-software-engineer for architectural guidance
        - qa-test-engineer for comprehensive testing
        - code-refactoring-expert for quality assurance
        - Conditional: security-threat-analyst, performance-optimizer
      </complex_tasks>
    </agent_selection>
  </task_analysis>
  
  <pipeline_configuration>
    <quality_gates>
      - Code quality threshold: maintainability, readability
      - Test coverage threshold: comprehensive scenarios
      - Security validation: threat model compliance
      - Performance benchmarks: response time, efficiency
    </quality_gates>
    
    <integration_points>
      - Pre-implementation: architectural guidance
      - During implementation: continuous quality checking
      - Post-implementation: comprehensive validation
      - Pre-commit: final quality pipeline execution
    </integration_points>
  </pipeline_configuration>
</pipeline_initialization>

<instructions>
  ACTION: Initialize quality pipeline based on available agents and task complexity
  FALLBACK: Continue with standard execute-tasks.md if no agents available
  LOG: Quality pipeline configuration for transparency
</instructions>

</step>

<step number="3.5" name="architectural_implementation_planning">

### Step 3.5: Architectural Implementation Planning

<step_metadata>
  <agent>senior-software-engineer</agent>
  <trigger>Complex implementation tasks requiring architectural thinking</trigger>
  <purpose>Professional architectural guidance for complex features</purpose>
  <optional>true</optional>
</step_metadata>

<complexity_detection>
  <triggers>
    - Multi-service integration requirements
    - Complex algorithm implementation
    - Significant architectural changes
    - Performance-critical implementations
    - Integration with external systems
    - Database schema changes with business logic
  </triggers>
  
  <complexity_indicators>
    - Task spans multiple system components
    - Requires new patterns or architectural decisions
    - High performance or scalability requirements
    - Complex business logic implementation
    - Security-critical implementations
  </complexity_indicators>
</complexity_detection>

<subagent_invocation>
  <condition>
    IF senior-software-engineer available AND complex_implementation_detected
  </condition>
  
  <agent_prompt>
    I need architectural implementation guidance for this Agent OS task execution:
    
    **Implementation Context:**
    - Current Task: [TASK_DESCRIPTION]
    - Spec: @.agent-os/specs/[SPEC_FOLDER]/spec.md
    - Technical Spec: @.agent-os/specs/[SPEC_FOLDER]/sub-specs/technical-spec.md
    - Codebase Context: [EXISTING_PATTERNS_AND_ARCHITECTURE]
    - Tech Stack: @.agent-os/product/tech-stack.md
    
    **Architectural Guidance Needed:**
    1. Implementation approach validation
    2. Architectural patterns recommendation
    3. Integration strategy with existing code
    4. Performance and scalability considerations
    5. Code organization and structure
    6. Error handling and edge case strategy
    7. Testing approach for complex features
    
    **Request:**
    Provide professional architectural guidance that balances technical excellence with pragmatic delivery. Focus on maintainable, scalable implementation that follows established patterns.
    
    Output should include:
    - Implementation strategy with clear phases
    - Code organization recommendations
    - Integration patterns with existing architecture
    - Risk mitigation for complex aspects
    - Quality checkpoints throughout implementation
  </agent_prompt>
  
  <integration>
    <enhanced_planning>
      - Detailed implementation strategy
      - Architectural pattern recommendations
      - Code organization structure
      - Integration approach with existing systems
      - Risk mitigation strategies
      - Quality validation checkpoints
    </enhanced_planning>
    
    <implementation_guidance>
      - Phase-by-phase implementation plan
      - Specific patterns and practices to follow
      - Error handling and edge case strategies
      - Performance optimization opportunities
      - Testing strategy integration
    </implementation_guidance>
  </integration>
</subagent_invocation>

<instructions>
  ACTION: Invoke senior-software-engineer for complex implementation guidance
  CONDITION: Complex features requiring architectural thinking
  INTEGRATION: Enhance implementation plan with professional architectural guidance
  TIMING: After standard planning, before development execution
</instructions>

</step>

<step number="6.5" name="continuous_quality_assurance">

### Step 6.5: Continuous Quality Assurance During Development

<step_metadata>
  <agents>["code-refactoring-expert", "qa-test-engineer"]</agents>
  <trigger>During development execution</trigger>
  <purpose>Continuous quality monitoring and improvement</purpose>
  <timing>parallel with development</timing>
</step_metadata>

<continuous_quality_process>
  <monitoring_points>
    - After each significant code change
    - Before completing each subtask
    - When complex logic is implemented
    - After integration with existing code
  </monitoring_points>
  
  <quality_checks>
    <code_quality>
      <agent>code-refactoring-expert</agent>
      <triggers>
        - Code complexity increases beyond thresholds
        - Duplication detected
        - Anti-patterns identified
        - Technical debt accumulation
      </triggers>
      <actions>
        - Immediate refactoring recommendations
        - Code structure improvements
        - Pattern application suggestions
        - Technical debt prevention
      </actions>
    </code_quality>
    
    <test_quality>
      <agent>qa-test-engineer</agent>
      <triggers>
        - New functionality implementation
        - Edge cases discovered during development
        - Integration points created
        - Error handling implemented
      </triggers>
      <actions>
        - Test coverage analysis
        - Additional test scenarios identification
        - Test quality improvements
        - Edge case validation
      </actions>
    </test_quality>
  </quality_checks>
</continuous_quality_process>

<subagent_invocation>
  <parallel_execution>
    <code_quality_agent>
      <agent>code-refactoring-expert</agent>
      <prompt>
        Monitor this implementation for code quality issues:
        
        **Current Implementation:**
        [CURRENT_CODE_CHANGES]
        
        **Quality Analysis Needed:**
        1. Code complexity and maintainability
        2. Duplication and DRY principle adherence
        3. Design pattern application
        4. Technical debt prevention
        5. Code organization and structure
        
        **Provide:**
        - Immediate refactoring recommendations
        - Code quality improvements
        - Pattern suggestions for better structure
        - Technical debt prevention strategies
        
        Focus on maintaining high code quality throughout development process.
      </prompt>
    </code_quality_agent>
    
    <test_quality_agent>
      <agent>qa-test-engineer</agent>
      <prompt>
        Validate and enhance testing for this implementation:
        
        **Implementation Context:**
        [CURRENT_IMPLEMENTATION_STATE]
        
        **Test Quality Analysis:**
        1. Test coverage completeness
        2. Edge case coverage
        3. Error scenario testing
        4. Integration test adequacy
        5. Test quality and maintainability
        
        **Provide:**
        - Additional test scenarios needed
        - Test quality improvements
        - Edge case identification
        - Integration testing enhancements
        
        Ensure comprehensive testing throughout development.
      </prompt>
    </test_quality_agent>
  </parallel_execution>
</subagent_invocation>

<instructions>
  ACTION: Continuously monitor and improve code and test quality during development
  AGENTS: code-refactoring-expert and qa-test-engineer in parallel
  INTEGRATION: Apply recommendations immediately during development
  FREQUENCY: At logical development checkpoints
</instructions>

</step>

<step number="7.5" name="security_validation_pipeline">

### Step 7.5: Security Validation Pipeline

<step_metadata>
  <agent>security-threat-analyst</agent>
  <trigger>Security-critical implementations</trigger>
  <purpose>Continuous security validation throughout development</purpose>
  <optional>true</optional>
</step_metadata>

<security_feature_detection>
  <automatic_triggers>
    - Authentication or authorization code
    - Data validation and sanitization
    - API endpoint implementations
    - Database query implementations
    - File upload or processing logic
    - External integration implementations
    - Cryptographic operations
    - Session management code
  </automatic_triggers>
  
  <security_patterns>
    - Input validation implementations
    - Output encoding and sanitization
    - Authentication mechanisms
    - Authorization checks
    - Data protection implementations
    - Error handling that might leak information
  </security_patterns>
</security_feature_detection>

<subagent_invocation>
  <condition>
    IF security-threat-analyst available AND security_critical_implementation
  </condition>
  
  <agent_prompt>
    I need continuous security validation for this implementation:
    
    **Security-Critical Implementation:**
    - Current Code: [SECURITY_CRITICAL_CODE]
    - Implementation Context: [FEATURE_SECURITY_CONTEXT]
    - Security Spec: @.agent-os/specs/[SPEC_FOLDER]/sub-specs/security-spec.md (if exists)
    - Tech Stack Security: @.agent-os/product/tech-stack.md
    
    **Security Validation Required:**
    1. Code-level security analysis
    2. Vulnerability identification
    3. Security best practices compliance
    4. Input validation and sanitization verification
    5. Authentication and authorization correctness
    6. Data protection implementation validation
    7. Security testing recommendations
    
    **Provide:**
    - Immediate security issues identification
    - Code-level security improvements
    - Security testing enhancements
    - Compliance verification
    
    Focus on preventing security vulnerabilities through secure implementation practices.
  </agent_prompt>
  
  <integration>
    <security_validation>
      - Real-time vulnerability detection
      - Security best practices enforcement
      - Secure coding pattern recommendations
      - Security test enhancement suggestions
    </security_validation>
    
    <security_quality_gates>
      - No high-severity vulnerabilities
      - Input validation completeness
      - Output encoding correctness
      - Authentication/authorization accuracy
      - Data protection compliance
    </security_quality_gates>
  </integration>
</subagent_invocation>

<instructions>
  ACTION: Continuously validate security throughout implementation
  CONDITION: Security-critical features or patterns detected
  INTEGRATION: Apply security improvements immediately
  BLOCKING: High-severity security issues must be resolved before proceeding
</instructions>

</step>

<step number="8.5" name="performance_optimization_pipeline">

### Step 8.5: Performance Optimization Pipeline

<step_metadata>
  <agent>performance-optimizer</agent>
  <trigger>Performance-critical implementations or issues detected</trigger>
  <purpose>Performance analysis and optimization</purpose>
  <optional>true</optional>
</step_metadata>

<performance_detection>
  <automatic_triggers>
    - Database query implementations
    - API endpoint implementations
    - Large data processing logic
    - Complex algorithm implementations
    - Rendering or UI performance code
    - Caching implementations
    - External service integrations
  </automatic_triggers>
  
  <performance_indicators>
    - Complex database operations
    - Nested loops or recursive operations
    - Large data set processing
    - Network request implementations
    - File system operations
    - Memory-intensive operations
  </performance_indicators>
</performance_detection>

<subagent_invocation>
  <condition>
    IF performance-optimizer available AND performance_critical_implementation
  </condition>
  
  <agent_prompt>
    I need performance analysis and optimization for this implementation:
    
    **Performance-Critical Implementation:**
    - Current Code: [PERFORMANCE_CRITICAL_CODE]
    - Implementation Context: [PERFORMANCE_REQUIREMENTS]
    - Technical Spec: @.agent-os/specs/[SPEC_FOLDER]/sub-specs/technical-spec.md
    - Tech Stack: @.agent-os/product/tech-stack.md
    
    **Performance Analysis Required:**
    1. Performance bottleneck identification
    2. Optimization opportunities analysis
    3. Scalability assessment
    4. Resource usage optimization
    5. Caching strategy recommendations
    6. Database query optimization
    7. Performance testing strategy
    
    **Provide:**
    - Performance improvement recommendations
    - Optimization implementation guidance
    - Performance testing enhancements
    - Scalability considerations
    
    Focus on achieving optimal performance while maintaining code quality and maintainability.
  </agent_prompt>
  
  <integration>
    <performance_optimization>
      - Performance bottleneck identification
      - Optimization recommendations
      - Scalability improvements
      - Caching strategy implementation
      - Resource usage optimization
    </performance_optimization>
    
    <performance_quality_gates>
      - Response time benchmarks met
      - Resource usage within limits
      - Scalability requirements satisfied
      - Performance tests passing
    </performance_quality_gates>
  </integration>
</subagent_invocation>

<instructions>
  ACTION: Analyze and optimize performance for critical implementations
  CONDITION: Performance-critical features or bottlenecks detected
  INTEGRATION: Apply performance optimizations during implementation
  VALIDATION: Performance benchmarks must be met before completion
</instructions>

</step>

<step number="8.75" name="comprehensive_quality_pipeline">

### Step 8.75: Comprehensive Quality Pipeline Execution

<step_metadata>
  <purpose>Execute full quality pipeline before final validation</purpose>
  <agents>["code-refactoring-expert", "qa-test-engineer", "security-threat-analyst", "performance-optimizer"]</agents>
  <timing>Before Step 8 quality assurance verification</timing>
  <replaces>Basic quality checks</replaces>
</step_metadata>

<quality_pipeline_execution>
  <pipeline_stages>
    <stage name="code_quality" blocking="false">
      <agent>code-refactoring-expert</agent>
      <purpose>Final code quality validation and improvement</purpose>
      <criteria>
        - Code maintainability standards met
        - Technical debt minimized
        - Design patterns properly applied
        - Code duplication eliminated
      </criteria>
    </stage>
    
    <stage name="test_quality" blocking="true">
      <agent>qa-test-engineer</agent>
      <purpose>Comprehensive test validation</purpose>
      <criteria>
        - Test coverage meets standards
        - Edge cases thoroughly tested
        - Error scenarios covered
        - Integration tests comprehensive
      </criteria>
    </stage>
    
    <stage name="security_validation" blocking="true">
      <agent>security-threat-analyst</agent>
      <purpose>Final security validation</purpose>
      <condition>security-critical features</condition>
      <criteria>
        - No high-severity vulnerabilities
        - Security best practices followed
        - Threat model compliance verified
        - Security tests comprehensive
      </criteria>
    </stage>
    
    <stage name="performance_validation" blocking="false">
      <agent>performance-optimizer</agent>
      <purpose>Performance benchmark validation</purpose>
      <condition>performance-critical features</condition>
      <criteria>
        - Performance benchmarks met
        - Resource usage optimized
        - Scalability requirements satisfied
        - Performance tests passing
      </criteria>
    </stage>
  </pipeline_stages>
  
  <execution_strategy>
    <parallel_execution>
      Run non-blocking stages in parallel for efficiency
      Execute blocking stages sequentially
      Aggregate results for comprehensive quality report
    </parallel_execution>
    
    <failure_handling>
      - Blocking failures halt execution
      - Non-blocking failures generate warnings
      - All issues must be addressed before proceeding
      - Quality report generated for transparency
    </failure_handling>
  </execution_strategy>
</quality_pipeline_execution>

<comprehensive_quality_prompt>
  Execute comprehensive quality pipeline for completed implementation:
  
  **Implementation Summary:**
  - Completed Tasks: [TASK_SUMMARY]
  - Code Changes: [CODE_CHANGE_SUMMARY]
  - Test Implementation: [TEST_SUMMARY]
  - Security Considerations: [SECURITY_SUMMARY]
  - Performance Aspects: [PERFORMANCE_SUMMARY]
  
  **Quality Pipeline Execution:**
  Please execute your specialized quality analysis:
  
  **For code-refactoring-expert:**
  - Final code quality assessment
  - Technical debt evaluation
  - Refactoring recommendations for future
  
  **For qa-test-engineer:**
  - Comprehensive test validation
  - Coverage analysis and gaps identification
  - Test quality assessment
  
  **For security-threat-analyst (if applicable):**
  - Final security validation
  - Vulnerability assessment
  - Security compliance verification
  
  **For performance-optimizer (if applicable):**
  - Performance benchmark validation
  - Optimization verification
  - Scalability assessment
  
  **Required Output:**
  - Quality assessment summary
  - Issues identified (blocking vs non-blocking)
  - Recommendations for improvement
  - Quality gate pass/fail status
</comprehensive_quality_prompt>

<instructions>
  ACTION: Execute comprehensive quality pipeline with all available agents
  BLOCKING: Address all blocking issues before proceeding
  INTEGRATION: Replace Step 8 basic quality checks with comprehensive pipeline
  REPORTING: Generate detailed quality report for transparency
</instructions>

</step>

<step number="9.5" name="enhanced_git_workflow">

### Step 9.5: Enhanced Git Workflow with Quality Integration

<step_metadata>
  <purpose>Git workflow enhanced with quality pipeline results</purpose>
  <depends_on>comprehensive quality pipeline completion</depends_on>
</step_metadata>

<enhanced_git_process>
  <quality_integration>
    <commit_enhancement>
      - Include quality metrics in commit messages
      - Reference quality pipeline results
      - Document any quality exceptions or technical debt
    </commit_enhancement>
    
    <pr_enhancement>
      <quality_summary>
        - Code quality assessment results
        - Test coverage metrics
        - Security validation status
        - Performance benchmark results
      </quality_summary>
      
      <subagent_insights>
        - Architectural decisions made
        - Security considerations addressed
        - Performance optimizations applied
        - Code quality improvements implemented
      </subagent_insights>
    </pr_enhancement>
  </quality_integration>
  
  <professional_pr_template>
    ## Summary
    [FEATURE_DESCRIPTION]
    
    **Fixes #[ISSUE_NUMBER]**
    
    ## Implementation Details
    [IMPLEMENTATION_APPROACH_WITH_ARCHITECTURAL_INSIGHTS]
    
    ## Quality Pipeline Results
    - **Code Quality**: ✅ All standards met
    - **Test Coverage**: ✅ [X]% coverage, all scenarios tested
    - **Security Validation**: ✅ No vulnerabilities detected
    - **Performance**: ✅ All benchmarks met
    
    ## Subagent Contributions
    - **Architecture**: [SENIOR_SOFTWARE_ENGINEER_INSIGHTS]
    - **Testing**: [QA_TEST_ENGINEER_ENHANCEMENTS]
    - **Security**: [SECURITY_THREAT_ANALYST_VALIDATION]
    - **Performance**: [PERFORMANCE_OPTIMIZER_IMPROVEMENTS]
    
    ## Changes Made
    - [HIGH_LEVEL_CHANGE_1]
    - [HIGH_LEVEL_CHANGE_2]
    
    ## Testing
    - [COMPREHENSIVE_TEST_COVERAGE_SUMMARY]
    - All quality gates passed ✓
    
    ## Issue Status
    - [ ] Update issue with implementation details
    - [ ] Close issue when PR is merged
  </professional_pr_template>
</enhanced_git_process>

<instructions>
  ACTION: Create enhanced git workflow integrating quality pipeline results
  INTEGRATION: Include subagent insights in commit messages and PR descriptions
  QUALITY: Document quality metrics and validation results
  PROFESSIONALISM: Generate enterprise-grade documentation
</instructions>

</step>

</process_flow>

## Fallback Strategy

<fallback_behavior>
  <no_subagents_available>
    Continue with standard execute-tasks.md workflow
    Log that quality enhancements are unavailable
    Maintain full compatibility with original process
    Provide standard quality assurance (Step 8)
  </no_subagents_available>
  
  <partial_subagents_available>
    Use available agents for applicable quality checks
    Skip enhancement steps for unavailable agents
    Maintain workflow continuity
    Provide partial quality pipeline execution
  </partial_subagents_available>
  
  <subagent_errors>
    Log errors but continue with standard workflow
    Provide error context for troubleshooting
    Never block standard workflow execution
    Fall back to manual quality checks
  </subagent_errors>
  
  <quality_pipeline_failures>
    <blocking_failures>
      - Security vulnerabilities (high severity)
      - Test failures
      - Critical performance issues
      ACTION: Stop execution, require fixes
    </blocking_failures>
    
    <non_blocking_failures>
      - Code quality recommendations
      - Performance optimizations
      - Minor security improvements
      ACTION: Log warnings, allow continuation
    </non_blocking_failures>
  </quality_pipeline_failures>
</fallback_behavior>

## Enhanced Quality Standards

<enhanced_quality_metrics>
  <code_quality>
    - Maintainability index > 80
    - Cyclomatic complexity < 10 per method
    - Code duplication < 5%
    - Technical debt ratio < 10%
  </code_quality>
  
  <test_quality>
    - Line coverage > 80%
    - Branch coverage > 75%
    - Edge case coverage comprehensive
    - Error scenario coverage complete
  </test_quality>
  
  <security_quality>
    - Zero high-severity vulnerabilities
    - OWASP Top 10 compliance
    - Input validation comprehensive
    - Output encoding complete
  </security_quality>
  
  <performance_quality>
    - Response time < defined SLAs
    - Memory usage within limits
    - Database query optimization applied
    - Caching strategy implemented
  </performance_quality>
</enhanced_quality_metrics>

## Professional Development Outcomes

<professional_outcomes>
  <first_try_success>
    Target: 95% first-try implementation success
    Measurement: Implementations requiring no major revisions
    Baseline: 60% with standard workflow
  </first_try_success>
  
  <code_quality_improvement>
    Target: Enterprise-grade code quality
    Measurement: Automated quality metrics
    Benefits: Reduced technical debt, easier maintenance
  </code_quality_improvement>
  
  <security_assurance>
    Target: Zero security vulnerabilities in production
    Measurement: Security scan results
    Benefits: Risk reduction, compliance achievement
  </security_assurance>
  
  <performance_optimization>
    Target: Optimal performance from first implementation
    Measurement: Performance benchmark compliance
    Benefits: Reduced optimization cycles, better user experience
  </performance_optimization>
  
  <comprehensive_testing>
    Target: Production-ready test coverage
    Measurement: Test quality metrics and edge case coverage
    Benefits: Reduced bugs, confidence in deployments
  </comprehensive_testing>
</professional_outcomes>

This enhanced workflow transforms Agent OS task execution from a good structured approach into a **professional development powerhouse** that delivers enterprise-grade code quality, comprehensive security validation, and optimal performance from the first implementation attempt.