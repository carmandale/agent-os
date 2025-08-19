#!/usr/bin/env python3
"""
Agent OS Task Tool Hook for Subagent Integration
=================================================
Intercepts Claude Code Task tool calls and routes them to specialized subagents
for optimized performance and reduced token usage.
"""

import json
import sys
import os
from pathlib import Path

# Add hooks directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

try:
    from subagent_detector import SubagentDetector
    from task_tool_wrapper import TaskToolWrapper
    SUBAGENTS_AVAILABLE = True
except ImportError:
    SUBAGENTS_AVAILABLE = False

def main():
    """Main hook entry point for Task tool interception."""
    
    # Read input from Claude Code
    try:
        input_data = json.loads(sys.stdin.read()) if not sys.stdin.isatty() else {}
    except json.JSONDecodeError:
        # If we can't parse input, allow the tool to proceed normally
        print(json.dumps({"action": "allow"}))
        sys.exit(0)
    
    # Check if subagents are available
    if not SUBAGENTS_AVAILABLE:
        # Subagents not available, proceed normally
        print(json.dumps({"action": "allow"}))
        sys.exit(0)
    
    # Get tool information
    tool_name = input_data.get("tool_name", "")
    
    # Only intercept Task tool
    if tool_name != "Task":
        print(json.dumps({"action": "allow"}))
        sys.exit(0)
    
    # Get task parameters
    tool_input = input_data.get("tool_input", {})
    prompt = tool_input.get("prompt", "")
    description = tool_input.get("description", "")
    
    # Initialize detector and wrapper
    try:
        detector = SubagentDetector()
        wrapper = TaskToolWrapper()
        
        # Create context for detection
        context = {
            "message": prompt,
            "description": description,
            "tool_input": tool_input
        }
        
        # Detect if a subagent should handle this
        detection_result = detector.detect(context)
        
        if detection_result.get("agent") != "general-purpose":
            # Log detection for debugging if enabled
            if os.environ.get("AGENT_OS_DEBUG") == "true":
                debug_path = Path.home() / ".agent-os" / "logs" / "subagent-routing.log"
                debug_path.parent.mkdir(parents=True, exist_ok=True)
                with open(debug_path, "a") as f:
                    f.write(f"[Task Hook] Routing to {detection_result['agent']}: {prompt[:100]}\n")
            
            # Add subagent type to the tool input
            tool_input["subagent_type"] = detection_result["agent"]
            
            # Return modified input to Claude Code
            result = {
                "action": "modify",
                "modified_input": {
                    "tool_name": "Task",
                    "tool_input": tool_input
                },
                "message": f"🤖 Routing to specialized {detection_result['agent']} subagent for optimized performance"
            }
        else:
            # Use general-purpose agent
            result = {"action": "allow"}
        
        print(json.dumps(result))
        
    except Exception as e:
        # On any error, allow normal operation
        if os.environ.get("AGENT_OS_DEBUG") == "true":
            debug_path = Path.home() / ".agent-os" / "logs" / "subagent-errors.log"
            debug_path.parent.mkdir(parents=True, exist_ok=True)
            with open(debug_path, "a") as f:
                f.write(f"[Task Hook Error] {str(e)}\n")
        
        print(json.dumps({"action": "allow"}))
        sys.exit(0)

if __name__ == "__main__":
    main()