#!/bin/bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTCONFIG_DIR="$(dirname "$SCRIPT_DIR")"

# 色付きの出力用
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cd "$DOTCONFIG_DIR"

# ローカルに未コミットの変更があるかチェック
if ! git diff --quiet || ! git diff --cached --quiet; then
    log_warn "ローカルに未コミットの変更があります"
    git status --short
    echo ""
    read -p "変更を stash して続行しますか？ [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        git stash push -m "dotconfig update $(date +%Y%m%d%H%M%S)"
        log_info "変更を stash しました"
    else
        log_error "更新を中止しました"
        exit 1
    fi
fi

# リモートから最新を取得
log_info "リモートから最新を取得中..."
git fetch origin main

# 更新があるかチェック
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    log_info "既に最新です"
    exit 0
fi

# 更新内容を表示
log_info "更新内容:"
git log --oneline HEAD..origin/main

echo ""
read -p "更新を適用しますか？ [y/N]: " answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    log_info "更新を中止しました"
    exit 0
fi

# 更新を適用
git pull origin main
log_info "更新が完了しました"

# setup.shを再実行するか確認
echo ""
read -p "setup.sh を再実行しますか？ [y/N]: " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    "$SCRIPT_DIR/setup.sh"
fi
