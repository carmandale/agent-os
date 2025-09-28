# Agent OS Repository Cleanup Plan

> Status: Draft for implementation
> Owners: Agent OS Maintainers
> Last Updated: 2025-09-20

This document captures the baseline findings from the repository audit and defines the cleanup strategy, action items, migration notes, and deprecation timeline.

It is designed to be used alongside the automated tools:
- Auditor: `python3 tools/repo-auditor.py --json tmp/cleanup_inventory.json --md tmp/cleanup_report.md`
- Context validation: `bash tools/context-integration.sh validate`
- Reference validation: `bash tools/validate-references.sh --summary`

---

## 1) Executive Summary

The audit surfaced four primary classes of issues:

1. Duplicated implementations
   - Parallel hook stacks in `hooks/` (current) and `hooks-stable/` (legacy).
   - Multiple identical benchmark files.
   - Documentation directories that duplicate command content.

2. Broken imports (Python)
   - Many standard-library or external imports show as "broken" in best‑effort static checks (benign).
   - A material subset are real issues: references to non-existent internal modules/files (e.g., `shared.git_utils`, `context_aware_hook.py`).

3. Potentially unreferenced files
   - Backup files and historical artifacts committed by mistake.
   - Experimental tests tied to not-yet-implemented libraries.
   - Example configs shipped alongside the installer-configured equivalents.

4. Configuration confusion
   - Multiple hook configuration styles in-tree (JSON samples vs. installer-generated settings).

The plan below consolidates the code paths, quarantines experimental work, and removes dead/duplicate artifacts with a clear migration path.

---

## 2) Audit Findings Snapshot

From the latest run of `tools/repo-auditor.py`:

- Duplicate groups: 9
  - Notable: entire `hooks-stable/` mirrors current `hooks/` functionality.
  - Three identical benchmark files in `hooks/tests/modular/`.
  - Documentation duplication under a path like `docs/BUILDER_METHODDS_agent-os/` mirroring items in `commands/` (treat as duplicate content to be consolidated).

- Broken imports (best-effort): 213
  - Majority are stdlib/third-party that the static resolver cannot confirm; safe to ignore.
  - Real issues to address:
    - `shared.git_utils` (referenced by a legacy hygiene stub).
    - `context_aware_hook.py` (referenced by some tests but not present).
    - Mismatched module names (`hook_core` vs `hook_core_optimized` in tests).

- Potentially unreferenced files: 77
  - Backup files in the repository (e.g., `*.backup`).
  - Experimental tests (depend on missing libs).
  - Configuration examples that are not actually used by the installer.

Note: The auditor is a heuristic tool. Each candidate should be reviewed before deletion.

---

## 3) Priority Cleanup Decisions

1. Designate `hooks/` as the single authoritative hook implementation.
   - Deprecate and remove `hooks-stable/` after a short migration window.
   - Provide migration guidance (see Section 6).

2. Normalize hook configuration.
   - Treat `hooks/claude-code-hooks.json` and `hooks/agent-os-bash-hooks.json` as examples only (move under `hooks/examples/`).
   - Keep `hooks/install-hooks.sh` as the canonical way to write `~/.claude/settings.json`.

3. Add a compatibility shim to close test/module drift.
   - Provide `hooks/modules/hook_core.py` that re-exports from `hook_core_optimized.py`.

4. Quarantine experimental / planned tests.
   - Move tests relying on not-yet-existing libs into `tests/experimental/` (or mark skipped).
   - Document their status with clear headers.

5. Remove obviously broken/orphaned code paths.
   - Example: `hooks/pretool/workspace_hygiene.py` referencing missing `shared.git_utils`.

6. Establish a tidy deletion of backup artifacts and dead files.

---

## 4) Duplicate Mapping → Action Items

| Duplicate Area | Representative Paths | Action |
|---|---|---|
| Hooks (stable vs current) | `hooks-stable/*` vs `hooks/*` | Remove `hooks-stable/*` after deprecation window; all users migrate to `hooks/` |
| Benchmark files | `hooks/tests/modular/benchmark_final.py`, `benchmark_optimized.py`, `benchmark_test.py` | Keep a single canonical benchmark (`benchmark_final.py`), delete the others |
| Docs/Commands duplication | e.g., `docs/BUILDER_METHODDS_agent-os/` vs `commands/` | Consolidate under commands + core docs; remove or merge duplicated docs |

Notes:
- Keep a release/tag pre-cleanup for historical reference.
- Add a migration advisory to the changelog for the hooks consolidation.

---

## 5) Broken Imports → Remediation Plan

Category A: True errors
- `shared.git_utils`: remove the referencing script (`hooks/pretool/workspace_hygiene.py`) or replace with current utilities in `hooks/lib` or Python modular handlers.
- `context_aware_hook.py`: tests that reference this should be moved to `tests/experimental/` or the file should be implemented per spec; until then, mark as experimental.
- `hook_core` vs `hook_core_optimized`: add `hooks/modules/hook_core.py` that re-exports from `hook_core_optimized.py` for backward-compatibility in tests.

