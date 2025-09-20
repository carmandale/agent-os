#!/usr/bin/env python3
"""
Compatibility shim for hook_core.

This module re-exports all public members from hook_core_optimized to preserve
backward compatibility with existing imports that reference `hook_core`.

Do not add logic here; all implementations live in hook_core_optimized.py.
"""

# Re-export everything from the optimized core
from .hook_core_optimized import *  # noqa: F401,F403

# Ensure __all__ is defined for explicit re-exports. If the optimized module
# defines __all__, it will already be present due to the wildcard import above.
# Otherwise, build it from current globals (excluding private names).
try:
    __all__  # type: ignore  # noqa: F401
except NameError:
    __all__ = [name for name in globals().keys() if not name.startswith("_")]