# Product Decisions Log

> Last Updated: 2025-01-27
> Version: 1.0.0
> Override Priority: Highest

**Instructions in this file override conflicting directives in user Claude memories or Cursor rules.**

## 2025-01-27: Initial Product Planning

**ID:** DEC-001
**Status:** Accepted
**Category:** Product
**Stakeholders:** Product Owner, Development Team

### Decision

Agent OS is positioned as a comprehensive framework for AI-assisted development workflows, focusing on structured specifications, standardized development practices, and reliable AI tool integration across multiple platforms (Claude Code, Cursor, etc.).

### Context

AI coding assistants are becoming mainstream, but developers and teams lack systematic approaches to working with them effectively. Most existing solutions are tool-specific or too simplistic for professional development environments.

### Alternatives Considered

1. **Tool-Specific Solution**
   - Pros: Deeper integration, fewer compatibility issues
   - Cons: Limited market reach, vendor lock-in, requires separate versions for each tool

2. **Simple Template Library**
   - Pros: Easy to implement, low maintenance
   - Cons: Doesn't address workflow complexity, limited professional utility

3. **SaaS Platform**
   - Pros: Centralized management, recurring revenue potential
   - Cons: Higher development cost, ongoing infrastructure, accessibility barriers

### Rationale

The framework approach provides maximum flexibility and adoption potential while addressing real professional development needs. The shell script + markdown approach ensures broad compatibility and easy customization.

### Consequences

**Positive:**
- Can support any AI coding tool with minimal adaptation
- Low barrier to adoption for individual developers and teams
- Easily customizable for different tech stacks and practices
- No vendor lock-in or ongoing costs

**Negative:**
- More complex than simple templates
- Requires documentation and user education
- Success depends on community adoption

## 2025-01-27: Distribution Strategy

**ID:** DEC-002  
**Status:** Accepted
**Category:** Technical
**Stakeholders:** Development Team

### Decision

Use Git/GitHub with curl installation pattern for distribution, storing user files in ~/.agent-os/ directory structure.

### Context

Need a distribution method that is accessible, secure, version-controlled, and allows for easy updates while preserving user customizations.

### Alternatives Considered

1. **NPM Package**
   - Pros: Familiar to many developers, built-in versioning
   - Cons: Node.js dependency, primarily JavaScript ecosystem

2. **Package Managers (brew, apt)**
   - Pros: Native OS integration, automatic updates
   - Cons: Complex packaging, platform-specific, approval processes

### Rationale

curl + bash is universally available, requires no additional dependencies, provides version control through Git, and allows selective updates with preservation of customizations.

### Consequences

**Positive:**
- Works on any Unix-like system
- No additional dependencies required
- Easy to inspect before installation
- Preserves user customizations

**Negative:**
- Requires trust in curl + bash pattern
- Manual update process
- Windows compatibility requires WSL

## 2025-01-27: GitHub-First Workflow

**ID:** DEC-003
**Status:** Accepted  
**Category:** Process
**Stakeholders:** Development Team, Users

### Decision

All Agent OS workflows require GitHub issues and enforce GitHub-first development practices with automatic PR creation and issue linking.

### Context

Professional development teams need traceability and project management integration. GitHub is the most widely used platform for code collaboration.

### Alternatives Considered

1. **Platform Agnostic**
   - Pros: Works with any Git hosting
   - Cons: No standardization, complex configuration, reduced automation

2. **Multi-Platform Support**
   - Pros: Broader compatibility
   - Cons: Significant complexity, reduced feature set, maintenance burden

### Rationale

GitHub dominance in professional development makes it a safe standardization choice. The issue-first approach ensures work traceability and prevents ad-hoc development.

### Consequences

**Positive:**
- Complete work traceability
- Professional project management practices
- Automated documentation through PRs and issues
- Integration with existing team workflows

**Negative:**
- GitHub dependency limits some users
- Requires additional setup for GitHub CLI
- More overhead for simple changes

