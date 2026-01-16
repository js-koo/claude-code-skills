#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="$HOME/.claude-workflows"
COMMANDS_DIR="$HOME/.claude/commands"

echo -e "${YELLOW}"
echo "╔═══════════════════════════════════════╗"
echo "║    Claude Code Skills Uninstaller     ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Remove symlinks
echo -e "${YELLOW}🔗 Removing symlinks...${NC}"
for cmd in "$INSTALL_DIR/commands"/*.md 2>/dev/null; do
    filename=$(basename "$cmd")
    target="$COMMANDS_DIR/$filename"

    if [ -L "$target" ]; then
        rm "$target"
        echo "   ✓ $filename removed"
    fi
done

# Remove install directory
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}📁 Removing installation directory...${NC}"
    rm -rf "$INSTALL_DIR"
    echo "   ✓ $INSTALL_DIR removed"
fi

echo ""
echo -e "${GREEN}✅ Uninstall complete!${NC}"
echo ""
echo -e "${YELLOW}⚠️  Please restart Claude Code.${NC}"
echo ""
