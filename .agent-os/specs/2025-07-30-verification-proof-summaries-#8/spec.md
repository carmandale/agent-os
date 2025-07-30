# Spec Requirements Document

> Spec: Verification Proof in Completion Summaries
> Created: 2025-07-30
> GitHub Issue: #8
> Status: Planning

## Overview

Require verification proof in all completion summaries to prevent Claude from claiming work is complete without demonstrating that features actually work, ensuring completion claims are backed by concrete evidence.

**CLAUDE CODE INTEGRATION NOTE**: This solution integrates with the completed Claude Code hooks system (Issue #37) and relates to project configuration amnesia prevention (Issue #12). Verification proof will be enforced through workflow modules and hooks to ensure Claude cannot mark tasks complete without providing evidence.

## User Stories

### Evidence-Based Completion Claims

As a developer using Agent OS, I want Claude to provide concrete proof that features work before marking them complete, so that I can trust completion summaries and know work is actually finished.

**Current Problem:** Claude frequently claims work is complete without testing:
- Marks authentication as "✓ COMPLETE" without testing login flow
- Claims scripts work without running them
- Says tests pass without showing test output
- Reports "all functionality verified" without evidence

**Expected Workflow:** Claude must provide verification proof before any completion claims - test output, screenshots, command results, or functional demonstrations.

### Trust Restoration in AI Assistance

As a developer, I want to trust that when Claude says something is complete, it actually works, so that I don't waste time debugging "finished" features that are broken.

**Required Evidence Types:**
- Frontend features: Browser screenshots or Playwright test results
- Backend APIs: curl command results or API test output  
- Scripts: Actual execution output with success confirmation
- Tests: Complete test suite results showing pass/fail status

## Spec Scope

1. **Mandatory Verification Requirements** - Define what evidence is required for different types of work
2. **Evidence Collection System** - Automated capture of verification proof during task execution
3. **Completion Summary Templates** - Standardized formats that require evidence before completion claims
4. **Hook Integration** - Prevent completion without verification through Claude Code hooks
5. **Validation Workflow** - Multi-step verification process for complex features

## Out of Scope

- Manual verification for non-Agent OS workflows
- Complex integration testing beyond basic functionality proof
- Performance testing or load testing requirements
- Third-party service verification (external APIs, services)

## Expected Deliverable

1. **No completion without verification proof** - Claude cannot mark work complete without providing concrete evidence
2. **Evidence included in all summaries** - Test output, screenshots, or functional proof required in completion summaries
3. **Verification templates enforced** - Standardized proof requirements for frontend, backend, and script work