Category B: Benign (std/3p)
- FYI only. The auditor flags imports it cannot resolve locally; no action unless they genuinely fail during runtime/CI.

---

## 6) Migration Notes (Hooks Consolidation)

Authoritative path: `hooks/`

Legacy path: `hooks-stable/` (to be removed)

What to change if you were using `hooks-stable`:
- Use the installer: `~/.agent-os/hooks/install-hooks.sh` to write your `~/.claude/settings.json`.
- Hooks provided and supported:
  - PreToolUse (Bash): `pre-bash-hook.sh`
  - PostToolUse (Bash): `post-bash-hook.sh`
  - UserPromptSubmit: `user-prompt-submit-hook.sh`
  - Stop: `stop-hook.sh`
  - Notification: `notify-hook.sh`
- The modular Python dispatcher (`hooks/workflow-enforcement-hook.py`) continues to handle PreToolUse/PostToolUse/UserPrompt/Task as configured by the installer.

Users with manual `hooks-stable` references should update paths to the equivalents in `hooks/`.

---

## 7) Unreferenced Files → Disposition

Proposed categories and treatments:

- Backup/temporary artifacts (e.g., `*.backup`, `tmp/*` intended outputs)
  - Remove from repo. Add to `.gitignore` when appropriate.

- Example configurations
  - Move to `hooks/examples/` with a README that clarifies they are samples and not authoritative.

- Experimental tests and spikes
  - Move to `tests/experimental/` (or `hooks/tests/experimental/` for hook-internal tests).
  - Add a standardized header: "Experimental – depends on future libraries; excluded from CI."

- Historical documentation duplicates
  - Merge into canonical docs or delete the duplicates; preserve under `/docs/ARCHIVE.md` if needed.

---

## 8) Deprecation Timeline

- T0 (merge):
  - Publish this plan; add release notes; tag pre-cleanup snapshot.
  - Introduce `hooks/modules/hook_core.py` shim.
  - Move example configs under `hooks/examples/`.
  - Quarantine experimental tests.
  - Delete duplicate benchmarks beyond the canonical one.

- T0 + 1 week:
  - Remove `hooks-stable/` from repository.
  - Update docs and installer notes; include migration section in README and CHANGELOG.

- T0 + 2–3 weeks:
  - Remove backup artifacts and confirmed unreferenced files.
  - Run full validation (Section 10).

- T0 + 4 weeks:
  - Close-out review. Ensure CI green and reference validators clean.

---

## 9) Acceptance Criteria & Validation

All of the following must be true to complete cleanup:

1. Hook system
   - `hooks/` is the only hook implementation.
   - Installer config is the single source of truth for settings.
   - No references to `hooks-stable/` remain in the tree.

2. Tests
   - CI passes with stable test suites only.
   - Experimental tests exist but do not run in CI by default.

3. Duplicates
   - Canonical benchmark only (`hooks/tests/modular/benchmark_final.py`).
   - No duplicate doc directories overlapping with commands.

4. Broken imports
   - No category A broken imports remain (e.g., `shared.git_utils`, missing `context_aware_hook.py`).
   - `hook_core` compatibility provided.

5. Reference & context validation
   - `bash tools/context-integration.sh validate` passes (no fatal errors).
   - `bash tools/validate-references.sh --summary` shows no broken references for active contexts.
   - `python3 tools/repo-auditor.py` outputs zero (or acknowledged) duplicates, no Category A broken imports, and a reviewed list of unreferenced candidates.

---

## 10) Implementation Checklist

- [ ] Add `hooks/modules/hook_core.py` shim re-exporting `hook_core_optimized`.
- [ ] Move example configs to `hooks/examples/` with README.
- [ ] Remove duplicate benchmarks (keep `benchmark_final.py`).
- [ ] Quarantine experimental tests in `tests/experimental/` (and/or mark skipped).
- [ ] Remove `hooks-stable/` after deprecation window.
- [ ] Remove backup files committed to repo (e.g., `*.backup`).
- [ ] Run validators and auditor; triage remaining items.
- [ ] Update documentation and CHANGELOG with migration notes.

---

## 11) Appendix

### A. Running the Auditor

```bash
# Default outputs under tmp/
python3 tools/repo-auditor.py \
  --json tmp/cleanup_inventory.json \
  --md tmp/cleanup_report.md

# Exclude large or irrelevant directories
python3 tools/repo-auditor.py \
  --exclude .git --exclude node_modules --exclude .venv
```

### B. Proposed Directory Moves

- `hooks/claude-code-hooks.json` → `hooks/examples/claude-code-hooks.json`
- `hooks/agent-os-bash-hooks.json` → `hooks/examples/agent-os-bash-hooks.json`

### C. Known Gaps to Address

- Tests referring to `context_aware_hook.py` need either a stub implementation or relocation to experimental.
- Libraries referenced in tests (e.g., `scripts/lib/update-documentation-lib.sh`, `scripts/lib/roadmap-sync.sh`) should be implemented or tests kept experimental until ready.

---

This plan is intended to be living documentation. As we resolve items and close gaps, update the sections above, especially the Acceptance Criteria and Implementation Checklist.