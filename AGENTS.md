# Repository Guidelines

## Project Structure & Module Organization
- `tools/aos` is the CLI entrypoint; `scripts/` houses shell orchestrators that enforce standards.
- `instructions/` and `commands/` define agent-facing prompts; `standards/` holds default coding rules.
- `.agent-os/` mirrors the product workspace for internal dogfooding; `integrations/` and `workflow-modules/` bundle optional plugins.
- `templates/` and `docs/` provide reusable spec scaffolds and architecture notes.
- Automated checks live in `tests/`, mixing Bats suites for shell flows and Python smoke tests.

## Build, Test, and Development Commands
- `./setup.sh` installs or refreshes the local Agent OS toolchain.
- `./scripts/workspace-hygiene-check.sh` confirms clean git state, active spec, and issue linkage.
- `./scripts/workflow-status.sh check` reports the current workflow session and blockers.
- `bats tests` runs the shell regression suite; append `--filter <pattern>` to target a workflow.
- `pytest tests/test_project_root_resolver.py` executes the Python validator; scale with `pytest tests/` when adding coverage.

## Coding Style & Naming Conventions
- Tabs are mandatory; set your editor to render tabs at four columns.
- Follow `standards/code-style.md`: Python uses snake_case functions, PascalCase classes, double-quoted f-strings, and type hints by default.
- JavaScript/TypeScript favors camelCase variables, PascalCase components, modern ES modules, and Tailwind utility groupings.
- Prefix React hooks with `use`, keep components functional, and comment only to explain intent.

## Testing Guidelines
- Mirror executable names when adding Bats files (e.g., `tests/workflow-validation.bats`).
- Place Python coverage in `tests/test_*.py`, using fixtures and type hints.
- Maintain ≥80% coverage on touched areas and capture failing cases before fixes.
- Run `bats` and the relevant `pytest` targets before claiming completion, and paste the output into specs or PR descriptions to satisfy the testing-enforcer.

## Commit & Pull Request Guidelines
- Use `<type>: summary` plus the GitHub issue reference (e.g., `fix: resolve workflow status leak #123`).
- Commit scoped, test-backed changes only, regenerating automated artifacts when required.
- PRs must link the driving issue, describe implementation and tests, and attach screenshots or logs for CLI or UX changes.
- Validate `./scripts/workflow-validator.sh` before requesting review.

## Agent Workflow Tips
Keep the REPO (`agent-os/`), SYSTEM install (`~/.agent-os/`), and PROJECT overlays (`your-app/.agent-os/`) distinct. Run `aos status` to confirm your SYSTEM baseline, and use `./scripts/work-session-manager.sh start` for long-running tasks so background process tracking stays accurate.
