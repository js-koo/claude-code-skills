#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="$HOME/.claude-code-skills"
COMMANDS_DIR="$HOME/.claude/commands"

echo -e "${YELLOW}"
echo "╔═══════════════════════════════════════╗"
echo "║    Claude Code Skills Uninstaller     ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Remove symlinks
echo -e "${YELLOW}🔗 심링크 제거 중...${NC}"
for cmd in "$INSTALL_DIR/commands"/*.md 2>/dev/null; do
    filename=$(basename "$cmd")
    target="$COMMANDS_DIR/$filename"

    if [ -L "$target" ]; then
        rm "$target"
        echo "   ✓ $filename 제거됨"
    fi
done

# Remove install directory
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}📁 설치 폴더 제거 중...${NC}"
    rm -rf "$INSTALL_DIR"
    echo "   ✓ $INSTALL_DIR 제거됨"
fi

echo ""
echo -e "${GREEN}✅ 삭제 완료!${NC}"
echo ""
echo -e "${YELLOW}⚠️  Claude Code를 재시작하세요.${NC}"
echo ""