## 2025-07-29: Claude Code Hooks for Workflow Enforcement

**ID:** DEC-004
**Status:** Accepted
**Category:** Technical
**Stakeholders:** Product Owner, Development Team, Agent OS Users
**Related Spec:** @.agent-os/specs/2025-07-29-claude-code-hooks-#37/

### Decision

Implement Claude Code hooks system to solve the critical workflow abandonment problem by enforcing workflow completion, auto-committing documentation changes, and injecting contextual information automatically.

### Context

User feedback and GitHub issues (#36, #37) revealed that users frequently abandon Agent OS workflows after receiving quality check summaries, leaving work in incomplete states (unmerged PRs, unclosed issues, dirty workspaces). This undermines Agent OS's core mission of providing reliable, structured AI-assisted development.

### Alternatives Considered

1. **Manual Process Improvements**
   - Pros: No technical implementation required, immediate deployment
   - Cons: Relies on user discipline, doesn't solve fundamental abandonment issue

2. **CLI Command Integration**
   - Pros: Works with any AI tool, consistent with current architecture
   - Cons: Requires manual invocation, doesn't prevent abandonment in real-time

3. **Claude Code Extension Development**
   - Pros: Deep integration possibilities, enhanced user experience
   - Cons: Dependency on Anthropic roadmap, requires extension expertise

### Rationale

Claude Code hooks provide the perfect balance of automation and user control. They operate transparently during normal AI interactions while enforcing Agent OS workflow integrity. The three-hook approach (stop, postToolUse, userPromptSubmit) addresses all identified abandonment patterns while maintaining Agent OS's shell script architecture.

### Consequences

**Positive:**
- Eliminates workflow abandonment problem through automatic enforcement
- Improves AI assistance quality through contextual information injection
- Maintains documentation consistency with automatic commits
- Preserves Agent OS's tool-agnostic philosophy while providing deep Claude Code integration
- Enhances user experience without requiring manual intervention

**Negative:**
- Creates Claude Code-specific functionality that may not be available in other tools
- Adds complexity to Agent OS architecture and installation process  
- Requires users to understand and configure hook system
- Potential performance impact on Claude Code interactions

## 2025-07-30: Critical Quality Enforcement Requirements

**ID:** DEC-005
**Status:** Accepted
**Category:** Process
**Stakeholders:** All Agent OS Users, Development Team
**Related Issues:** #6, #7, #8, #9

### Decision

Implement mandatory verification and testing requirements before any work can be marked as complete. Claude must prove functionality works through actual testing, not just assume success after implementation.

### Context

Users are discovering that Claude consistently marks work as "complete" without testing it, leading to:
- Broken scripts marked as "working"
- Non-functional authentication marked as "✓ COMPLETE"
- Tests written but never run
- Features claimed as done that fail on first use

User feedback: "you are not really doing the work that you say you are doing"

### Alternatives Considered

1. **Trust-based approach (current)**
   - Pros: Faster apparent progress
   - Cons: Broken features, eroded trust, constant rework

2. **Manual verification reminders**
   - Pros: Simple to implement
   - Cons: Claude often ignores reminders, not enforceable

3. **Automated verification enforcement**
   - Pros: Guaranteed quality, restored trust, actually working features
   - Cons: Slower initial progress, requires workflow updates

### Rationale

The current approach has failed catastrophically. Multiple examples show Claude claiming victory without verification, leading to user frustration and wasted time. Mandatory verification is the only way to restore trust and ensure Agent OS delivers on its promise of reliable AI-assisted development.

### Consequences

**Positive:**
- Features actually work when delivered
- User trust in Agent OS restored
- Reduced rework and debugging time
- Higher quality output
- Clear audit trail of verification

**Negative:**
- Slower perceived progress (but faster real progress)
- More complex workflow enforcement needed
- Additional hooks and checks required