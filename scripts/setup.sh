#!/bin/bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTCONFIG_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_CONFIG_DIR="$DOTCONFIG_DIR/.config"
TARGET_CONFIG_DIR="$HOME/.config"

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

detect_os() {
    if [ "$(uname)" = "Darwin" ]; then
        echo "macos"
    else
        echo "linux"
    fi
}

OS="$(detect_os)"

setup_config_symlink() {
    # 1. 移行処理: ~/.config がリポジトリ全体へのリンクになっている場合
    if [ -L "$TARGET_CONFIG_DIR" ]; then
        current_link=$(readlink "$TARGET_CONFIG_DIR")
        if [ "$current_link" = "$SOURCE_CONFIG_DIR" ]; then
            log_warn "Detected ~/.config linked to repo directly. Migrating to individual directory links..."
            rm "$TARGET_CONFIG_DIR"
            mkdir -p "$TARGET_CONFIG_DIR"
        else
            # 別の場所へのリンクの場合、安全のためエラーにする
             log_error "~/.config is a symlink to different location: $current_link"
             log_error "Please resolve manually."
             exit 1
        fi
    fi

    if [ ! -d "$TARGET_CONFIG_DIR" ]; then
        mkdir -p "$TARGET_CONFIG_DIR"
        log_info "Created directory: $TARGET_CONFIG_DIR"
    fi

    # 2. サブディレクトリごとのリンク作成
    # SOURCE_CONFIG_DIR内のディレクトリをループ
    for config_path in "$SOURCE_CONFIG_DIR"/*; do
        config_name=$(basename "$config_path")
        target_path="$TARGET_CONFIG_DIR/$config_name"

        # ディレクトリ以外はスキップ（必要に応じてファイルも対応可能だが現状はディレクトリのみ）
        if [ ! -d "$config_path" ]; then
            continue
        fi

        # 既にリンク済みかチェック
        if [ -L "$target_path" ]; then
            current_link=$(readlink "$target_path")
            if [ "$current_link" = "$config_path" ]; then
                log_info "~/.config/$config_name is already linked"
                continue
            else
                log_warn "~/.config/$config_name is a symlink to different location: $current_link"
                log_warn "Backing up and replacing..."
                mv "$target_path" "${target_path}.backup.$(date +%Y%m%d%H%M%S)"
            fi
        # 実ディレクトリ/ファイルが存在する場合はバックアップ
        elif [ -e "$target_path" ]; then
             log_warn "Existing ~/.config/$config_name found. Backing up."
             mv "$target_path" "${target_path}.backup.$(date +%Y%m%d%H%M%S)"
        fi

        ln -s "$config_path" "$target_path"
        log_info "Created symlink: ~/.config/$config_name -> $config_path"
    done
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
        log_warn "Homebrew (or Linuxbrew) is not installed. Skipping."
        return 0
    fi

    if [ ! -f "$BREWFILE" ]; then
        log_warn "Brewfile not found. Skipping."
        return 0
    fi

    log_info "Installing packages from Brewfile..."

    if [ "$OS" = "macos" ]; then
        brew bundle --file="$BREWFILE"
    else
        # Linux: exclude 'cask' lines
        local TEMP_BREWFILE
        TEMP_BREWFILE=$(mktemp)
        # cask行を除外して一時ファイルに保存
        grep -v "^cask" "$BREWFILE" > "$TEMP_BREWFILE"

        log_info "Running brew bundle (excluding casks for Linux)..."
        # --file で一時ファイルを指定
        # brew bundle がエラーを返しても続行するか？ set -e なので止まる。
        # 失敗する可能性のあるパッケージがある場合は考慮が必要だが、
        # 今回は基本的なCLIツールのみなのでそのまま実行。
        brew bundle --file="$TEMP_BREWFILE" || log_warn "brew bundle had some errors."

        rm "$TEMP_BREWFILE"
    fi

    log_info "Brewfile installation complete"
}

setup_hammerspoon() {
    if [ "$OS" != "macos" ]; then
        log_info "Skipping Hammerspoon setup (macOS only)"
        return 0
    fi

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

setup_claude() {
    local SOURCE_CLAUDE_DIR="$DOTCONFIG_DIR/.claude"
    local TARGET_CLAUDE_DIR="$HOME/.claude"

    # ~/.claudeが存在しない場合は作成
    if [ ! -d "$TARGET_CLAUDE_DIR" ]; then
        mkdir -p "$TARGET_CLAUDE_DIR"
        log_info "Created ~/.claude directory"
    fi

    # CLAUDE.mdのシンボリックリンクを作成
    local SOURCE_CLAUDE_MD="$SOURCE_CLAUDE_DIR/CLAUDE.md"
    local TARGET_CLAUDE_MD="$TARGET_CLAUDE_DIR/CLAUDE.md"

    if [ -L "$TARGET_CLAUDE_MD" ]; then
        current_link=$(readlink "$TARGET_CLAUDE_MD")
        if [ "$current_link" = "$SOURCE_CLAUDE_MD" ]; then
            log_info "~/.claude/CLAUDE.md is already linked"
            return 0
        else
            log_warn "~/.claude/CLAUDE.md is a symlink to different location: $current_link"
            rm "$TARGET_CLAUDE_MD"
        fi
    elif [ -f "$TARGET_CLAUDE_MD" ]; then
        log_warn "Existing ~/.claude/CLAUDE.md found. Backing up."
        mv "$TARGET_CLAUDE_MD" "$TARGET_CLAUDE_MD.backup.$(date +%Y%m%d%H%M%S)"
    fi

    ln -s "$SOURCE_CLAUDE_MD" "$TARGET_CLAUDE_MD"
    log_info "Created symlink: ~/.claude/CLAUDE.md -> $SOURCE_CLAUDE_MD"
}

# メイン処理
log_info "Detected OS: $OS"
setup_config_symlink
setup_zshrc
setup_brewfile
setup_hammerspoon
setup_claude

log_info "Setup complete!"
