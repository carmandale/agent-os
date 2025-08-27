#!/usr/bin/env python3
"""
Agent OS Hook Core Module - Optimized Version
=============================================
Performance-optimized shared utilities with caching and async patterns.
"""

import json
import os
import subprocess
import sys
import threading
import time
from datetime import datetime
from typing import Optional, Dict, Any, List, Tuple
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeoutError

# Add parent directory to path for project root resolver
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
try:
    from scripts.project_root_resolver import ProjectRootResolver
except ImportError:
    ProjectRootResolver = None


# Global cache with TTL
class TTLCache:
    """Simple thread-safe TTL cache for subprocess results."""
    
    def __init__(self, default_ttl=30):
        self._cache = {}
        self._timestamps = {}
        self._lock = threading.Lock()
        self.default_ttl = default_ttl
    
    def get(self, key: str, ttl: int = None) -> Optional[Any]:
        """Get cached value if not expired."""
        with self._lock:
            if key not in self._cache:
                return None
            
            age = time.time() - self._timestamps[key]
            if age > (ttl or self.default_ttl):
                del self._cache[key]
                del self._timestamps[key]
                return None
            
            return self._cache[key]
    
    def set(self, key: str, value: Any) -> None:
        """Set cached value with current timestamp."""
        with self._lock:
            self._cache[key] = value
            self._timestamps[key] = time.time()


# Global cache instance
_cache = TTLCache()


class OptimizedSubprocess:
    """Optimized subprocess execution with caching and timeouts."""
    
    @staticmethod
    def run_cached(cmd: List[str], cwd: str = None, timeout: float = 2.0, 
                   cache_key: str = None, cache_ttl: int = 10) -> Tuple[int, str, str]:
        """Run subprocess with caching and strict timeout."""
        # Create cache key from command and cwd
        if cache_key is None:
            cache_key = f"{':'.join(cmd)}:{cwd or 'none'}"
        
        # Try cache first
        cached = _cache.get(cache_key, cache_ttl)
        if cached is not None:
            return cached
        
        # Run with timeout using ThreadPoolExecutor for reliability
        with ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(subprocess.run, cmd, 
                                   capture_output=True, text=True, 
                                   cwd=cwd, timeout=timeout)
            try:
                result = future.result(timeout=timeout + 0.5)  # Small buffer
                output = (result.returncode, result.stdout or "", result.stderr or "")
                _cache.set(cache_key, output)
                return output
            except (FuturesTimeoutError, subprocess.TimeoutExpired):
                return (124, "", "Command timed out")  # 124 is timeout exit code
            except Exception as e:
                return (1, "", str(e))


class HookError(Exception):
    """Base exception for hook-related errors."""
    pass


class HookLogger:
    """Optimized logging with reduced I/O."""
    
    _log_buffer = []
    _last_flush = time.time()
    _lock = threading.Lock()
    
    @classmethod
    def debug(cls, message: str) -> None:
        """Write debug logs with buffering."""
        if os.environ.get("AGENT_OS_DEBUG", "").lower() != "true":
            return
        
        timestamp = datetime.now().isoformat()
        log_entry = f"[{timestamp}] {message}"
        
        with cls._lock:
            cls._log_buffer.append(log_entry)
            
            # Flush buffer every 5 seconds or when it gets large
            now = time.time()
            if (now - cls._last_flush > 5.0) or (len(cls._log_buffer) > 20):
                cls._flush_buffer()
                cls._last_flush = now
    
    @classmethod
    def _flush_buffer(cls):
        """Flush log buffer to disk."""
        if not cls._log_buffer:
            return
        
        log_path = Path.home() / ".agent-os" / "logs" / "hooks-debug.log"
        log_path.parent.mkdir(parents=True, exist_ok=True)
        
        try:
            with open(log_path, "a") as f:
                f.write("\n".join(cls._log_buffer) + "\n")
            cls._log_buffer.clear()
        except Exception:
            pass  # Don't let logging failures break hooks


class WorkspaceResolver:
    """Optimized workspace resolution."""
    
    @staticmethod
    def resolve(input_data: Optional[Dict[str, Any]] = None) -> str:
        """Fast workspace resolution with minimal fallback."""
        # Use ProjectRootResolver if available (cached)
        if ProjectRootResolver:
            try:
                resolver = ProjectRootResolver()
                file_path = None
                if input_data:
                    tool_input = input_data.get("tool_input", {}) or {}
                    for key in ["file_path", "path"]:
                        p = tool_input.get(key)
                        if isinstance(p, str) and p.strip():
                            file_path = p
                            break
                
                return resolver.resolve(file_path=file_path, hook_payload=input_data)
            except Exception:
                pass
        
        # Quick fallback to current directory (most common case)
        return os.getcwd()


