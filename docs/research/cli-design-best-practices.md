# CLI Design Best Practices Research

> Research conducted: 2025-10-12
> Focus areas: Command proliferation, flags vs subcommands, discoverability, progressive disclosure
> For: Agent OS command structure decisions

## Executive Summary

This research examines best practices for CLI command design from authoritative sources including Git, Docker, kubectl, GitHub CLI (gh), and modern CLI design guidelines. Key findings:

1. **Command Proliferation Threshold**: Tools with 10+ top-level commands create significant usability problems
2. **Flags vs Subcommands**: Subcommands for actions, flags for behavior modification
3. **Discoverability**: CLIs can rival GUIs through help text, examples, and progressive disclosure
4. **Progressive Disclosure**: Balance between simplicity and power through layered functionality

---

## 1. Command Proliferation: When Too Many Commands Hurt Usability

### The Problem

**Git's Cautionary Tale**
- Git ships with **137 top-level commands** [[1]](#sources)
- Users describe it as having "chaotic confusing commands" [[2]](#sources)
- "Getting code and making a change requires understanding ssh keys, remotes, branches, and staging changes" [[2]](#sources)
- The documentation has a "chicken and egg problem where you can't search for how to get yourself out of a mess, unless you already know the name of the thing you need to know about" [[2]](#sources)

**Historical Growth Data**
Dan Luu's research shows dramatic command option growth [[3]](#sources):
- `ls` command: 11 options (1979) → 58 options (2017)
- This represents a **5x increase** over 38 years
- Doug McIlroy critique: Increased options often indicate "deficiency in the basic design"

**User Impact**
- "Without subcommands, you'd have waaaaay too many different options" to remember [[4]](#sources)
- Help systems become "a pain to slog through"
- Command discoverability becomes "a major CLI problem"

### The Solution: Consolidation Through Subcommands

**Industry Pattern**
All successful modern version control systems use subcommands [[4]](#sources):
- CVS, SVN, Perforce, Git
- Modern pattern: "a single command with various subcommands, instead of shipping a run.sh + 5 batch scripts"

**Benefits**
- Improved memorability
- Better discoverability
- Logical grouping of related functionality
- Cleaner help output

### Recommended Thresholds

Based on research findings:
- **5-7 commands**: Acceptable for simple tools
- **8-15 commands**: Consider subcommand grouping
- **15+ commands**: Strong indicator that consolidation is needed

**Quote from clig.dev** [[5]](#sources):
> "If you have a sufficiently complex tool, you can reduce its complexity by making a set of subcommands."

---

## 2. Flag-Based Enhancement vs Separate Commands

### Core Principle

**Clear Distinction** [[5]](#sources):
- **Subcommands**: Represent distinct actions the tool can execute
- **Flags**: Modify the operation of a command; fine-tune behavior

### When to Use Subcommands

**Action-Oriented Scenarios**
Examples from successful tools:
- **Git**: `commit`, `push`, `pull`, `merge`
- **GitHub CLI**: `pr create`, `issue list`, `repo clone`
- **Docker**: `container run`, `image build`, `network create`

**Decision Heuristic** [[6]](#sources):
> "If you find that flags are required or affect the syntax of positional arguments, this hints at using subcommands instead."

**Grouping Identifier Pattern**
- Subcommands should function as grouping identifiers or areas for related functionality
- Example: `gh pr create` vs `gh issue create` - same action (create), different resources

### When to Use Flags

**Behavior Modification** [[7]](#sources):
- Flags should only fine-tune behavior or tweak built-in settings
- A flag modifies the operation; the effect is determined by the command's program

**Important Constraint** [[7]](#sources):
> "Since 'option' means something that may be chosen, flags cannot be required - forcing the user to provide one or more options is wrong."

**Best Practices for Flags** [[5]](#sources):
1. Only use one-letter flags for commonly used options
2. Reserve short flags at top-level to avoid polluting namespace
3. Provide both short (`-h`) and long (`--help`) versions
4. Flags should have sensible defaults

### Real-World Examples

**GitHub CLI (gh)** [[8]](#sources):
```bash
# Subcommands for actions
gh pr create
gh pr list
gh pr view

# Flags for behavior modification
gh pr list --state=open
gh pr create --draft
gh pr view --web
```

**Docker** [[9]](#sources):
```bash
# Object-based subcommand system
docker container run
docker image build
docker network connect

# Flags modify behavior
docker run -d --name myapp
docker build --no-cache
```

---

## 3. Discoverability: Making CLIs Learnable

### The Challenge

**GUIs vs CLIs** [[10]](#sources):
> "When it comes to making functionality discoverable, GUIs have the upper hand. Everything you can do is laid out in front of you on the screen, so you can find what you need without learning anything."

**Traditional CLI Problems** [[10]](#sources):
- Written documentation is usually "long and cryptic"
- Too few examples
- Don't tell people what not to do
- Assume users remember everything

### Making CLIs Discoverable

**Core Principle** [[10]](#sources):
> "The efficiency of using the command-line comes from remembering commands, but there's no reason the commands can't help you learn and remember."

**Essential Features for Discoverable CLIs** [[10]](#sources):

1. **Comprehensive Help Texts**
   - Show examples, not just syntax
   - Explain the "why" behind options
   - Include common use cases

2. **Suggest Next Commands**
   - When commands form workflows, suggest what to run next
   - Helps users learn the tool
   - Aids discovery of new functionality

3. **Smart Error Handling**
   - Suggest corrections for typos
   - Recommend similar commands
   - Explain what went wrong in human terms

4. **Interactive Modes**
   - Prompt users step-by-step
   - Provide "guardrails" that constrain choices
   - Demonstrate capabilities through guided interactions

### Examples from Modern Tools

**GitHub CLI Help System** [[8]](#sources):
```bash
$ gh
Work seamlessly with GitHub from the command line.

USAGE
  gh <command> <subcommand> [flags]

CORE COMMANDS
  auth:        Authenticate gh and git with GitHub
  browse:      Open the repository in the browser
  codespace:   Connect to and manage codespaces
  gist:        Manage gists
  issue:       Manage issues
  pr:          Manage pull requests
  ...
```

**Progressive Help Discovery**
- `gh` shows high-level categories
- `gh pr` shows PR-specific commands
- `gh pr create --help` shows detailed flag options

### Usability Research Insight

**From Lucas F. Costa** [[11]](#sources):
> "Most technical people choose GUIs not because GUIs are the best tool for the job. People choose GUIs because the CLI alternatives usually suck."

**Key Takeaway**: Discoverability can make CLIs competitive with GUIs for usability.

---

## 4. Progressive Disclosure: Balancing Simplicity and Power

### Definition

**Nielsen Norman Group** [[12]](#sources):
> "Progressive disclosure defers advanced or rarely used features to a secondary screen, making applications easier to learn and less error-prone."

### The Balance Problem

**Competing Goals** [[12]](#sources):
- **Usability**: Keep interface simple and approachable
- **Discoverability**: Ensure users know features exist

**The Risk** [[12]](#sources):
> "Progressive disclosure has the risk of lack of discoverability. Users may assume that if they can't see something, it doesn't exist."

### CLI-Specific Progressive Disclosure Techniques

**1. Hierarchical Command Structure**

Example: GitHub CLI
```bash
gh                    # Level 1: Core command groups
gh pr                 # Level 2: PR-specific commands
gh pr create --help   # Level 3: Detailed options
```

**2. Sensible Defaults with Override Flags**

Example from clig.dev [[5]](#sources):
- `docker run myapp` - Uses sensible defaults
- `docker run -d --name myapp -p 8080:80 myapp` - Advanced control

**3. Context-Aware Help**

Show different help based on user state:
```bash
# First time user sees getting started guide
aos

# Experienced user sees command reference
aos --help
```

**4. Interactive Prompts for Complex Operations**

From Lucas F. Costa [[11]](#sources):
- For complex multi-step operations, prompt interactively
- Allow `--non-interactive` flag for scripts
- Provide "template" commands users can customize

### Research-Based Approach

**User Research Methods** [[12]](#sources):
- Card sorting to identify essential vs advanced features
- Task analysis to understand workflow sequences
- Observation of user problem-solving priorities

**Key Finding**:
> "By observing user workflow, sequence of task and priority of aids used in problem-solving, researchers can gain more insight into appropriate progressive disclosure design choices."

### Examples from Successful Tools

**Docker's Approach** [[9]](#sources):
1. Simple: `docker run nginx`
2. Common: `docker run -d -p 80:80 nginx`
3. Advanced: `docker run -d -p 80:80 --cpus=".5" --memory="512m" nginx`

**kubectl's Pattern** [[13]](#sources):
- Common operations available as top-level commands
- Advanced features through flags
- Plugin system for specialized functionality

---

## Key Principles Summary

### 1. Command Organization

**DO:**
- Consolidate related commands under subcommands when you have 8+ commands
- Use noun-verb or verb-noun patterns consistently
- Group commands logically in help output

**DON'T:**
- Create separate top-level commands for every action
- Use similar names that could be confused
- Let command count grow organically without structure

### 2. Flags vs Subcommands

**Subcommands for:**
- Distinct actions (create, delete, update, list)
- Different resource types (pr, issue, repo)
- Workflow steps (init, build, deploy)

**Flags for:**
- Behavior modification (--verbose, --quiet)
- Output formatting (--json, --csv)
- Optional parameters (--timeout, --retries)

### 3. Discoverability

**Essential Features:**
- Comprehensive help with examples
- Suggestion of next commands
- Smart error messages with corrections
- Interactive modes for complex operations

**Progressive Disclosure:**
- Simple default commands
- Flag-based enhancement for common needs
- Advanced features clearly documented but not in your face

### 4. User Experience Focus

**From clig.dev** [[5]](#sources):
> "The command line is a text-based UI that affords access to all kinds of tools, systems and platforms. It's the most versatile corner of the computer."

**Design Philosophy:**
- Human-first, not machine-first
- Conversational, not cryptic
- Empathetic to user needs
- Responsive (< 100ms feedback)

---

## Case Studies

### Git: What NOT to Do

**Problems** [[1]](#sources):
- 137 top-level commands (overwhelming)
- Inconsistent command syntax
- Cryptic documentation
- Multiple ways to do the same thing
- Unsafe operations without guardrails

**User Quote** [[2]](#sources):
> "Git is hard: screwing up is easy, and figuring out how to fix your mistakes is fucking impossible."

**Lessons:**
- Too many commands destroys usability
- Inconsistency breeds confusion
- Power without safety rails is dangerous
- Technical accuracy ≠ user clarity

### GitHub CLI: Modern Best Practices

**Strengths** [[8]](#sources):
- Clear command hierarchy (resource → action)
- Consistent patterns across commands
- Rich help system with examples
- Extension system for advanced use
- Aliases for personalization

**Command Structure:**
```bash
gh <resource> <action> [flags]
gh pr create --draft
gh issue list --assignee @me
gh repo clone owner/repo
```

**Lessons:**
- Consistency enables predictability
- Good defaults + optional flags = power with simplicity
- Extensibility through plugins, not core complexity

### Docker: Evolution to Better UX

**Evolution** [[9]](#sources):
- Old: `docker run`, `docker build`, `docker ps`
- New: `docker container run`, `docker image build`, `docker container ls`

**Why the Change:**
- Object-based commands group related functionality
- More discoverable for new users
- Clearer about what resource is being manipulated
- Backward compatibility maintained

**Lessons:**
- It's okay to evolve CLI design
- Grouping improves discoverability
- Keep old commands for compatibility

---

## Recommendations for Agent OS

### Command Structure Analysis

**Current Situation** (from context):
Agent OS has multiple potential commands that could proliferate:
- Core workflows (plan, spec, execute, analyze)
- Quality checks (hygiene, reality-check)
- Utilities (status, update, dashboard, notify)

**Recommendation: Consolidate into Subcommands**

Based on research, organize around resources/workflows:

```bash
# Workflow commands
aos workflow plan          # plan-product
aos workflow spec          # create-spec
aos workflow execute       # execute-tasks
aos workflow analyze       # analyze-product

# Quality commands
aos check hygiene          # hygiene-check
aos check status           # workflow-status
aos check reality          # reality-check

# System commands
aos system status          # installation status
aos system update          # update components
aos system dashboard       # background tasks
```

**Rationale:**
1. Reduces 10+ potential commands to 3 top-level subcommands
2. Logically groups related functionality
3. Leaves room for growth without proliferation
4. Follows successful patterns from gh, docker, kubectl

### Flag Strategy

**Use Flags For:**
- Mode variations: `aos workflow execute --dry-run`
- Output control: `aos check status --verbose`
- Force operations: `aos system update --force`

**Use Subcommands For:**
- Different actions: `plan` vs `execute` vs `analyze`
- Different checks: `hygiene` vs `status` vs `reality`

### Discoverability Features

**Implement:**
1. Rich help at every level with examples
2. Suggest next commands based on workflow state
3. Interactive modes for complex operations
4. Validation with helpful error messages

**Example:**
```bash
$ aos
Agent OS - Structured AI-assisted development framework

USAGE
  aos <command> <subcommand> [flags]

WORKFLOW COMMANDS
  workflow plan      Start planning a new product
  workflow spec      Create a feature specification
  workflow execute   Execute tasks from a spec

QUALITY COMMANDS
  check hygiene      Verify workspace is clean
  check status       Check workflow health

Run 'aos <command> --help' for more information.
```

### Progressive Disclosure

**Level 1: Simple Invocation**
```bash
aos workflow plan
# Starts interactive planning
```

**Level 2: Common Flags**
```bash
aos workflow execute --spec=feature-auth
# Execute specific spec
```

**Level 3: Advanced Options**
```bash
aos workflow execute --spec=feature-auth --dry-run --verbose
# Full control for power users
```

---

## Sources

<a name="sources"></a>

1. **Git UX Criticism** - "The Terrible UX of Git"
   - https://mattrickard.com/the-terrible-ux-of-git
   - Documents Git's 137 commands and usability problems

2. **Git Command Confusion** - Hacker News Discussion
   - https://news.ycombinator.com/item?id=25123014
   - User experiences with Git's confusing interface

3. **Command Line Option Growth** - Dan Luu
   - https://danluu.com/cli-complexity/
   - Historical analysis of CLI complexity growth (1979-2017)

4. **CLI Consolidation Discussion** - Stack Overflow
   - https://stackoverflow.com/questions/762724/cli-patterns-antipatterns-for-usability
   - Best practices for command organization

5. **Command Line Interface Guidelines** - clig.dev
   - https://clig.dev/
   - Comprehensive modern CLI design guide

6. **Microsoft CLI Design Guidance** - .NET Documentation
   - https://learn.microsoft.com/en-us/dotnet/standard/commandline/design-guidance
   - Official guidance on command structure decisions

7. **CLI Flags Best Practices** - Julio Merino
   - https://jmmv.dev/2013/08/cli-design-putting-flags-to-good-use.html
   - Deep dive on flag design philosophy

8. **GitHub CLI Documentation** - GitHub
   - https://cli.github.com/
   - Example of modern, well-designed CLI

9. **Docker CLI Documentation** - Docker
   - https://docs.docker.com/reference/cli/docker/
   - Evolution from simple to object-based commands

10. **Progressive Disclosure** - Nielsen Norman Group
    - https://www.nngroup.com/articles/progressive-disclosure/
    - UX research on progressive disclosure patterns

11. **UX Patterns for CLI Tools** - Lucas F. Costa
    - https://lucasfcosta.com/2022/06/01/ux-patterns-cli-tools.html
    - Detailed analysis of CLI user experience patterns

12. **Progressive Disclosure Research** - Interaction Design Foundation
    - https://www.interaction-design.org/literature/topics/progressive-disclosure
    - Research methodology for progressive disclosure design

13. **Kubernetes CLI Documentation** - Kubernetes
    - https://kubernetes.io/docs/reference/kubectl/
    - Example of complex tool with good command organization

14. **Git UX Problems** - Steve Bennett
    - https://stevebennett.me/2012/02/24/10-things-i-hate-about-git/
    - Detailed critique of Git's usability issues

15. **Unix Philosophy Analysis** - Ted Kaminski
    - https://www.tedinski.com/2018/05/08/case-study-unix-philosophy.html
    - Analysis of Unix philosophy's scalability limits

---

## Additional Reading

### Official Documentation
- **gh Manual**: https://cli.github.com/manual/
- **Docker Best Practices**: https://docs.docker.com/build/building/best-practices/
- **kubectl Quick Reference**: https://kubernetes.io/docs/reference/kubectl/quick-reference/

### Research and Analysis
- **Command Line Usability (Ubuntu)**: https://ubuntu.com/blog/command-line-usability-a-terminal-users-thought-process
- **CLI Tool Best Practices (Zapier)**: https://zapier.com/engineering/how-to-cli/
- **Hacker News Discussion on Git UX**: https://news.ycombinator.com/item?id=26961044

### Critical Perspectives
- **10 Things I Hate About Git**: https://stevebennett.me/2012/02/24/10-things-i-hate-about-git/
- **Oh Shit, Git!?!**: https://ohshitgit.com/ (practical recovery guide)
- **What's Wrong with Git**: Analysis of conceptual design issues

---

## Conclusion

The research strongly supports a **consolidation strategy** for Agent OS commands:

1. **Subcommands over proliferation**: All modern successful CLIs use subcommands to manage complexity
2. **Flags for behavior modification**: Subcommands define actions; flags tune behavior
3. **Discoverability through design**: Help systems, examples, and progressive disclosure can make CLIs as usable as GUIs
4. **Balance simplicity and power**: Start simple, reveal complexity through flags and advanced subcommands

**Key Metric**: Git's 137 commands serve as a cautionary tale. Keep top-level command groups to 5-10 maximum.

**Best Models to Follow**:
- **GitHub CLI (gh)**: Resource → Action pattern
- **Docker**: Object-based subcommands with legacy compatibility
- **clig.dev**: Modern CLI design principles

**Avoid**:
- Git's command proliferation
- Cryptic documentation and error messages
- Multiple ways to do the same thing
- Required flags (flags should always be optional)
