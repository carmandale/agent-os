#!/bin/bash
# Agent OS Documentation Updater (discovery-first; evidence-only)

set -euo pipefail

MODE="dry-run"
CREATE_MISSING=0
DEEP=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) MODE="dry-run" ;;
    --diff-only) MODE="diff-only" ;;
    --create-missing) CREATE_MISSING=1 ;;
    --deep) DEEP=1 ;;
  esac
done

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$repo_root"

changed=$(git diff --name-only HEAD 2>/dev/null || true)

echo "# Discovery"
if [[ -z "$changed" ]]; then
  echo "No changes detected."
  exit 0
fi
echo "$changed" | sed 's/^/- /'

# Optional deep evidence-first audit
if [[ $DEEP -eq 1 ]]; then
  echo ""
  echo "# Deep Evidence Audit (Dev/Test/Prod)"
  evidence_files=(
    "backend/app/config.py"
    "backend/app/database.py"
    "alembic/env.py" "alembic/versions" "migrations" "migrations/versions"
    "docker-compose.yml" "docker-compose.yaml" "Dockerfile" "Dockerfile.prod"
    "render.yaml" "vercel.json" "nixpacks.toml" "Procfile"
    ".env.example" ".env" "start.sh" "start-production.sh"
    "docs/POSTGRES_SETUP.md" "README.md" "CLAUDE.md"
  )
  POSTGRES_HITS=0; SQLITE_HITS=0
  for f in "${evidence_files[@]}"; do
    if [[ -f "$f" ]]; then
      # Show limited excerpts with line numbers for postgres/sqlite
      pg=$(grep -nEi "postgres|psycopg|DATABASE_URL.*postgres" "$f" 2>/dev/null | head -5 || true)
      sq=$(grep -nEi "sqlite|\.db\b|sqlite3" "$f" 2>/dev/null | head -5 || true)
      if [[ -n "$pg" ]]; then
        POSTGRES_HITS=$((POSTGRES_HITS+1))
        echo "\n- $f (postgres-related):"; echo "$pg" | sed 's/^/  /'
      fi
      if [[ -n "$sq" ]]; then
        SQLITE_HITS=$((SQLITE_HITS+1))
        echo "\n- $f (sqlite-related):"; echo "$sq" | sed 's/^/  /'
      fi
    fi
  done
  echo "\nSummary: postgres-signals=$POSTGRES_HITS, sqlite-signals=$SQLITE_HITS"
fi

needs_changelog=0; needs_readme=0; needs_product=0; needs_docs=0
# Heuristic 1: core Agent OS files likely require CHANGELOG
echo "$changed" | grep -qE "^(scripts/|tools/|setup\.sh|setup-claude-code\.sh|setup-cursor\.sh|hooks/|instructions/|workflow-modules/)" && needs_changelog=1
# Heuristic 2: any non-doc change anywhere should update CHANGELOG (generalize for other repos)
if echo "$changed" | grep -vqE "^(docs/|\.agent-os/product/|\.github/|CHANGELOG\.md$)"; then
  needs_changelog=1
fi
echo "$changed" | grep -qE "^(tools/|setup\.sh|README\.md|CLAUDE\.md)" && needs_readme=1
echo "$changed" | grep -qE "^(instructions/|workflow-modules/)" && needs_docs=1
echo "$changed" | grep -qE "^(\.agent-os/product/|instructions/core/execute-tasks\.md|instructions/core/execute-task\.md)" && needs_product=1

echo ""
echo "# Proposed Documentation Updates"

proposals=()
[[ $needs_changelog -eq 1 ]] && proposals+=("CHANGELOG.md")
[[ $needs_readme -eq 1 ]] && proposals+=("README.md" "CLAUDE.md")
[[ $needs_docs -eq 1 ]] && proposals+=("docs/*")
[[ $needs_product -eq 1 ]] && proposals+=(".agent-os/product/{roadmap.md,decisions.md}")

if [[ ${#proposals[@]} -eq 0 ]]; then
  echo "No documentation changes required by heuristics."
  exit 0
fi

printf '%s\n' "${proposals[@]}" | sed 's/^/- /'

missing=()
for target in CHANGELOG.md README.md CLAUDE.md \
              .agent-os/product/roadmap.md .agent-os/product/decisions.md; do
  if printf '%s\n' "${proposals[@]}" | grep -q "$target"; then
    [[ ! -f "$target" ]] && missing+=("$target")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo ""
  echo "# Missing Required Docs"
  printf '%s\n' "${missing[@]}" | sed 's/^/- /'
  if [[ $CREATE_MISSING -eq 1 && "$MODE" != "diff-only" ]]; then
    echo ""
    echo "# Creating minimal scaffolds (References only)"
    for f in "${missing[@]}"; do
      mkdir -p "$(dirname "$f")"
      {
        echo "# $(basename "$f" .md | tr '-' ' ' | sed 's/.*/\u&/')"
        echo ""
        echo "## References"
        echo "- Diff: see 'git diff --name-only HEAD'"
      } > "$f"
      echo "Created $f"
    done
  else
    # Enforce CHANGELOG presence when changes require it
    if printf '%s\n' "${missing[@]}" | grep -q '^CHANGELOG.md$'; then
      echo "CHANGELOG.md is required for documenting changes."
      exit 2
    fi
  fi
fi

if [[ "$MODE" == "dry-run" ]]; then
  # Fail (exit 2) if proposals exist or deep audit found contradictions
  if [[ ${#proposals[@]} -gt 0 ]]; then exit 2; fi
  if [[ $DEEP -eq 1 ]]; then
    # If deep scan suggests sqlite text present alongside postgres signals, flag proposals
    if [[ $POSTGRES_HITS -gt 0 && $SQLITE_HITS -gt 0 ]]; then
      echo "\nDeep audit detected possible doc/config mismatch (postgres + sqlite signals)."
      exit 2
    fi
  fi
  exit 0
fi

if [[ "$MODE" == "diff-only" ]]; then
  git --no-pager diff --stat
  exit 0
fi

exit 0

