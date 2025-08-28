#!/bin/bash
# Agent OS Documentation Updater (discovery-first; evidence-only)
# Detects documentation drift and provides actionable recommendations

set -euo pipefail

# Source the enhanced library if available
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
if [[ -f "$SCRIPT_DIR/lib/update-documentation-lib.sh" ]]; then
    source "$SCRIPT_DIR/lib/update-documentation-lib.sh"
fi

# Parse command line arguments
MODE="dry-run"
CREATE_MISSING=0
DEEP=0
UPDATE_CHANGELOG=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) MODE="dry-run" ;;
    --diff-only) MODE="diff-only" ;;
    --create-missing) CREATE_MISSING=1 ;;
    --deep) DEEP=1 ;;
    --update-changelog) UPDATE_CHANGELOG=1 ;;
    --changelog-only) UPDATE_CHANGELOG=1; MODE="changelog-only" ;;
  esac
done

# Navigate to repository root
repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$repo_root"

# Get changed files
changed=$(git diff --name-only HEAD 2>/dev/null || true)

echo "# Discovery"
if [[ -z "$changed" ]]; then
  echo "No changes detected."
  exit 0
fi
echo "$changed" | sed 's/^/- /'

# If diff-only mode, skip all checks and just show diff
if [[ "$MODE" == "diff-only" ]]; then
  echo ""
  echo "# Git Diff Statistics"
  git --no-pager diff --stat HEAD
  exit 0
fi

# Function to check if CHANGELOG has recent entries (last 30 days)
check_changelog_recent() {
  if [[ ! -f CHANGELOG.md ]]; then
    return 1
  fi
  
  # Check for dates within last 30 days
  local thirty_days_ago=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d 2>/dev/null || echo "2024-01-01")
  if grep -E "^## [0-9]{4}-[0-9]{2}-[0-9]{2}" CHANGELOG.md | head -5 | grep -qE "$(date +%Y-%m)" ; then
    return 0
  fi
  return 1
}

