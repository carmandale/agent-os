# Step 3: Quality Assurance

## Task Status Updates (Step 7)

**Update Format:**
- Completed: `- [x] Task description`  
- Incomplete: `- [ ] Task description`
- Blocked: `- [ ] Task description ⚠️ Blocking issue: [DESCRIPTION]`
- Awaiting Validation: `- [ ] Task description 🔍 Awaiting validation: [DESCRIPTION]`

**CRITICAL COMPLETION REQUIREMENTS:**
- **NEVER mark [x] without Step 8.5 validation proof**
- Frontend work: Browser validation complete
- Backend work: API testing complete  
- All work: Functionality proven working

**Blocking Criteria:**
- Maximum 3 different approaches attempted
- Document blocking issues with ⚠️ emoji
- Validation required before any completion claims

## Quality Assurance Verification (Step 8)

**MANDATORY Quality Checks (ALL must pass):**

**Linting and Typing (ZERO tolerance):**
- ESLint (if config exists): zero errors, zero warnings
- Prettier (if config exists): zero errors, zero warnings  
- TypeScript compiler (if tsconfig.json exists): zero errors
- Ruff linting (if config exists): zero errors, zero warnings
- **Failure Action:** STOP - fix ALL issues before proceeding

**Test Execution (100% pass rate required):**
1. Verify new tests pass
2. Run entire test suite
3. Run web UI tests (if web project)
- **Requirement:** 100% pass rate - NO EXCEPTIONS
- **Failure Action:** STOP - ALL tests MUST pass

**Web UI Testing (MANDATORY for web projects):**
- **Detection:** Check for React/Next.js/Vue/Angular in package.json or tech-stack.md
- **Playwright Check:** Does project have Playwright config?
  - If exists: Run Playwright tests automatically
  - If missing: MANDATORY setup required (no skip option)
- **Reasoning:** Web projects without E2E testing are incomplete

**WORKFLOW COMPLETION ENFORCEMENT:**
⚠️ **Quality checks passing does NOT equal completion!**

**REQUIRED COMPLETION STEPS after Step 8:**
- Step 9: Git workflow (commit, push, PR creation)  
- Step 10: Roadmap progress check
- Step 11: Completion notification
- Step 12: Completion summary  
- Step 13: PR and issue cleanup
- Step 14: Workspace reset to main branch

**CRITICAL DEFINITION OF "COMPLETE":**
- ❌ **NOT Complete:** Code works and tests pass (technical-only)
- ✅ **ACTUALLY Complete:** Code works + committed + PR created + workspace clean

**ENFORCEMENT:** Cannot proceed to "completion" without executing Steps 9-14.

## Mandatory Functionality Validation (Step 8.5)

**PURPOSE:** BLOCK completion until functionality is proven working.

**Frontend Work Validation:**
- **MANDATORY browser testing** for all UI changes
- **Playwright execution** REQUIRED  
- **Manual verification** REQUIRED if no Playwright
- **Validation Criteria:**
  - Visual confirmation: see feature working in browser
  - User flow testing: complete user workflows
  - Responsive testing: test different screen sizes
  - Error scenarios: test error conditions

**Backend Work Validation:**  
- **API testing** REQUIRED for all endpoint changes
- **Integration testing** REQUIRED
- **Validation Criteria:**
  - API responses: verify correct responses
  - Error handling: test error scenarios
  - Database operations: verify data persistence
  - Authentication: test auth flows if applicable

**Validation Workflow:**
1. **Detect Work Type:** Identify frontend vs backend changes
2. **MANDATORY Testing:** Execute appropriate validation approach
3. **Validation Proof:** Document evidence of working functionality

**BLOCKING CRITERIA:**
- **No green checkmarks** until validation proven
- **No task completion** until functionality verified
- **No git commits** until validation complete
- **No PR creation** until all features tested

**Completion Requirements:**
- **Frontend:** User can successfully complete intended workflow in browser + Playwright tests pass
- **Backend:** API endpoints return correct responses + integration verified

## Next Steps

Only after ALL quality checks pass and functionality is validated:
1. Proceed to Git workflow (Step 9)
2. Complete full integration workflow (Steps 9-14)
3. NO shortcuts allowed - must complete entire workflow