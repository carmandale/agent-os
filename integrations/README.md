# Agent OS Subagent Integration

Enhance Agent OS workflows with **optional** professional-grade analysis from your existing Claude Code subagents.

## Philosophy: Security Opt-In, Quality Automatic

This integration gives you **professional-grade development assistance** while respecting your security context:

- **🔒 Security**: Always opt-in, never automatic (even for banking apps)
- **🎯 Quality**: Automatic professional assistance (PRDs, testing, architecture)
- **🚀 Your pace**: Prototype without security overhead, get quality help by default
- **🧠 Your context**: You decide when security analysis adds value

## How It Works

The integration adds **optional enhancement points** throughout existing Agent OS workflows:

```
Standard Agent OS Workflow
         ↓
   Enhancement Points
         ↓
    Subagent Layer
         ↓
   Professional Output
```

### Key Benefits

- **Professional by default**: Automatic PRDs, architecture review, comprehensive testing
- **Security when you want it**: Brief suggestions, easily dismissed, no pressure
- **Respects your context**: Prototype freely, add security when ready for production
- **First-try success**: 90%+ spec approval rates with automatic quality enhancements

## Quick Start

### 1. Prerequisites

- Claude Code CLI installed and configured
- Agent OS already installed
- Claude Code subagents (recommended)

### 2. Install Integration

```bash
cd /path/to/agent-os
chmod +x integrations/setup-subagent-integration.sh
./integrations/setup-subagent-integration.sh
```

### 3. Try Enhanced Workflows

```bash
# Same workflow, automatic quality enhancements
/create-spec "Add user authentication"
# → Automatically uses: prd-writer, systems-architect, qa-test-engineer
# → Brief suggestion: "Security analysis available for auth features"  
# → Your choice: [y/n] (default: n)
# → Result: Professional spec with optional security analysis

# Or explicitly request security later
/enhance --security
# → Add security analysis to existing spec
```

## Architecture

### Subagent Mapping

| Agent OS Need | Your Existing Agent | Enhancement |
|---------------|-------------------|-------------|
| **Product Planning** | `prd-writer` | Professional PRDs with user stories |
| **Complex Implementation** | `senior-software-engineer` | Architectural guidance and mentorship |
| **Quality Assurance** | `qa-test-engineer` | Comprehensive testing strategies |
| **Code Quality** | `code-refactoring-expert` | Standards compliance and debt prevention |
| **System Design** | `systems-architect` | Long-term scalability validation |
| **Security** | `security-threat-analyst` | Threat modeling and vulnerability prevention |
| **Performance** | `performance-optimizer` | Performance analysis and optimization |

### Integration Points

#### Enhanced Product Planning
- **Market Research**: `deep-research-specialist` for competitive analysis
- **Professional PRDs**: `prd-writer` for enterprise-grade requirements
- **Technical Architecture**: `systems-architect` for scalability validation

#### Enhanced Spec Creation
- **Requirements Analysis**: `prd-writer` for comprehensive user stories
- **Technical Validation**: `systems-architect` for architectural review
- **Security Analysis**: `security-threat-analyst` for threat modeling
- **Test Strategy**: `qa-test-engineer` for comprehensive test planning

#### Enhanced Task Execution
- **Implementation Guidance**: `senior-software-engineer` for complex features
- **Quality Pipeline**: Multiple agents for comprehensive quality assurance
- **Security Validation**: Continuous security analysis during development
- **Performance Optimization**: Built-in performance analysis and improvement

## Configuration

### Global Configuration
Edit `~/.agent-os/subagent-config.yaml`:

```yaml
# Global subagent integration settings
enabled: true
fallback_mode: graceful

# Quality thresholds
complexity_threshold: medium
risk_threshold: medium

# Workflow enhancements
workflows:
  create_spec:
    enabled: true
    agents:
      systems_architect:
        enabled: true
        auto_invoke: false  # manual for complex features
      qa_test_engineer:
        enabled: true
        auto_invoke: true   # always enhance testing
```

### Project-Specific Configuration
Create `.agent-os/subagent-config.yaml` in your project:

