#!/usr/bin/env bash

# Basic test helper for Agent OS tests

# Utility functions for tests
setup_test_repo() {
    export TEST_REPO_DIR=$(mktemp -d)
    cd "$TEST_REPO_DIR"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
}

cleanup_test_repo() {
    if [[ -n "${TEST_REPO_DIR:-}" ]] && [[ -d "$TEST_REPO_DIR" ]]; then
        cd /
        rm -rf "$TEST_REPO_DIR"
        unset TEST_REPO_DIR
    fi
}
