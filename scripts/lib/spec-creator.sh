#!/bin/bash
# Spec Creator Library
# Functions for creating and managing Agent OS specification directories

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" >&2
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" >&2
}

log_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

# ============================================================================
# Spec Name Validation and Sanitization
# ============================================================================

validate_spec_name() {
    local spec_name="$1"
    
    # Check for empty name
    if [[ -z "$spec_name" ]]; then
        log_error "Spec name cannot be empty"
        return 1
    fi
    
    # Check for minimum length
    if [[ ${#spec_name} -lt 3 ]]; then
        log_error "Spec name must be at least 3 characters"
        return 1
    fi
    
    # Check for invalid characters
    if [[ "$spec_name" =~ [/\.] ]]; then
        log_error "Spec name cannot contain '/' or '.' characters"
        return 1
    fi
    
    return 0
}

sanitize_spec_name() {
    local spec_name="$1"
    
    # Convert to lowercase, replace spaces and special chars with hyphens
    local sanitized
    sanitized=$(echo "$spec_name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g' | sed 's/^-+\|-+$//g')
    
    echo "$sanitized"
}

# ============================================================================
# Spec Directory Generation
# ============================================================================

generate_spec_directory() {
    local spec_name="$1"
    local issue_number="${2:-}"
    
    if ! validate_spec_name "$spec_name"; then
        return 1
    fi
    
    local sanitized_name
    sanitized_name=$(sanitize_spec_name "$spec_name")
    
    local current_date
    current_date=$(date +%Y-%m-%d)
    
    local spec_dir_name
    if [[ -n "$issue_number" ]]; then
        spec_dir_name="${current_date}-${sanitized_name}-#${issue_number}"
    else
        spec_dir_name="${current_date}-${sanitized_name}"
    fi
    
    echo "$spec_dir_name"
}

check_spec_directory_exists() {
    local spec_dir="$1"
    
    if [[ -d ".agent-os/specs/$spec_dir" ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Spec Directory and File Creation
# ============================================================================

create_spec_directory() {
    local spec_dir="$1"
    
    # Create the directory structure
    mkdir -p ".agent-os/specs/$spec_dir/sub-specs"
    
    # Create essential template files if they don't exist
    local tasks_file=".agent-os/specs/$spec_dir/tasks.md"
    if [[ ! -f "$tasks_file" ]]; then
        # Extract feature name from spec_dir for template
        local feature_name
        feature_name=$(echo "$spec_dir" | sed 's/^[0-9-]*-//' | sed 's/-#[0-9]*$//' | tr '-' ' ')
        create_tasks_template "$spec_dir" "$feature_name"
    fi
    
    log_info "Created spec directory: $spec_dir"
    return 0
}

setup_spec_structure() {
    local spec_dir="$1"
    
    create_spec_directory "$spec_dir"
    
    # Create .gitkeep for empty sub-specs directory
    touch ".agent-os/specs/$spec_dir/sub-specs/.gitkeep"
    
    log_success "Set up complete spec structure for: $spec_dir"
    return 0
}

# ============================================================================
# Template Generation
# ============================================================================

create_spec_template() {
    local spec_dir="$1"
    local feature_name="$2"
    local issue_number="${3:-}"
    
    local spec_file=".agent-os/specs/$spec_dir/spec.md"
    
    # Don't overwrite existing spec files
    if [[ -f "$spec_file" ]]; then
        log_warning "Spec file already exists, skipping: $spec_file"
        return 0
    fi
    
    local current_date
    current_date=$(date +%Y-%m-%d)
    
    cat > "$spec_file" <<EOF
# Spec Requirements Document

> Spec: ${feature_name}
> Created: ${current_date}
> Status: Planning
$(if [[ -n "$issue_number" ]]; then echo "> Issue: #${issue_number}"; fi)

## Overview

Brief description of what this specification covers and its purpose within the Agent OS framework.

## User Stories

**As a Developer**, I want [specific functionality] so that [benefit/outcome].

**As a Product Manager**, I want [specific functionality] so that [benefit/outcome].

**As a Team Member**, I want [specific functionality] so that [benefit/outcome].

## Spec Scope

### Core Features

1. **Feature 1**
   - Description of feature 1
   - Key functionality points
   - Integration requirements

2. **Feature 2**
   - Description of feature 2
   - Key functionality points
   - Integration requirements

### Technical Requirements

- **Performance**: Response time requirements, throughput expectations
- **Security**: Authentication, authorization, data protection requirements
- **Compatibility**: Browser support, platform requirements
- **Scalability**: Expected load, growth considerations
- **Integration**: External systems, APIs, third-party services

### Success Criteria

- [ ] **Functional**: All core features working as specified
- [ ] **Performance**: Meets all performance benchmarks
- [ ] **Quality**: Passes all tests with 100% coverage
- [ ] **Documentation**: Complete user and developer documentation
- [ ] **Deployment**: Successfully deployed to production environment

## Implementation Notes

### Architecture Decisions

Document key architectural choices and their rationale.

### Risk Assessment

- **High Risk**: [Describe high-risk items and mitigation strategies]
- **Medium Risk**: [Describe medium-risk items and monitoring plans]
- **Dependencies**: [External dependencies and contingency plans]

### Testing Strategy

- **Unit Tests**: Component-level testing approach
- **Integration Tests**: System integration testing strategy
- **User Acceptance Testing**: End-user validation approach
- **Performance Testing**: Load and stress testing plans

---

*This spec is part of the Agent OS framework for structured AI-assisted development.*
EOF

    log_success "Created spec template: $spec_file"
    return 0
}

create_tasks_template() {
    local spec_dir="$1"
    local feature_name="$2"
    
    local tasks_file=".agent-os/specs/$spec_dir/tasks.md"
    
    # Don't overwrite existing tasks files
    if [[ -f "$tasks_file" ]]; then
        log_warning "Tasks file already exists, skipping: $tasks_file"
        return 0
    fi
    
    cat > "$tasks_file" <<EOF
# Implementation Tasks

> Feature: ${feature_name}
> Status: Planning
> Last Updated: $(date +%Y-%m-%d)

## Phase 1: Planning and Setup

### 1.1 Requirements Analysis
- [ ] Review and validate all requirements from spec.md
- [ ] Identify dependencies and integration points
- [ ] Create detailed technical design document
- [ ] Validate approach with stakeholders

### 1.2 Environment Setup
- [ ] Set up development environment
- [ ] Configure necessary tools and dependencies
- [ ] Create testing framework structure
- [ ] Set up continuous integration pipeline

## Phase 2: Implementation

### 2.1 Core Infrastructure
- [ ] Implement core data structures
- [ ] Create base classes and interfaces
- [ ] Set up error handling and logging
- [ ] Implement configuration management

### 2.2 Feature Implementation
- [ ] Implement Feature 1 (from spec.md)
- [ ] Implement Feature 2 (from spec.md)
- [ ] Add feature integration logic
- [ ] Implement user interface components

### 2.3 Integration and APIs
- [ ] Implement external API integrations
- [ ] Create internal API endpoints
- [ ] Add authentication and authorization
- [ ] Implement data validation and sanitization

## Phase 3: Testing

### 3.1 Unit Testing
- [ ] Write unit tests for all core functions
- [ ] Achieve 100% code coverage
- [ ] Set up automated testing pipeline
- [ ] Create test data fixtures

### 3.2 Integration Testing
- [ ] Test component interactions
- [ ] Validate API integrations
- [ ] Test error scenarios and edge cases
- [ ] Performance and load testing

### 3.3 User Acceptance Testing
- [ ] Create user testing scenarios
- [ ] Conduct usability testing
- [ ] Gather and incorporate feedback
- [ ] Validate against success criteria

## Phase 4: Documentation and Deployment

### 4.1 Documentation
- [ ] Write user documentation
- [ ] Create developer/API documentation
- [ ] Update architecture documentation
- [ ] Create deployment and maintenance guides

### 4.2 Deployment Preparation
- [ ] Prepare production environment
- [ ] Create deployment scripts
- [ ] Set up monitoring and alerting
- [ ] Create rollback procedures

### 4.3 Go-Live
- [ ] Deploy to staging environment
- [ ] Conduct final pre-production testing
- [ ] Deploy to production
- [ ] Monitor and verify successful deployment

## Notes

### Blockers and Dependencies
- [ ] List any blockers or external dependencies
- [ ] Track resolution status and timelines

### Technical Debt
- [ ] Document any technical debt incurred
- [ ] Plan for future refactoring tasks

### Lessons Learned
- [ ] Document insights and lessons learned during implementation
- [ ] Update development processes based on experience

---

*Task tracking for Agent OS structured development workflow.*
EOF

    log_success "Created tasks template: $tasks_file"
    return 0
}

# ============================================================================
# GitHub Integration
# ============================================================================

create_spec_from_issue() {
    local issue_number="$1"
    
    # Try to fetch issue information from GitHub
    local issue_title
    if command -v gh >/dev/null 2>&1; then
        issue_title=$(gh issue view "$issue_number" --json title --jq '.title' 2>/dev/null) || {
            log_error "Failed to fetch issue #$issue_number from GitHub"
            return 1
        }
    else
        log_error "GitHub CLI (gh) not available - cannot fetch issue information"
        return 1
    fi
    
    # Generate spec directory name from issue title
    local spec_dir
    spec_dir=$(generate_spec_directory "$issue_title" "$issue_number")
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to generate spec directory name"
        return 1
    fi
    
    echo "$spec_dir"
    return 0
}

# ============================================================================
# Complete Spec Creation Workflow
# ============================================================================

create_complete_spec() {
    local spec_name="$1"
    local issue_number="${2:-}"
    
    # Generate directory name
    local spec_dir
    spec_dir=$(generate_spec_directory "$spec_name" "$issue_number")
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Check if spec already exists
    if check_spec_directory_exists "$spec_dir"; then
        log_warning "Spec directory already exists: $spec_dir"
        return 1
    fi
    
    # Create the complete spec structure
    setup_spec_structure "$spec_dir"
    create_spec_template "$spec_dir" "$spec_name" "$issue_number"
    create_tasks_template "$spec_dir" "$spec_name"
    
    log_success "Created complete spec: $spec_dir"
    echo "$spec_dir"
    return 0
}