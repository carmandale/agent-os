# Command Distinction: execute-tasks vs execute-task

## Overview

Agent OS has two related but distinct execution workflows that serve different purposes in the development process.

## execute-tasks (Orchestrator) - `/execute-tasks`

**Command**: `execute-tasks.md`  
**Instruction**: `@~/.agent-os/instructions/core/execute-tasks.md`  
**Purpose**: High-level workflow orchestrator for complete spec execution

### What it does:
- **Phase 0**: Repository Discovery Gate (mandatory investigation)
- **Phase 0.5**: Transparent Work Session Detection (auto-start)
- **Phase 1**: Hygiene and Setup (workspace validation)
- **Phase 1.5**: Deep Reality Check (dev/test/prod validation)
- **Phase 2**: Planning and Implementation (delegates to execute-task)
- **Phase 3**: Quality Assurance (comprehensive testing)
- **Phase 4**: Git Integration and Completion (PR creation, merge)

### When to use:
- Starting work on a new spec
- Need complete workflow orchestration
- Want automated quality gates
- Working with multiple tasks in sequence

### Delegation:
```markdown
FOR each selected parent task:
  EXECUTE @~/.agent-os/instructions/core/execute-task.md with:
    - parent_task_number
    - all associated subtasks
```

## execute-task (Individual Task Worker) - Internal Use Only

**Instruction**: `@~/.agent-os/instructions/core/execute-task.md`  
**Purpose**: Execute a single parent task and its subtasks with strict subagent enforcement

### What it does:
- **Step 1**: Task Understanding (context-fetcher subagent)
- **Step 2**: Technical Requirements Analysis (context-fetcher subagent)
- **Step 3**: Implementation Planning
- **Step 4**: Development Execution with TDD
- **Step 5**: Testing and Verification (test-runner subagent)
- **Step 6**: Task Status Update and Completion

### When it's used:
- Called automatically by execute-tasks during Phase 2
- Focuses on single task implementation
- Enforces subagent usage for specific steps
- Not intended for direct user invocation

### Subagent Enforcement:
```xml
<enforcement>
  - For any <step> that declares subagent="...", the specified subagent MUST be invoked
  - Generic tool use is NOT permitted for those steps
  - Validator: fail if a required subagent step is executed without its subagent
</enforcement>
```

## Key Differences

| Aspect | execute-tasks | execute-task |
|--------|---------------|--------------|
| **Scope** | Full spec workflow | Single task focus |
| **User Interface** | `/execute-tasks` command | Internal delegation only |
| **Phases** | 5 comprehensive phases | 6 focused steps |
| **Quality Gates** | All phases include QA | Step 5 testing focus |
| **Work Sessions** | Auto-start detection | Inherits session state |
| **Git Integration** | Complete PR workflow | Task status updates |
| **Subagent Use** | Optional/automatic | Strictly enforced |

## Usage Examples

### Correct Usage:
```
User: "/execute-tasks"
→ Executes complete workflow orchestrator
→ Automatically delegates to execute-task for individual tasks
→ Handles all quality gates and git integration
```

### Incorrect Usage:
```
User: "/execute-task" 
→ No such command exists for users
→ This is an internal instruction file only
→ Use /execute-tasks instead
```

## Command Path Resolution

Both instructions follow the organized structure:
- **Commands**: `commands/execute-tasks.md` (user-facing only)
- **Instructions**: `instructions/core/execute-tasks.md` and `instructions/core/execute-task.md`
- **References**: All use `@~/.agent-os/instructions/core/` paths

## Implementation Notes

The orchestrator pattern allows for:
1. **Separation of Concerns**: High-level orchestration vs focused task execution
2. **Reusability**: execute-task can be called for multiple tasks
3. **Quality Assurance**: Each level has appropriate quality gates
4. **Transparency**: Users interact with simple `/execute-tasks` command
5. **Flexibility**: Internal architecture can evolve independently