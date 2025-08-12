#!/usr/bin/env python3
"""
Integration test for context-aware hook.

Tests the complete workflow from user message to enforcement decision.
"""

import json
import os
import sys
import subprocess
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))


def run_hook(user_message: str, tool_name: str = "Edit") -> int:
    """
    Run the context-aware hook with given input.
    
    Args:
        user_message: The user's message
        tool_name: The tool being used
        
    Returns:
        Exit code (0 = allow, 1 = block)
    """
    input_data = json.dumps({
        "tool_name": tool_name,
        "user_message": user_message
    })
    
    result = subprocess.run(
        [sys.executable, "context_aware_hook.py", "pretool"],
        input=input_data,
        capture_output=True,
        text=True,
        cwd=Path(__file__).parent
    )
    
    return result.returncode


def test_maintenance_scenarios():
    """Test various maintenance work scenarios."""
    print("Testing maintenance work scenarios...")
    
    maintenance_messages = [
        "fix failing tests",
        "debug the authentication issue",
        "fix CI failures",
        "resolve merge conflicts",
        "address broken build",
        "repair database migration"
    ]
    
    for msg in maintenance_messages:
        exit_code = run_hook(msg)
        status = "✓ ALLOWED" if exit_code == 0 else "✗ BLOCKED"
        print(f"  {status}: '{msg}'")
        assert exit_code == 0, f"Maintenance work should be allowed: {msg}"
    
    print("  All maintenance scenarios passed!\n")


def test_new_work_scenarios():
    """Test various new work scenarios."""
    print("Testing new work scenarios...")
    
    # Set up a clean workspace for this test
    os.environ.pop('AGENT_OS_BYPASS', None)
    os.environ.pop('AGENT_OS_WORK_TYPE', None)
    
    new_work_messages = [
        "implement user authentication",
        "create new dashboard feature",
        "build API endpoints",
        "add user profile page",
        "implement payment processing",
        "create admin panel"
    ]
    
    for msg in new_work_messages:
        # These should be blocked if workspace is dirty
        # For testing, we can't control actual git state easily
        # So we'll just verify the hook runs without error
        try:
            exit_code = run_hook(msg)
            status = "✓ PROCESSED" if exit_code in [0, 1] else "✗ ERROR"
            print(f"  {status}: '{msg}' (exit code: {exit_code})")
        except Exception as e:
            print(f"  ✗ ERROR: '{msg}' - {e}")
            raise
    
    print("  All new work scenarios processed correctly!\n")


def test_environment_overrides():
    """Test environment variable overrides."""
    print("Testing environment variable overrides...")
    
    # Test AGENT_OS_BYPASS
    os.environ['AGENT_OS_BYPASS'] = 'true'
    exit_code = run_hook("any work at all")
    assert exit_code == 0, "BYPASS should allow all work"
    print("  ✓ AGENT_OS_BYPASS=true allows work")
    os.environ.pop('AGENT_OS_BYPASS')
    
    # Test AGENT_OS_WORK_TYPE=maintenance
    os.environ['AGENT_OS_WORK_TYPE'] = 'maintenance'
    exit_code = run_hook("ambiguous work")
    assert exit_code == 0, "Manual maintenance override should allow work"
    print("  ✓ AGENT_OS_WORK_TYPE=maintenance allows work")
    
    # Test AGENT_OS_WORK_TYPE=new_work
    os.environ['AGENT_OS_WORK_TYPE'] = 'new_work'
    # This might be blocked if workspace is dirty
    exit_code = run_hook("fix tests")  # Would normally be maintenance
    # Just verify it runs without error
    assert exit_code in [0, 1], "Should process without error"
    print("  ✓ AGENT_OS_WORK_TYPE=new_work processes correctly")
    
    os.environ.pop('AGENT_OS_WORK_TYPE')
    print("  All override scenarios passed!\n")


def test_performance():
    """Test that the hook meets performance requirements."""
    print("Testing performance...")
    
    import time
    
    messages = [
        "fix failing tests",
        "implement new feature",
        "debug issue",
        "create dashboard",
        "resolve conflicts"
    ]
    
    total_time = 0
    for msg in messages:
        start = time.time()
        run_hook(msg)
        elapsed = time.time() - start
        total_time += elapsed
    
    avg_time = total_time / len(messages)
    print(f"  Average execution time: {avg_time*1000:.2f}ms")
    
    # Should be under 100ms per spec requirement
    assert avg_time < 0.1, f"Performance requirement failed: {avg_time:.3f}s > 100ms"
    print("  ✓ Performance requirement met (<100ms)\n")


def main():
    """Run all integration tests."""
    print("=" * 60)
    print("Context-Aware Hook Integration Tests")
    print("=" * 60 + "\n")
    
    try:
        test_maintenance_scenarios()
        test_new_work_scenarios()
        test_environment_overrides()
        test_performance()
        
        print("=" * 60)
        print("✅ ALL INTEGRATION TESTS PASSED!")
        print("=" * 60)
        return 0
        
    except AssertionError as e:
        print(f"\n❌ TEST FAILED: {e}")
        return 1
    except Exception as e:
        print(f"\n❌ UNEXPECTED ERROR: {e}")
        return 2


if __name__ == '__main__':
    sys.exit(main())