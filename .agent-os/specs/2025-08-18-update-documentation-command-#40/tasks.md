# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-08-18-update-documentation-command-#40/spec.md

> Created: 2025-08-18
> Status: Ready for Implementation

## Tasks

- [x] 1. Fix the update-documentation.sh script to focus on documentation drift detection
  - [x] 1.1 Write tests for documentation drift detection functionality
  - [x] 1.2 Remove database configuration checks from the script
  - [x] 1.3 Implement normal mode documentation health checks
  - [x] 1.4 Verify all tests pass

- [x] 2. Implement deep mode comprehensive audit functionality
  - [x] 2.1 Write tests for deep mode audit functionality
  - [x] 2.2 Implement GitHub issue/spec cross-referencing
  - [x] 2.3 Implement file reference validation
  - [x] 2.4 Verify all tests pass

- [x] 3. Create the slash command interface
  - [x] 3.1 Create ~/.claude/commands/update-documentation.md
  - [x] 3.2 Update setup scripts to install the command
  - [x] 3.3 Test command integration

- [x] 4. Update instruction files and hooks
  - [x] 4.1 Update instructions/core/execute-tasks.md Phase 4
  - [x] 4.2 Update instructions/core/execute-task.md
  - [x] 4.3 Update hooks/workflow-enforcement-hook.py

- [x] 5. Update documentation and CI
  - [x] 5.1 Update README.md with command details
  - [x] 5.2 Update CLAUDE.md with command usage
  - [x] 5.3 Update CHANGELOG.md
  - [x] 5.4 Create CI guard workflow (already exists as docs-update-guard.yml)