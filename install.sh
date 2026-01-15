#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/js-koo/claude-code-skills.git"
INSTALL_DIR="$HOME/.claude-code-skills"
COMMANDS_DIR="$HOME/.claude/commands"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════╗"
echo "║     Claude Code Skills Installer      ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Check git
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ git is not installed.${NC}"
    exit 1
fi

# Clone or update
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}📦 Existing installation found. Updating...${NC}"
    cd "$INSTALL_DIR"
    git pull
else
    echo -e "${GREEN}📥 Downloading...${NC}"
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Create commands directory
mkdir -p "$COMMANDS_DIR"

# Create symlinks
echo -e "${GREEN}🔗 Creating symlinks...${NC}"
for cmd in "$INSTALL_DIR/commands"/*.md; do
    filename=$(basename "$cmd")
    target="$COMMANDS_DIR/$filename"

    if [ -L "$target" ]; then
        rm "$target"
    fi

    ln -s "$cmd" "$target"
    echo "   ✓ $filename"
done

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✅ Installation complete!          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
echo ""
echo -e "Available commands:"
echo -e "  ${BLUE}/pr-resolver${NC} - Handle PR review comments"
echo ""
echo -e "${YELLOW}⚠️  Please restart Claude Code.${NC}"
echo ""
