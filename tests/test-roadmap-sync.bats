#!/usr/bin/env bats

# Test suite for roadmap synchronization functionality  
# Tests automatic roadmap.md status updates based on completed specs and tasks

setup() {
    # Create a temporary test directory
    export TEST_DIR="$(mktemp -d)"
    export ORIG_DIR="$(pwd)"
    cd "$TEST_DIR"
    
    # Initialize git repo for testing
    git init >/dev/null 2>&1
    git config user.email "test@example.com"
    git config user.name "Test User"
    
    # Create initial commit
    touch README.md
    git add README.md
    git commit -m "Initial commit" >/dev/null 2>&1
    
    # Create .agent-os directory structure
    mkdir -p .agent-os/product .agent-os/specs
    
    # Path to the roadmap sync library (will be created in Task 4.2)
    export ROADMAP_LIB_PATH="$ORIG_DIR/scripts/lib/roadmap-sync.sh"
    
    # Create a test roadmap.md
    create_test_roadmap
}

teardown() {
    cd "$ORIG_DIR"
    rm -rf "$TEST_DIR"
}

create_test_roadmap() {
    cat > .agent-os/product/roadmap.md <<'EOF'
# Product Roadmap

> Last Updated: 2024-08-28
> Version: 1.0.0
> Status: Active Development

## Phase 1: Core Framework (✅ COMPLETE)

- [x] Core setup scripts - Installation framework `M`
- [x] Workflow instruction files - Core workflows `XL`
- [x] Health check verification system - Quality assurance `S`

## Phase 2: Enhanced Features (🔄 IN PROGRESS)

- [x] CHANGELOG auto-update functionality - Documentation automation `L`
- [ ] Spec directory creation system - Workflow automation `M`
- [ ] Roadmap synchronization - Status tracking `M`
- [ ] Reference fixing system - Documentation integrity `S`

## Phase 3: Advanced Integration (⏳ PLANNED)

- [ ] Multi-project support - Enterprise features `XL`
- [ ] Advanced analytics - Reporting system `L`
- [ ] Team collaboration features - Multi-user support `L`

## Completed Features

### v1.0.0 - Core Release
- Setup and installation system
- Basic workflow instructions
- Health checking capabilities

### v1.1.0 - Enhanced Documentation
- CHANGELOG auto-generation
- Documentation drift detection
- Quality assurance improvements
EOF
}

create_completed_specs() {
    # Create a completed spec to test detection
    mkdir -p ".agent-os/specs/2024-08-28-test-completed-feature-#123"
    cat > ".agent-os/specs/2024-08-28-test-completed-feature-#123/tasks.md" <<'EOF'
# Implementation Tasks

> Status: Complete
> Last Updated: 2024-08-28

## Phase 1: Planning
- [x] Requirements analysis
- [x] Technical design

## Phase 2: Implementation  
- [x] Core functionality
- [x] Integration testing

## Phase 3: Testing
- [x] Unit tests
- [x] User acceptance testing
EOF

    # Create an in-progress spec
    mkdir -p ".agent-os/specs/2024-08-28-test-progress-feature-#456"
    cat > ".agent-os/specs/2024-08-28-test-progress-feature-#456/tasks.md" <<'EOF'
# Implementation Tasks

> Status: In Progress
> Last Updated: 2024-08-28

## Phase 1: Planning
- [x] Requirements analysis
- [ ] Technical design

## Phase 2: Implementation  
- [ ] Core functionality
- [ ] Integration testing
EOF
}

# ============================================================================
# Roadmap Parsing Tests
# ============================================================================

@test "parse_roadmap_structure() identifies phases and tasks" {
    source "$ROADMAP_LIB_PATH"
    
    result=$(parse_roadmap_structure ".agent-os/product/roadmap.md")
    [ "$?" -eq 0 ]
    
    # Should identify phases
    [[ "$result" == *"Phase 1: Core Framework"* ]]
    [[ "$result" == *"Phase 2: Enhanced Features"* ]]
    [[ "$result" == *"Phase 3: Advanced Integration"* ]]
}

