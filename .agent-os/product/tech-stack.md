# Technical Stack

> Last Updated: 2025-01-27
> Version: 1.0.0

## Core Technologies

**Primary Language:** Shell (Bash)
**Documentation Format:** Markdown
**Distribution Method:** Git/GitHub with curl installation
**Version Control:** Git with conventional commits

## Framework Components

**Standards Templates:**
- Tech stack configuration
- Code style preferences  
- Best practices guidelines

**Workflow Instructions:**
- Product planning framework
- Feature specification creation
- Task execution with TDD
- Product analysis for existing codebases

**Integration Scripts:**
- Claude Code command setup
- Cursor rules configuration
- Health check verification

## Distribution Architecture

**Installation Method:** curl + bash scripts
**Storage Location:** ~/.agent-os/ (user home directory)
**File Structure:**
- ~/.agent-os/standards/ (global standards)
- ~/.agent-os/instructions/ (workflow templates)
- Project-level: .agent-os/product/ (project-specific docs)

## Development Environment

**No Development Servers Required**
- Frontend Port: N/A (framework, not web app)
- Backend Port: N/A (no server components)

**Local Development:**
- Shell script testing
- Markdown validation
- Git workflow testing
- Real-world usage validation

## Integration Targets

**Claude Code:**
- Slash command integration (/plan-product, /create-spec, etc.)
- Context file referencing (@.agent-os/product/...)
- Global standards access (@~/.agent-os/...)

**Cursor:**
- .cursorrules file configuration
- Project context integration
- Workflow automation

**GitHub:**
- Issue-based workflow
- PR creation and management
- Branch naming conventions

## Quality Assurance

**Testing Strategy:** Real-world usage validation
**Documentation:** Comprehensive markdown docs
**Error Handling:** Graceful fallbacks and user guidance
**Compatibility:** Cross-platform shell script compatibility

## Deployment

**Distribution:** GitHub repository with curl installation
**Updates:** Pull-based updates with --overwrite flags
**Customization:** User-modifiable templates and standards
**Version Management:** Git tags and semantic versioning