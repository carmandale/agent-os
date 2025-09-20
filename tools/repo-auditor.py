#!/usr/bin/env python3
"""
repo-auditor.py
Agent OS Repository Auditor

Purpose:
- Baseline the repository state for clean-up work.
- Detect duplicate files by content hash.
- Detect broken imports in Python files (best-effort resolution within repo).
- Identify potentially unreferenced files.

Outputs:
- JSON report (default: tmp/cleanup_inventory.json)
- Markdown report (default: tmp/cleanup_report.md)
- Brief summary to stdout

Usage:
  python3 tools/repo-auditor.py
  python3 tools/repo-auditor.py --root . --json tmp/inventory.json --md tmp/report.md
  python3 tools/repo-auditor.py --exclude .git --exclude node_modules
"""

from __future__ import annotations

import argparse
import ast
import hashlib
import io
import json
import os
import re
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional, Iterable


# -------------------------------
# Utilities
# -------------------------------

DEFAULT_EXCLUDES = {
    ".git", ".hg", ".svn", "__pycache__", ".mypy_cache", ".pytest_cache",
    ".idea", ".vscode", "node_modules", ".venv", "venv", "dist", "build",
    ".DS_Store", ".cache"
}

TEXT_EXTENSIONS = {
    ".md", ".markdown", ".txt", ".json", ".yml", ".yaml", ".toml", ".ini",
    ".sh", ".bash", ".zsh", ".ps1",
    ".py", ".pyi",
    ".bats",
    ".js", ".jsx", ".ts", ".tsx",
    ".css", ".scss", ".less",
    ".c", ".cc", ".cpp", ".h", ".hpp",
    ".go", ".rb", ".rs", ".java", ".kt", ".scala",
    ".sql",
}

# Files under these top-level dirs are considered source-of-truth and may be referenced indirectly
LIKELY_TOP_DIRS = {
    "hooks", "scripts", "tools", "instructions", "workflow-modules",
    "commands", "claude-code", "docs", "standards", "tests"
}

MAX_READ_BYTES = 1_000_000  # 1 MB safety cap when reading files as text


def is_probably_text(path: Path) -> bool:
    # Heuristic: look at extension; fallback to sniff first 2KB for null bytes
    if path.suffix.lower() in TEXT_EXTENSIONS:
        return True
    try:
        with open(path, "rb") as f:
            chunk = f.read(2048)
        return b"\x00" not in chunk
    except Exception:
        return False


def read_text_safely(path: Path, max_bytes: int = MAX_READ_BYTES) -> str:
    try:
        with open(path, "rb") as f:
            data = f.read(max_bytes)
        # Try utf-8 first, fallback to latin-1
        try:
            return data.decode("utf-8", errors="ignore")
        except Exception:
            return data.decode("latin-1", errors="ignore")
    except Exception:
        return ""


def sha256_file(path: Path) -> Optional[str]:
    try:
        h = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                h.update(chunk)
        return h.hexdigest()
    except Exception:
        return None


def path_within(root: Path, path: Path) -> str:
    try:
        return str(path.resolve().relative_to(root.resolve())).replace("\\", "/")
    except Exception:
        # If not relative (e.g., symlink outside), return name
        return path.name


# -------------------------------
# Data Models
# -------------------------------

@dataclass
class DuplicateEntry:
    hash: str
    files: List[str]


@dataclass
class BrokenImport:
    file: str
    import_name: str
    line: Optional[int] = None
    column: Optional[int] = None
    resolved_candidates: List[str] = None


@dataclass
class AuditorResult:
    root: str
    files_scanned: int
    py_files_scanned: int
    duplicates: List[DuplicateEntry]
    broken_imports: List[BrokenImport]
    unreferenced_candidates: List[str]


# -------------------------------
# Repository Scanner
# -------------------------------

class RepoScanner:
    def __init__(self, root: Path, excludes: Set[str]):
        self.root = root
        self.excludes = set(excludes)

    def iter_files(self) -> Iterable[Path]:
        for p in self.root.rglob("*"):
            if not p.is_file():
                continue
            # Exclude directories by any segment name
            parts = set(p.relative_to(self.root).parts)
            if any(seg in self.excludes for seg in parts):
                continue
            yield p


# -------------------------------
# Duplicate Detector
# -------------------------------