@test "parse_roadmap_structure() detects completion status" {
    skip "Function not yet implemented - Task 4.2"
    source "$ROADMAP_LIB_PATH"
    
    result=$(parse_roadmap_structure ".agent-os/product/roadmap.md")
    [ "$?" -eq 0 ]
    
    # Should detect completed phases
    [[ "$result" == *"✅ COMPLETE"* ]]
    [[ "$result" == *"🔄 IN PROGRESS"* ]]
    [[ "$result" == *"⏳ PLANNED"* ]]
}

@test "extract_roadmap_tasks() lists individual tasks" {
    source "$ROADMAP_LIB_PATH"
    
    result=$(extract_roadmap_tasks ".agent-os/product/roadmap.md" "Phase 2")
    [ "$?" -eq 0 ]
    
    # Should extract Phase 2 tasks
    [[ "$result" == *"Team standards sharing system"* ]]
    [[ "$result" == *"Multi-project workspace management"* ]]
    [[ "$result" == *"Shared decision logging across projects"* ]]
}

# ============================================================================
# Spec Completion Detection Tests
# ============================================================================

@test "detect_completed_specs() finds finished specifications" {
    skip "Function not yet implemented - Task 4.2"
    source "$ROADMAP_LIB_PATH"
    
    create_completed_specs
    
    result=$(detect_completed_specs)
    [ "$?" -eq 0 ]
    
    # Should find completed spec
    [[ "$result" == *"2024-08-28-test-completed-feature-#123"* ]]
    # Should not include in-progress spec
    [[ "$result" != *"2024-08-28-test-progress-feature-#456"* ]]
}

@test "analyze_spec_tasks() determines spec completion status" {
    source "$ROADMAP_LIB_PATH"
    
    create_completed_specs
    
    # Test completed spec
    result=$(analyze_spec_tasks ".agent-os/specs/2024-08-28-test-completed-feature-#123/tasks.md")
    [ "$?" -eq 0 ]
    [[ "$result" == "complete" ]]
    
    # Test in-progress spec
    result=$(analyze_spec_tasks ".agent-os/specs/2024-08-28-test-progress-feature-#456/tasks.md")
    [ "$?" -eq 0 ]
    [[ "$result" == "in-progress" ]]
}

@test "match_spec_to_roadmap() connects specs to roadmap items" {
    skip "Function not yet implemented - Task 4.2"
    source "$ROADMAP_LIB_PATH"
    
    create_completed_specs
    
    result=$(match_spec_to_roadmap "CHANGELOG auto-update functionality")
    [ "$?" -eq 0 ]
    
    # Should identify matching patterns
    [[ "$result" == *"changelog"* ]] || [[ "$result" == *"auto-update"* ]]
}

# ============================================================================
# Roadmap Update Tests
# ============================================================================

@test "update_roadmap_status() marks completed items" {
    skip "Function not yet implemented - Task 4.2"
    source "$ROADMAP_LIB_PATH"
    
    # Copy roadmap for testing
    cp .agent-os/product/roadmap.md .agent-os/product/roadmap.md.backup
    
    update_roadmap_status ".agent-os/product/roadmap.md" "Spec directory creation system" "completed"
    [ "$?" -eq 0 ]
    
    # Should update the task to completed
    grep -q "\\[x\\] Spec directory creation system" ".agent-os/product/roadmap.md"
    
    # Restore backup
    mv .agent-os/product/roadmap.md.backup .agent-os/product/roadmap.md
}

@test "update_roadmap_status() handles phase status changes" {
    skip "Function not yet implemented - Task 4.2"
    source "$ROADMAP_LIB_PATH"
    
    # Copy roadmap for testing
    cp .agent-os/product/roadmap.md .agent-os/product/roadmap.md.backup
    
    # Mark all Phase 2 tasks as complete
    update_roadmap_status ".agent-os/product/roadmap.md" "Spec directory creation system" "completed"
    update_roadmap_status ".agent-os/product/roadmap.md" "Roadmap synchronization" "completed"
    update_roadmap_status ".agent-os/product/roadmap.md" "Reference fixing system" "completed"
    
    # Should update phase status
    update_phase_status ".agent-os/product/roadmap.md" "Phase 2"
    grep -q "Phase 2.*✅ COMPLETE" ".agent-os/product/roadmap.md"
    
    # Restore backup
    mv .agent-os/product/roadmap.md.backup .agent-os/product/roadmap.md
}

