"""
Git utilities with caching and timeout management
"""
import subprocess
import asyncio
from typing import Optional, Tuple
from .cache_manager import cache

async def check_git_status_async(cwd: str, timeout: float = 0.5) -> bool:
    """Check git status with timeout and caching"""
    cache_key = f"git_status_{cwd}_{int(time.time()/30)}"
    
    if cached := cache.get(cache_key):
        return cached
    
    try:
        proc = await asyncio.create_subprocess_exec(
            'git', 'status', '--porcelain',
            cwd=cwd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await asyncio.wait_for(
            proc.communicate(), 
            timeout=timeout
        )
        
        result = proc.returncode == 0 and len(stdout.strip()) == 0
        cache.set(cache_key, result)
        return result
        
    except asyncio.TimeoutError:
        # Fail open for performance
        return True
    except Exception:
        return True

def check_git_status_sync(cwd: str) -> bool:
    """Synchronous wrapper for git status check"""
    return asyncio.run(check_git_status_async(cwd))
