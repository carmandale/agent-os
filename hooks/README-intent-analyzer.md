# Intent Analysis Engine

The Intent Analysis Engine is a core component of Agent OS's context-aware workflow enforcement system. It analyzes user messages to distinguish between maintenance work (fixing bugs, debugging issues) and new development work (implementing features, building new systems).

## Features

- **Pattern-based Classification**: Uses regex patterns to identify maintenance vs new work intent
- **Configurable Patterns**: YAML configuration file allows customization of patterns
- **Confidence Scoring**: Provides confidence scores for classification decisions
- **Ambiguous Intent Detection**: Identifies unclear messages that need clarification
- **High Performance**: Sub-millisecond analysis time for typical user messages
- **Comprehensive Logging**: Debug logging for troubleshooting classification decisions

## Usage

### Command Line

```bash
# Test a message
python3 intent_analyzer.py "fix the failing authentication tests"
# Output: Intent Type: maintenance, Confidence: 0.62

# Enable debug logging
python3 intent_analyzer.py "implement user dashboard" --debug
```

### Python API

```python
from intent_analyzer import IntentAnalyzer, IntentType

analyzer = IntentAnalyzer()
result = analyzer.analyze_intent("fix the failing tests")

if result.intent_type == IntentType.MAINTENANCE:
    # Allow work with dirty workspace
    print(f"Maintenance work detected: {result.reasoning}")
elif result.intent_type == IntentType.NEW_WORK:
    # Require clean workspace
    print(f"New work detected: {result.reasoning}")
else:
    # Ambiguous - prompt user for clarification
    print(f"Ambiguous intent: {result.reasoning}")
```

## Configuration

The intent analyzer can be configured via `~/.agent-os/config/workflow-enforcement.yaml`:

```yaml
maintenance_patterns:
  - '\bfix\b.*\btests?\b'
  - '\bdebug\b'
  - '\bresolve\b.*\bconflicts?\b'

new_work_patterns:
  - '\bimplement\b.*\bfeature\b'
  - '\bcreate\b.*\bcomponent\b'
  - '\bbuild\b.*\bnew\b'

confidence_threshold: 0.3
ambiguous_threshold: 0.15
```

## Default Patterns

### Maintenance Work Patterns
- Fix tests, bugs, issues, errors
- Debug any problems
- Resolve conflicts or pipeline failures
- Update dependencies
- Repair, correct, mend, patch

### New Work Patterns
- Implement features, dashboards, profiles
- Build new systems or components
- Create features, APIs, interfaces
- Add functionality or systems
- Develop or design new components

## Dependencies

- Python 3.7+
- PyYAML (optional - falls back to defaults if not available)

## Testing

```bash
# Run basic functionality tests
python3 -c "from intent_analyzer import *; print('Import successful')"

# Test with sample messages
python3 intent_analyzer.py "fix the failing tests"
python3 intent_analyzer.py "implement user dashboard"
```