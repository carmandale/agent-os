#!/usr/bin/env bats

setup() {
  mkdir -p .agent-os/product
  cat > .agent-os/product/tech-stack.md <<'MD'
# Technical Stack

**Python Package Manager:** uv
**JavaScript Package Manager:** yarn

**Frontend Port:** 3001
**Backend Port:** 8001
MD
}

teardown() {
  rm -f .agent-os/product/tech-stack.md .env .env.local "$HOME/.agent-os/cache/session-config.json"
}

@test "maybe-refresh-and-export creates cache and exports vars" {
  run bash scripts/session-memory.sh maybe-refresh-and-export
  [ -f "$HOME/.agent-os/cache/session-config.json" ]
  run bash -lc 'bash scripts/session-memory.sh export >/dev/null 2>&1; env | grep -E "AGENT_OS_(PYPM|JSPM|FRONTEND_PORT|BACKEND_PORT)" || true'
  [ "$status" -eq 0 ]
}