class DuplicateDetector:
    def __init__(self):
        self.by_hash: Dict[str, List[Path]] = {}

    def add(self, path: Path):
        h = sha256_file(path)
        if not h:
            return
        self.by_hash.setdefault(h, []).append(path)

    def get_duplicates(self, root: Path) -> List[DuplicateEntry]:
        out: List[DuplicateEntry] = []
        for h, paths in self.by_hash.items():
            if len(paths) > 1:
                out.append(DuplicateEntry(hash=h, files=[path_within(root, p) for p in sorted(paths)]))
        # Sort deterministically
        out.sort(key=lambda e: (len(e.files) * -1, e.hash))
        return out


# -------------------------------
# Python Import Analyzer (best-effort)
# -------------------------------

class PythonImportAnalyzer:
    """
    Best-effort Python import resolver limited to repo files.
    Tries to resolve 'import a.b' or 'from a.b import c' to paths within the repo:
      <root>/a/b.py or <root>/a/b/__init__.py
    For relative imports, resolve relative to the file's directory, ascending as needed.
    """
    def __init__(self, root: Path):
        self.root = root

    def parse_imports(self, py_path: Path) -> List[Tuple[str, Optional[int], Optional[int]]]:
        imports: List[Tuple[str, Optional[int], Optional[int]]] = []
        try:
            text = read_text_safely(py_path)
            tree = ast.parse(text)
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for alias in node.names:
                        imports.append((alias.name, getattr(node, "lineno", None), getattr(node, "col_offset", None)))
                elif isinstance(node, ast.ImportFrom):
                    # Relative level handling: build a dotted base if possible
                    base = "." * (node.level or 0) + (node.module or "")
                    if base.strip("."):
                        imports.append((base, getattr(node, "lineno", None), getattr(node, "col_offset", None)))
                    else:
                        # 'from . import something' — we still record as relative to current
                        imports.append(("." * (node.level or 0), getattr(node, "lineno", None), getattr(node, "col_offset", None)))
        except Exception:
            # If parse fails, return empty list
            return []
        return imports

    def _module_to_candidate_paths(self, importer_path: Path, module_name: str) -> List[Path]:
        """
        Produce candidate file paths inside the repo for a given module name.
        - Absolute: root/<mod path>.py or root/<mod path>/__init__.py
        - Relative (leading dots): resolve against importer directory ancestors.
        """
        candidates: List[Path] = []
        relative_dots = len(module_name) - len(module_name.lstrip("."))
        dotted = module_name.lstrip(".")
        components = dotted.split(".") if dotted else []

        # Determine base directories to search
        base_dirs: List[Path] = []

        if relative_dots > 0:
            # Relative to importer directory, ascend (relative_dots - 1) times
            base = importer_path.parent
            for _ in range(max(relative_dots - 1, 0)):
                base = base.parent
            base_dirs.append(base)
        else:
            # Absolute search starting points: repo root and all ancestors of importer up to root
            base_dirs.append(self.root)
            # Include importer ancestors to emulate package roots
            p = importer_path.parent
            while self.root in p.parents or p == self.root:
                base_dirs.append(p)
                if p == self.root:
                    break
                p = p.parent

        for base in base_dirs:
            if components:
                path1 = base.joinpath(*components).with_suffix(".py")
                path2 = base.joinpath(*components, "__init__.py")
                candidates.extend([path1, path2])
            else:
                # Case: only dots (e.g., "from . import x") -> current package __init__.py
                candidates.append(base / "__init__.py")

        # Normalize unique existing ones
        uniq: List[Path] = []
        seen = set()
        for c in candidates:
            try:
                rp = c.resolve()
            except Exception:
                rp = c
            if rp in seen:
                continue
            seen.add(rp)
            uniq.append(c)
        return uniq

    def resolve_within_repo(self, importer_path: Path, module_name: str) -> Tuple[bool, List[str]]:
        candidates = self._module_to_candidate_paths(importer_path, module_name)
        found = []
        for c in candidates:
            # Only accept if under repo root
            try:
                if c.exists() and self.root.resolve() in c.resolve().parents or c.resolve() == self.root.resolve():
                    found.append(str(c))
            except Exception:
                continue
        return (len(found) > 0, found)

    def find_broken_imports(self, py_files: List[Path]) -> List[BrokenImport]:
        results: List[BrokenImport] = []
        for p in py_files:
            imports = self.parse_imports(p)
            for name, line, col in imports:
                ok, cands = self.resolve_within_repo(p, name)
                if not ok:
                    # Exclude common stdlib/3p names heuristically? Keep them as potential issues unless obviously stdlib
                    results.append(BrokenImport(
                        file=path_within(self.root, p),
                        import_name=name,
                        line=line, column=col,
                        resolved_candidates=[]
                    ))
        # Deduplicate consecutive identical entries
        uniq: Dict[Tuple[str, str, Optional[int]], BrokenImport] = {}
        for bi in results:
            key = (bi.file, bi.import_name, bi.line)
            if key not in uniq:
                uniq[key] = bi
        return list(uniq.values())


