#!/bin/bash
# Migration script from monolithic to modular hooks

echo "Migrating Agent OS hooks to modular architecture..."

# Backup current hooks
cp ~/.agent-os/hooks/workflow-enforcement-hook.py ~/.agent-os/hooks/workflow-enforcement-hook.py.backup

# Install new modular hooks  
./setup.sh

echo "Migration complete. Old hooks backed up with .backup extension"
