#!/bin/bash

# update-local-install.sh
# Updates local Agent OS installation to use canonical file names (no versions)

set -e

echo "🧹 Cleaning up local Agent OS installation..."
echo "============================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Update aos alias
echo "📍 Updating aos alias..."
if grep -q "aos-v4" ~/.zshrc 2>/dev/null || grep -q "aos-v4" ~/.bashrc 2>/dev/null; then
    # Update in zshrc if present
    if [ -f ~/.zshrc ]; then
        sed -i.bak 's/aos-v4/aos/g' ~/.zshrc
        echo "  ✓ Updated ~/.zshrc"
    fi
    
    # Update in bashrc if present
    if [ -f ~/.bashrc ]; then
        sed -i.bak 's/aos-v4/aos/g' ~/.bashrc
        echo "  ✓ Updated ~/.bashrc"
    fi
    
    echo -e "${YELLOW}  ⚠️  Please run 'source ~/.zshrc' or 'source ~/.bashrc' to reload${NC}"
else
    echo "  ℹ️  No aos-v4 references found in shell config"
fi

# 2. Copy canonical aos tool if needed
if [ -f ~/.agent-os/tools/aos-v4 ] && [ ! -f ~/.agent-os/tools/aos ]; then
    echo ""
    echo "📦 Installing canonical aos tool..."
    cp ~/.agent-os/tools/aos-v4 ~/.agent-os/tools/aos
    chmod +x ~/.agent-os/tools/aos
    echo "  ✓ Created ~/.agent-os/tools/aos"
fi

# 3. Copy canonical workflow hook if needed  
if [ -f ~/.agent-os/hooks/workflow-enforcement-hook-v2.py ] && [ ! -f ~/.agent-os/hooks/workflow-enforcement-hook.py ]; then
    echo ""
    echo "🪝 Installing canonical workflow hook..."
    cp ~/.agent-os/hooks/workflow-enforcement-hook-v2.py ~/.agent-os/hooks/workflow-enforcement-hook.py
    echo "  ✓ Created ~/.agent-os/hooks/workflow-enforcement-hook.py"
fi

# 4. Update Claude settings
if [ -f ~/.claude/settings.json ]; then
    echo ""
    echo "⚙️  Updating Claude Code settings..."
    if grep -q "workflow-enforcement-hook-v2.py" ~/.claude/settings.json; then
        sed -i.bak 's/workflow-enforcement-hook-v2\.py/workflow-enforcement-hook.py/g' ~/.claude/settings.json
        echo "  ✓ Updated ~/.claude/settings.json to use canonical hook"
        echo -e "${YELLOW}  ⚠️  Please restart Claude Code for changes to take effect${NC}"
    else
        echo "  ℹ️  Claude settings already using canonical names"
    fi
fi

# 5. Optional: Remove old versioned files
echo ""
echo "🗑️  Optional cleanup of old versioned files:"
echo ""
echo "The following versioned files can be safely removed:"

OLD_FILES=(
    ~/.agent-os/tools/aos-v3
    ~/.agent-os/tools/aos-v4
    ~/.agent-os/tools/aos-background
    ~/.agent-os/tools/aos-improved
    ~/.agent-os/hooks/workflow-enforcement-hook-v2.py
    ~/.agent-os/hooks/workflow-enforcement-hook-v3.py
)

found_old=false
for file in "${OLD_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  - $file"
        found_old=true
    fi
done

if [ "$found_old" = true ]; then
    echo ""
    read -p "Remove these old versioned files? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for file in "${OLD_FILES[@]}"; do
            if [ -f "$file" ]; then
                rm "$file"
                echo "  ✓ Removed $(basename $file)"
            fi
        done
    else
        echo "  ℹ️  Old files kept (you can remove them manually later)"
    fi
else
    echo "  ✓ No old versioned files found"
fi

echo ""
echo -e "${GREEN}✅ Local installation cleanup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Run 'source ~/.zshrc' or 'source ~/.bashrc' to reload shell"
echo "  2. Restart Claude Code to pick up new hook configuration"
echo "  3. Test with 'aos status' to verify everything works"
echo ""