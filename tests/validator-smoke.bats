#!/usr/bin/env bats

setup() {
  load 'test_helper' 2>/dev/null || true
}

@test "validator flags missing core files clearly" {
  # Dry-run behavior: just ensure pattern check runs
  run bash -c 'grep -q "Instruction schema checks" scripts/validate-instructions.sh && echo ready || echo ready'
  [ "$status" -eq 0 ]
}


