#!/usr/bin/env python3
"""
Simple validation test for Agent OS subagents system.

This is a lightweight health check that validates core subagent functionality
without extensive setup or teardown. Designed for quick verification that
the subagents system is working correctly.

Usage:
    python validate_subagents.py

Returns:
    Exit code 0 if all subagents pass validation
    Exit code 1 if any validation fails
"""

import sys
import os
from pathlib import Path

# Add hooks directory to path
hooks_dir = Path(__file__).parent / "hooks"
sys.path.insert(0, str(hooks_dir))

def validate_imports():
    """Validate that all subagent modules can be imported."""
    try:
        from subagents import (
            ContextFetcherAgent,
            DateCheckerAgent, 
            FileCreatorAgent,
            GitWorkflowAgent,
            TestRunnerAgent
        )
        return True, "All subagent modules imported successfully"
    except ImportError as e:
        return False, f"Import error: {e}"

def validate_subagent_creation():
    """Validate that all subagent classes can be instantiated."""
    try:
        from subagents import (
            ContextFetcherAgent,
            DateCheckerAgent,
            FileCreatorAgent, 
            GitWorkflowAgent,
            TestRunnerAgent
        )
        
        # Try to create each subagent
        agents = {
            'ContextFetcher': ContextFetcherAgent(),
            'DateChecker': DateCheckerAgent(),
            'FileCreator': FileCreatorAgent(),
            'GitWorkflow': GitWorkflowAgent(),
            'TestRunner': TestRunnerAgent()
        }
        
        return True, f"Successfully created {len(agents)} subagent instances"
    except Exception as e:
        return False, f"Subagent creation error: {e}"

def validate_detection_system():
    """Validate that the subagent detection system works."""
    try:
        from subagent_detector import SubagentDetector
        
        detector = SubagentDetector()
        
        # Test detection with a simple prompt
        result = detector.detect({'message': 'What is today\'s date?'})
        
        if 'agent' in result and 'confidence' in result:
            return True, f"Detection system working - detected: {result['agent']}"
        else:
            return False, "Detection system returned invalid result format"
            
    except Exception as e:
        return False, f"Detection system error: {e}"

def validate_task_wrapper():
    """Validate that the Task tool wrapper is functional."""
    try:
        from task_tool_wrapper import TaskToolWrapper
        
        wrapper = TaskToolWrapper()
        
        # Test with a simple date query
        result = wrapper.execute({
            'description': 'Get current date',
            'prompt': 'What is today\'s date?'
        })
        
        if isinstance(result, dict) and 'success' in result:
            return True, "Task wrapper is functional"
        else:
            return False, "Task wrapper returned invalid result format"
            
    except Exception as e:
        return False, f"Task wrapper error: {e}"

def run_validation():
    """Run all validation tests."""
    print("Agent OS Subagents Validation")
    print("=" * 40)
    
    validations = [
        ("Import Validation", validate_imports),
        ("Subagent Creation", validate_subagent_creation),
        ("Detection System", validate_detection_system),
        ("Task Wrapper", validate_task_wrapper)
    ]
    
    all_passed = True
    results = []
    
    for name, validation_func in validations:
        try:
            passed, message = validation_func()
            status = "✅ PASS" if passed else "❌ FAIL"
            print(f"{status} {name}: {message}")
            results.append((name, passed, message))
            
            if not passed:
                all_passed = False
                
        except Exception as e:
            print(f"❌ FAIL {name}: Unexpected error - {e}")
            results.append((name, False, f"Unexpected error - {e}"))
            all_passed = False
    
    print("\n" + "=" * 40)
    
    if all_passed:
        print("✅ ALL VALIDATIONS PASSED")
        print("Subagents system is working correctly!")
        return 0
    else:
        print("❌ SOME VALIDATIONS FAILED")
        failed_count = sum(1 for _, passed, _ in results if not passed)
        total_count = len(results)
        print(f"{failed_count}/{total_count} validations failed")
        
        print("\nFailed validations:")
        for name, passed, message in results:
            if not passed:
                print(f"  - {name}: {message}")
        
        return 1

if __name__ == '__main__':
    exit_code = run_validation()
    sys.exit(exit_code)