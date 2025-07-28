---
description: Enhanced Product Planning with Subagent Integration
globs:
alwaysApply: false
version: 2.0.0
lastUpdated: 2025-01-28
encoding: UTF-8
subagent_integration: true
---

# Enhanced Product Planning with Subagents

<ai_meta>
  <parsing_rules>
    - Process XML blocks first for structured data
    - Execute instructions in sequential order
    - Integrate subagent professional insights throughout planning
    - Maintain backward compatibility with standard workflow
  </parsing_rules>
  <subagent_integration>
    - Professional PRD creation with prd-writer
    - Technical architecture validation with systems-architect
    - Deep market research with deep-research-specialist
    - Comprehensive documentation with content-marketer-writer
  </subagent_integration>
</ai_meta>

## Overview

This enhanced version of plan-product.md integrates Claude Code subagents to create professional-grade product documentation with enterprise-level depth and quality. The integration provides comprehensive market research, technical architecture validation, and professional PRD creation while maintaining full backward compatibility.

## Subagent Integration Architecture

### Professional Planning Agents

<planning_agents>
  <agent name="prd-writer">
    <purpose>Transform basic product concepts into comprehensive PRDs</purpose>
    <trigger>Product planning and mission documentation</trigger>
    <timing>After user context gathering (Step 3.5)</timing>
    <replaces>Basic mission.md creation</replaces>
  </agent>
  
  <agent name="systems-architect">
    <purpose>Technical architecture validation and system design</purpose>
    <trigger>Complex technical products or architectural decisions</trigger>
    <timing>During tech-stack.md creation (Step 4.5)</timing>
    <enhances>Technical architecture documentation</enhances>
  </agent>
  
  <agent name="deep-research-specialist">
    <purpose>Market research and competitive analysis</purpose>
    <trigger>Product planning with market positioning needs</trigger>
    <timing>Before mission creation (Step 2.5)</timing>
    <enhances>Product context and market understanding</enhances>
  </agent>
  
  <agent name="content-marketer-writer">
    <purpose>Professional documentation and communication</purpose>
    <trigger>Complex product documentation needs</trigger>
    <timing>Final documentation enhancement (Step 7.5)</timing>
    <enhances>All product documentation quality</enhances>
  </agent>
</planning_agents>

## Enhanced Workflow Process

<process_flow>

<step number="0" name="planning_enhancement_initialization">

### Step 0: Planning Enhancement Initialization

<step_metadata>
  <purpose>Initialize subagent planning enhancements</purpose>
  <required>false</required>
  <fallback>continue with standard workflow</fallback>
</step_metadata>

<enhancement_detection>
  <available_agents_check>
    1. Scan ~/.claude/agents/ for planning-relevant subagents
    2. Assess product complexity and enhancement needs
    3. Determine optimal agent utilization strategy
    4. Initialize professional planning pipeline
  </available_agents_check>
  
  <product_complexity_analysis>
    <complexity_factors>
      - Technical product complexity (enterprise vs simple tools)
      - Market competition level (established vs new markets)
      - User persona complexity (multiple segments vs single user type)
      - Business model complexity (B2B vs B2C, multi-sided markets)
      - Regulatory or compliance requirements
    </complexity_factors>
    
    <enhancement_strategy>
      <simple_products>
        - prd-writer for professional mission documentation
        - Optional: systems-architect for technical validation
      </simple_products>
      
      <complex_products>
        - deep-research-specialist for market analysis
        - prd-writer for comprehensive PRD creation
        - systems-architect for technical architecture
        - content-marketer-writer for documentation quality
      </complex_products>
    </enhancement_strategy>
  </product_complexity_analysis>
</enhancement_detection>

<instructions>
  ACTION: Detect and configure planning enhancement strategy
  FALLBACK: Continue with standard plan-product.md if no agents available
  LOG: Enhancement strategy for user transparency
</instructions>

</step>

<step number="2.5" name="market_research_enhancement">

### Step 2.5: Market Research and Competitive Analysis

<step_metadata>
  <agent>deep-research-specialist</agent>
  <trigger>Complex products requiring market positioning</trigger>
  <purpose>Professional market research and competitive analysis</purpose>
  <optional>true</optional>
</step_metadata>