# -------------------------------
# Unreferenced File Detector
# -------------------------------

PATH_TOKEN_RE = re.compile(r"[A-Za-z0-9_\-./]+(?:\.[A-Za-z0-9_\-]+)")
SLASH_HINT_RE = re.compile(r"[A-Za-z0-9_\-]+/[A-Za-z0-9_\-./]+")


class UnreferencedDetector:
    """
    Heuristic detector for potentially unreferenced files.

    Strategy:
    - Build a searchable corpus of text from repository files (with size cap).
    - For each file:
        - Check if its relative path string appears in any other file's content.
        - Else check whether its basename appears in any other file's content.
        - If neither is found, mark as "potentially unreferenced".
    - Whitelist common roots and well-known file types to reduce noise.
    """
    def __init__(self, root: Path, excludes: Set[str]):
        self.root = root
        self.excludes = excludes

    def _collect_text_files(self) -> List[Path]:
        files: List[Path] = []
        for p in self.root.rglob("*"):
            if not p.is_file():
                continue
            if any(seg in self.excludes for seg in p.relative_to(self.root).parts):
                continue
            if is_probably_text(p):
                files.append(p)
        return files

    def _build_corpus(self, files: List[Path]) -> Dict[str, Set[str]]:
        """
        Returns dict mapping path->set of tokens (including raw content for path matching).
        """
        corpus: Dict[str, Set[str]] = {}
        for p in files:
            rel = path_within(self.root, p)
            text = read_text_safely(p)
            tokens: Set[str] = set()
            # Path-like tokens and words
            for m in PATH_TOKEN_RE.findall(text):
                if "/" in m or "." in m:
                    tokens.add(m)
            # Add the full text into a mini-index (large but capped), by chunk of lines if needed
            # For efficiency, store only tokens, and special-case exact path checks separately.
            corpus[rel] = tokens
        return corpus

    def find_unreferenced(self, all_files: List[Path]) -> List[str]:
        text_files = self._collect_text_files()
        corpus = self._build_corpus(text_files)

        rel_files = [path_within(self.root, p) for p in all_files]
        # Build a fast lookup for basenames used
        referencing_files = set(corpus.keys())

        unref_candidates: List[str] = []
        for rel in rel_files:
            # Exclude tmp and certain doc roots from "unreferenced" heuristics
            parts = rel.split("/")
            if parts and parts[0] in {"tmp"}:
                continue
            # Skip the report outputs themselves
            if rel.startswith("tmp/cleanup_"):
                continue

            basename = os.path.basename(rel)
            found_ref = False
            for other in referencing_files:
                if other == rel:
                    continue
                tokens = corpus.get(other, set())
                # Exact relative path seen?
                if rel in tokens:
                    found_ref = True
                    break
                # Basename seen?
                if basename and basename in tokens:
                    found_ref = True
                    break
            if not found_ref:
                unref_candidates.append(rel)

        # Prioritize likely source trees; sort deterministically
        def score(path: str) -> Tuple[int, str]:
            head = path.split("/", 1)[0]
            score_dir = 0
            if head in LIKELY_TOP_DIRS:
                score_dir = -1
            return (score_dir, path)

        unref_candidates = sorted(set(unref_candidates), key=score)
        return unref_candidates


# -------------------------------
# Markdown Report Generator
# -------------------------------

def generate_markdown(result: AuditorResult) -> str:
    md = io.StringIO()
    print("# Agent OS Repository Audit Report", file=md)
    print("", file=md)
    print(f"- Root: `{result.root}`", file=md)
    print(f"- Files scanned: `{result.files_scanned}`", file=md)
    print(f"- Python files scanned: `{result.py_files_scanned}`", file=md)
    print(f"- Duplicate groups: `{len(result.duplicates)}`", file=md)
    print(f"- Broken imports (best-effort): `{len(result.broken_imports)}`", file=md)
    print(f"- Potentially unreferenced files: `{len(result.unreferenced_candidates)}`", file=md)
    print("", file=md)

    # Duplicates
    print("## Duplicate Files (by SHA-256)", file=md)
    if not result.duplicates:
        print("_No duplicates detected_", file=md)
    else:
        for dup in result.duplicates:
            print(f"- Hash: `{dup.hash}`", file=md)
            for f in dup.files:
                print(f"  - {f}", file=md)
    print("", file=md)

    # Broken imports
    print("## Broken Python Imports (best-effort)", file=md)
    if not result.broken_imports:
        print("_No broken imports detected_", file=md)
    else:
        for bi in result.broken_imports:
            loc = f"{bi.file}:{bi.line}" if bi.line else bi.file
            print(f"- {loc} → `{bi.import_name}`", file=md)
    print("", file=md)

    # Unreferenced
    print("## Potentially Unreferenced Files (heuristic)", file=md)
    if not result.unreferenced_candidates:
        print("_No unreferenced candidates detected_", file=md)
    else:
        for f in result.unreferenced_candidates:
            print(f"- {f}", file=md)
    print("", file=md)

    print("> Note: Import resolution and unreferenced detection are heuristic. Review before taking action.", file=md)
    return md.getvalue()


