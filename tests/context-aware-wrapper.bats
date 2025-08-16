#!/usr/bin/env bats

setup() {
  # Create a clean git repo for isolation
  TMPDIR=$(mktemp -d)
  pushd "$TMPDIR" >/dev/null
  git init -q
  git config user.email test@example.com
  git config user.name test
  # copy scripts into temp so tests run relative
  mkdir -p scripts
  cp "$BATS_TEST_DIRNAME/../scripts/intent-analyzer.sh" scripts/
  cp "$BATS_TEST_DIRNAME/../scripts/context-aware-wrapper.sh" scripts/
  cp "$BATS_TEST_DIRNAME/../scripts/workspace-state.sh" scripts/
}

teardown() {
  popd >/dev/null
  rm -rf "$TMPDIR"
}

@test "maintenance allowed even when dirty" {
  echo test > foo
  git add foo
  # dirty state is fine for maintenance
  run env AGENT_OS_STATE_TTL=0 bash scripts/context-aware-wrapper.sh --intent-text "fix failing tests" --action-type write
  [ "$status" -eq 0 ]
  [[ "$output" =~ ALLOW ]]
}

@test "new work blocked when dirty" {
  echo test2 >> foo
  run env AGENT_OS_STATE_TTL=0 bash scripts/context-aware-wrapper.sh --intent-text "implement new feature" --action-type write
  [ "$status" -ne 0 ]
  [[ "$output" =~ BLOCK ]]
}

@test "ambiguous allows read-only but blocks write" {
  run env AGENT_OS_STATE_TTL=0 bash scripts/context-aware-wrapper.sh --intent-text "update authentication" --action-type read
  [ "$status" -eq 0 ]
  run env AGENT_OS_STATE_TTL=0 bash scripts/context-aware-wrapper.sh --intent-text "update authentication" --action-type write
  [ "$status" -ne 0 ]
}


