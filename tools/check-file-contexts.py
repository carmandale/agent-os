#!/usr/bin/env python3
"""
check-file-contexts.py
Agent OS Context-Aware File Checker

Advanced Python-based analysis of Agent OS file contexts with detailed validation rules
and context drift detection capabilities.
"""

import os
import sys
import json
import re
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple, Any
from dataclasses import dataclass, asdict
from enum import Enum
import argparse


class ContextType(Enum):
    """Agent OS context types"""
    SOURCE = "source"
    INSTALL = "install" 
    PROJECT = "project"


class FileType(Enum):
    """Agent OS file types with different context rules"""
    STANDARD = "standard"          # standards/ files - customizable
    INSTRUCTION = "instruction"    # instructions/ files - updatable
    SCRIPT = "script"             # scripts/ files - always updated
    WORKFLOW = "workflow"         # workflow-modules/ files - always updated
    COMMAND = "command"           # commands/ files - source only
    AGENT = "agent"              # claude-code/agents/ files - source only
    HOOK = "hook"                # hooks/ files - source only
    TOOL = "tool"                # tools/ files - source and install
    TEST = "test"                # tests/ files - source only
    SPEC = "spec"                # specs/ files - project only
    PRODUCT = "product"          # product/ files - project only
    CONFIG = "config"            # setup and config files
    DOCS = "docs"                # documentation files


@dataclass
class FileInfo:
    """Information about a file in Agent OS context"""
    path: Path
    relative_path: str
    context: ContextType
    file_type: FileType
    is_executable: bool
    size: int
    references: List[str]
    referenced_by: List[str]


@dataclass
class ContextValidationResult:
    """Result of context validation"""
    is_valid: bool
    violations: List[str]
    warnings: List[str]
    file_count: int
    reference_count: int
    context_map: Dict[str, FileInfo]


