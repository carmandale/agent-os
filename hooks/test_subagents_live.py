#!/usr/bin/env python3
"""
Live test harness for Agent OS Subagents.

This script allows testing the subagents interactively to verify
they work correctly in a real environment.
"""

import os
import sys
import json
from pathlib import Path

# Add hooks directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from task_tool_wrapper import TaskToolWrapper
from subagent_detector import SubagentDetector
from subagents import (
    ContextFetcherAgent,
    DateCheckerAgent,
    FileCreatorAgent,
    GitWorkflowAgent,
    TestRunnerAgent
)


def test_detection():
    """Test the detection system."""
    print("\n" + "="*60)
    print("TESTING SUBAGENT DETECTION")
    print("="*60)
    
    detector = SubagentDetector()
    
    test_cases = [
        "Search for all TODO comments in Python files",
        "What's today's date?",
        "Create a new README.md file",
        "Commit these changes to git",
        "Run the test suite with coverage"
    ]
    
    for prompt in test_cases:
        result = detector.detect({'message': prompt})
        print(f"\nPrompt: {prompt}")
        print(f"Detected: {result['agent']}")
        print(f"Confidence: {result['confidence']:.2f}")
        print(f"Reason: {result['reason']}")


def test_context_fetcher():
    """Test the context fetcher agent."""
    print("\n" + "="*60)
    print("TESTING CONTEXT FETCHER")
    print("="*60)
    
    agent = ContextFetcherAgent()
    
    # Create a test file
    test_file = Path('test_search.py')
    test_file.write_text('''
# TODO: Implement main function
def hello():
    # TODO: Add greeting logic
    return "Hello World"

# FIXME: This needs error handling
def process():
    pass
''')
    
    # Test searching
    result = agent.execute({
        'operation': 'grep',
        'query': 'TODO',
        'path': '.'
    })
    
    print(f"\nSearch for 'TODO':")
    print(f"Success: {result.get('success')}")
    print(f"Matches: {result.get('matches', [])[:3]}")  # First 3 matches
    
    # Clean up
    test_file.unlink()


def test_date_checker():
    """Test the date checker agent."""
    print("\n" + "="*60)
    print("TESTING DATE CHECKER")
    print("="*60)
    
    agent = DateCheckerAgent()
    
    # Test getting current date
    result = agent.execute({'operation': 'current'})
    
    print(f"\nCurrent date:")
    print(f"Date: {result.get('date')}")
    print(f"ISO: {result.get('iso_date')}")
    print(f"Components: Year={result.get('components', {}).get('year')}, "
          f"Month={result.get('components', {}).get('month')}, "
          f"Day={result.get('components', {}).get('day')}")


def test_file_creator():
    """Test the file creator agent."""
    print("\n" + "="*60)
    print("TESTING FILE CREATOR")
    print("="*60)
    
    agent = FileCreatorAgent()
    
    # Test creating a file
    test_content = "# Test File\n\nThis is a test file created by the subagent."
    result = agent.execute({
        'operation': 'create',
        'path': 'test_output.md',
        'content': test_content
    })
    
    print(f"\nCreate file 'test_output.md':")
    print(f"Success: {result.get('success')}")
    
    if result.get('success'):
        # Verify file exists
        if Path('test_output.md').exists():
            print("File created successfully!")
            content = Path('test_output.md').read_text()
            print(f"Content preview: {content[:50]}...")
            # Clean up
            Path('test_output.md').unlink()
        else:
            print("File not found!")


def test_git_workflow():
    """Test the git workflow agent."""
    print("\n" + "="*60)
    print("TESTING GIT WORKFLOW")
    print("="*60)
    
    agent = GitWorkflowAgent()
    
    # Test git status
    result = agent.execute({'operation': 'status'})
    
    print(f"\nGit status:")
    print(f"Branch: {result.get('branch')}")
    print(f"Clean: {result.get('clean')}")
    print(f"Modified files: {len(result.get('modified', []))}")
    print(f"Untracked files: {len(result.get('untracked', []))}")


def test_test_runner():
    """Test the test runner agent."""
    print("\n" + "="*60)
    print("TESTING TEST RUNNER")
    print("="*60)
    
    agent = TestRunnerAgent()
    
    # Create a simple test file
    test_file = Path('test_sample.py')
    test_file.write_text('''
import unittest

class TestSample(unittest.TestCase):
    def test_pass(self):
        self.assertTrue(True)
    
    def test_math(self):
        self.assertEqual(2 + 2, 4)

if __name__ == '__main__':
    unittest.main()
''')
    
    # Test discovery
    result = agent.execute({
        'operation': 'discover',
        'path': '.'
    })
    
    print(f"\nTest discovery:")
    print(f"Framework detected: {result.get('framework')}")
    print(f"Test files found: {result.get('test_files')}")
    print(f"Total tests: {result.get('total_tests')}")
    
    # Clean up
    test_file.unlink()


def test_task_wrapper():
    """Test the Task tool wrapper integration."""
    print("\n" + "="*60)
    print("TESTING TASK TOOL WRAPPER")
    print("="*60)
    
    wrapper = TaskToolWrapper()
    
    test_tasks = [
        {
            'description': 'Search for imports',
            'prompt': 'Find all import statements in Python files'
        },
        {
            'description': 'Get current date',
            'prompt': "What's today's date for naming a folder?"
        },
        {
            'description': 'Create README',
            'prompt': 'Create a new README.md file'
        }
    ]
    
    for task in test_tasks:
        print(f"\n{task['description']}:")
        result = wrapper.execute(task)
        print(f"Agent used: {result.get('_agent_used')}")
        print(f"Optimized: {result.get('_optimized')}")
        print(f"Success: {result.get('success')}")


def main():
    """Run all tests."""
    print("\n" + "="*60)
    print("AGENT OS SUBAGENTS - LIVE TEST")
    print("="*60)
    
    try:
        test_detection()
        test_context_fetcher()
        test_date_checker()
        test_file_creator()
        test_git_workflow()
        test_test_runner()
        test_task_wrapper()
        
        print("\n" + "="*60)
        print("ALL TESTS COMPLETED SUCCESSFULLY!")
        print("="*60)
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    main()