<market_research_triggers>
  <complexity_indicators>
    - Competitive market with established players
    - B2B products requiring market validation
    - Novel product categories requiring education
    - Multi-market or international expansion
    - Regulatory or compliance-heavy industries
  </complexity_indicators>
  
  <research_areas>
    - Competitive landscape analysis
    - Market size and opportunity assessment
    - User behavior and preference research
    - Technology trend analysis
    - Regulatory environment research
  </research_areas>
</market_research_triggers>

<subagent_invocation>
  <condition>
    IF deep-research-specialist available AND complex_market_product
  </condition>
  
  <agent_prompt>
    I need comprehensive market research for this product planning:
    
    **Product Context:**
    - Main Idea: [USER_PROVIDED_PRODUCT_CONCEPT]
    - Target Users: [USER_PROVIDED_TARGET_USERS]
    - Key Features: [USER_PROVIDED_FEATURES]
    - Tech Stack: [USER_PROVIDED_OR_DEFAULT_TECH_STACK]
    
    **Market Research Required:**
    1. Competitive landscape analysis
       - Direct and indirect competitors
       - Feature comparison and differentiation opportunities
       - Pricing and business model analysis
       - Market positioning insights
    
    2. Market opportunity assessment
       - Total addressable market (TAM) research
       - Market trends and growth patterns
       - User behavior and preference insights
       - Technology adoption patterns
    
    3. Strategic positioning recommendations
       - Unique value proposition refinement
       - Market entry strategy insights
       - Differentiation opportunities
       - Risk assessment and mitigation
    
    **Output Requirements:**
    Provide comprehensive market intelligence that will enhance the product mission, positioning, and go-to-market strategy. Focus on actionable insights for product planning and competitive positioning.
  </agent_prompt>
  
  <integration>
    <market_intelligence>
      - Competitive landscape map
      - Market opportunity quantification
      - User persona refinement based on research
      - Differentiation strategy recommendations
      - Market positioning insights
    </market_intelligence>
    
    <planning_enhancement>
      - Enhanced product mission with market context
      - Refined target user definitions
      - Competitive differentiators identification
      - Market-validated feature prioritization
      - Go-to-market strategy foundations
    </planning_enhancement>
  </integration>
</subagent_invocation>

<instructions>
  ACTION: Conduct comprehensive market research for complex products
  CONDITION: Complex markets or competitive products
  INTEGRATION: Enhance all subsequent planning with market intelligence
  TIMING: Before mission creation for maximum impact
</instructions>

</step>

<step number="3.5" name="professional_prd_creation">

### Step 3.5: Professional PRD Creation

<step_metadata>
  <agent>prd-writer</agent>
  <trigger>Product planning requiring professional documentation</trigger>
  <purpose>Transform basic product concepts into comprehensive PRDs</purpose>
  <replaces>Basic mission.md creation (Step 3)</replaces>
</step_metadata>

<prd_enhancement_strategy>
  <comprehensive_requirements>
    - Professional user story creation with unique IDs
    - Detailed acceptance criteria for all features
    - Success metrics and KPI definition
    - Comprehensive persona development
    - Technical requirements specification
    - Business goals alignment
  </comprehensive_requirements>
  
  <professional_standards>
    - Enterprise-grade documentation quality
    - Testable and measurable requirements
    - Clear traceability from goals to features
    - Risk assessment and mitigation strategies
    - Implementation priority frameworks
  </professional_standards>
</prd_enhancement_strategy>

