#!/usr/bin/env python3
"""
Test Runner Subagent - Test execution, validation, and coverage reporting.

This subagent provides comprehensive test management for Agent OS projects,
handling various test frameworks, coverage analysis, and result reporting.
"""

import os
import subprocess
import json
import re
from typing import Dict, Any, Optional, List, Tuple
from pathlib import Path
import logging

logger = logging.getLogger(__name__)


class TestRunnerAgent:
    """
    Specialized agent for test execution and validation.
    
    Provides:
    - Multi-framework test execution (pytest, unittest, jest, etc.)
    - Coverage analysis and reporting
    - Test discovery and filtering
    - Result parsing and formatting
    - Performance benchmarking
    """
    
    def __init__(self):
        """Initialize the test runner agent."""
        self.test_frameworks = {
            'python': {
                'pytest': {
                    'command': 'pytest',
                    'config_files': ['pytest.ini', 'pyproject.toml', 'setup.cfg'],
                    'test_patterns': ['test_*.py', '*_test.py'],
                    'coverage_flag': '--cov'
                },
                'unittest': {
                    'command': 'python -m unittest',
                    'config_files': [],
                    'test_patterns': ['test_*.py'],
                    'coverage_flag': None
                }
            },
            'javascript': {
                'jest': {
                    'command': 'jest',
                    'config_files': ['jest.config.js', 'jest.config.json'],
                    'test_patterns': ['*.test.js', '*.spec.js'],
                    'coverage_flag': '--coverage'
                },
                'mocha': {
                    'command': 'mocha',
                    'config_files': ['.mocharc.js', 'mocha.opts'],
                    'test_patterns': ['*.test.js', '*.spec.js'],
                    'coverage_flag': '--reporter=json'
                }
            },
            'typescript': {
                'jest': {
                    'command': 'jest',
                    'config_files': ['jest.config.ts'],
                    'test_patterns': ['*.test.ts', '*.spec.ts'],
                    'coverage_flag': '--coverage'
                },
                'vitest': {
                    'command': 'vitest',
                    'config_files': ['vitest.config.ts'],
                    'test_patterns': ['*.test.ts', '*.spec.ts'],
                    'coverage_flag': '--coverage'
                }
            }
        }
    
    def execute(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a test-related task.
        
        Args:
            task: Dictionary containing test operation parameters
            
        Returns:
            Dictionary with test results
        """
        operation = task.get('operation', 'run')
        
        if operation == 'run':
            return self._run_tests(task)
        elif operation == 'discover':
            return self._discover_tests(task)
        elif operation == 'coverage':
            return self._get_coverage(task)
        elif operation == 'benchmark':
            return self._run_benchmark(task)
        elif operation == 'validate':
            return self._validate_tests(task)
        else:
            return {'error': f'Unknown operation: {operation}'}
    
    def _detect_framework(self, path: str = '.') -> Tuple[str, str, Dict[str, Any]]:
        """
        Detect the test framework in use.
        
        Args:
            path: Project path to check
            
        Returns:
            Tuple of (language, framework, config)
        """
        project_path = Path(path)
        
        # Check for Python test frameworks
        if (project_path / 'pytest.ini').exists() or \
           (project_path / 'pyproject.toml').exists():
            return 'python', 'pytest', self.test_frameworks['python']['pytest']
        
        if any((project_path / f).exists() for f in ['test_*.py', '*_test.py']):
            # Check if pytest is available
            try:
                subprocess.run(['pytest', '--version'], 
                             capture_output=True, timeout=2)
                return 'python', 'pytest', self.test_frameworks['python']['pytest']
            except:
                return 'python', 'unittest', self.test_frameworks['python']['unittest']
        
        # Check for JavaScript/TypeScript frameworks
        if (project_path / 'package.json').exists():
            try:
                with open(project_path / 'package.json', 'r') as f:
                    package = json.load(f)
                    deps = {**package.get('dependencies', {}), 
                           **package.get('devDependencies', {})}
                    
                    if 'jest' in deps:
                        lang = 'typescript' if 'typescript' in deps else 'javascript'
                        return lang, 'jest', self.test_frameworks[lang]['jest']
                    elif 'vitest' in deps:
                        return 'typescript', 'vitest', self.test_frameworks['typescript']['vitest']
                    elif 'mocha' in deps:
                        return 'javascript', 'mocha', self.test_frameworks['javascript']['mocha']
            except:
                pass
        
        # Default to Python unittest
        return 'python', 'unittest', self.test_frameworks['python']['unittest']
    
    def _run_tests(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Run tests with the detected or specified framework.
        
        Args:
            task: Test execution parameters
            
        Returns:
            Test results
        """
        try:
            path = task.get('path', '.')
            pattern = task.get('pattern', '')
            framework = task.get('framework', '')
            verbose = task.get('verbose', False)
            coverage = task.get('coverage', False)
            
            # Detect framework if not specified
            if not framework:
                lang, framework, config = self._detect_framework(path)
            else:
                # Find framework config
                lang = task.get('language', 'python')
                config = self.test_frameworks.get(lang, {}).get(framework, {})
            
            if not config:
                return {
                    'success': False,
                    'error': f'Unknown framework: {framework}'
                }
            
            # Build command
            cmd = config['command'].split()
            
            # Add pattern if specified
            if pattern:
                cmd.append(pattern)
            
            # Add verbosity
            if verbose:
                if framework == 'pytest':
                    cmd.append('-v')
                elif framework == 'jest':
                    cmd.append('--verbose')
            
            # Add coverage
            if coverage and config.get('coverage_flag'):
                cmd.append(config['coverage_flag'])
            
            # Run tests
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=path,
                timeout=60
            )
            
            # Parse results
            test_results = self._parse_test_output(result.stdout, framework)
            
            return {
                'success': result.returncode == 0,
                'framework': framework,
                'language': lang,
                'tests_run': test_results.get('tests_run', 0),
                'tests_passed': test_results.get('tests_passed', 0),
                'tests_failed': test_results.get('tests_failed', 0),
                'tests_skipped': test_results.get('tests_skipped', 0),
                'duration': test_results.get('duration', 'unknown'),
                'output': result.stdout if verbose else test_results.get('summary', ''),
                'errors': result.stderr if result.returncode != 0 else None
            }
            
        except subprocess.TimeoutExpired:
            return {
                'success': False,
                'error': 'Test execution timeout (60s)'
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _parse_test_output(self, output: str, framework: str) -> Dict[str, Any]:
        """
        Parse test output based on framework.
        
        Args:
            output: Test output text
            framework: Test framework name
            
        Returns:
            Parsed test results
        """
        results = {
            'tests_run': 0,
            'tests_passed': 0,
            'tests_failed': 0,
            'tests_skipped': 0,
            'duration': 'unknown',
            'summary': ''
        }
        
        if framework == 'pytest':
            # Parse pytest output
            # Example: "5 passed, 1 failed, 2 skipped in 1.23s"
            match = re.search(
                r'(\d+) passed(?:, (\d+) failed)?(?:, (\d+) skipped)?(?:.* in ([\d.]+)s)?',
                output
            )
            if match:
                results['tests_passed'] = int(match.group(1))
                results['tests_failed'] = int(match.group(2) or 0)
                results['tests_skipped'] = int(match.group(3) or 0)
                results['tests_run'] = results['tests_passed'] + results['tests_failed']
                results['duration'] = f"{match.group(4)}s" if match.group(4) else 'unknown'
            
            # Get summary line
            lines = output.strip().split('\n')
            if lines:
                results['summary'] = lines[-1]
                
        elif framework == 'unittest':
            # Parse unittest output
            # Example: "Ran 10 tests in 0.005s"
            match = re.search(r'Ran (\d+) tests? in ([\d.]+)s', output)
            if match:
                results['tests_run'] = int(match.group(1))
                results['duration'] = f"{match.group(2)}s"
            
            # Check for OK or FAILED
            if 'OK' in output:
                results['tests_passed'] = results['tests_run']
            elif 'FAILED' in output:
                match = re.search(r'failures=(\d+)', output)
                if match:
                    results['tests_failed'] = int(match.group(1))
                    results['tests_passed'] = results['tests_run'] - results['tests_failed']
            
            # Get result line
            for line in output.split('\n'):
                if line.startswith('OK') or line.startswith('FAILED'):
                    results['summary'] = line
                    break
                    
        elif framework == 'jest':
            # Parse jest output
            # Example: "Tests: 2 failed, 3 passed, 5 total"
            match = re.search(
                r'Tests:\s+(?:(\d+) failed,\s*)?(?:(\d+) passed,\s*)?(\d+) total',
                output
            )
            if match:
                results['tests_failed'] = int(match.group(1) or 0)
                results['tests_passed'] = int(match.group(2) or 0)
                results['tests_run'] = int(match.group(3))
            
            # Duration
            match = re.search(r'Time:\s+([\d.]+)s', output)
            if match:
                results['duration'] = f"{match.group(1)}s"
            
            # Get summary
            for line in output.split('\n'):
                if 'Tests:' in line:
                    results['summary'] = line.strip()
                    break
        
        return results
    
    def _discover_tests(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Discover available tests in the project.
        
        Args:
            task: Discovery parameters
            
        Returns:
            List of discovered tests
        """
        try:
            path = task.get('path', '.')
            pattern = task.get('pattern', '*')
            
            lang, framework, config = self._detect_framework(path)
            test_files = []
            
            # Find test files based on framework patterns
            project_path = Path(path)
            for pattern in config.get('test_patterns', []):
                test_files.extend(project_path.rglob(pattern))
            
            # Parse test files to find test cases
            tests = []
            for test_file in test_files:
                file_tests = self._parse_test_file(test_file, lang, framework)
                tests.extend(file_tests)
            
            return {
                'success': True,
                'framework': framework,
                'language': lang,
                'test_files': len(test_files),
                'total_tests': len(tests),
                'tests': tests[:100]  # Limit to first 100
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _parse_test_file(self, file_path: Path, language: str, 
                        framework: str) -> List[Dict[str, str]]:
        """
        Parse a test file to find test cases.
        
        Args:
            file_path: Path to test file
            language: Programming language
            framework: Test framework
            
        Returns:
            List of test cases
        """
        tests = []
        
        try:
            with open(file_path, 'r') as f:
                content = f.read()
                
            if language == 'python':
                # Find test functions/methods
                pattern = r'def (test_\w+)'
                matches = re.findall(pattern, content)
                for match in matches:
                    tests.append({
                        'file': str(file_path),
                        'name': match,
                        'type': 'function'
                    })
                
                # Find test classes
                class_pattern = r'class (Test\w+)'
                classes = re.findall(class_pattern, content)
                for cls in classes:
                    tests.append({
                        'file': str(file_path),
                        'name': cls,
                        'type': 'class'
                    })
                    
            elif language in ['javascript', 'typescript']:
                # Find describe blocks
                describe_pattern = r'describe\([\'"]([^\'"]*)[\'"]\s*,'
                describes = re.findall(describe_pattern, content)
                for desc in describes:
                    tests.append({
                        'file': str(file_path),
                        'name': desc,
                        'type': 'suite'
                    })
                
                # Find it/test blocks
                test_pattern = r'(?:it|test)\([\'"]([^\'"]*)[\'"]\s*,'
                test_cases = re.findall(test_pattern, content)
                for test in test_cases:
                    tests.append({
                        'file': str(file_path),
                        'name': test,
                        'type': 'test'
                    })
                    
        except Exception as e:
            logger.warning(f"Failed to parse test file {file_path}: {e}")
        
        return tests
    
    def _get_coverage(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Get test coverage information.
        
        Args:
            task: Coverage parameters
            
        Returns:
            Coverage results
        """
        try:
            path = task.get('path', '.')
            
            # Run tests with coverage
            test_task = {**task, 'coverage': True}
            test_result = self._run_tests(test_task)
            
            if not test_result['success']:
                return test_result
            
            # Try to get coverage report
            lang, framework, _ = self._detect_framework(path)
            
            if framework == 'pytest':
                # Try to get coverage report
                result = subprocess.run(
                    ['coverage', 'report', '--format=json'],
                    capture_output=True,
                    text=True,
                    cwd=path,
                    timeout=10
                )
                
                if result.returncode == 0:
                    coverage_data = json.loads(result.stdout)
                    return {
                        'success': True,
                        'total_coverage': coverage_data.get('totals', {}).get('percent_covered', 0),
                        'files': coverage_data.get('files', {}),
                        'summary': f"Coverage: {coverage_data.get('totals', {}).get('percent_covered', 0):.1f}%"
                    }
            
            # Fallback to basic test results
            return {
                'success': True,
                'message': 'Tests run with coverage flag, but detailed report unavailable',
                **test_result
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _run_benchmark(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Run performance benchmarks.
        
        Args:
            task: Benchmark parameters
            
        Returns:
            Benchmark results
        """
        try:
            path = task.get('path', '.')
            iterations = task.get('iterations', 3)
            
            # Run tests multiple times to get performance data
            times = []
            for i in range(iterations):
                import time
                start = time.perf_counter()
                
                result = self._run_tests({**task, 'verbose': False})
                
                end = time.perf_counter()
                times.append(end - start)
                
                if not result['success']:
                    return {
                        'success': False,
                        'error': f"Benchmark failed on iteration {i+1}",
                        'details': result
                    }
            
            # Calculate statistics
            avg_time = sum(times) / len(times)
            min_time = min(times)
            max_time = max(times)
            
            return {
                'success': True,
                'iterations': iterations,
                'average_time': f"{avg_time:.3f}s",
                'min_time': f"{min_time:.3f}s",
                'max_time': f"{max_time:.3f}s",
                'all_times': [f"{t:.3f}s" for t in times]
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def _validate_tests(self, task: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate that tests meet quality standards.
        
        Args:
            task: Validation parameters
            
        Returns:
            Validation results
        """
        try:
            # Run tests
            test_result = self._run_tests(task)
            
            if not test_result['success']:
                return {
                    'success': False,
                    'validation': 'FAILED',
                    'reason': 'Tests are not passing',
                    'details': test_result
                }
            
            # Check coverage if required
            min_coverage = task.get('min_coverage', 0)
            if min_coverage > 0:
                coverage_result = self._get_coverage(task)
                if coverage_result.get('total_coverage', 0) < min_coverage:
                    return {
                        'success': False,
                        'validation': 'INSUFFICIENT_COVERAGE',
                        'reason': f"Coverage {coverage_result.get('total_coverage', 0):.1f}% is below minimum {min_coverage}%",
                        'details': coverage_result
                    }
            
            # Check test count
            min_tests = task.get('min_tests', 0)
            if test_result.get('tests_run', 0) < min_tests:
                return {
                    'success': False,
                    'validation': 'INSUFFICIENT_TESTS',
                    'reason': f"Only {test_result.get('tests_run', 0)} tests found, minimum is {min_tests}",
                    'details': test_result
                }
            
            return {
                'success': True,
                'validation': 'PASSED',
                'tests_run': test_result.get('tests_run', 0),
                'tests_passed': test_result.get('tests_passed', 0),
                'coverage': coverage_result.get('total_coverage', 'N/A') if min_coverage > 0 else 'N/A',
                'message': 'All validation criteria met'
            }
            
        except Exception as e:
            return {
                'success': False,
                'validation': 'ERROR',
                'error': str(e)
            }