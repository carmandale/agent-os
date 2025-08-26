"""
TTL-based memory cache for expensive operations
"""
import time
from typing import Any, Optional, Dict

class CacheManager:
    def __init__(self):
        self._cache: Dict[str, tuple[Any, float]] = {}
        self._ttl_seconds = 30  # Default TTL
    
    def get(self, key: str) -> Optional[Any]:
        """Get value from cache if not expired"""
        if key in self._cache:
            value, timestamp = self._cache[key]
            if time.time() - timestamp < self._ttl_seconds:
                return value
            else:
                del self._cache[key]
        return None
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        """Store value in cache with TTL"""
        ttl = ttl or self._ttl_seconds
        self._cache[key] = (value, time.time())
    
    def clear(self) -> None:
        """Clear all cached values"""
        self._cache.clear()

# Singleton instance
cache = CacheManager()
