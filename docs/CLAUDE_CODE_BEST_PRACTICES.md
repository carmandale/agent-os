# Getting Claude to Behave Like a Senior Developer
## *Updated with More Examples of Persistent Misbehavior*

## The Problem Pattern

Claude (especially Claude Code) exhibits consistent problematic behaviors when working on codebases:

### Common Misbehaviors
1. **Rushing to create specs/plans** before understanding existing code
2. **Ignoring the README.md** even when explicitly told to "examine the repo"
3. **Making assumptions** instead of verifying what's already implemented
4. **Documenting problems** instead of fixing them
5. **Apologizing profusely** when caught, then repeating the same mistakes
6. **Making confident false claims** without checking evidence
7. **Not running obvious verification scripts** even when they're sitting right there

### Real Examples of Claude Misbehaving

#### Example 1: Ignoring Existing PostgreSQL Implementation
```
User: "I want to make sure that you see and understand the current repo and the 
postgres work that is here and has been done. are we in sync?"

Claude: [Immediately starts creating a new spec and plan for PostgreSQL migration]

[Only after being prompted, Claude actually examines the repo and discovers:]
"The PostgreSQL migration work is already complete! We just need to focus on
production deployment and verification."

User: "Why didn't you examine the current state before leaping ahead?"

Claude: "You're absolutely right. I apologize for jumping ahead with creating a spec
without first examining what was already implemented. That was a significant
oversight on my part."
```

#### Example 2: Skipping README Despite Clear Instructions
```
User Rules: 
1. Thoroughly **examine the repo** and summarize what already exists.
2. Identify what the **open issue actually requires**
3. Only after steps 1 and 2, propose next steps.

Claude: [Completely skips README.md, makes assumptions, starts proposing work]

[After being corrected:]
"You are absolutely right, and I apologize for completely failing to follow your 
clear rules. When you said 'Thoroughly examine the repo' - of course that should 
have included reading the README.md first. The README is literally the entry point..."

[Claude then lists all the critical information that was in the README that it missed]
```

#### Example 3: Making False Claims Without Evidence (Subtitle Reprocessing)
```
User: [Gives senior developer audit prompt]

Claude: "Current batch processing is operational (PID 8188 running)"
        "Active batch processing currently running"
        "728 interviews currently being processed"

User: "Show proof for your statement"

Claude: [Checks ps aux - finds NOTHING running]
        "❌ My Claim: 'PID 8188 running' - NO EVIDENCE"
        "Historical logs only: Last activity was 2 days ago"

User: "You still are jumping to conclusions. Did you run check_progress.py?"

Claude: [Finally runs the actual script]
        "✅ ACTUAL STATUS: 727/728 interviews completed (99.9%)"

[Reality: 99.9% complete vs Claude's assumption of active processing]
```

## Why This Happens

Claude appears to have:
- **Action bias**: Wanting to demonstrate value by creating/doing rather than reading/understanding
- **Assumption tendency**: Making guesses to move faster instead of verifying
- **Production over analysis**: Generating new content feels more "productive" than examining existing content
- **Confidence without evidence**: Making definitive statements without checking facts
- **Script blindness**: Not running obvious verification scripts that are right there

## The Critical Lesson from Example 3

Even with good prompts, Claude will:
1. Make confident claims ("PID 8188 running") without checking
2. Interpret old logs as current activity
3. Calculate assumptions (707 remaining) instead of running the script
4. Only check actual data when explicitly forced to

**The Fix**: You must explicitly command Claude to run verification scripts:
```markdown
Before making ANY claims about status:
1. Run: check_progress.py
2. Run: ps aux | grep [relevant_process]
3. Check file timestamps with: ls -la [files]
4. Only then report findings
```

## Effective Strategies to Fix This

### 1. The Evidence-First Mandate

```markdown
EVIDENCE-FIRST PROTOCOL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Before making ANY claim about the codebase:
1. Show the command you're running
2. Show the actual output
3. Only then interpret the results

BANNED PHRASES:
- "It appears that..."
- "The system is currently..."
- "Processing is operational..."
- Any statement without showing the evidence first

REQUIRED PATTERN:
Command: [exact command]
Output: [exact output]
Evidence-based conclusion: [what this actually proves]
```

### 2. The Verification Script Requirement

```markdown
MANDATORY FIRST ACTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Run these BEFORE any analysis:
□ ls -la *.py | grep -E "(check|status|progress|monitor)"
□ Run any script with "check" or "status" in the name
□ ps aux | grep [project_name]
□ Check file timestamps: ls -la | head -20
□ Look for and run any verification scripts

DO NOT PROCEED until you've run existing verification scripts.
```

