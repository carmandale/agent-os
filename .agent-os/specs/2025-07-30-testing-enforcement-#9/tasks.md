# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-07-30-testing-enforcement-#9/spec.md

> Created: 2025-07-30
> Status: Ready for Implementation

## Tasks

- [x] 1. Create Testing Enforcement Hook System
  - [x] 1.1 Write tests for testing detection in Claude's responses
  - [x] 1.2 Create testing-enforcer.sh to detect completion claims without evidence
  - [x] 1.3 Implement patterns to identify "complete" claims in responses
  - [x] 1.4 Add detection for common false completion phrases
  - [x] 1.5 Create blocking mechanism when testing evidence is missing
  - [x] 1.6 Integrate with existing stop-hook.sh system
  - [x] 1.7 Verify all detection tests pass

- [ ] 2. Build Testing Evidence Standards
  - [x] 2.1 Write tests for evidence validation logic
  - [x] 2.2 Define required evidence for frontend work (browser/Playwright)
  - [x] 2.3 Define required evidence for backend work (API calls/tests)
  - [x] 2.4 Define required evidence for scripts (execution output)
  - [ ] 2.5 Create evidence templates for different work types
  - [ ] 2.6 Implement evidence extraction from Claude's responses
  - [ ] 2.7 Verify all evidence validation tests pass

- [ ] 3. Implement Workflow Module Updates
  - [ ] 3.1 Write tests for updated workflow behavior
  - [ ] 3.2 Update step-3-quality-assurance.md with testing requirements
  - [ ] 3.3 Add mandatory testing step before completion claims
  - [ ] 3.4 Create testing checklist templates
  - [ ] 3.5 Update completion summary requirements
  - [ ] 3.6 Add testing evidence to PR descriptions
  - [ ] 3.7 Verify workflow integration tests pass

- [ ] 4. Create Testing Reminder System
  - [ ] 4.1 Write tests for testing reminder injection
  - [ ] 4.2 Create testing-reminder.sh for context injection
  - [ ] 4.3 Add reminders based on work type detection
  - [ ] 4.4 Integrate with user-prompt-submit-hook.sh
  - [ ] 4.5 Create work-type specific testing guidance
  - [ ] 4.6 Add testing commands suggestions
  - [ ] 4.7 Verify reminder system tests pass

- [ ] 5. End-to-End Testing and Validation
  - [ ] 5.1 Write integration tests for complete system
  - [ ] 5.2 Test frontend completion blocking without browser proof
  - [ ] 5.3 Test backend completion blocking without API tests
  - [ ] 5.4 Test script completion blocking without execution
  - [ ] 5.5 Verify false positive prevention
  - [ ] 5.6 Test with real Agent OS workflows
  - [ ] 5.7 Verify all integration tests pass