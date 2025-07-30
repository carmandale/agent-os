# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-30-intelligent-workspace-cleanup-#11/spec.md

> Created: 2025-07-30
> Version: 1.0.0

## Technical Requirements

### Core Workspace Analysis Engine
- **File Categorization System**: Analyze uncommitted changes and categorize each file/change as:
  - `valuable`: Actual code, documentation, configuration changes worth committing
  - `temporary`: Build artifacts, logs, cache files that should be ignored/deleted
  - `sensitive`: Files containing potential secrets, API keys, credentials requiring manual review
  - `unknown`: Files requiring user decision

- **Pattern Matching Engine**: Rule-based system using:
  - File extension patterns (`.log`, `.tmp`, `.cache`, etc.)
  - Path patterns (`node_modules/`, `.next/`, `dist/`, `build/`, etc.)
  - Content patterns for sensitive data (API_KEY=, password=, token=, etc.)
  - Gitignore-like pattern matching for flexible rules

- **Security Scanner**: Detect common secret patterns in file content:
  - Environment variables with sensitive names
  - JWT tokens, API keys, database URLs
  - Private keys, certificates
  - Common service credentials (AWS, Google, etc.)

### Smart Cleanup Actions Engine
- **Valuable Files**: Add to git staging area for commit
- **Temporary Files**: 
  - Delete if truly temporary (logs, caches)
  - Add to .gitignore if recurring pattern
  - Move to temp directory if potentially needed
- **Sensitive Files**: 
  - Block automatic processing
  - Provide secure cleanup guidance
  - Suggest .env.example patterns
- **Unknown Files**: Present to user with context and suggested actions

### Hook Integration Architecture
- **Replace Current Behavior**: Modify workflow-enforcement-hook-v2.py to call workspace analyzer instead of requiring blind commits
- **Progressive Cleanup**: Handle one category at a time to avoid overwhelming user
- **Fallback Safety**: If analysis fails, fall back to current behavior with clear warnings
- **User Override**: Provide escape hatch for urgent situations

## Approach Options

**Option A: Shell Script Implementation**
- Pros: Consistent with Agent OS architecture, fast execution, no additional dependencies
- Cons: Limited pattern matching capabilities, harder to maintain complex logic

**Option B: Python Script Integration** (Selected)
- Pros: Rich pattern matching, easy integration with existing hook, extensive string/file processing
- Cons: Adds Python dependency (already exists via hooks)

**Option C: External Tool Integration**
- Pros: Leverage existing tools like git-secrets, pre-commit
- Cons: Additional dependencies, less control over user experience

**Rationale:** Option B provides the best balance of capability and integration. Since Agent OS hooks already use Python, extending the existing hook system is the most natural approach.

## Implementation Strategy

### Phase 1: Core Analysis Engine
1. **File Pattern Database**: Create comprehensive rules for common temporary files, build artifacts, and sensitive patterns
2. **Workspace Scanner**: Implement git status parsing and file content analysis
3. **Categorization Logic**: Apply rules to determine file categories
4. **Basic Actions**: Implement cleanup actions for each category

### Phase 2: Hook Integration
1. **Modify Hook Architecture**: Update workflow-enforcement-hook-v2.py to use workspace analyzer
2. **User Interface**: Create clear prompts and guidance for each cleanup scenario
3. **Safety Mechanisms**: Implement checks and confirmations for potentially destructive actions
4. **Testing Framework**: Comprehensive testing with various workspace scenarios

### Phase 3: Advanced Features
1. **Learning System**: Track user decisions to improve categorization
2. **Project-Specific Rules**: Allow customization per project/repository
3. **Integration Points**: Connect with existing gitignore management
4. **Performance Optimization**: Efficient processing for large workspaces

## External Dependencies

**No New Dependencies Required**
- Uses existing Python 3 (already required for hooks)
- Uses existing git CLI (already required for Agent OS)
- Uses existing shell environment (bash)

**Leveraged Existing Components:**
- Current hook system in ~/.agent-os/hooks/
- Existing Agent OS shell script architecture
- Git integration patterns already established

## File Structure Changes

```
~/.agent-os/hooks/
├── workflow-enforcement-hook-v2.py (modified)
├── workspace-analyzer.py (new)
└── cleanup-patterns.json (new)

~/.agent-os/scripts/
└── workspace-cleanup.sh (new - fallback/standalone usage)
```

## Configuration System

### Default Pattern Rules
```json
{
  "temporary_patterns": [
    "*.log", "*.tmp", "*.cache", "*.pid",
    "node_modules/", ".next/", "dist/", "build/",
    "__pycache__/", "*.pyc", ".pytest_cache/",
    ".DS_Store", "Thumbs.db"
  ],
  "sensitive_patterns": [
    "API_KEY=", "SECRET_KEY=", "PASSWORD=", "TOKEN=",
    "private_key", "-----BEGIN", "aws_access_key",
    "database_url", "connection_string"
  ],
  "valuable_patterns": [
    "*.py", "*.js", "*.ts", "*.md", "*.json",
    "*.yml", "*.yaml", "*.sh", "*.sql"
  ]
}
```

### User Customization
- Project-specific overrides in `.agent-os/project/cleanup-rules.json`
- Global user customization in `~/.agent-os/user-cleanup-rules.json`
- CLI flags for temporary rule adjustments

## Security Considerations

- **No Automatic Deletion of Sensitive Files**: Always require user confirmation
- **Secure Temporary Storage**: If moving files, use secure temporary locations
- **Audit Trail**: Log all cleanup actions for accountability
- **Pattern Privacy**: Ensure secret detection patterns don't log actual secret values
- **User Control**: Always provide way to abort or modify automated actions