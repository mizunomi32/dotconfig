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

setup_config_symlink() {
    # 既にシンボリックリンクで正しくリンクされている場合
    if [ -L "$TARGET_CONFIG_DIR" ]; then
        current_link=$(readlink "$TARGET_CONFIG_DIR")
        if [ "$current_link" = "$SOURCE_CONFIG_DIR" ]; then
            log_info "~/.config is already linked to $SOURCE_CONFIG_DIR"
            return 0
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
}

setup_zshrc() {
    local ZSHRC="$HOME/.zshrc"
    local SOURCE_LINE="[ -f ~/.config/zsh/.zshrc ] && source ~/.config/zsh/.zshrc"
    local MARKER="# dotconfig zsh settings"

    # ~/.zshrcが存在しない場合は作成
    if [ ! -f "$ZSHRC" ]; then
        log_warn "~/.zshrc not found. Creating new file."
        touch "$ZSHRC"
    fi

    # 既に追記済みかチェック
    if grep -qF "$MARKER" "$ZSHRC"; then
        log_info "zsh settings already configured in ~/.zshrc"
        return 0
    fi

    # source行を追記
    echo "" >> "$ZSHRC"
    echo "$MARKER" >> "$ZSHRC"
    echo "$SOURCE_LINE" >> "$ZSHRC"
    log_info "Added zsh settings to ~/.zshrc"
}

setup_brewfile() {
    local BREWFILE="$DOTCONFIG_DIR/Brewfile"

    if ! command -v brew &>/dev/null; then
        log_warn "Homebrew がインストールされていません。スキップします。"
        return 0
    fi

    if [ ! -f "$BREWFILE" ]; then
        log_warn "Brewfile が見つかりません。スキップします。"
        return 0
    fi

    log_info "Brewfile からパッケージをインストール中..."
    brew bundle --file="$BREWFILE"
    log_info "Brewfile のインストールが完了しました"
}

setup_hammerspoon() {
    local SOURCE_HAMMERSPOON_DIR="$DOTCONFIG_DIR/.hammerspoon"
    local TARGET_HAMMERSPOON_DIR="$HOME/.hammerspoon"
    local BACKUP_HAMMERSPOON_DIR="$HOME/.hammerspoon.backup.$(date +%Y%m%d%H%M%S)"

    # 既にシンボリックリンクで正しくリンクされている場合
    if [ -L "$TARGET_HAMMERSPOON_DIR" ]; then
        current_link=$(readlink "$TARGET_HAMMERSPOON_DIR")
        if [ "$current_link" = "$SOURCE_HAMMERSPOON_DIR" ]; then
            log_info "~/.hammerspoon is already linked to $SOURCE_HAMMERSPOON_DIR"
            return 0
        else
            log_error "~/.hammerspoon is a symlink to different location: $current_link"
            log_error "Remove manually and re-run this script."
            exit 1
        fi
    fi

    # ~/.hammerspoonが存在する場合はバックアップ
    if [ -d "$TARGET_HAMMERSPOON_DIR" ]; then
        log_warn "Existing ~/.hammerspoon found. Backing up to $BACKUP_HAMMERSPOON_DIR"
        mv "$TARGET_HAMMERSPOON_DIR" "$BACKUP_HAMMERSPOON_DIR"
        log_info "Backup created at $BACKUP_HAMMERSPOON_DIR"
    fi

    # シンボリックリンクを作成
    ln -s "$SOURCE_HAMMERSPOON_DIR" "$TARGET_HAMMERSPOON_DIR"
    log_info "Created symlink: ~/.hammerspoon -> $SOURCE_HAMMERSPOON_DIR"
}

# メイン処理
setup_config_symlink
setup_zshrc
setup_brewfile
setup_hammerspoon

log_info "Setup complete!"
