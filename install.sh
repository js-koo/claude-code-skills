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
    echo -e "${RED}❌ git이 설치되어 있지 않습니다.${NC}"
    exit 1
fi

# Clone or update
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}📦 기존 설치 발견. 업데이트 중...${NC}"
    cd "$INSTALL_DIR"
    git pull origin main
else
    echo -e "${GREEN}📥 다운로드 중...${NC}"
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Create commands directory
mkdir -p "$COMMANDS_DIR"

# Create symlinks
echo -e "${GREEN}🔗 심링크 생성 중...${NC}"
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
echo -e "${GREEN}║        ✅ 설치 완료!                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
echo ""
echo -e "사용 가능한 명령어:"
echo -e "  ${BLUE}/pr-resolver${NC} - PR 리뷰 코멘트 처리"
echo ""
echo -e "${YELLOW}⚠️  Claude Code를 재시작하세요.${NC}"
echo ""
