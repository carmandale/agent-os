#!/usr/bin/env python3
"""
Quick benchmark for optimized hook architecture.
"""

import json
import subprocess
import time
import statistics
from pathlib import Path

def benchmark_hook(hook_path, hook_type, payload, iterations=10):
    """Benchmark a specific hook."""
    latencies = []
    project_root = Path(__file__).parent.parent.parent.parent
    
    for _ in range(iterations):
        start_time = time.time()
        
        try:
            subprocess.run(
                ["python3", str(hook_path), hook_type],
                input=json.dumps(payload),
                text=True,
                capture_output=True,
                timeout=10,
                cwd=project_root
            )
            end_time = time.time()
            latency_ms = (end_time - start_time) * 1000
            latencies.append(latency_ms)
        except Exception:
            latencies.append(5000)
    
    return {
        'mean': statistics.mean(latencies),
        'p95': statistics.quantiles(latencies, n=100)[94] if len(latencies) >= 5 else max(latencies)
    }

def main():
    project_root = Path(__file__).parent.parent.parent.parent
    optimized_hook = project_root / "hooks" / "workflow-enforcement-hook-optimized.py"
    
    # Test the slow scenarios
    scenarios = [
        ("pretool", {"tool_name": "Bash", "tool_input": {"command": "cp file1 file2"}}),
        ("pretool", {"tool_name": "Write", "tool_input": {"file_path": "test.py"}}),
        ("userprompt", {"prompt": "Let's continue with the next task"}),
    ]
    
    print("=== Optimized Hook Benchmark ===")
    all_pass = True
    
    for hook_type, payload in scenarios:
        result = benchmark_hook(optimized_hook, hook_type, payload)
        scenario_name = f"{hook_type}_{payload.get('tool_name', 'prompt')}"
        
        print(f"{scenario_name}:")
        print(f"  Mean: {result['mean']:.1f}ms")
        print(f"  P95:  {result['p95']:.1f}ms")
        
        if result['p95'] > 500:
            print(f"  ❌ FAILS P95 < 500ms")
            all_pass = False
        else:
            print(f"  ✅ Meets P95 < 500ms")
        print()
    
    if all_pass:
        print("✅ All scenarios meet P95 < 500ms requirement!")
    else:
        print("❌ Some scenarios still fail P95 requirement")
    
    return all_pass

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