<subagent_invocation>
  <condition>
    IF prd-writer available
  </condition>
  
  <agent_prompt>
    I need professional PRD creation for this Agent OS product planning:
    
    **Product Planning Context:**
    - Main Idea: [USER_PROVIDED_CONCEPT]
    - Key Features: [USER_PROVIDED_FEATURES]
    - Target Users: [USER_PROVIDED_USERS]
    - Tech Stack Preferences: [USER_PROVIDED_OR_DEFAULT_STACK]
    - Market Research: [MARKET_INTELLIGENCE_IF_AVAILABLE]
    - Global Standards: @~/.agent-os/standards/tech-stack.md, @~/.agent-os/standards/best-practices.md
    
    **Professional PRD Requirements:**
    
    1. **Product Vision & Strategy**
       - Clear product vision statement
       - Business objectives and success criteria
       - Market positioning and competitive differentiation
       - Target user personas with detailed characteristics
    
    2. **Functional Requirements**
       - Comprehensive feature specifications
       - User stories with unique IDs (US-001, US-002, etc.)
       - Detailed acceptance criteria for each story
       - Priority classification (Must-Have, Should-Have, Nice-to-Have)
    
    3. **Technical Requirements**
       - System architecture considerations
       - Integration requirements
       - Performance and scalability requirements
       - Security and compliance requirements
    
    4. **Success Metrics & KPIs**
       - Quantifiable success metrics
       - User engagement indicators
       - Business impact measurements
       - Quality gates and acceptance criteria
    
    5. **Implementation Strategy**
       - Feature prioritization framework
       - Development phase planning
       - Risk assessment and mitigation
       - Go-to-market considerations
    
    **Output Format:**
    Create comprehensive mission.md that serves as a professional PRD while maintaining Agent OS format compatibility. Focus on enterprise-grade quality with complete traceability and measurable requirements.
  </agent_prompt>
  
  <integration>
    <professional_mission_md>
      # Product Mission (Professional PRD)
      
      > Last Updated: [CURRENT_DATE]
      > Version: 1.0.0
      > Document Type: Product Requirements Document (PRD)
      
      ## Executive Summary
      [PROFESSIONAL_PRODUCT_VISION_AND_STRATEGY]
      
      ## Business Objectives
      [QUANTIFIABLE_BUSINESS_GOALS_AND_SUCCESS_CRITERIA]
      
      ## Market Analysis
      [COMPETITIVE_POSITIONING_AND_MARKET_OPPORTUNITY]
      
      ## User Personas
      [DETAILED_PERSONA_SPECIFICATIONS_WITH_BEHAVIORAL_INSIGHTS]
      
      ## Functional Requirements
      [COMPREHENSIVE_USER_STORIES_WITH_ACCEPTANCE_CRITERIA]
      
      ## Technical Requirements
      [SYSTEM_ARCHITECTURE_AND_TECHNICAL_SPECIFICATIONS]
      
      ## Success Metrics
      [QUANTIFIABLE_KPIS_AND_MEASUREMENT_FRAMEWORK]
      
      ## Implementation Roadmap
      [PRIORITIZED_DEVELOPMENT_PHASES_WITH_RISK_ASSESSMENT]
    </professional_mission_md>
    
    <enhanced_planning_outputs>
      - Professional-grade user stories with unique IDs
      - Comprehensive acceptance criteria
      - Quantifiable success metrics
      - Enterprise-level persona development
      - Technical requirements specification
      - Risk-assessed implementation roadmap
    </enhanced_planning_outputs>
  </integration>
</subagent_invocation>

<instructions>
  ACTION: Create professional PRD replacing basic mission.md creation
  CONDITION: Always invoke if prd-writer available
  INTEGRATION: Professional-grade mission.md with comprehensive requirements
  QUALITY: Enterprise-level documentation standards
</instructions>

</step>

<step number="4.5" name="technical_architecture_validation">

### Step 4.5: Technical Architecture Validation

<step_metadata>
  <agent>systems-architect</agent>
  <trigger>Complex technical products or architectural decisions</trigger>
  <purpose>Professional technical architecture validation and enhancement</purpose>
  <enhances>tech-stack.md creation (Step 4)</enhances>
</step_metadata>

<architectural_complexity_detection>
  <triggers>
    - Microservices or distributed system architecture
    - High-scale or high-performance requirements
    - Complex integration requirements (multiple APIs, services)
    - Enterprise or B2B products with compliance needs
    - Novel technical approaches or emerging technologies
    - Multi-platform or cross-platform requirements
  </triggers>
  
  <architectural_concerns>
    - Scalability and performance architecture
    - Security architecture and threat modeling
    - Integration architecture and API design
    - Data architecture and storage strategy
    - Deployment and infrastructure architecture
    - Monitoring and observability architecture
  </architectural_concerns>
</architectural_complexity_detection>

