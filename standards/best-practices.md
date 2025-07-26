# Development Best Practices

> Version: 1.1.0
> Last updated: 2025-07-26
> Scope: Global development standards

## Context

This file is part of the Agent OS standards system. These global best practices are referenced by all product codebases and provide default development guidelines. Individual projects may extend or override these practices in their `.agent-os/product/dev-best-practices.md` file.

## Core Principles

### Keep It Simple
- Implement code in the fewest lines possible
- Avoid over-engineering solutions
- Choose straightforward approaches over clever ones

### Optimize for Readability
- Prioritize code clarity over micro-optimizations
- Write self-documenting code with clear variable names
- Add comments for "why" not "what"

### DRY (Don't Repeat Yourself)
- Extract repeated business logic to private methods
- Extract repeated UI markup to reusable components
- Create utility functions for common operations

### GitHub Issue & PR Workflow (Required)
**Every piece of work must follow this workflow - no exceptions:**

1. **All work starts with a GitHub issue** - Create or reference an existing issue before any development
2. **All commits reference the issue** - Use format: `feat: implement user auth #123` or `fix: resolve login bug #456`
3. **All PRs link to issues** - Use keywords: `Fixes #123`, `Closes #123`, or `Relates to #123`
4. **Issues and PRs must be updated and closed** - Keep them current and close when work is complete
5. **Focused, frequent commits** - Commit specific, tangible accomplishments, not random work batches

## Dependencies

### Choose Libraries Wisely
When adding third-party dependencies:
- Select the most popular and actively maintained option
- Check the library's GitHub repository for:
  - Recent commits (within last 6 months)
  - Active issue resolution
  - Number of stars/downloads
  - Clear documentation

## Code Organization

### File Structure
- Keep files focused on a single responsibility
- Group related functionality together
- Use consistent naming conventions

### Testing
- Write tests for new functionality
- Maintain existing test coverage
- Test edge cases and error conditions

---

*Customize this file with your team's specific practices. These guidelines apply to all code written by humans and AI agents.*