# Function to check for open issues without specs
check_issues_without_specs() {
  local issues_without_specs=()
  
  # Check if gh CLI is available
  if ! command -v gh &> /dev/null; then
    return 0
  fi
  
  # Get open issues
  local open_issues=$(gh issue list --state open --json number,title 2>/dev/null || echo "[]")
  
  if [[ "$open_issues" != "[]" ]]; then
    # Parse issue numbers using jq if available, otherwise basic parsing
    if command -v jq &> /dev/null; then
      while IFS= read -r issue_num; do
        if [[ ! -d ".agent-os/specs/"*"-#${issue_num}" ]]; then
          issues_without_specs+=("$issue_num")
        fi
      done < <(echo "$open_issues" | jq -r '.[].number')
    fi
  fi
  
  if [[ ${#issues_without_specs[@]} -gt 0 ]]; then
    echo "## Issues without specs:"
    printf -- '- Issue #%s\n' "${issues_without_specs[@]}"
  fi
  return 0
}

# Function to check for recent PRs in CHANGELOG
check_recent_prs() {
  if ! command -v gh &> /dev/null; then
    return 0
  fi
  
  local recent_prs=$(gh pr list --state merged --limit 5 --json number,title,mergedAt 2>/dev/null || echo "[]")
  
  if [[ "$recent_prs" != "[]" && -f CHANGELOG.md ]]; then
    if command -v jq &> /dev/null; then
      local undocumented_prs=()
      while IFS= read -r pr_num; do
        if ! grep -q "#${pr_num}" CHANGELOG.md 2>/dev/null; then
          undocumented_prs+=("$pr_num")
        fi
      done < <(echo "$recent_prs" | jq -r '.[].number')
      
      if [[ ${#undocumented_prs[@]} -gt 0 ]]; then
        echo "## Recent PRs not in CHANGELOG:"
        printf -- '- PR #%s\n' "${undocumented_prs[@]}"
      fi
    fi
  fi
  return 0
}

# Deep mode: Comprehensive documentation audit
if [[ $DEEP -eq 1 ]]; then
  echo ""
  echo "# Deep Documentation Audit"
  
  # Check core Agent OS documentation files
  echo ""
  echo "## Core Documentation Status"
  core_files=(
    "README.md"
    "CHANGELOG.md"
    "CLAUDE.md"
    ".agent-os/product/mission.md"
    ".agent-os/product/roadmap.md"
    ".agent-os/product/tech-stack.md"
    ".agent-os/product/decisions.md"
  )
  
  missing_core=()
  for file in "${core_files[@]}"; do
    if [[ -f "$file" ]]; then
      echo "✓ $file exists"
    else
      echo "✗ $file MISSING"
      missing_core+=("$file")
    fi
  done
  
  # Check for broken file references
  echo ""
  echo "## File Reference Validation"
  broken_refs=()
  
  # Find all @-prefixed file references in documentation
  for doc_file in $(find . -name "*.md" -type f 2>/dev/null | grep -v node_modules | grep -v .git); do
    # Extract @-prefixed paths
    refs=$(grep -oE '@[./][^[:space:]]+\.md' "$doc_file" 2>/dev/null || true)
    if [[ -n "$refs" ]]; then
      while IFS= read -r ref; do
        # Remove @ prefix and check if file exists
        ref_path="${ref#@}"
        if [[ ! -f "$ref_path" ]]; then
          broken_refs+=("$doc_file references missing file: $ref_path")
        fi
      done <<< "$refs"
    fi
  done
  
  if [[ ${#broken_refs[@]} -gt 0 ]]; then
    echo "Found broken references:"
    printf -- '%s\n' "${broken_refs[@]}" | sed 's/^/- /'
  else
    echo "All file references valid"
  fi
  
  # Cross-reference specs with issues
  echo ""
  echo "## Spec-Issue Cross-Reference"
  if [[ -d ".agent-os/specs" ]]; then
    for spec_dir in .agent-os/specs/*/; do
      if [[ -d "$spec_dir" ]]; then
        spec_name=$(basename "$spec_dir")
        # Extract issue number from spec folder name
        if [[ "$spec_name" =~ \#([0-9]+) ]]; then
          issue_num="${BASH_REMATCH[1]}"
          if command -v gh &> /dev/null; then
            if gh issue view "$issue_num" &>/dev/null; then
              echo "✓ Spec $spec_name corresponds to issue #$issue_num"
            else
              echo "✗ Spec $spec_name references non-existent issue #$issue_num"
            fi
          fi
        fi
      fi
    done
  fi
  
  # Check roadmap completion status
  echo ""
  echo "## Roadmap Status Check"
  if [[ -f ".agent-os/product/roadmap.md" ]]; then
    completed_items=$(grep -c '\[x\]' .agent-os/product/roadmap.md 2>/dev/null || echo "0")
    pending_items=$(grep -c '\[ \]' .agent-os/product/roadmap.md 2>/dev/null || echo "0")
    echo "Completed items: $completed_items"
    echo "Pending items: $pending_items"
  fi
  
  # Check for orphaned specs (specs without corresponding issues)
  echo ""
  echo "## Orphaned Specs Check"
  if [[ -d ".agent-os/specs" ]]; then
    for spec_dir in .agent-os/specs/*/; do
      if [[ -d "$spec_dir" ]]; then
        spec_name=$(basename "$spec_dir")
        if ! [[ "$spec_name" =~ \#[0-9]+ ]]; then
          echo "⚠ Spec $spec_name does not reference an issue number"
        fi
      fi
    done
  fi
fi

# Normal mode: Quick documentation health check
needs_changelog=0
needs_readme=0
needs_product=0
needs_docs=0

# Check if code changes require CHANGELOG update
if echo "$changed" | grep -qE "^(scripts/|tools/|setup\.sh|setup-claude-code\.sh|setup-cursor\.sh|hooks/|instructions/|workflow-modules/)" ; then
  needs_changelog=1
fi

# Check if any non-doc change should update CHANGELOG
if echo "$changed" | grep -vqE "^(docs/|\.agent-os/product/|\.github/|CHANGELOG\.md$|README\.md$|CLAUDE\.md$)" ; then
  needs_changelog=1
fi

# Check if README needs update
if echo "$changed" | grep -qE "^(tools/|setup\.sh|commands/)" ; then
  needs_readme=1
fi

# Check if documentation needs update
if echo "$changed" | grep -qE "^(instructions/|workflow-modules/|hooks/)" ; then
  needs_docs=1
fi

# Check if product documentation needs update
if echo "$changed" | grep -qE "^(\.agent-os/product/|instructions/core/)" ; then
  needs_product=1
fi

echo ""
echo "# Proposed Documentation Updates"

proposals=()
[[ $needs_changelog -eq 1 ]] && proposals+=("CHANGELOG.md")
[[ $needs_readme -eq 1 ]] && proposals+=("README.md" "CLAUDE.md")
[[ $needs_docs -eq 1 ]] && proposals+=("docs/*")
[[ $needs_product -eq 1 ]] && proposals+=(".agent-os/product/{roadmap.md,decisions.md}")

# Additional checks in normal mode
if ! check_changelog_recent; then
  if [[ $needs_changelog -eq 0 ]]; then
    proposals+=("CHANGELOG.md (no recent entries)")
    needs_changelog=1
  fi
fi

check_issues_without_specs
check_recent_prs

if [[ ${#proposals[@]} -eq 0 ]]; then
  echo "No documentation changes required."
  exit 0
fi

printf -- '%s\n' "${proposals[@]}" | sort -u | sed 's/^/- /'

# Check for missing required documentation
missing=()
for target in CHANGELOG.md README.md CLAUDE.md \
              .agent-os/product/roadmap.md .agent-os/product/decisions.md; do
  if printf -- '%s\n' "${proposals[@]}" | grep -q "$target"; then
    [[ ! -f "$target" ]] && missing+=("$target")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo ""
  echo "# Missing Required Documentation"
  printf -- '%s\n' "${missing[@]}" | sed 's/^/- /'
  
  if [[ $CREATE_MISSING -eq 1 && "$MODE" != "diff-only" ]]; then
    echo ""
    echo "# Creating minimal scaffolds (References only)"
    for f in "${missing[@]}"; do
      mkdir -p "$(dirname "$f")"
      {
        echo "# $(basename "$f" .md | tr '-' ' ' | sed 's/.*/\u&/')"
        echo ""
        echo "## References"
        echo "- Created by: update-documentation.sh"
        echo "- Date: $(date +%Y-%m-%d)"
        echo "- Diff: \`git diff --name-only HEAD\`"
        echo ""
        echo "## Content"
        echo "<!-- Add documentation content here -->"
      } > "$f"
      echo "Created $f"
    done
  else
    # Exit with error if required documentation is missing
    if printf -- '%s\n' "${missing[@]}" | grep -q '^CHANGELOG.md$'; then
      echo ""
      echo "ERROR: CHANGELOG.md is required for documenting changes."
      exit 2
    fi
  fi
fi

# Handle different modes
if [[ "$MODE" == "dry-run" ]]; then
  # Exit with error code if documentation updates are needed
  if [[ ${#proposals[@]} -gt 0 ]]; then 
    echo ""
    echo "Documentation updates required. Run without --dry-run to see details."
    exit 2
  fi
  exit 0
fi

exit 0