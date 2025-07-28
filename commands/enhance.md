# Enhance Current Spec/Task

Add subagent analysis to current work when you're ready for it.

This command allows you to optionally enhance your current spec or task execution with specialized subagent analysis. All enhancements are completely optional and you can pick and choose which ones are valuable for your specific context.

## Usage

```bash
/enhance                    # Show available enhancements for current context
/enhance --security         # Add security analysis to current spec/task
/enhance --architecture     # Add architectural validation
/enhance --testing          # Add comprehensive testing strategy
/enhance --performance      # Add performance optimization
/enhance --prd              # Add professional PRD elements
/enhance --quality          # Add code quality analysis
/enhance --all              # Add all applicable enhancements (rare - only if you really want everything)
```

## Available Enhancements

### For Specs (`create-spec` workflow)
- **Security Analysis**: Threat modeling and security best practices (when ready for production)
- **Architectural Review**: System design validation and scalability planning
- **Professional Testing**: Comprehensive test strategy with edge cases
- **PRD Enhancement**: Professional user stories and acceptance criteria

### For Tasks (`execute-tasks` workflow)
- **Senior Engineering**: Architectural guidance for complex implementations
- **Code Quality**: Maintainability analysis and improvement suggestions
- **Performance**: Optimization analysis and recommendations
- **Security Validation**: Security review of implementation

## Philosophy

- **Your choice**: Never automatic, always optional
- **When you're ready**: Perfect for prototypes that are becoming production systems
- **Educational**: Learn best practices without enforcement
- **Contextual**: Only suggest enhancements that make sense for your project

## Examples

### Prototype to Production
```bash
# Start simple
/create-spec "User authentication system"
# → Creates basic spec focused on functionality

# Later, when ready for production
/enhance --security --architecture
# → Adds comprehensive security analysis and architectural review
```

### Learning and Growth
```bash
# Working on a feature
/execute-tasks

# Want to learn better patterns
/enhance --quality --architecture
# → Get professional guidance on code quality and design patterns
```

### Selective Enhancement
```bash
# Only want security analysis for this banking prototype
/enhance --security
# → Just security, nothing else

# Want comprehensive analysis
/enhance --all
# → Everything applicable (use sparingly)
```

## Integration

This command works with your current Agent OS workflow state:
- Detects whether you're in planning, spec creation, or task execution
- Shows only relevant enhancements for your current context
- Maintains your existing work and adds enhancements on top
- Can be used multiple times to add different enhancements

Remember: You know your project better than any AI. Use enhancements when they add value, skip them when they don't. No judgment either way!