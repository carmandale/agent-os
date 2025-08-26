#!/usr/bin/env python3
"""
Performance benchmark for modular hooks architecture.
Validates P95 latency requirements and compares with monolithic version.
"""

import json
import os
import subprocess
import sys
import time
import statistics
from pathlib import Path


class HookBenchmark:
    """Benchmark hook performance and validate latency requirements."""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent.parent.parent
        self.monolithic_hook = self.project_root / "hooks" / "workflow-enforcement-hook.py"
        self.modular_hook = self.project_root / "hooks" / "workflow-enforcement-hook-modular.py"
        
    def create_test_payloads(self):
        """Create test payloads for different hook types."""
        return {
            "bash_readonly": {
                "tool_name": "Bash",
                "tool_input": {"command": "ls -la"}
            },
            "bash_write": {
                "tool_name": "Bash", 
                "tool_input": {"command": "echo test > file.txt"}
            },
            "write_tool": {
                "tool_name": "Write",
                "tool_input": {"file_path": "test.py"}
            },
            "userprompt": {
                "prompt": "Let's continue with the next task"
            },
            "posttool": {
                "tool_name": "Write",
                "tool_input": {"file_path": "test.py"}
            }
        }
    
    def benchmark_hook(self, hook_path, hook_type, payload, iterations=20):
        """Benchmark a specific hook with given payload."""
        latencies = []
        
        for _ in range(iterations):
            start_time = time.time()
            
            try:
                result = subprocess.run(
                    ["python3", str(hook_path), hook_type],
                    input=json.dumps(payload),
                    text=True,
                    capture_output=True,
                    timeout=10,
                    cwd=self.project_root
                )
                
                end_time = time.time()
                latency_ms = (end_time - start_time) * 1000
                latencies.append(latency_ms)
                
            except subprocess.TimeoutExpired:
                latencies.append(10000)  # 10 second timeout as penalty
            except Exception as e:
                print(f"Error running hook: {e}")
                latencies.append(5000)  # 5 second penalty for errors
        
        return {
            'mean': statistics.mean(latencies),
            'median': statistics.median(latencies), 
            'p95': self.calculate_percentile(latencies, 95),
            'p99': self.calculate_percentile(latencies, 99),
            'min': min(latencies),
            'max': max(latencies),
            'latencies': latencies
        }
    
    def calculate_percentile(self, data, percentile):
        """Calculate percentile value."""
        return statistics.quantiles(data, n=100)[percentile-1]
    
    def run_benchmarks(self):
        """Run comprehensive performance benchmarks."""
        payloads = self.create_test_payloads()
        results = {}
        
        # Test scenarios
        scenarios = [
            ("pretool", "bash_readonly"),
            ("pretool", "bash_write"),
            ("pretool", "write_tool"),
            ("userprompt", "userprompt"),
            ("posttool", "posttool")
        ]
        
        print("=== Hook Performance Benchmark ===\n")
        
        # Benchmark modular architecture
        print("Testing Modular Architecture:")
        for hook_type, payload_key in scenarios:
            payload = payloads[payload_key]
            result = self.benchmark_hook(self.modular_hook, hook_type, payload)
            
            scenario_key = f"{hook_type}_{payload_key}"
            results[f"modular_{scenario_key}"] = result
            
            print(f"  {scenario_key}:")
            print(f"    Mean: {result['mean']:.1f}ms")
            print(f"    P95:  {result['p95']:.1f}ms")
            print(f"    P99:  {result['p99']:.1f}ms")
            
            # Validate P95 requirement
            if result['p95'] > 500:
                print(f"    ❌ FAILS P95 < 500ms requirement!")
            else:
                print(f"    ✅ Meets P95 < 500ms requirement")
            print()
        
        # Benchmark original monolithic version if it exists
        if self.monolithic_hook.exists():
            print("\nTesting Monolithic Architecture (for comparison):")
            for hook_type, payload_key in scenarios:
                payload = payloads[payload_key]
                result = self.benchmark_hook(self.monolithic_hook, hook_type, payload)
                
                scenario_key = f"{hook_type}_{payload_key}"
                results[f"monolithic_{scenario_key}"] = result
                
                print(f"  {scenario_key}:")
                print(f"    Mean: {result['mean']:.1f}ms")
                print(f"    P95:  {result['p95']:.1f}ms")
                print(f"    P99:  {result['p99']:.1f}ms")
                print()
        
        return results
    
    def analyze_results(self, results):
        """Analyze benchmark results and provide summary."""
        print("\n=== Performance Analysis ===")
        
        # Check P95 compliance
        modular_scenarios = [k for k in results.keys() if k.startswith("modular_")]
        failing_scenarios = []
        
        for scenario in modular_scenarios:
            p95 = results[scenario]['p95']
            if p95 > 500:
                failing_scenarios.append((scenario, p95))
        
        if failing_scenarios:
            print(f"❌ {len(failing_scenarios)} scenarios fail P95 < 500ms requirement:")
            for scenario, p95 in failing_scenarios:
                print(f"   {scenario}: {p95:.1f}ms")
        else:
            print("✅ All scenarios meet P95 < 500ms requirement")
        
        # Compare architectures if both exist
        modular_p95s = [results[k]['p95'] for k in modular_scenarios]
        monolithic_scenarios = [k for k in results.keys() if k.startswith("monolithic_")]
        
        if monolithic_scenarios:
            monolithic_p95s = [results[k]['p95'] for k in monolithic_scenarios]
            
            avg_modular_p95 = statistics.mean(modular_p95s)
            avg_monolithic_p95 = statistics.mean(monolithic_p95s)
            
            improvement = ((avg_monolithic_p95 - avg_modular_p95) / avg_monolithic_p95) * 100
            
            print(f"\nPerformance Comparison:")
            print(f"  Modular avg P95:    {avg_modular_p95:.1f}ms")
            print(f"  Monolithic avg P95: {avg_monolithic_p95:.1f}ms") 
            print(f"  Improvement:        {improvement:.1f}%")
        
        return len(failing_scenarios) == 0


def main():
    """Run performance benchmarks."""
    benchmark = HookBenchmark()
    results = benchmark.run_benchmarks()
    success = benchmark.analyze_results(results)
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