<subagent_invocation>
  <condition>
    IF systems-architect available AND complex_technical_architecture
  </condition>
  
  <agent_prompt>
    I need technical architecture validation for this product planning:
    
    **Product Technical Context:**
    - Product Mission: [PROFESSIONAL_PRD_MISSION]
    - Tech Stack Choices: [USER_PROVIDED_OR_DEFAULT_TECH_STACK]
    - Scalability Requirements: [FROM_PRD_TECHNICAL_REQUIREMENTS]
    - Integration Needs: [FROM_FUNCTIONAL_REQUIREMENTS]
    - Performance Requirements: [FROM_SUCCESS_METRICS]
    - Global Tech Standards: @~/.agent-os/standards/tech-stack.md
    
    **Architecture Validation Required:**
    
    1. **System Architecture Review**
       - Validate tech stack choices against requirements
       - Identify potential scalability bottlenecks
       - Recommend architectural patterns and practices
       - Assess system complexity and maintainability
    
    2. **Integration Architecture**
       - API design strategy recommendations
       - External service integration patterns
       - Data flow and communication patterns
       - Event-driven architecture considerations
    
    3. **Infrastructure Architecture**
       - Deployment strategy recommendations
       - Infrastructure scaling approach
       - Monitoring and observability strategy
       - Disaster recovery and backup considerations
    
    4. **Security Architecture**
       - Security architecture patterns
       - Authentication and authorization strategy
       - Data protection and privacy architecture
       - Compliance and regulatory considerations
    
    5. **Performance Architecture**
       - Performance optimization strategies
       - Caching and data access patterns
       - Load balancing and distribution strategies
       - Resource optimization approaches
    
    **Output Requirements:**
    Provide comprehensive technical architecture validation that enhances the tech-stack.md with professional architectural insights, patterns, and long-term scalability considerations.
  </agent_prompt>
  
  <integration>
    <enhanced_tech_stack>
      # Technical Stack (Architectural Design)
      
      > Last Updated: [CURRENT_DATE]
      > Version: 1.0.0
      > Architecture Review: Professional Systems Architecture
      
      ## System Architecture
      [ARCHITECTURAL_PATTERNS_AND_DESIGN_DECISIONS]
      
      ## Technology Stack
      [VALIDATED_AND_ENHANCED_TECH_CHOICES]
      
      ## Integration Architecture
      [API_DESIGN_AND_INTEGRATION_PATTERNS]
      
      ## Infrastructure Architecture
      [DEPLOYMENT_AND_INFRASTRUCTURE_STRATEGY]
      
      ## Security Architecture
      [SECURITY_PATTERNS_AND_COMPLIANCE_STRATEGY]
      
      ## Performance Architecture
      [PERFORMANCE_OPTIMIZATION_AND_SCALING_STRATEGY]
      
      ## Implementation Guidelines
      [ARCHITECTURAL_BEST_PRACTICES_AND_STANDARDS]
    </enhanced_tech_stack>
    
    <architectural_decisions>
      - Validated technology choices with rationale
      - Architectural patterns and design decisions
      - Scalability and performance strategies
      - Security architecture and compliance approach
      - Integration patterns and API design
      - Infrastructure and deployment strategies
    </architectural_decisions>
  </integration>
</subagent_invocation>

<instructions>
  ACTION: Validate and enhance technical architecture for complex products
  CONDITION: Complex technical architectures or enterprise requirements
  INTEGRATION: Professional architectural insights in tech-stack.md
  TIMING: After tech stack gathering, before roadmap creation
</instructions>

</step>

<step number="5.5" name="professional_roadmap_enhancement">

### Step 5.5: Professional Roadmap Enhancement

<step_metadata>
  <purpose>Integrate subagent insights into professional roadmap creation</purpose>
  <depends_on>PRD creation and architectural validation</depends_on>
  <enhances>roadmap.md creation (Step 5)</enhances>
</step_metadata>

<roadmap_enhancement_strategy>
  <professional_inputs>
    - Market intelligence from research phase
    - Professional user stories from PRD creation
    - Technical architecture insights
    - Risk assessments and mitigation strategies
    - Business objectives and success metrics
  </professional_inputs>
  
  <enhanced_roadmap_features>
    - Evidence-based feature prioritization
    - Technical dependency mapping
    - Risk-assessed development phases
    - Market timing considerations
    - Resource and complexity estimation
    - Success milestone definitions
  </enhanced_roadmap_features>
</roadmap_enhancement_strategy>