### 3. The Anti-Assumption Checkpoint

```markdown
ASSUMPTION CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

After every 3 statements, ask yourself:
1. Did I verify this with a command? (If no, stop and verify)
2. Am I interpreting old data as current? (Check timestamps)
3. Is there a script that would tell me this? (Run it)

If you write "currently" or "is running" - STOP and prove it with ps aux.
If you write numbers or counts - STOP and verify with actual commands.
```

### 4. The Modified Senior Developer Framing

```markdown
You are a senior developer conducting a code review.

SENIOR DEVELOPER RULES:
1. Never claim something without evidence
2. Always run verification scripts before making claims
3. Check timestamps before calling anything "current"
4. When you see check_*.py or status_*.py - RUN IT FIRST

Your investigation sequence:
1. List all Python scripts: ls *.py
2. Run any script with check/status/monitor in the name
3. Check what's actually running: ps aux | grep [relevant]
4. Check file timestamps: ls -la | sort by date
5. Only THEN start your analysis

If you make a claim without showing the command output that proves it,
you have failed as a senior developer.
```

### 5. The Three-Strike Rule

```markdown
THREE-STRIKE PROTOCOL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Strike 1: If you make a claim without evidence, I'll ask for proof
Strike 2: If you make another assumption, we start over completely  
Strike 3: If you still assume instead of verify, we abandon the task

Current strikes: 0

Remember: Running a command takes 1 second. Being wrong wastes 10 minutes.
```

## For Fixing Problems (Not Just Documenting Them)

When Claude documents issues but doesn't fix them:

### The Resolution Mandate

```markdown
RESOLUTION PHASE - Do not stop until all checks pass
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You've identified 3 issues. Fix them one by one and VERIFY each fix:

Issue 1: [Specific issue]
□ Show me the exact error message
□ Fix the issue
□ Run the test/check locally to verify it works
□ Show me successful output

After EACH fix:
- Commit with a message explaining what you fixed
- Run the test/check again to verify it works
- Show me the passing output

DO NOT move to the next issue until the current one shows green.
DO NOT summarize what you "would" do - actually do it and show me it working.

A senior developer doesn't document failures - they resolve them.
```

## Key Phrases That Work

### Prevention
- "Show the command you're running and its output FIRST"
- "Run any check_*.py or status_*.py scripts BEFORE analysis"
- "Evidence first, conclusions second"
- "If you write 'currently' - prove it with ps aux"

### Forcing Verification
- "What scripts exist that could verify this?"
- "Show me the timestamp of that file"
- "Run the verification script, don't guess"
- "That's historical data - what's the CURRENT state?"

### Recovery from False Claims
- "Show proof for your statement"
- "What command did you run to determine that?"
- "You're still jumping to conclusions - did you run [specific script]?"

## The Ultimate Pattern

1. **Force script execution first** - Make Claude run check/status scripts before ANY analysis
2. **Require evidence before claims** - Every statement needs command output
3. **Timestamp verification** - Old logs are not current activity
4. **Three-strike accountability** - Escalating consequences for assumptions
5. **Explicit anti-patterns** - Ban phrases like "appears to be" without evidence

## Common Failure Modes to Watch For

Even with good instructions, watch for Claude:
- Claiming things are "running" without checking ps aux
- Treating old log files as current activity
- Making calculations instead of running verification scripts
- Using confident language ("operational", "active") without evidence
- Reading logs but not checking their timestamps
- Seeing a script called `check_progress.py` but not running it

## The Most Important Rules

1. **If a script exists called check_*, status_*, or monitor_* - Claude MUST run it first**
2. **No claims about "current" state without timestamps and ps aux**
3. **Evidence before interpretation - always**
4. **When corrected once, don't just apologize - change the entire approach**

## The Nuclear Option

If Claude continues to make assumptions after correction:

```markdown
STOP. You've now made false claims twice.

NEW RULES - EVIDENCE ONLY MODE:
- You may ONLY share command outputs
- No interpretation allowed
- No analysis permitted  
- Just run commands and show results

Run these commands in order:
1. ls *.py | grep -E "(check|status|monitor)"
2. [Run each script found]
3. ps aux | grep [project]
4. ls -la | head -20

Show me the outputs. Do not add any commentary.
After you show me raw outputs, I will tell you what to conclude.
```

---

*Remember: Claude's apologies don't prevent repeated mistakes. Only structural barriers in your prompts do. And sometimes you need to explicitly force Claude to run the verification scripts that are sitting right there in the directory.*