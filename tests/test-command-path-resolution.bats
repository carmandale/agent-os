#!/usr/bin/env bats

# Test command path resolution for Claude Code commands

load test_helper

setup() {
    setup_test_repo
    
    # Create test command directory
    mkdir -p "$TEST_REPO_DIR/commands"
    
    # Copy actual commands for testing
    cp "$BATS_TEST_DIRNAME/../commands/"*.md "$TEST_REPO_DIR/commands/"
}

teardown() {
    cleanup_test_repo
}

@test "execute-tasks command points to correct instruction file" {
    local execute_tasks_cmd="$TEST_REPO_DIR/commands/execute-tasks.md"
    
    # Verify file exists
    [ -f "$execute_tasks_cmd" ]
    
    # Check that it points to the correct path
    run grep -o "@~/.agent-os/instructions/core/execute-tasks.md" "$execute_tasks_cmd"
    [ "$status" -eq 0 ]
    [ "$output" = "@~/.agent-os/instructions/core/execute-tasks.md" ]
}

@test "execute-tasks vs execute-task distinction is clear" {
    # execute-tasks.md should exist (orchestrator)
    [ -f "$TEST_REPO_DIR/commands/execute-tasks.md" ]
    
    # Check if execute-task.md exists (should not exist as command)
    [ ! -f "$TEST_REPO_DIR/commands/execute-task.md" ]
    
    # Verify execute-tasks points to orchestrator instruction
    run grep "core/execute-tasks.md" "$TEST_REPO_DIR/commands/execute-tasks.md"
    [ "$status" -eq 0 ]
}

@test "all commands point to valid instruction paths" {
    for cmd_file in "$TEST_REPO_DIR/commands"/*.md; do
        if [ -f "$cmd_file" ]; then
            local cmd_name=$(basename "$cmd_file" .md)
            
            # Extract instruction path from command
            local instruction_path=$(grep -o "@~/.agent-os/instructions[^[:space:]]*" "$cmd_file" || echo "")
            
            if [ -n "$instruction_path" ]; then
                # Convert to actual file path for testing
                local actual_path=$(echo "$instruction_path" | sed 's|@~/.agent-os/instructions|'"$BATS_TEST_DIRNAME"'/../instructions|')
                
                # Verify instruction file exists
                if [ ! -f "$actual_path" ]; then
                    echo "Command $cmd_name points to non-existent instruction: $instruction_path" >&2
                    echo "Expected file: $actual_path" >&2
                    return 1
                fi
            fi
        fi
    done
}

@test "command names match their instruction counterparts" {
    # Check key commands
    local commands=("plan-product" "create-spec" "execute-tasks" "analyze-product")
    
    for cmd in "${commands[@]}"; do
        local cmd_file="$TEST_REPO_DIR/commands/$cmd.md"
        
        # Command file should exist
        [ -f "$cmd_file" ]
        
        # Should point to instruction with same name
        run grep "@~/.agent-os/instructions.*$cmd.md" "$cmd_file"
        [ "$status" -eq 0 ]
    done
}

@test "execute-tasks command has correct description" {
    local execute_tasks_cmd="$TEST_REPO_DIR/commands/execute-tasks.md"
    
    # Should have a clear description
    run grep -i "execute.*task" "$execute_tasks_cmd"
    [ "$status" -eq 0 ]
    
    # Should not be confused with singular execute-task
    run grep -v "Execute Task$" "$execute_tasks_cmd"  # Should not be exactly "Execute Task"
    [ "$status" -eq 0 ]
}

@test "all instruction file references use correct paths" {
    # Find all @ references in commands
    for cmd_file in "$TEST_REPO_DIR/commands"/*.md; do
        if [ -f "$cmd_file" ]; then
            # Check for old-style paths that might be incorrect
            run grep "@~/.agent-os/instructions/[^/]*\.md" "$cmd_file"
            if [ "$status" -eq 0 ]; then
                # If found, it might be an old-style path - verify it's intentional
                local found_path="$output"
                if [[ "$found_path" != *"/core/"* ]] && [[ "$found_path" != *"/meta/"* ]]; then
                    echo "Potentially incorrect path format in $(basename "$cmd_file"): $found_path" >&2
                    echo "Expected paths should include '/core/' or '/meta/' subdirectory" >&2
                    return 1
                fi
            fi
        fi
    done
}