<enhanced_roadmap_creation>
  <data_integration>
    <from_prd>
      - Professional user stories with priorities
      - Business objectives and success metrics
      - Comprehensive feature specifications
      - Risk assessments and dependencies
    </from_prd>
    
    <from_architecture>
      - Technical complexity assessments
      - Implementation dependency mapping
      - Infrastructure and scaling considerations
      - Security and compliance requirements
    </from_architecture>
    
    <from_market_research>
      - Competitive timing considerations
      - Market opportunity prioritization
      - User adoption strategy insights
      - Go-to-market milestone alignment
    </from_market_research>
  </data_integration>
  
  <professional_roadmap_structure>
    ## Phase 0: Foundation & Architecture
    **Goal:** Establish technical foundation and core architecture
    **Success Criteria:** [MEASURABLE_TECHNICAL_MILESTONES]
    **Business Impact:** [QUANTIFIED_BUSINESS_VALUE]
    
    ### Must-Have Features (Technical Foundation)
    - [ ] [ARCHITECTURAL_FOUNDATION_FEATURE] - [TECHNICAL_RATIONALE] `[EFFORT_WITH_CONFIDENCE]`
    
    ### Dependencies & Risks
    - Technical: [ARCHITECTURAL_DEPENDENCIES]
    - Business: [MARKET_TIMING_CONSIDERATIONS]
    - Resource: [TEAM_AND_INFRASTRUCTURE_NEEDS]
    
    ### Success Metrics
    - [QUANTIFIABLE_TECHNICAL_METRICS]
    - [MEASURABLE_BUSINESS_OUTCOMES]
    
    ## Phase 1: Core MVP (Market Validation)
    [CONTINUE_WITH_PROFESSIONAL_STRUCTURE]
  </professional_roadmap_structure>
</enhanced_roadmap_creation>

<instructions>
  ACTION: Create professional roadmap integrating all subagent insights
  INTEGRATION: Market research, PRD insights, and architectural considerations
  QUALITY: Evidence-based prioritization with quantifiable success metrics
  TIMING: After all planning enhancements are complete
</instructions>

</step>

<step number="7.5" name="documentation_quality_enhancement">

### Step 7.5: Documentation Quality Enhancement

<step_metadata>
  <agent>content-marketer-writer</agent>
  <trigger>Complex product documentation requiring professional quality</trigger>
  <purpose>Enhance all documentation for professional presentation</purpose>
  <optional>true</optional>
</step_metadata>

<documentation_enhancement_scope>
  <target_documents>
    - mission.md (Professional PRD)
    - tech-stack.md (Technical Architecture)
    - roadmap.md (Strategic Roadmap)
    - decisions.md (Decision Documentation)
    - CLAUDE.md (Project Integration)
  </target_documents>
  
  <enhancement_areas>
    - Professional writing quality and clarity
    - Consistent terminology and style
    - Executive summary and key insights
    - Visual formatting and readability
    - Cross-document coherence and flow
  </enhancement_areas>
</documentation_enhancement_scope>

<subagent_invocation>
  <condition>
    IF content-marketer-writer available AND professional_documentation_needed
  </condition>
  
  <agent_prompt>
    I need professional documentation enhancement for this Agent OS product planning:
    
    **Documentation Set:**
    - Mission/PRD: @.agent-os/product/mission.md
    - Technical Architecture: @.agent-os/product/tech-stack.md
    - Strategic Roadmap: @.agent-os/product/roadmap.md
    - Decision Log: @.agent-os/product/decisions.md
    - Project Integration: CLAUDE.md
    
    **Enhancement Requirements:**
    
    1. **Professional Writing Quality**
       - Clear, concise, and engaging writing
       - Consistent terminology and style
       - Executive-level communication quality
       - Technical accuracy with business clarity
    
    2. **Document Coherence**
       - Consistent narrative across all documents
       - Cross-references and integration points
       - Logical flow and structure
       - Professional formatting and presentation
    
    3. **Stakeholder Communication**
       - Executive summary sections for key documents
       - Clear value propositions and business cases
       - Technical concepts explained for business audiences
       - Actionable insights and recommendations
    
    4. **Documentation Standards**
       - Professional document structure
       - Consistent formatting and style
       - Clear headings and navigation
       - Comprehensive but concise content
    
    **Output Requirements:**
    Enhance all product documentation to enterprise-grade professional quality while maintaining Agent OS format compatibility and technical accuracy.
  </agent_prompt>
  
  <integration>
    <documentation_enhancements>
      - Professional writing quality across all documents
      - Consistent style and terminology
      - Executive summaries for key insights
      - Enhanced readability and presentation
      - Cross-document coherence and integration
    </documentation_enhancements>
    
    <professional_standards>
      - Enterprise-grade documentation quality
      - Stakeholder-appropriate communication levels
      - Clear business value articulation
      - Technical concepts accessible to all audiences
      - Professional formatting and structure
    </professional_standards>
  </integration>
