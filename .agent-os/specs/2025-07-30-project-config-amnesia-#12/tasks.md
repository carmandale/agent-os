# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-07-30-project-config-amnesia-#12/spec.md

> Created: 2025-07-30
> Status: Ready for Implementation

## Tasks

- [ ] 1. Create Core Configuration Loading Infrastructure
  - [ ] 1.1 Write tests for project-context-loader.sh main entry point
  - [ ] 1.2 Implement project-context-loader.sh with configuration file detection
  - [ ] 1.3 Create configuration parsing utilities for .env, .env.local files
  - [ ] 1.4 Add startup script analysis for start.sh, dev.sh, package.json
  - [ ] 1.5 Implement Agent OS tech-stack.md parsing functionality
  - [ ] 1.6 Add error handling and graceful fallbacks for missing files
  - [ ] 1.7 Verify all configuration loading tests pass

- [ ] 2. Build Configuration Resolution and Hierarchy System
  - [ ] 2.1 Write tests for config-resolver.py configuration merging logic
  - [ ] 2.2 Implement config-resolver.py with JSON configuration processing
  - [ ] 2.3 Create configuration hierarchy resolution (env files > startup scripts > tech-stack.md > global)
  - [ ] 2.4 Add precedence rule application for conflicting configuration values
  - [ ] 2.5 Implement port number extraction and validation from various sources
  - [ ] 2.6 Add package manager detection patterns and validation
  - [ ] 2.7 Verify all configuration resolution tests pass

- [ ] 3. Implement Session Memory and Persistence
  - [ ] 3.1 Write tests for session-memory.sh state management
  - [ ] 3.2 Create session-memory.sh with configuration storage in environment variables
  - [ ] 3.3 Implement configuration caching using ~/.agent-os/cache/session-config.json
  - [ ] 3.4 Add session validation and configuration drift detection
  - [ ] 3.5 Create cache invalidation when configuration files change
  - [ ] 3.6 Add memory cleanup and reset functionality
  - [ ] 3.7 Verify all session memory tests pass

- [ ] 4. Create Configuration Validation and Auto-Correction
  - [ ] 4.1 Write tests for config-validator.sh command validation logic
  - [ ] 4.2 Implement config-validator.sh with pre-command validation
  - [ ] 4.3 Add auto-correction for common configuration violations
  - [ ] 4.4 Create detection patterns for package manager switches (uv vs pip, npm vs yarn)
  - [ ] 4.5 Implement port number validation in command contexts
  - [ ] 4.6 Add startup command consistency checking
  - [ ] 4.7 Verify all validation and auto-correction tests pass

- [ ] 5. Integrate with Existing Hook System
  - [ ] 5.1 Write tests for hook integration with configuration loading
  - [ ] 5.2 Modify user-prompt-submit-hook.sh to call project-context-loader.sh
  - [ ] 5.3 Enhance context injection to include resolved project configuration
  - [ ] 5.4 Add pre-command validation hook integration
  - [ ] 5.5 Optimize hook performance to minimize execution time
  - [ ] 5.6 Test hook behavior with various Claude Code interaction patterns
  - [ ] 5.7 Verify all hook integration tests pass

- [ ] 6. Update Workflow Modules for Configuration Awareness
  - [ ] 6.1 Write tests for workflow module integration
  - [ ] 6.2 Update step-1-hygiene-and-setup.md to include mandatory context loading
  - [ ] 6.3 Modify execute-tasks.md to reference loaded configuration consistently
  - [ ] 6.4 Enhance project-context-loader references throughout workflow modules
  - [ ] 6.5 Add configuration validation checkpoints in critical workflow steps
  - [ ] 6.6 Update workflow error handling to account for configuration issues
  - [ ] 6.7 Verify all workflow module integration tests pass

- [ ] 7. Create Installation and Setup Integration
  - [ ] 7.1 Write tests for setup script integration
  - [ ] 7.2 Update setup-claude-code.sh to install configuration loading hooks
  - [ ] 7.3 Add configuration loading to health check verification (check-agent-os.sh)
  - [ ] 7.4 Create configuration template files for new projects
  - [ ] 7.5 Add migration support for existing Agent OS installations
  - [ ] 7.6 Update installation documentation with configuration loading features
  - [ ] 7.7 Verify all setup and installation tests pass

- [ ] 8. Performance Optimization and Error Handling
  - [ ] 8.1 Write comprehensive performance and error handling tests
  - [ ] 8.2 Optimize configuration loading performance for large projects
  - [ ] 8.3 Implement robust error handling for malformed configuration files
  - [ ] 8.4 Add comprehensive logging and debug mode support
  - [ ] 8.5 Create graceful degradation when configuration detection fails
  - [ ] 8.6 Add performance monitoring and optimization for hook integration
  - [ ] 8.7 Verify all performance and error handling requirements are met

- [ ] 9. End-to-End Testing and Validation
  - [ ] 9.1 Write comprehensive integration tests for complete workflows
  - [ ] 9.2 Test configuration loading with real-world project structures
  - [ ] 9.3 Validate configuration persistence across multiple Claude Code sessions
  - [ ] 9.4 Test configuration amnesia prevention in various interaction scenarios
  - [ ] 9.5 Validate hook integration performance and reliability
  - [ ] 9.6 Test migration scenarios from current Agent OS installations
  - [ ] 9.7 Verify all end-to-end tests pass and configuration amnesia is eliminated