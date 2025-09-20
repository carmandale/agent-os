# Experimental Hook Tests

This directory contains experimental or planned tests that currently depend on modules not yet implemented in this repository (e.g., a future `context_aware_hook.py`) or on external modules that are not available.

Purpose:
- Quarantine non-passing tests without deleting them
- Preserve test intent for future implementation work
- Keep CI green while documenting outstanding work

Notes:
- These tests are not part of the stable CI test suite.
- Once the missing modules are implemented, move the corresponding tests back to the primary test locations and re-enable them in CI.
- Example missing dependencies referenced by these tests:
  - `context_aware_hook.py` (planned context-aware workflow hook)
  - Any other future modules referenced by these tests

Status:
- Kept for reference and future activation.