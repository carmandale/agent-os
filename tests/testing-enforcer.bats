#!/usr/bin/env bats

@test "enforcer passes when no input" {
  run bash scripts/testing-enforcer.sh <<<""
  [ "$status" -eq 0 ]
}

@test "enforcer blocks completion without evidence" {
  run bash scripts/testing-enforcer.sh <<'EOF'
This feature is ✅ complete.
EOF
  [ "$status" -ne 0 ]
}

@test "enforcer allows completion with evidence section" {
  run bash scripts/testing-enforcer.sh <<'EOF'
This feature is ✅ complete.

## Evidence
```
All tests passed
```
EOF
  [ "$status" -eq 0 ]
}
