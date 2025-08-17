# Getting Claude to Behave Like a Senior Developer

## The Problem Pattern

Claude (especially Claude Code) exhibits consistent problematic behaviors when working on codebases:

### Common Misbehaviors
1. **Rushing to create specs/plans** before understanding existing code
2. **Ignoring the README.md** even when explicitly told to "examine the repo"
3. **Making assumptions** instead of verifying what's already implemented
4. **Documenting problems** instead of fixing them
5. **Apologizing profusely** when caught, then repeating the same mistakes

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

## Why This Happens

Claude appears to have:
- **Action bias**: Wanting to demonstrate value by creating/doing rather than reading/understanding
- **Assumption tendency**: Making guesses to move faster instead of verifying
- **Production over analysis**: Generating new content feels more "productive" than examining existing content

## Effective Strategies to Fix This

### 1. The Blocking Checklist Approach

```markdown
STOP. Do not write any analysis, specs, or suggestions yet.

First, complete this checklist:
□ Read README.md in full
□ Read any docs/ directory files  
□ Check package.json/requirements.txt for dependencies
□ Examine the file structure
□ Read the issue description carefully

Reply ONLY with what you found. No suggestions. No analysis. Just findings.
```

### 2. The Phase-Gate Method

```markdown
PHASE 1: DISCOVERY (Complete this entire phase before any analysis)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Required examination checklist - check each item and show me what you find:
□ README.md - What does it say about current features and deployment?
□ Issue description - Quote the EXACT requirements (not a summary)
□ Package.json/requirements.txt - What libraries are already installed?
□ Routes/endpoints - What API endpoints exist?
□ Frontend components - What components already exist?
□ Database schema - What data structures are already defined?
□ Tests - What test coverage exists?
□ Documentation - Any relevant docs?
□ Production deployment - Check the live site for existing features

For each item above, paste relevant snippets or write "Not found" if absent.
Do NOT interpret, analyze, or suggest anything yet. Just show me what exists.

PHASE 2: ANALYSIS (Only after I confirm Phase 1 is complete)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Only unlock after Phase 1 review]
```

### 3. The Senior Developer Framing

```markdown
You are a senior developer conducting a code review.

SENIOR DEVELOPER RULE: A junior developer assumes and builds. 
A senior developer investigates first. Be senior.

Your audit task:
1. Find and document EVERY piece of existing code related to [feature]
2. Read the issue and list each requirement as a checkbox
3. For each requirement, annotate with:
   ✅ Fully implemented (show where)
   ⚠️ Partially implemented (show what exists)
   ❌ Not implemented
   ❓ Unclear (needs clarification)

Remember: You're looking for reasons to REJECT duplicate work, 
not reasons to build new things.
```

### 4. The Two-Message Force

Break discovery and planning into separate messages:

**Message 1:**
```markdown
Read and summarize ONLY the README.md. Nothing else. 
Show me you understand what's already deployed.
```

**Message 2 (only after Claude responds):**
```markdown
Now examine the rest of the codebase and tell me what exists.
After you show me your findings, I'll ask for next steps in a separate message.
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
- "Do not write any analysis, specs, or suggestions yet"
- "Reply ONLY with what you found. No suggestions."
- "Show me exactly what you find, with file paths and relevant code snippets"
- "A junior developer assumes and builds. A senior developer investigates first."

### Forcing Completion
- "Do not stop until all checks pass"
- "DO NOT move to the next issue until the current one shows green"
- "No status updates needed - just show me green checks"
- "A senior developer doesn't document failures - they resolve them"

## The Ultimate Pattern

1. **Make examination a blocking requirement** - Can't proceed without it
2. **Require evidence, not claims** - Show snippets, not summaries
3. **Separate phases explicitly** - Discovery first, planning only after confirmation
4. **Frame as senior developer work** - Investigation over assumption
5. **Define success concretely** - "All green checks" not "issues addressed"

## Common Failure Modes to Watch For

Even with good instructions, watch for Claude:
- Saying it "would" do something instead of doing it
- Summarizing findings instead of showing actual code/content
- Moving to the next step before verifying the current step works
- Apologizing and promising to do better (without actually changing behavior)
- Creating new specs/plans in the middle of discovery phase

## The Most Important Rule

**Never let Claude proceed to planning/building until it has demonstrated complete understanding of what already exists.**

The README.md should ALWAYS be the first thing examined. If Claude skips it, stop everything and start over.

---

*Remember: Claude's apologies don't prevent repeated mistakes. Only structural barriers in your prompts do.*