# Spec Requirements Document

> Spec: AOS Installer Improvements
> Created: 2025-08-18
> GitHub Issue: #65
> Status: Planning

## Overview

Fix the Agent OS CLI installer to properly update Claude hooks when needed and enhance the init command to handle all project setup issues. This improves user experience by ensuring update commands actually update all outdated components as detected.

## User Stories

### Fix Hook Update Detection

As a developer using Agent OS, I want the `aos update` command to actually update my Claude hooks when `aos status` detects they need updating, so that I can maintain current workflow enforcement without manual intervention.

**Workflow**: User runs `aos status` → sees "Claude hooks need update" → runs `aos update` → hooks are actually updated → subsequent `aos status` shows hooks are current.

### Enhanced Init Command

As a developer setting up Agent OS in a project, I want the `aos init` command to detect and fix all project setup issues comprehensively, so that my project environment is properly configured for Agent OS workflows.

**Workflow**: User runs `aos init` in a project with various setup issues → command detects all problems → offers to fix them individually or all at once → actually resolves the issues → provides clear feedback about what was updated.

### Clear Update Feedback

As a developer maintaining Agent OS installations, I want clear, specific feedback about what components were updated during any update operation, so that I understand exactly what changed and can verify the update was successful.

**Workflow**: User runs any update command → system shows what was checked, what needed updating, and what was actually updated → user has confidence in the system state.

## Spec Scope

1. **Hook Update Logic** - Fix the smart_update() function to properly handle Claude hook updates when detected
2. **Project Issue Detection** - Enhance check_project_currency() to comprehensively detect all setup issues  
3. **Init Command Enhancement** - Improve quick_setup_project() to handle all detected project issues
4. **Update Feedback System** - Add detailed reporting of what was updated during any operation
5. **Hook Update Mechanism** - Create dedicated hook update functionality that can be called from multiple commands

## Out of Scope

- Changing the hook detection algorithm itself (focus on fixing the update mechanism)
- Adding new types of project setup beyond current Claude/Cursor support
- Rewriting the entire CLI architecture (focused improvements only)

## Expected Deliverable

1. Users can successfully update Claude hooks when `aos status` detects they need updating
2. `aos init` command properly resolves all detected project setup issues
3. All update commands provide clear feedback about what was checked and updated
4. Hook updates work reliably across different project configurations

## Spec Documentation

- Tasks: @.agent-os/specs/2025-08-18-aos-installer-improvements-#65/tasks.md
- Technical Specification: @.agent-os/specs/2025-08-18-aos-installer-improvements-#65/sub-specs/technical-spec.md
- Tests Specification: @.agent-os/specs/2025-08-18-aos-installer-improvements-#65/sub-specs/tests.md