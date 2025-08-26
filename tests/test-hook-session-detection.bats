#!/usr/bin/env bats

# Test hook session state detection functionality

load test_helper

setup() {
    setup_test_repo
    
    # Create mock hook script for testing
    mkdir -p "$TEST_REPO_DIR/hooks"
    cat > "$TEST_REPO_DIR/hooks/test-hook.py" << 'EOF'
#!/usr/bin/env python3
import os
import sys

# Mock the session detection logic from workflow-enforcement-hook.py
def detect_work_session():
    # Environment variable detection
    work_session_active = os.environ.get("AGENT_OS_WORK_SESSION", "").lower() == "true"
    
    # Session file detection
    session_file = os.path.expanduser("~/.agent-os/cache/work-session")
    session_exists = os.path.exists(session_file)
    
    return work_session_active or session_exists

def main():
    if detect_work_session():
        print("SESSION_ACTIVE")
        sys.exit(0)
    else:
        print("NO_SESSION")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF
    chmod +x "$TEST_REPO_DIR/hooks/test-hook.py"
}

teardown() {
    cleanup_test_repo
    # Clean up any session files
    rm -f ~/.agent-os/cache/work-session 2>/dev/null || true
    unset AGENT_OS_WORK_SESSION 2>/dev/null || true
}

@test "hook detects work session via environment variable" {
    export AGENT_OS_WORK_SESSION=true
    
    run python3 "$TEST_REPO_DIR/hooks/test-hook.py"
    [ "$status" -eq 0 ]
    [ "$output" = "SESSION_ACTIVE" ]
}

@test "hook detects work session via session file" {
    # Ensure environment variable is not set
    unset AGENT_OS_WORK_SESSION 2>/dev/null || true
    
    # Create session file
    mkdir -p ~/.agent-os/cache
    echo '{"active": true, "started": "2025-08-24T06:00:00Z"}' > ~/.agent-os/cache/work-session
    
    run python3 "$TEST_REPO_DIR/hooks/test-hook.py"
    [ "$status" -eq 0 ]
    [ "$output" = "SESSION_ACTIVE" ]
}

@test "hook detects work session with both environment variable and file" {
    export AGENT_OS_WORK_SESSION=true
    mkdir -p ~/.agent-os/cache
    echo '{"active": true, "started": "2025-08-24T06:00:00Z"}' > ~/.agent-os/cache/work-session
    
    run python3 "$TEST_REPO_DIR/hooks/test-hook.py"
    [ "$status" -eq 0 ]
    [ "$output" = "SESSION_ACTIVE" ]
}

@test "hook detects no session when neither env var nor file present" {
    unset AGENT_OS_WORK_SESSION 2>/dev/null || true
    rm -f ~/.agent-os/cache/work-session 2>/dev/null || true
    
    run python3 "$TEST_REPO_DIR/hooks/test-hook.py"
    [ "$status" -eq 1 ]
    [ "$output" = "NO_SESSION" ]
}

@test "hook detects no session with env var set to false" {
    export AGENT_OS_WORK_SESSION=false
    rm -f ~/.agent-os/cache/work-session 2>/dev/null || true
    
    run python3 "$TEST_REPO_DIR/hooks/test-hook.py"
    [ "$status" -eq 1 ]
    [ "$output" = "NO_SESSION" ]
}

@test "hook detects no session with invalid env var value" {
    export AGENT_OS_WORK_SESSION=invalid
    rm -f ~/.agent-os/cache/work-session 2>/dev/null || true
    
    run python3 "$TEST_REPO_DIR/hooks/test-hook.py"
    [ "$status" -eq 1 ]
    [ "$output" = "NO_SESSION" ]
}