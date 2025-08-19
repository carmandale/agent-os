# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-08-18-aos-installer-improvements-#65/spec.md

> Created: 2025-08-18
> Version: 1.0.0

## Technical Requirements

### Hook Update Detection Enhancement
- Modify `check_project_currency()` to return structured data about specific issues
- Add hook version checking that compares against expected hook identifiers
- Implement hook update detection that works independently of global installation status

### Smart Update Function Improvements  
- Enhance `smart_update()` to handle project-level component updates
- Add hook update capability when project issues are detected
- Maintain backward compatibility with existing update workflow

### Init Command Enhancement
- Expand `quick_setup_project()` to handle comprehensive project issue resolution
- Add interactive and non-interactive modes for fixing multiple issues
- Implement granular control over which issues to fix

### Update Feedback System
- Add detailed logging of what components were checked during updates
- Provide clear before/after status reporting
- Include specific information about hook versions and what changed

### Hook Update Mechanism
- Create dedicated `update_claude_hooks()` function
- Ensure hook updates work regardless of whether hooks are currently installed
- Add validation that hook updates actually succeeded

## Approach Options

**Option A:** Minimal Changes - Just fix the hook update detection
- Pros: Low risk, minimal code changes, focused fix
- Cons: Doesn't address broader init command issues, limited scope

**Option B:** Comprehensive Project Setup Overhaul (Selected)
- Pros: Addresses all related project setup issues, improves overall user experience
- Cons: Larger scope, more testing required, potential for regressions

**Option C:** Separate Hook Management Command
- Pros: Clear separation of concerns, specific hook management
- Cons: Adds complexity, another command to learn, doesn't fix existing commands

**Rationale:** Option B is selected because the hook update issue is symptomatic of broader project setup reliability problems. A comprehensive fix improves the overall reliability of Agent OS installer components.

## External Dependencies

- **None** - All changes use existing bash scripting and curl utilities
- **Justification:** Maintaining the current shell-based architecture for maximum compatibility

## Implementation Details

### Hook Update Flow
1. Detect current hook configuration in `$HOME/.claude/settings.json`
2. Compare against expected hook version identifiers
3. If outdated, re-run hook installation process
4. Validate that hooks were properly updated
5. Provide clear feedback about the update

### Project Issue Detection Enhancement
1. Return structured issue data instead of simple strings
2. Include severity levels for different types of issues
3. Add specific remediation actions for each issue type
4. Support batch processing of multiple issues

### Update Command Integration
1. Check for both global and project-level update needs
2. Handle project updates when global installation is current
3. Provide unified reporting across all update types
4. Support selective updates based on user preferences

### Error Handling
- Graceful fallback when hook updates fail
- Clear error messages with specific remediation steps
- Validation of successful updates before claiming completion
- Rollback capability if updates partially fail