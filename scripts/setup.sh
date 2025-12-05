#!/bin/bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTCONFIG_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_CONFIG_DIR="$DOTCONFIG_DIR/.config"
TARGET_CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config.backup.$(date +%Y%m%d%H%M%S)"

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

# 既にシンボリックリンクで正しくリンクされている場合
if [ -L "$TARGET_CONFIG_DIR" ]; then
    current_link=$(readlink "$TARGET_CONFIG_DIR")
    if [ "$current_link" = "$SOURCE_CONFIG_DIR" ]; then
        log_info "~/.config is already linked to $SOURCE_CONFIG_DIR"
        exit 0
    else
        log_error "~/.config is a symlink to different location: $current_link"
        log_error "Remove manually and re-run this script."
        exit 1
    fi
fi

# ~/.configが存在する場合はバックアップ
if [ -d "$TARGET_CONFIG_DIR" ]; then
    log_warn "Existing ~/.config found. Backing up to $BACKUP_DIR"
    mv "$TARGET_CONFIG_DIR" "$BACKUP_DIR"
    log_info "Backup created at $BACKUP_DIR"
fi

# シンボリックリンクを作成
ln -s "$SOURCE_CONFIG_DIR" "$TARGET_CONFIG_DIR"
log_info "Created symlink: ~/.config -> $SOURCE_CONFIG_DIR"

log_info "Setup complete!"