# -------------------------------
# Main
# -------------------------------

def main(argv: Optional[List[str]] = None) -> int:
    global MAX_READ_BYTES
    parser = argparse.ArgumentParser(description="Agent OS repository auditor")
    parser.add_argument("--root", type=str, default=None, help="Repository root (default: repo root)")
    parser.add_argument("--json", dest="json_out", type=str, default="tmp/cleanup_inventory.json", help="JSON output path")
    parser.add_argument("--md", dest="md_out", type=str, default="tmp/cleanup_report.md", help="Markdown output path")
    parser.add_argument("--exclude", action="append", default=[], help="Exclude directory or name (can repeat)")
    parser.add_argument("--max-bytes", type=int, default=MAX_READ_BYTES, help="Max bytes to read from files")
    args = parser.parse_args(argv)

    # Determine root
    if args.root:
        root = Path(args.root).resolve()
    else:
        # Assume tools/repo-auditor.py location within repo
        here = Path(__file__).resolve()
        # Repo root is two levels up (tools/ is under repo root)
        root = here.parent.parent.resolve()
        # Fallback: if VERSION exists above, prefer that
        if not (root / "VERSION").exists():
            # Try current working directory
            cwd = Path.cwd().resolve()
            if (cwd / "VERSION").exists():
                root = cwd

    if not root.exists():
        print(f"[repo-auditor] Root does not exist: {root}", file=sys.stderr)
        return 2

    # Configure global read cap
    MAX_READ_BYTES = max(1024, int(args.max_bytes))

    excludes = DEFAULT_EXCLUDES.union(set(args.exclude))

    scanner = RepoScanner(root, excludes)
    files = list(scanner.iter_files())
    py_files = [p for p in files if p.suffix == ".py"]

    # Duplicates
    dd = DuplicateDetector()
    for f in files:
        dd.add(f)
    duplicates = dd.get_duplicates(root)

    # Broken imports
    pia = PythonImportAnalyzer(root)
    broken_imports = pia.find_broken_imports(py_files)

    # Unreferenced
    ud = UnreferencedDetector(root, excludes)
    unref_candidates = ud.find_unreferenced(files)

    result = AuditorResult(
        root=str(root),
        files_scanned=len(files),
        py_files_scanned=len(py_files),
        duplicates=duplicates,
        broken_imports=broken_imports,
        unreferenced_candidates=unref_candidates
    )

    # Ensure tmp output directory
    json_out = Path(args.json_out)
    md_out = Path(args.md_out)
    for out in [json_out, md_out]:
        out.parent.mkdir(parents=True, exist_ok=True)

    # Serialize JSON
    def encode(obj):
        if isinstance(obj, AuditorResult):
            d = asdict(obj)
            # Convert nested dataclasses in lists
            d["duplicates"] = [asdict(x) for x in obj.duplicates]
            d["broken_imports"] = [asdict(x) for x in obj.broken_imports]
            return d
        return obj

    with open(json_out, "w", encoding="utf-8") as f:
        json.dump(encode(result), f, indent=2)

    # Write Markdown
    md_report = generate_markdown(result)
    with open(md_out, "w", encoding="utf-8") as f:
        f.write(md_report)

    # Print brief summary
    print("Agent OS Repository Audit Summary")
    print("---------------------------------")
    print(f"Root: {result.root}")
    print(f"Files scanned: {result.files_scanned} (Python: {result.py_files_scanned})")
    print(f"Duplicate groups: {len(result.duplicates)}")
    print(f"Broken imports (best-effort): {len(result.broken_imports)}")
    print(f"Potentially unreferenced files: {len(result.unreferenced_candidates)}")
    print(f"JSON report: {json_out}")
    print(f"Markdown report: {md_out}")

    return 0


if __name__ == "__main__":
    sys.exit(main())