</subagent_invocation>

<instructions>
  ACTION: Enhance all documentation to professional enterprise standards
  CONDITION: Professional or enterprise product documentation needs
  INTEGRATION: Apply enhancements across entire documentation set
  TIMING: Final step before completion for maximum impact
</instructions>

</step>

</process_flow>

## Professional Planning Outcomes

<enhanced_planning_results>
  <professional_prd>
    <quality_standards>
      - Enterprise-grade product requirements documentation
      - Comprehensive user stories with unique IDs and acceptance criteria
      - Quantifiable success metrics and KPIs
      - Professional persona development with behavioral insights
      - Risk-assessed implementation roadmap
    </quality_standards>
    
    <business_value>
      - Clear business objectives and success criteria
      - Market-validated product positioning
      - Evidence-based feature prioritization
      - Professional stakeholder communication
    </business_value>
  </professional_prd>
  
  <technical_architecture>
    <architectural_quality>
      - Professional system architecture validation
      - Scalability and performance considerations
      - Security architecture and compliance strategy
      - Integration patterns and API design
      - Infrastructure and deployment strategies
    </architectural_quality>
    
    <technical_value>
      - Long-term architectural sustainability
      - Risk-mitigated technology choices
      - Professional development standards
      - Scalable and maintainable system design
    </technical_value>
  </technical_architecture>
  
  <market_intelligence>
    <research_quality>
      - Comprehensive competitive landscape analysis
      - Market opportunity quantification
      - User behavior and preference insights
      - Technology trend analysis and positioning
    </research_quality>
    
    <strategic_value>
      - Evidence-based market positioning
      - Competitive differentiation strategies
      - Market timing and opportunity insights
      - Risk-assessed go-to-market strategies
    </strategic_value>
  </market_intelligence>
</enhanced_planning_results>

## Fallback Strategy

<fallback_behavior>
  <no_subagents_available>
    Continue with standard plan-product.md workflow
    Log that professional enhancements are unavailable
    Maintain full compatibility with original process
    Provide standard Agent OS planning quality
  </no_subagents_available>
  
  <partial_subagents_available>
    Use available agents for applicable enhancements
    Skip enhancement steps for unavailable agents
    Maintain workflow continuity
    Provide partial professional enhancement
  </partial_subagents_available>
  
  <subagent_errors>
    Log errors but continue with standard workflow
    Provide error context for troubleshooting
    Never block standard workflow execution
    Fall back to basic planning documentation
  </subagent_errors>
</fallback_behavior>

## Professional Quality Standards

<quality_metrics>
  <documentation_quality>
    - Enterprise-grade writing and presentation
    - Comprehensive requirements coverage
    - Professional stakeholder communication
    - Technical accuracy with business clarity
  </documentation_quality>
  
  <planning_quality>
    - Evidence-based decision making
    - Market-validated product positioning
    - Risk-assessed implementation strategies
    - Quantifiable success metrics and KPIs
  </planning_quality>
  
  <technical_quality>
    - Professional architectural validation
    - Scalable and maintainable system design
    - Security and compliance considerations
    - Performance and optimization strategies
  </technical_quality>
  
  <business_quality>
    - Clear business objectives and value propositions
    - Market opportunity analysis and positioning
    - Competitive differentiation strategies
    - Professional go-to-market considerations
  </business_quality>
</quality_metrics>

This enhanced workflow transforms Agent OS product planning from good structured documentation into **enterprise-grade product strategy and planning** with professional PRD quality, comprehensive market intelligence, validated technical architecture, and stakeholder-ready documentation that drives successful product development from day one.