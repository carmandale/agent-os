#!/usr/bin/env bats

setup() {
  mkdir -p .agent-os/product
  cat > .agent-os/product/tech-stack.md <<'MD'
# Technical Stack

## Package Managers (CRITICAL - DO NOT CHANGE)

**Python Package Manager:** uv
**JavaScript Package Manager:** yarn

## Development Environment

**Frontend Port:** 3001
**Backend Port:** 8001
MD
}

teardown() {
  rm -f .agent-os/product/tech-stack.md .env .env.local
}

@test "resolver reads tech-stack defaults" {
  run python3 scripts/config-resolver.py
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"python_package_manager":"uv"'
  echo "$output" | grep -q '"javascript_package_manager":"yarn"'
  echo "$output" | grep -q '"frontend_port":3001'
  echo "$output" | grep -q '"backend_port":8001'
}

@test ".env overrides ports with higher precedence" {
  echo "PORT=3100" > .env.local
  echo "API_PORT=8100" > .env
  run python3 scripts/config-resolver.py
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"frontend_port":3100'
  echo "$output" | grep -q '"backend_port":8100'
}


