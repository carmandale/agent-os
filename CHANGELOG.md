# Changelog

All notable changes to Agent OS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-01-10

### Added
- **Workflow Enforcement Hooks v2 & v3**: Improved hooks with better compound command handling
- **Update System**: Comprehensive update guide and `check-updates.sh` script
- **Smart `aos` Alias v2**: Improved interactive setup with smart updates
- **Version Tracking**: Proper VERSION file and release system
- **Documentation**: 
  - UPDATE_GUIDE.md for handling updates
  - PRODUCT_DOCS_TRACKING.md for gitignore best practices
  - Expanded workflow modules with better enforcement
- **Testing Reminders**: Hook system to prevent false completion claims (#9)

### Changed
- **Hook Improvements**:
  - TodoWrite no longer blocks as "new work"
  - Better handling of compound git commands
  - Smart detection of documentation updates (v3)
  - Allow file operations (chmod, mv, rm, cp) with git
- **Workflow Modules**: Enhanced with stricter validation requirements
- **Installation Process**: Quieter output, better error handling

### Fixed
- Compound command blocking in hooks (e.g., `chmod +x && git add && git commit`)
- Redundant update messages in `aos` alias
- False completion claims without actual testing
- Configuration amnesia issues (#12)

### Security
- Hooks now properly validate work before allowing completion claims
- Stricter enforcement of testing requirements

## [1.1.0] - 2025-01-07

### Added
- Initial Claude Code hooks implementation
- Workspace hygiene checking
- Task status validation
- GitHub workflow integration

### Changed
- Enhanced error handling in setup scripts
- Improved workspace validation

## [1.0.0] - 2024-12-15

### Added
- Initial fork from Builder Methods Agent OS
- Tab indentation preference
- Python/React stack defaults
- GitHub Issues workflow enforcement
- Basic installation scripts

---

## Release Types

- **Major (X.0.0)**: Breaking changes, architectural updates
- **Minor (0.X.0)**: New features, backwards compatible
- **Patch (0.0.X)**: Bug fixes, minor improvements