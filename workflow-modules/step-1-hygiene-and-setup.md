# Step 1: Hygiene and Setup

## Workspace Hygiene Check (Step 0)

Execute workspace hygiene check using the dynamic script that will verify:
- Git status (clean/dirty)
- Open PRs status  
- Open issues that need closing
- Current branch appropriateness

If workspace is dirty, the script will guide through cleanup options including autonomous subagent cleanup.

## GitHub Issue Verification (Step 1)

**CRITICAL REQUIREMENT:** All Agent OS work must be linked to GitHub issues.

Check if the spec folder name contains a GitHub issue number (format: YYYY-MM-DD-spec-name-#123).

If no issue found:
- STOP execution immediately
- Request user to create GitHub issue and update spec folder name
- Store issue number for commit messages

## Project Memory Refresh (Step 1.2) - BLOCKING

**MANDATORY** project context loading to prevent Claude Code amnesia:

The project context loader script will extract and verify:
- Python package manager (uv, pip, poetry, pipenv)
- JavaScript package manager (npm, yarn, pnpm, bun)  
- Frontend and backend port numbers
- Startup commands and environment configuration
- E2E testing configuration
- Project structure type

**BLOCKING REQUIREMENT:** Must output complete configuration verification before proceeding.

**Amnesia Prevention:** Throughout the session, ALWAYS use the package managers and configurations loaded here. NEVER default to different tools.

## Codebase Reality Check (Step 1.5)

Execute task validation script to verify:
- Task status consistency (main tasks vs subtasks)
- Implementation files vs task claims
- Recent git history vs current task state

**Blocking Criteria:** Stop execution if critical inconsistencies detected:
- Major implementation exists but task shows "not started"
- All subtasks complete but main task unchecked
- Tasks reference non-existent files

**User Approval Required:** When discrepancies found, offer reconciliation options.

## Next Steps

After hygiene and setup steps pass:
1. Proceed to task assignment and context analysis
2. All configuration loaded here must be maintained throughout execution
3. Any validation failures require resolution before continuing