# Test Fixtures for Stop-Hook Context

This directory contains test fixtures for the stop-hook context extraction enhancement.

## Files

### branch-names.txt
Contains various branch naming patterns to test issue number extraction:
- Standard patterns: `feature-#123-description`
- Issue at start: `#123-feature-name`
- Issue at end: `feature-name-#123`
- No issue: `feature-name`
- Edge cases: multiple issues, zero issue, large numbers

### spec-folders.txt
Contains spec folder naming patterns to test spec detection:
- Standard date-prefixed folders: `2025-10-12-feature-name-#98`
- Various date formats
- Edge cases: non-standard names, files, hidden folders

## Usage

These fixtures are used by `test-stop-hook-context.sh` to verify that the context extraction functions handle all supported patterns correctly.

Tests should read these files and create temporary test repositories with the specified branch names or spec folder structures.
