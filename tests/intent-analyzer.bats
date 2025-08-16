#!/usr/bin/env bats

@test "classifies maintenance" {
  run bash scripts/intent-analyzer.sh --text "fix failing tests in CI"
  [ "$status" -eq 0 ]
  [ "$output" = "MAINTENANCE" ]
}

@test "classifies new work" {
  run bash scripts/intent-analyzer.sh --text "implement new dashboard feature"
  [ "$status" -eq 0 ]
  [ "$output" = "NEW" ]
}

@test "ambiguous when unclear" {
  run bash scripts/intent-analyzer.sh --text "update authentication system"
  [ "$status" -eq 0 ]
  [ "$output" = "AMBIGUOUS" ]
}


