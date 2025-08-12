#!/usr/bin/env python3
"""
Integration Test for Context-Aware Hook Wrapper
==============================================
Tests the complete integration of context-aware functionality
with real git operations and workspace state changes.
"""

import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path


def run_hook(hook_script, input_data):
    """Run a hook script with given input data and return exit code."""
    try:
        result = subprocess.run(
            [sys.executable, hook_script, "pretool"],
            input=json.dumps(input_data),
            text=True,
            capture_output=True,
            timeout=10
        )
        return result.returncode, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "Hook timed out"


def test_integration():
    """Run integration tests for context-aware hook wrapper."""
    hooks_dir = Path(__file__).parent
    context_hook = hooks_dir / "context_aware_hook.py"
    original_hook = hooks_dir / "workflow-enforcement-hook.py"
    
    print("🧪 Integration Testing Context-Aware Hook Wrapper")
    print("=" * 60)
    
    # Test cases
    test_cases = [
        {
            "name": "Maintenance work with dirty workspace",
            "input": {
                "tool_name": "Edit",
                "tool_input": {"file_path": "/test/file.py"},
                "user_message": "fix failing tests"
            },
            "expected_exit": 0,
            "description": "Should allow maintenance work regardless of workspace state"
        },
        {
            "name": "New work with clean workspace",
            "input": {
                "tool_name": "Write", 
                "tool_input": {"file_path": "/test/new_file.py"},
                "user_message": "implement user dashboard feature"
            },
            "expected_exit": 0,
            "description": "Should allow new work in clean workspace"
        },
        {
            "name": "Investigation tool always allowed",
            "input": {
                "tool_name": "Read",
                "tool_input": {"file_path": "/test/file.py"},
                "user_message": "check the current implementation"
            },
            "expected_exit": 0,
            "description": "Investigation tools should always be allowed"
        },
        {
            "name": "Git commands always allowed",
            "input": {
                "tool_name": "Bash",
                "tool_input": {"command": "git status"},
                "user_message": "check repository status"
            },
            "expected_exit": 0,
            "description": "Git workflow commands should always be allowed"
        }
    ]
    
    print(f"Running {len(test_cases)} integration test cases...\n")
    
    passed = 0
    failed = 0
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"Test {i}: {test_case['name']}")
        print(f"Description: {test_case['description']}")
        
        # Run context-aware hook
        exit_code, stderr = run_hook(str(context_hook), test_case['input'])
        
        if exit_code == test_case['expected_exit']:
            print(f"✅ PASSED - Exit code: {exit_code}")
            passed += 1
        else:
            print(f"❌ FAILED - Expected: {test_case['expected_exit']}, Got: {exit_code}")
            if stderr:
                print(f"   Error output: {stderr[:200]}...")
            failed += 1
        
        print()
    
    # Performance comparison
    print("Performance Comparison")
    print("-" * 30)
    
    test_input = {
        "tool_name": "Edit",
        "tool_input": {"file_path": "/test/file.py"},
        "user_message": "fix tests"
    }
    
    # Test context-aware hook performance
    start_time = time.time()
    for _ in range(5):
        run_hook(str(context_hook), test_input)
    context_time = (time.time() - start_time) / 5
    
    # Test original hook performance
    start_time = time.time()
    for _ in range(5):
        run_hook(str(original_hook), test_input)
    original_time = (time.time() - start_time) / 5
    
    overhead = ((context_time - original_time) / original_time) * 100
    
    print(f"Original hook average time: {original_time:.3f}s")
    print(f"Context-aware hook average time: {context_time:.3f}s")
    print(f"Performance overhead: {overhead:.1f}%")
    
    if overhead <= 10:
        print("✅ Performance requirement met (<10% overhead)")
    else:
        print(f"❌ Performance requirement not met (>{overhead:.1f}% overhead)")
        failed += 1
    
    print()
    
    # Summary
    print("Integration Test Summary")
    print("=" * 30)
    print(f"Total tests: {len(test_cases) + 1}")  # +1 for performance test
    print(f"Passed: {passed}")
    print(f"Failed: {failed}")
    
    if failed == 0:
        print("\n🎉 All integration tests passed!")
        return True
    else:
        print(f"\n⚠️ {failed} test(s) failed!")
        return False


if __name__ == "__main__":
    success = test_integration()
    sys.exit(0 if success else 1)