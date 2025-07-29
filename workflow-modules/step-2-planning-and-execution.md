# Step 2: Planning and Execution  

## Task Assignment (Step 2)

**Task Selection Logic:**
- **Explicit:** User specifies exact task(s) to execute
- **Implicit:** Find next uncompleted parent task in tasks.md
- **Default:** Select next uncompleted task if not specified

**Confirmation Required:** Always confirm task selection with user before proceeding.

## Context Analysis (Step 2)

**Read Required Documentation:**
- Spec SRD file (main requirements)
- Spec tasks.md (task breakdown)
- All files in spec sub-specs/ folder (technical details)
- @.agent-os/product/mission.md (product alignment)

**Analysis Purpose:** Complete understanding of requirements and how task fits into overall spec goals.

## Implementation Planning (Step 3)

**Create Detailed Execution Plan:**
- Numbered list with sub-bullets
- All subtasks from tasks.md included
- Implementation approach described
- Dependencies to install identified
- Test strategy outlined

**Plan Template:**
```
## Implementation Plan for [TASK_NAME]

1. **[MAJOR_STEP_1]**
   - [SPECIFIC_ACTION]
   - [SPECIFIC_ACTION]

2. **[MAJOR_STEP_2]**
   - [SPECIFIC_ACTION]

**Dependencies to Install:**
- [LIBRARY_NAME] - [PURPOSE]

**Test Strategy:**
- [TEST_APPROACH]
```

**BLOCKING:** Do not proceed without explicit user approval of the plan.

## Development Server Check (Step 4)

**Check for Running Server:**
- Detect if development server is running on configured ports
- If running: Ask user permission to shut down
- If not running: Proceed immediately

**User Prompt (only if server detected):**
"A development server is currently running. Should I shut it down before proceeding? (yes/no)"

## Git Branch Management (Step 5)

**Branch Naming:** Derive from spec folder name (exclude date prefix)
- Example: folder `2025-03-15-password-reset-#123` → branch `password-reset`

**Branch Logic:**
- **Case A:** Current branch matches spec name → PROCEED immediately
- **Case B:** Current branch is main/staging/review → CREATE new branch and PROCEED  
- **Case C:** Current branch is different feature → ASK permission to create new branch

**Case C Prompt:**
"Current branch: [CURRENT_BRANCH]. This spec needs branch: [SPEC_BRANCH]. May I create a new branch for this spec? (yes/no)"

## Development Execution (Step 6)

**Execution Standards:**
- Follow approved implementation plan exactly
- Adhere to all spec specifications
- Apply @.agent-os/product/code-style.md
- Apply @.agent-os/product/dev-best-practices.md
- Use Test-Driven Development (TDD) approach

**TDD Workflow:**
1. Write failing tests first
2. Implement minimal code to pass  
3. Refactor while keeping tests green
4. Repeat for each feature

**Optional Linting During Development:**
- Run linting if configs detected (ESLint, Prettier, TypeScript, Ruff)
- Fix obvious formatting issues  
- Report but don't block on linting errors (save blocking for QA step)

## Next Steps

After planning and execution complete:
1. Proceed to task status updates
2. Continue to quality assurance verification
3. Maintain coding standards throughout