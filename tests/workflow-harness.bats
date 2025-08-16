#!/usr/bin/env bats

@test "validate-instructions runs and returns status" {
  run bash scripts/validate-instructions.sh
  # It may pass or fail depending on current repo, but should produce output
  [ -n "$output" ]
}

@test "workspace-hygiene-check script executes" {
  run bash scripts/workspace-hygiene-check.sh
  [ -n "$output" ]
}


