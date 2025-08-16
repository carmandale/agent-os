#!/usr/bin/env bash
# Pre-command guard: load session config and validate command consistency
set -euo pipefail

# Ensure cache is current and variables are exported
bash scripts/session-memory.sh maybe-refresh-and-export || true

# Validate intended command (all args)
bash scripts/config-validator.sh "$@"


