#!/usr/bin/env python3
"""
Compatibility shim for hook_core.

This module re-exports all public members from hook_core_optimized to preserve
backward compatibility with existing imports that reference `hook_core`.

It supports two import contexts:
1) Direct module import with sys.path pointing to the modules directory:
   from hook_core import ...
   In this case, we use absolute import: from hook_core_optimized import *
2) Package import (hooks.modules.hook_core):
   from hooks.modules.hook_core import ...
   In this case, we fall back to relative import: from .hook_core_optimized import *
"""

# Prefer absolute import when the modules directory is on sys.path
try:
    from hook_core_optimized import *  # type: ignore  # noqa: F401,F403
except Exception:
    # Fallback for package-relative import
    from .hook_core_optimized import *  # type: ignore  # noqa: F401,F403

# Ensure __all__ is defined for explicit re-exports.
try:
    __all__  # type: ignore  # noqa: F401
except NameError:
    __all__ = [name for name in globals().keys() if not name.startswith("_")]