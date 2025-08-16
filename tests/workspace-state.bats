#!/usr/bin/env bats

setup() {
  TMPDIR=$(mktemp -d)
  pushd "$TMPDIR" >/dev/null
  git init -q
  git config user.email test@example.com
  git config user.name test
  mkdir -p scripts
  cp "$BATS_TEST_DIRNAME/../scripts/workspace-state.sh" scripts/
}

teardown() {
  popd >/dev/null
  rm -rf "$TMPDIR"
}

@test "workspace-state emits json and caches" {
  run env AGENT_OS_STATE_TTL=0 bash scripts/workspace-state.sh
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"dirty":'
  echo "$output" | grep -q '"open_prs":'
}


