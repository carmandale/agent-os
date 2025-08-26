#!/usr/bin/env python3
"""
PreToolUse Hook: Workspace Hygiene Checker
Ensures git working directory is clean before modifications
"""
import sys
import json
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from shared.git_utils import check_git_status_sync

def main():
    try:
        input_data = json.loads(sys.stdin.read())
        
        # Only check for write operations
        if input_data.get('tool') not in ['Write', 'Edit', 'MultiEdit']:
            return 0
        
        cwd = input_data.get('cwd', os.getcwd())
        
        if not check_git_status_sync(cwd):
            print(json.dumps({
                "action": "block",
                "message": "Working directory has uncommitted changes. Please commit or stash first."
            }))
            return 1
        
        return 0
        
    except Exception as e:
        # Fail open on errors
        print(f"Hook error: {e}", file=sys.stderr)
        return 0

if __name__ == "__main__":
    sys.exit(main())
