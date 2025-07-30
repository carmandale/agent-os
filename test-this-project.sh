#!/bin/bash

# Test config injection on this project
cd "$(dirname "$0")"
source hooks/lib/project-config-injector.sh

echo "Testing config injection on Agent OS project:"
echo "============================================="
build_config_reminder