@test "sync_roadmap_dates() updates last modified timestamp" {
    source "$ROADMAP_LIB_PATH"
    
    # Copy roadmap for testing
    cp .agent-os/product/roadmap.md .agent-os/product/roadmap.md.backup
    
    sync_roadmap_dates ".agent-os/product/roadmap.md"
    [ "$?" -eq 0 ]
    
    # Should update the last updated date to today
    current_date=$(date +%Y-%m-%d)
    grep -q "Last Updated: $current_date" ".agent-os/product/roadmap.md"
    
    # Restore backup
    mv .agent-os/product/roadmap.md.backup .agent-os/product/roadmap.md
}

# ============================================================================
# Roadmap Structure Preservation Tests
# ============================================================================

@test "preserve_roadmap_structure() maintains formatting" {
    skip "Function not yet implemented - Task 4.2"
    source "$ROADMAP_LIB_PATH"
    
    # Copy original for comparison
    cp .agent-os/product/roadmap.md original.md
    
    # Make updates
    update_roadmap_status ".agent-os/product/roadmap.md" "Spec directory creation system" "completed"
    
    # Should preserve structure
    grep -q "# Product Roadmap" ".agent-os/product/roadmap.md"
    grep -q "## Phase 1: Core Framework" ".agent-os/product/roadmap.md"
    grep -q "## Completed Features" ".agent-os/product/roadmap.md"
    
    # Should preserve custom formatting
    grep -q "> Last Updated:" ".agent-os/product/roadmap.md"
    grep -q "> Version:" ".agent-os/product/roadmap.md"
}

@test "validate_roadmap_format() checks structure integrity" {
    source "$ROADMAP_LIB_PATH"
    
    # Valid roadmap should pass
    validate_roadmap_format ".agent-os/product/roadmap.md"
    [ "$?" -eq 0 ]
    
    # Create invalid roadmap
    echo "Invalid roadmap content" > invalid_roadmap.md
    
    ! validate_roadmap_format "invalid_roadmap.md"
}

# ============================================================================
# Integration and Workflow Tests
# ============================================================================

@test "full_roadmap_sync() integrates all components" {
    skip "Integration not yet implemented - Task 4.2"
    source "$ROADMAP_LIB_PATH"
    
    create_completed_specs
    
    # Copy roadmap for testing
    cp .agent-os/product/roadmap.md .agent-os/product/roadmap.md.backup
    
    result=$(full_roadmap_sync ".agent-os/product/roadmap.md")
    [ "$?" -eq 0 ]
    
    # Should update roadmap based on completed specs
    current_date=$(date +%Y-%m-%d)
    grep -q "Last Updated: $current_date" ".agent-os/product/roadmap.md"
    
    # Should detect and update completed items
    [[ "$result" == *"Updated"* ]] || [[ "$result" == *"synchronized"* ]]
    
    # Restore backup
    mv .agent-os/product/roadmap.md.backup .agent-os/product/roadmap.md
}

@test "roadmap_sync handles missing files gracefully" {
    source "$ROADMAP_LIB_PATH"
    
    # Test with non-existent roadmap
    ! validate_roadmap_format "nonexistent.md" 2>/dev/null
}

# ============================================================================
# Version Management Tests  
# ============================================================================

@test "update_roadmap_version() increments version properly" {
    source "$ROADMAP_LIB_PATH"
    
    # Copy roadmap for testing
    cp .agent-os/product/roadmap.md .agent-os/product/roadmap.md.backup
    
    update_roadmap_version ".agent-os/product/roadmap.md" "1.1.0"
    [ "$?" -eq 0 ]
    
    grep -q "Version: 1.1.0" ".agent-os/product/roadmap.md"
    
    # Restore backup
    mv .agent-os/product/roadmap.md.backup .agent-os/product/roadmap.md
}

@test "detect_version_milestones() identifies release points" {
    skip "Function not yet implemented - Task 4.2"
    source "$ROADMAP_LIB_PATH"
    
    create_completed_specs
    
    result=$(detect_version_milestones)
    [ "$?" -eq 0 ]
    
    # Should detect when phases are complete for version bumps
    [[ "$result" == *"Phase 1"* ]] # Phase 1 is marked complete
}