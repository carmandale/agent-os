#!/bin/bash

# Test config injection system
echo "Testing project configuration injection..."

# Create a test project
TEST_DIR="/tmp/test-config-project"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Initialize git
git init >/dev/null 2>&1
git config user.email "test@example.com" >/dev/null 2>&1
git config user.name "Test User" >/dev/null 2>&1

# Create test project files
cat > package.json << EOF
{
  "name": "test-project",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev"
  }
}
EOF

# Create yarn.lock to indicate yarn usage
touch yarn.lock

# Create .env.local with custom port
cat > .env.local << EOF
PORT=3005
NEXT_PUBLIC_API_URL=http://localhost:8005
EOF

# Create .env with backend port
cat > .env << EOF
API_PORT=8005
DATABASE_URL=postgresql://localhost/test
EOF

# Create Python project files
cat > requirements.txt << EOF
fastapi
uvicorn
EOF

# Create uv.lock to indicate uv usage
touch uv.lock

# Create startup script
cat > start.sh << EOF
#!/bin/bash
echo "Starting test project..."
EOF
chmod +x start.sh

# Source the config injector
source /Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/agent-os/hooks/lib/project-config-injector.sh

# Test the injection
echo
echo "=== Configuration Injection Test ==="
echo
build_config_reminder

# Cleanup
cd /Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/agent-os
rm -rf "$TEST_DIR"

echo
echo "=== Test Complete ==="