#!/usr/bin/env bash
# repo-cleanup-validate.sh
# Aggregate validation for Agent OS repository cleanup
#
# This script runs:
#  1) tools/context-integration.sh validate
#  2) tools/validate-references.sh --summary
#  3) tools/context-validator.sh
#  4) python3 tools/repo-auditor.py --json tmp/cleanup_inventory.json --md tmp/cleanup_report.md
#
# It summarizes the results and exits non-zero if any step fails.
#
# Usage:
#   ./scripts/repo-cleanup-validate.sh
#   ./scripts/repo-cleanup-validate.sh --no-audit   # Skip repo-auditor.py
#   ./scripts/repo-cleanup-validate.sh --continue-on-error  # Do not stop on first failure

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
  local level="$1"; shift
  local msg="$*"
  case "$level" in
    info)    echo -e "${BLUE}ℹ️  $msg${NC}" ;;
    success) echo -e "${GREEN}✅ $msg${NC}" ;;
    warn)    echo -e "${YELLOW}⚠️  $msg${NC}" ;;
    error)   echo -e "${RED}❌ $msg${NC}" ;;
    header)  echo -e "${PURPLE}$msg${NC}" ;;
    section) echo -e "${CYAN}$msg${NC}" ;;
    *)       echo "$msg" ;;
  esac
}

# Options
SKIP_AUDIT=false
CONTINUE_ON_ERROR=false
for arg in "$@"; do
  case "$arg" in
    --no-audit) SKIP_AUDIT=true ;;
    --continue-on-error) CONTINUE_ON_ERROR=true ;;
    -h|--help)
      cat <<EOF
Agent OS Repo Cleanup Validation

Usage:
  $0 [--no-audit] [--continue-on-error]

Options:
  --no-audit            Skip repo-auditor.py step
  --continue-on-error   Do not stop on first failure; report all results
  -h, --help            Show this help

EOF
      exit 0
      ;;
    *) print_status warn "Unknown option: $arg" ;;
  esac
done

# Ensure we run from repo root (detect VERSION and tools/)
if [[ ! -f "VERSION" || ! -d "tools" ]]; then
  print_status info "Not in repo root; attempting to change directory to script root"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
  cd "$REPO_ROOT"
fi

if [[ ! -f "VERSION" || ! -d "tools" ]]; then
  print_status error "Please run this script from the repository root"
  exit 2
fi

# Check required tools
missing=0
if ! command -v bash >/dev/null 2>&1; then print_status error "bash not found in PATH"; missing=$((missing+1)); fi
if ! command -v python3 >/dev/null 2>&1; then
  if [[ "$SKIP_AUDIT" != "true" ]]; then
    print_status warn "python3 not found; repo-auditor will be skipped"
    SKIP_AUDIT=true
  fi
fi

for script in "tools/context-integration.sh" "tools/validate-references.sh" "tools/context-validator.sh"; do
  if [[ ! -f "$script" ]]; then
    print_status error "Required tool missing: $script"
    missing=$((missing+1))
  fi
done

if [[ $missing -gt 0 ]]; then
  exit 3
fi

# Prepare tmp outputs
mkdir -p tmp
AUDIT_JSON="tmp/cleanup_inventory.json"
AUDIT_MD="tmp/cleanup_report.md"

# Track results
declare -A RESULTS
OVERALL_STATUS=0

run_step() {
  local key="$1"
  shift
  local cmd=("$@")
  print_status section "Running: ${cmd[*]}"
  if "${cmd[@]}"; then
    RESULTS["$key"]="0"
    print_status success "$key: OK"
  else
    RESULTS["$key"]="1"
    print_status error "$key: FAILED"
    if [[ "$CONTINUE_ON_ERROR" == "false" ]]; then
      print_status error "Stopping on first failure (use --continue-on-error to continue)"
      exit 1
    else
      OVERALL_STATUS=1
    fi
  fi
}

print_status header "🔧 Agent OS Repository Cleanup Validation"
echo "==============================================="
echo ""

# 1) Context integration validation (aggregates structure, references, analysis)
run_step "context-integration" bash tools/context-integration.sh validate

echo ""

# 2) Reference resolution (summary)
run_step "validate-references" bash tools/validate-references.sh --summary

echo ""

# 3) Context validator (source/install/project checks)
run_step "context-validator" bash tools/context-validator.sh

echo ""

# 4) Repo auditor (duplicates, broken imports, unreferenced files)
if [[ "$SKIP_AUDIT" == "true" ]]; then
  print_status warn "Skipping repo-auditor.py step (--no-audit)"
  RESULTS["repo-auditor"]="skipped"
else
  run_step "repo-auditor" python3 tools/repo-auditor.py --json "$AUDIT_JSON" --md "$AUDIT_MD"
fi

echo ""
print_status header "📋 Summary"
echo "-----------------------------------------------"
for key in "context-integration" "validate-references" "context-validator" "repo-auditor"; do
  status="${RESULTS[$key]:-skipped}"
  case "$status" in
    0) print_status success "• $key: OK" ;;
    1) print_status error   "• $key: FAILED" ;;
    skipped) print_status warn "• $key: SKIPPED" ;;
    *) print_status warn "• $key: $status" ;;
  esac
done

if [[ -f "$AUDIT_JSON" || -f "$AUDIT_MD" ]]; then
  echo ""
  print_status info "Artifacts:"
  [[ -f "$AUDIT_JSON" ]] && echo "  - JSON: $AUDIT_JSON"
  [[ -f "$AUDIT_MD"  ]] && echo "  - Report: $AUDIT_MD"
fi

echo ""
if [[ $OVERALL_STATUS -eq 0 ]]; then
  print_status success "Cleanup validation completed successfully"
else
  print_status error "Cleanup validation detected issues"
fi

exit $OVERALL_STATUS