class GitChecker:
    """Optimized git checks with aggressive caching."""
    
    @staticmethod
    def has_uncommitted_changes(cwd: str) -> bool:
        """Check git status with caching."""
        try:
            returncode, stdout, _ = OptimizedSubprocess.run_cached(
                ["git", "status", "--porcelain"], 
                cwd=cwd, timeout=3.0, cache_ttl=5
            )
            return returncode == 0 and bool(stdout.strip())
        except Exception:
            return False
    
    @staticmethod
    def has_open_prs(cwd: str) -> bool:
        """Check for open PRs with caching."""
        try:
            returncode, stdout, _ = OptimizedSubprocess.run_cached(
                ["gh", "pr", "list", "--state", "open", "--json", "number"], 
                cwd=cwd, timeout=3.0, cache_ttl=15
            )
            if returncode == 0:
                try:
                    prs = json.loads(stdout or "[]")
                    return len(prs) > 0
                except json.JSONDecodeError:
                    return False
            return False
        except Exception:
            return False


class IntentAnalyzer:
    """Optimized intent analysis with fallback and caching."""
    
    @staticmethod
    def get_intent(prompt_text: str = "") -> str:
        """Fast intent analysis with environment override."""
        # Environment override (fastest path)
        env_intent = os.environ.get("AGENT_OS_INTENT", "").strip().upper()
        if env_intent in {"MAINTENANCE", "NEW", "AMBIGUOUS"}:
            return env_intent
        
        # Use cached analyzer with short timeout
        text = prompt_text or os.environ.get("CLAUDE_USER_PROMPT", "")
        if not text.strip():
            return "AMBIGUOUS"
        
        try:
            returncode, stdout, _ = OptimizedSubprocess.run_cached(
                [os.path.expanduser("~/.agent-os/scripts/intent-analyzer.sh"), "--text", text],
                timeout=2.0, cache_ttl=30
            )
            val = (stdout or "").strip().upper()
            return val if val in {"MAINTENANCE", "NEW", "AMBIGUOUS"} else "AMBIGUOUS"
        except Exception:
            return "AMBIGUOUS"


class SpecChecker:
    """Optimized spec detection with filesystem caching."""
    
    @staticmethod
    def has_active_spec(cwd: str) -> bool:
        """Fast spec detection with caching."""
        try:
            returncode, stdout, _ = OptimizedSubprocess.run_cached(
                ["bash", "-lc", "ls -1 .agent-os/specs 2>/dev/null | wc -l"],
                cwd=cwd, timeout=2.0, cache_ttl=10
            )
            count = int((stdout or "0").strip())
            return returncode == 0 and count > 0
        except (ValueError, Exception):
            return False


class BaseHookHandler:
    """Optimized base handler with minimal initialization."""
    
    def __init__(self, input_data: Dict[str, Any]):
        self.input_data = input_data
        self._workspace_root = None  # Lazy initialization
        
    @property
    def workspace_root(self) -> str:
        """Lazy workspace resolution."""
        if self._workspace_root is None:
            self._workspace_root = WorkspaceResolver.resolve(self.input_data)
        return self._workspace_root
    
    def log_debug(self, message: str) -> None:
        """Log debug message."""
        HookLogger.debug(f"{self.__class__.__name__}: {message}")
    
    def get_tool_name(self) -> str:
        """Get the tool name from input data."""
        return self.input_data.get("tool_name", "")
    
    def get_tool_input(self) -> Dict[str, Any]:
        """Get the tool input from input data."""
        return self.input_data.get("tool_input", {})
    
    def exit_allow(self, reason: str = "") -> None:
        """Exit with success (allow the operation)."""
        if reason:
            self.log_debug(f"Allowing: {reason}")
        sys.exit(0)
    
    def exit_block(self, reason: str) -> None:
        """Exit with error (block the operation)."""
        self.log_debug(f"Blocking: {reason}")
        print(reason, file=sys.stderr)
        sys.exit(2)
    
    def check_work_session(self) -> bool:
        """Fast work session check."""
        work_session_active = os.environ.get("AGENT_OS_WORK_SESSION", "").lower() == "true"
        if work_session_active:
            return True
        
        session_file = os.path.expanduser("~/.agent-os/cache/work-session")
        return os.path.exists(session_file)
    
    def check_workflow_status(self) -> List[str]:
        """Optimized workflow status check."""
        issues = []
        
        # Skip expensive checks in work session mode
        if self.check_work_session():
            self.log_debug("Work session mode active - skipping hygiene checks")
            return issues
        
        # Use parallel execution for git checks
        with ThreadPoolExecutor(max_workers=2) as executor:
            git_future = executor.submit(GitChecker.has_uncommitted_changes, self.workspace_root)
            pr_future = executor.submit(GitChecker.has_open_prs, self.workspace_root)
            
            try:
                if git_future.result(timeout=3.0):
                    issues.append("Uncommitted changes detected")
            except Exception:
                pass
            
            try:
                if pr_future.result(timeout=3.0):
                    issues.append("Open pull requests need review/merge")
            except Exception:
                pass
        
        return issues
    
    def handle(self) -> None:
        """Main handler method to be implemented by subclasses."""
        raise NotImplementedError("Subclasses must implement handle() method")
