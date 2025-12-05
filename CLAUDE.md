# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

個人用の設定ファイル（dotfiles）管理リポジトリ。`~/.config`ディレクトリ全体をシンボリックリンクで管理する。

## セットアップ

```bash
./scripts/setup.sh
```

このスクリプトは：
- `~/.config` を本リポジトリの `.config/` へのシンボリックリンクとして作成
- 既存の `~/.config` がある場合は `~/.config.backup.{timestamp}` にバックアップ
- `~/.zshrc` に `.config/zsh/.zshrc` を読み込む行を追記
- 既に設定済みの場合は何もしない（冪等性）

## 管理対象の設定ファイル

- `.config/git/ignore` - グローバルgitignore
- `.config/htop/htoprc` - htop設定（htop自身が自動更新する）
- `.config/mise/config.toml` - mise（asdf後継）のグローバルツール設定
- `.config/wezterm/wezterm.lua` - WezTermターミナル設定
- `.config/zsh/.zshrc` - zsh設定（Zinit + Powerlevel10k）
- `.config/zsh/.p10k.zsh` - Powerlevel10k設定（`p10k configure`で生成）

## 注意事項

- `.gitignore`で除外されている設定ファイル（gcloud, firebase, 1password等）は機密情報を含むため管理対象外
- htoprcはhtop終了時に自動書き換えされるため、手動編集は推奨しない
- zsh設定を使用するには事前に `brew install fzf` が必要
- 初回ターミナル起動時にZinitが自動でプラグインをインストールする
- Powerlevel10kの設定は `p10k configure` で対話的に生成