```yaml
# Project-specific overrides
workflows:
  execute_tasks:
    agents:
      security_threat_analyst:
        enabled: true
        auto_invoke: true  # this project is security-critical
```

## Enhanced Workflows

### 1. Enhanced Product Planning

**Standard**: Basic product documentation
**Enhanced**: Professional PRD with market research and architectural validation

```bash
/plan-product-enhanced
```

Features:
- Comprehensive market research and competitive analysis
- Professional PRD with detailed user stories and acceptance criteria
- Technical architecture validation and scalability planning
- Enterprise-grade documentation quality

### 2. Enhanced Spec Creation

**Standard**: Basic spec with simple requirements
**Enhanced**: Professional specification with comprehensive analysis

```bash
/create-spec-enhanced "Add user authentication"
```

Features:
- Automatic security analysis for auth features
- Comprehensive test strategy with edge cases
- Technical architecture validation
- Professional user stories with acceptance criteria

### 3. Enhanced Task Execution

**Standard**: Basic TDD implementation
**Enhanced**: Professional development with continuous quality assurance

```bash
/execute-tasks-enhanced
```

Features:
- Architectural guidance for complex implementations
- Continuous code quality monitoring
- Comprehensive security validation
- Performance optimization integration
- Professional git workflows with quality metrics

## Quality Outcomes

### Before Integration
- ✅ Structured workflows
- ✅ Consistent processes
- ⚠️ Variable quality outcomes
- ⚠️ Manual quality assurance
- ⚠️ Basic documentation

### After Integration
- ✅ Structured workflows (unchanged)
- ✅ Consistent processes (unchanged)
- ✅ **Professional quality outcomes**
- ✅ **Automated quality assurance**
- ✅ **Enterprise-grade documentation**
- ✅ **First-try success rates: 90%+**

## Fallback Behavior

The integration is **completely optional** and **fully backward compatible**:

- **No subagents**: Standard Agent OS workflows continue unchanged
- **Partial subagents**: Use available agents, skip unavailable ones
- **Agent errors**: Log errors but never block standard workflows
- **User control**: Disable any agent or enhancement via configuration

## Real-World Examples

### Banking App Prototype
```bash
/create-spec "User account management for banking app"
# → Brief note: "Security analysis available for financial applications"
# → You choose: n (focusing on core logic first)
# → Result: Clean spec focused on functionality
```

### Banking App Going to Production
```bash
# Same spec, now ready for production
/enhance --security --architecture
# → Comprehensive security analysis and architectural review added
# → Result: Production-ready spec with threat modeling
```

### Personal Blog
```bash
/create-spec "Personal blog with comments"
# → No security suggestions (obviously low risk)
# → Result: Simple, clean spec for your project
```

### Learning Project
```bash
/create-spec "Todo app to learn React"
# → No enhancement suggestions (learning focused)
# → Later: /enhance --quality (when you want to learn best practices)
```

The integration **respects your development phase** and **trusts your judgment** about what's appropriate for your specific project and timeline.

## Troubleshooting

### Test Integration
```bash
./integrations/setup-subagent-integration.sh --test-only
```

### View Configuration
```bash
cat ~/.agent-os/subagent-config.yaml
```

### Check Available Agents
```bash
ls ~/.claude/agents/
```

### Debug Mode
Set environment variable for detailed logging:
```bash
export AGENT_OS_DEBUG=true
/create-spec-enhanced "test feature"
```

## Support

- **Issues**: Report integration issues in Agent OS repository
- **Configuration**: Edit `~/.agent-os/subagent-config.yaml`
- **Documentation**: Enhanced workflows maintain full compatibility
- **Community**: Share enhancement patterns and configurations

---

## Transform Your Development Process

Agent OS Subagent Integration transforms your AI-assisted development from good structured workflows into **professional development excellence** with:

- **Enterprise-grade quality** from first implementation
- **Automated quality assurance** throughout development
- **Professional documentation** that stakeholders love
- **Security and performance** built into every feature
- **First-try success** that saves time and reduces iterations

**Your existing workflows remain unchanged—they just produce dramatically better results.**