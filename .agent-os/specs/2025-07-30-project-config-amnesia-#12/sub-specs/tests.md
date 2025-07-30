# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-30-project-config-amnesia-#12/spec.md

> Created: 2025-07-30
> Version: 1.0.0

## Test Coverage

### Unit Tests

**project-context-loader.sh**
- Test configuration file detection across different project structures
- Test parsing of environment files (.env, .env.local) with various formats
- Test startup script analysis (start.sh, dev.sh, package.json scripts)
- Test Agent OS tech-stack.md parsing with different content variations
- Test configuration hierarchy resolution with conflicting values
- Test error handling for malformed, missing, or unreadable files

**config-resolver.py**
- Test JSON configuration merging with complex nested structures
- Test precedence rule application with multiple configuration sources
- Test port number extraction and validation from various formats
- Test package manager detection from different command patterns
- Test startup command parsing with complex multi-line scripts
- Test edge cases like commented lines, environment variable substitution

**session-memory.sh**
- Test session state initialization and configuration storage
- Test configuration persistence across multiple script invocations
- Test session validation and configuration drift detection
- Test cache invalidation when configuration files change
- Test memory cleanup and reset functionality

**config-validator.sh**
- Test command validation against stored project configuration
- Test auto-correction of common configuration violations
- Test detection of package manager switches (uv vs pip, npm vs yarn)
- Test port number validation in various command contexts
- Test startup command consistency checking

### Integration Tests

**Full Configuration Loading Workflow**
- Test end-to-end configuration loading for typical web project structures
- Test configuration resolution with realistic file combinations
- Test integration with existing Agent OS workflow modules
- Test performance under various project sizes and complexity levels

**Hook System Integration**
- Test user-prompt-submit-hook integration with configuration loading
- Test context injection enhancement with project configuration
- Test pre-command validation hook behavior
- Test hook performance impact with configuration loading enabled

**Real Project Scenarios**
- Test React + FastAPI project with uv and custom ports
- Test Next.js + Node.js project with yarn and default ports
- Test Django + PostgreSQL project with poetry and custom configuration
- Test monorepo project with multiple package managers and services
- Test legacy project migration with incomplete configuration

### Mocking Requirements

**File System Operations**
- Mock file existence checks (test -f, test -d)
- Mock file reading operations for various configuration file types
- Mock file modification time checks for cache invalidation
- Mock permission checks for configuration file access

**External Commands**
- Mock package manager availability checks (which uv, which npm)
- Mock git repository detection and status checks
- Mock environment variable detection and expansion
- Mock process execution for startup script analysis

**Network and System Resources**
- Mock port availability checks for configuration validation
- Mock system resource checks (disk space, memory for caching)
- Mock user permission checks for temporary file creation

## Test Data Setup

### Sample Project Configurations

**Minimal Web Project**
```
project-minimal/
├── .env.local (PORT=3001)
├── .env (API_PORT=8001)
├── start.sh (uv, npm commands)
└── .agent-os/product/tech-stack.md
```

**Complex Multi-Service Project**
```
project-complex/
├── frontend/
│   ├── .env.local (PORT=3002, REACT_APP_API_URL=http://localhost:8002)
│   └── package.json (yarn scripts)
├── backend/
│   ├── .env (API_PORT=8002, DATABASE_URL=...)
│   └── requirements.txt
├── start.sh (multi-service startup)
├── docker-compose.yml
└── .agent-os/product/tech-stack.md
```

**Legacy Project**
```
project-legacy/
├── old-config.ini
├── Makefile (startup commands)
├── package.json (outdated scripts)
└── README.md (manual setup instructions)
```

### Configuration Test Cases

**Environment File Variations**
- Standard KEY=value format
- Quoted values with spaces
- Comments and empty lines
- Environment variable expansion
- Multi-line values
- Special characters and encoding

**Startup Script Patterns**
- Simple command sequences
- Conditional execution (if statements)
- Background process management (&)
- Environment activation (source, activate)
- Complex pipe operations
- Error handling (set -e, trap)

**Package Manager Detection**
- uv vs pip detection in Python projects
- npm vs yarn vs pnpm in Node.js projects
- Poetry vs pipenv vs venv patterns
- Virtual environment activation patterns
- Lock file presence and analysis

## Performance Tests

### Load Testing
- **Configuration Loading Time**: Measure time to load configuration from projects with 100+ files
- **Memory Usage**: Monitor memory consumption during configuration parsing and caching
- **Cache Performance**: Measure cache hit/miss rates and lookup performance
- **Concurrent Access**: Test configuration loading with multiple simultaneous processes

### Regression Testing
- **Hook Integration Performance**: Ensure configuration loading doesn't slow down Claude Code hooks
- **File System Impact**: Monitor file system operation count and efficiency
- **Session Memory Overhead**: Measure memory usage growth over long sessions
- **Configuration Change Response**: Test performance when configuration files are frequently modified

## Error Handling Tests

### File System Error Conditions
- Configuration files with no read permissions
- Configuration files that are directories instead of files
- Symlinks pointing to non-existent files
- File system full conditions during cache creation
- Network file system timeout scenarios

### Configuration Error Conditions
- Malformed JSON in Agent OS tech-stack configuration
- Invalid port numbers (negative, too large, non-numeric)
- Circular dependencies in configuration inheritance
- Conflicting package manager specifications
- Missing required configuration fields

### Recovery Testing
- **Graceful Degradation**: Ensure system works with partial configuration
- **Automatic Repair**: Test auto-correction of common configuration errors
- **User Notification**: Verify clear error messages for unrecoverable conditions
- **Fallback Behavior**: Test behavior when all configuration sources fail

## Validation Tests

### Configuration Consistency
- **Cross-File Validation**: Ensure port numbers match between .env and start.sh
- **Package Manager Consistency**: Verify lock files match declared package managers
- **Startup Command Validation**: Confirm start.sh commands match tech-stack.md declarations
- **Environment Synchronization**: Check that environment variables align with configuration

### Real-World Compatibility
- **Popular Framework Testing**: Test with Create React App, Next.js, Vue CLI, Django, FastAPI
- **Package Manager Variations**: Test with all major package managers and their configuration patterns
- **Development Environment Testing**: Test with various shell environments (bash, zsh, fish)
- **Operating System Compatibility**: Test configuration loading on macOS, Linux, and WSL