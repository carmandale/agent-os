#!/usr/bin/env bats

# Test commit boundary detection for transparent work sessions

load test_helper

setup() {
    setup_test_repo
    
    # Create mock commit boundary detector
    cat > "$TEST_REPO_DIR/scripts/commit-boundary-detector.sh" << 'EOF'
#!/bin/bash
# Mock commit boundary detection script

detect_boundary() {
    local context="$1"
    local message="$2"
    
    # Natural commit boundaries in execute-tasks workflow
    case "$context" in
        "phase_0_complete"|"discovery_complete")
            echo "BOUNDARY: Phase 0 - Repository Discovery Complete"
            return 0
            ;;
        "phase_1_complete"|"setup_complete")
            echo "BOUNDARY: Phase 1 - Hygiene and Setup Complete"
            return 0
            ;;
        "phase_15_complete"|"reality_check_complete")
            echo "BOUNDARY: Phase 1.5 - Deep Reality Check Complete"
            return 0
            ;;
        "subtask_complete")
            echo "BOUNDARY: Subtask Implementation Complete"
            return 0
            ;;
        "task_complete"|"phase_2_complete")
            echo "BOUNDARY: Phase 2 - Task Implementation Complete"
            return 0
            ;;
        "quality_complete"|"phase_3_complete")
            echo "BOUNDARY: Phase 3 - Quality Assurance Complete"
            return 0
            ;;
        "git_complete"|"phase_4_complete")
            echo "BOUNDARY: Phase 4 - Git Integration Complete"
            return 0
            ;;
        *)
            echo "NO_BOUNDARY: Continuing work"
            return 1
            ;;
    esac
}

# Main execution
if [ $# -eq 0 ]; then
    echo "Usage: $0 <context> [message]"
    exit 1
fi

detect_boundary "$1" "$2"
EOF
    chmod +x "$TEST_REPO_DIR/scripts/commit-boundary-detector.sh"
}

teardown() {
    cleanup_test_repo
}

@test "detects Phase 0 completion boundary" {
    run "$TEST_REPO_DIR/scripts/commit-boundary-detector.sh" "discovery_complete"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "BOUNDARY: Phase 0 - Repository Discovery Complete" ]]
}

@test "detects Phase 1 completion boundary" {
    run "$TEST_REPO_DIR/scripts/commit-boundary-detector.sh" "setup_complete"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "BOUNDARY: Phase 1 - Hygiene and Setup Complete" ]]
}

@test "detects Phase 1.5 completion boundary" {
    run "$TEST_REPO_DIR/scripts/commit-boundary-detector.sh" "reality_check_complete"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "BOUNDARY: Phase 1.5 - Deep Reality Check Complete" ]]
}

@test "detects subtask completion boundary" {
    run "$TEST_REPO_DIR/scripts/commit-boundary-detector.sh" "subtask_complete"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "BOUNDARY: Subtask Implementation Complete" ]]
}

@test "detects Phase 2 completion boundary" {
    run "$TEST_REPO_DIR/scripts/commit-boundary-detector.sh" "task_complete"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "BOUNDARY: Phase 2 - Task Implementation Complete" ]]
}

@test "detects Phase 3 completion boundary" {
    run "$TEST_REPO_DIR/scripts/commit-boundary-detector.sh" "quality_complete"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "BOUNDARY: Phase 3 - Quality Assurance Complete" ]]
}

@test "detects Phase 4 completion boundary" {
    run "$TEST_REPO_DIR/scripts/commit-boundary-detector.sh" "git_complete"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "BOUNDARY: Phase 4 - Git Integration Complete" ]]
}

@test "does not detect boundary for intermediate work" {
    run "$TEST_REPO_DIR/scripts/commit-boundary-detector.sh" "implementation_in_progress"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "NO_BOUNDARY: Continuing work" ]]
}

@test "handles unknown context appropriately" {
    run "$TEST_REPO_DIR/scripts/commit-boundary-detector.sh" "unknown_context"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "NO_BOUNDARY" ]]
}