class AgentOSContextChecker:
    """Advanced context validation for Agent OS"""
    
    def __init__(self):
        self.source_context = self._get_source_context()
        self.install_context = self._get_install_context()
        self.project_context = self._get_project_context()
        
        # File type patterns
        self.file_type_patterns = {
            FileType.STANDARD: [r"^standards/.*\.md$"],
            FileType.INSTRUCTION: [r"^instructions/.*\.md$"],
            FileType.SCRIPT: [r"^scripts/.*\.(sh|py)$"],
            FileType.WORKFLOW: [r"^workflow-modules/.*\.md$"],
            FileType.COMMAND: [r"^commands/.*\.md$"],
            FileType.AGENT: [r"^claude-code/agents/.*\.md$"],
            FileType.HOOK: [r"^hooks/.*\.(sh|py|json)$", r"^hooks/lib/.*\.(sh|py)$"],
            FileType.TOOL: [r"^tools/.*$"],
            FileType.TEST: [r"^tests/.*\.(bats|sh|py)$"],
            FileType.SPEC: [r"^specs/.*\.md$"],
            FileType.PRODUCT: [r"^product/.*\.md$"],
            FileType.CONFIG: [r"^(setup.*\.sh|VERSION|.*\.json|.*\.yaml|.*\.toml)$"],
            FileType.DOCS: [r"^(README\.md|CHANGELOG\.md|.*\.md)$"],
        }
        
        # Context rules - where each file type is allowed
        self.context_rules = {
            FileType.STANDARD: {ContextType.SOURCE, ContextType.INSTALL, ContextType.PROJECT},
            FileType.INSTRUCTION: {ContextType.SOURCE, ContextType.INSTALL, ContextType.PROJECT},
            FileType.SCRIPT: {ContextType.SOURCE, ContextType.INSTALL},
            FileType.WORKFLOW: {ContextType.SOURCE, ContextType.INSTALL},
            FileType.COMMAND: {ContextType.SOURCE},
            FileType.AGENT: {ContextType.SOURCE},
            FileType.HOOK: {ContextType.SOURCE, ContextType.INSTALL},
            FileType.TOOL: {ContextType.SOURCE, ContextType.INSTALL},
            FileType.TEST: {ContextType.SOURCE},
            FileType.SPEC: {ContextType.PROJECT},
            FileType.PRODUCT: {ContextType.PROJECT},
            FileType.CONFIG: {ContextType.SOURCE, ContextType.INSTALL},
            FileType.DOCS: {ContextType.SOURCE, ContextType.PROJECT},
        }
        
        # Reference patterns
        self.reference_patterns = [
            r"@~/.agent-os/([^)\s]+)",      # Install context references
            r"@\.agent-os/([^)\s]+)",       # Project context references
            r"!~/.agent-os/scripts/([^)\s]+)",  # Script execution references
        ]

    def _get_source_context(self) -> Optional[Path]:
        """Get source context path"""
        script_dir = Path(__file__).parent
        return script_dir.parent.resolve()

    def _get_install_context(self) -> Optional[Path]:
        """Get install context path"""
        install_path = Path.home() / ".agent-os"
        return install_path if install_path.exists() else None

    def _get_project_context(self) -> Optional[Path]:
        """Get project context path by walking up directory tree"""
        current = Path.cwd()
        while current != current.parent:
            agent_os_dir = current / ".agent-os"
            if agent_os_dir.is_dir():
                return agent_os_dir
            current = current.parent
        return None

    def _classify_file(self, file_path: Path, context: ContextType) -> FileType:
        """Classify a file based on its path and context"""
        # Get relative path from context root
        if context == ContextType.SOURCE:
            relative_path = str(file_path.relative_to(self.source_context))
        elif context == ContextType.INSTALL:
            relative_path = str(file_path.relative_to(self.install_context))
        elif context == ContextType.PROJECT:
            relative_path = str(file_path.relative_to(self.project_context))
        else:
            relative_path = str(file_path)
        
        # Match against patterns
        for file_type, patterns in self.file_type_patterns.items():
            for pattern in patterns:
                if re.match(pattern, relative_path):
                    return file_type
        
        return FileType.DOCS  # Default fallback

    def _find_references(self, file_path: Path) -> List[str]:
        """Find Agent OS references in a file"""
        if not file_path.suffix.lower() in {'.md', '.sh', '.py'}:
            return []
        
        try:
            content = file_path.read_text(encoding='utf-8')
        except (UnicodeDecodeError, PermissionError):
            return []
        
        references = []
        for pattern in self.reference_patterns:
            matches = re.findall(pattern, content)
            for match in matches:
                if pattern.startswith("@~/.agent-os/"):
                    references.append(f"@~/.agent-os/{match}")
                elif pattern.startswith(r"@\.agent-os/"):
                    references.append(f"@.agent-os/{match}")
                elif pattern.startswith("!~/.agent-os/scripts/"):
                    references.append(f"!~/.agent-os/scripts/{match}")
        
        return references

    def _scan_context(self, context_path: Path, context_type: ContextType) -> Dict[str, FileInfo]:
        """Scan a context directory and catalog all files"""
        context_map = {}
        
        if not context_path or not context_path.exists():
            return context_map
        
        # Walk all files in context
        for file_path in context_path.rglob("*"):
            if not file_path.is_file():
                continue
            
            # Skip hidden files and common ignore patterns
            if any(part.startswith('.') for part in file_path.parts):
                continue
            
            try:
                relative_path = str(file_path.relative_to(context_path))
                file_type = self._classify_file(file_path, context_type)
                references = self._find_references(file_path)
                
                file_info = FileInfo(
                    path=file_path,
                    relative_path=relative_path,
                    context=context_type,
                    file_type=file_type,
                    is_executable=os.access(file_path, os.X_OK),
                    size=file_path.stat().st_size,
                    references=references,
                    referenced_by=[]  # Will be populated later
                )
                
                context_map[relative_path] = file_info
                
            except (PermissionError, OSError):
                continue
        
        return context_map

    def _validate_context_rules(self, context_map: Dict[str, FileInfo]) -> Tuple[List[str], List[str]]:
        """Validate that files are in correct contexts according to rules"""
        violations = []
        warnings = []
        
        for relative_path, file_info in context_map.items():
            allowed_contexts = self.context_rules.get(file_info.file_type, set())
            
            if file_info.context not in allowed_contexts:
                violations.append(
                    f"Context violation: {file_info.file_type.value} file '{relative_path}' "
                    f"found in {file_info.context.value} context, "
                    f"allowed contexts: {[c.value for c in allowed_contexts]}"
                )
            
            # Special validations for executable files
            if file_info.file_type == FileType.SCRIPT and not file_info.is_executable:
                warnings.append(f"Script file not executable: {relative_path}")
            
            # Check for suspicious file locations
            if file_info.file_type == FileType.TEST and file_info.context != ContextType.SOURCE:
                violations.append(f"Test files should only exist in source context: {relative_path}")
            
            if file_info.file_type == FileType.SPEC and file_info.context != ContextType.PROJECT:
                violations.append(f"Spec files should only exist in project context: {relative_path}")

        return violations, warnings

    def _validate_references(self, context_map: Dict[str, FileInfo]) -> Tuple[List[str], List[str]]:
        """Validate that all references resolve correctly"""
        violations = []
        warnings = []
        
        for relative_path, file_info in context_map.items():
            for reference in file_info.references:
                resolved = self._resolve_reference(reference)
                if not resolved:
                    violations.append(f"Broken reference: {reference} in {relative_path}")
                else:
                    # Track reverse references
                    if resolved in context_map:
                        context_map[resolved].referenced_by.append(relative_path)
        
        return violations, warnings

    def _resolve_reference(self, reference: str) -> Optional[str]:
        """Resolve a reference to actual file path"""
        if reference.startswith("@~/.agent-os/"):
            # Install context reference
            if not self.install_context:
                return None
            ref_path = reference[len("@~/.agent-os/"):]
            full_path = self.install_context / ref_path
            return ref_path if full_path.exists() else None
        
        elif reference.startswith("@.agent-os/"):
            # Project context reference with fallback
            ref_path = reference[len("@.agent-os/"):]
            
            # Try project context first
            if self.project_context:
                full_path = self.project_context / ref_path
                if full_path.exists():
                    return ref_path
            
            # Fall back to install context
            if self.install_context:
                full_path = self.install_context / ref_path
                if full_path.exists():
                    return ref_path
            
            return None
        
        elif reference.startswith("!~/.agent-os/scripts/"):
            # Script execution reference
            if not self.install_context:
                return None
            ref_path = reference[len("!~/.agent-os/"):]
            full_path = self.install_context / ref_path
            return ref_path if (full_path.exists() and os.access(full_path, os.X_OK)) else None
        
        return None

    def validate_all_contexts(self) -> ContextValidationResult:
        """Validate all available contexts"""
        all_context_maps = {}
        all_violations = []
        all_warnings = []
        total_files = 0
        total_references = 0
        
        # Scan all contexts
        contexts_to_scan = [
            (self.source_context, ContextType.SOURCE),
            (self.install_context, ContextType.INSTALL),
            (self.project_context, ContextType.PROJECT),
        ]
        
        for context_path, context_type in contexts_to_scan:
            if context_path and context_path.exists():
                context_map = self._scan_context(context_path, context_type)
                all_context_maps.update(context_map)
                total_files += len(context_map)
                total_references += sum(len(info.references) for info in context_map.values())
        
        # Validate context rules
        rule_violations, rule_warnings = self._validate_context_rules(all_context_maps)
        all_violations.extend(rule_violations)
        all_warnings.extend(rule_warnings)
        
        # Validate references
        ref_violations, ref_warnings = self._validate_references(all_context_maps)
        all_violations.extend(ref_violations)
        all_warnings.extend(ref_warnings)
        
        return ContextValidationResult(
            is_valid=len(all_violations) == 0,
            violations=all_violations,
            warnings=all_warnings,
            file_count=total_files,
            reference_count=total_references,
            context_map=all_context_maps
        )

    def detect_context_drift(self) -> Dict[str, List[str]]:
        """Detect files that may have drifted to wrong contexts"""
        drift_issues = {
            "duplicated_files": [],
            "outdated_install_files": [],
            "missing_project_overrides": [],
            "source_only_in_install": [],
        }
        
        if not (self.source_context and self.install_context):
            return drift_issues
        
        source_map = self._scan_context(self.source_context, ContextType.SOURCE)
        install_map = self._scan_context(self.install_context, ContextType.INSTALL)
        
        # Check for files that should be updated
        for rel_path, source_info in source_map.items():
            if rel_path in install_map:
                install_info = install_map[rel_path]
                
                # Check if install file is newer (potential drift)
                source_mtime = source_info.path.stat().st_mtime
                install_mtime = install_info.path.stat().st_mtime
                
                if install_mtime > source_mtime and source_info.file_type in {
                    FileType.SCRIPT, FileType.WORKFLOW, FileType.TOOL
                }:
                    drift_issues["outdated_install_files"].append(rel_path)
        
        # Check for source-only files in install context
        for rel_path, install_info in install_map.items():
            if install_info.file_type in {FileType.COMMAND, FileType.AGENT, FileType.TEST}:
                drift_issues["source_only_in_install"].append(rel_path)
        
        return drift_issues

    def generate_report(self, result: ContextValidationResult, 
                       output_format: str = "text") -> str:
        """Generate validation report in specified format"""
        if output_format == "json":
            return self._generate_json_report(result)
        else:
            return self._generate_text_report(result)

    def _generate_text_report(self, result: ContextValidationResult) -> str:
        """Generate human-readable text report"""
        report = []
        report.append("🔍 Agent OS Context Validation Report")
        report.append("=" * 40)
        report.append("")
        
        # Summary
        report.append(f"📊 Summary")
        report.append(f"  Total Files: {result.file_count}")
        report.append(f"  Total References: {result.reference_count}")
        report.append(f"  Violations: {len(result.violations)}")
        report.append(f"  Warnings: {len(result.warnings)}")
        report.append(f"  Status: {'✅ VALID' if result.is_valid else '❌ INVALID'}")
        report.append("")
        
        # Context breakdown
        context_stats = {}
        for file_info in result.context_map.values():
            ctx = file_info.context.value
            context_stats[ctx] = context_stats.get(ctx, 0) + 1
        
        report.append("📂 Context Distribution")
        for context, count in context_stats.items():
            report.append(f"  {context.title()}: {count} files")
        report.append("")
        
        # File type breakdown
        type_stats = {}
        for file_info in result.context_map.values():
            ftype = file_info.file_type.value
            type_stats[ftype] = type_stats.get(ftype, 0) + 1
        
        report.append("📄 File Type Distribution")
        for file_type, count in sorted(type_stats.items()):
            report.append(f"  {file_type.title()}: {count} files")
        report.append("")
        
        # Violations
        if result.violations:
            report.append("❌ Context Violations")
            for violation in result.violations:
                report.append(f"  • {violation}")
            report.append("")
        
        # Warnings
        if result.warnings:
            report.append("⚠️  Warnings")
            for warning in result.warnings:
                report.append(f"  • {warning}")
            report.append("")
        
        # Context drift detection
        drift_issues = self.detect_context_drift()
        if any(drift_issues.values()):
            report.append("🔄 Context Drift Detection")
            for issue_type, issues in drift_issues.items():
                if issues:
                    report.append(f"  {issue_type.replace('_', ' ').title()}: {len(issues)}")
                    for issue in issues[:5]:  # Show first 5
                        report.append(f"    - {issue}")
                    if len(issues) > 5:
                        report.append(f"    ... and {len(issues) - 5} more")
            report.append("")
        
        # Recommendations
        if result.violations or result.warnings:
            report.append("💡 Recommendations")
            if result.violations:
                report.append("  1. Fix context violations by moving files to correct locations")
                report.append("  2. Run context validation after making changes")
            if result.warnings:
                report.append("  3. Review warnings and address as needed")
                report.append("  4. Make script files executable where appropriate")
            report.append("  5. Use 'tools/context-validator.sh' for ongoing validation")
            report.append("")
        
        return "\n".join(report)

    def _generate_json_report(self, result: ContextValidationResult) -> str:
        """Generate JSON report for programmatic use"""
        # Convert dataclasses to dicts for JSON serialization
        context_map_serializable = {}
        for path, file_info in result.context_map.items():
            file_info_dict = asdict(file_info)
            file_info_dict['path'] = str(file_info_dict['path'])
            file_info_dict['context'] = file_info_dict['context'].value
            file_info_dict['file_type'] = file_info_dict['file_type'].value
            context_map_serializable[path] = file_info_dict
        
        report_data = {
            "is_valid": result.is_valid,
            "violations": result.violations,
            "warnings": result.warnings,
            "file_count": result.file_count,
            "reference_count": result.reference_count,
            "context_map": context_map_serializable,
            "drift_issues": self.detect_context_drift()
        }
        
        return json.dumps(report_data, indent=2)


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description="Agent OS Context-Aware File Checker",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                    # Validate all contexts
  %(prog)s --json             # Output JSON report
  %(prog)s --context source   # Check only source context
  %(prog)s --drift-only       # Check only for context drift
        """
    )
    
    parser.add_argument(
        "--context",
        choices=["source", "install", "project"],
        help="Validate specific context only"
    )
    
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output JSON report instead of text"
    )
    
    parser.add_argument(
        "--drift-only",
        action="store_true", 
        help="Check only for context drift issues"
    )
    
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Verbose output"
    )
    
    args = parser.parse_args()
    
    # Create checker instance
    checker = AgentOSContextChecker()
    
    if args.drift_only:
        # Only check for drift
        drift_issues = checker.detect_context_drift()
        if args.json:
            print(json.dumps(drift_issues, indent=2))
        else:
            print("🔄 Context Drift Detection")
            print("=" * 25)
            for issue_type, issues in drift_issues.items():
                if issues:
                    print(f"{issue_type.replace('_', ' ').title()}: {len(issues)}")
                    for issue in issues:
                        print(f"  - {issue}")
        return
    
    # Validate contexts
    result = checker.validate_all_contexts()
    
    # Generate and print report
    output_format = "json" if args.json else "text"
    report = checker.generate_report(result, output_format)
    print(report)
    
    # Exit with appropriate code
    sys.exit(0 if result.is_valid else 1)


if __name__ == "__main__":
    main()