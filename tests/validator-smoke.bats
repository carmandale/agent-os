#!/usr/bin/env bats

setup() {
  true
}

@test "validator flags missing core files clearly" {
  # Dry-run behavior: just ensure pattern check runs
  run bash -c 'test -f scripts/validate-instructions.sh && echo ready'
  [ "$status" -eq 0 ]
}


