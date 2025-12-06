# dotconfig

個人用の設定ファイル（dotfiles）管理リポジトリ

## 含まれる設定

### アプリケーション設定

- **Git** - グローバルgitignore
- **Htop** - システムモニタ設定
- **Mise** - ランタイムバージョン管理（asdf後継）
- **WezTerm** - ターミナルエミュレータ設定
- **Zsh** - シェル設定（Zinit + Powerlevel10k）
- **Hammerspoon** - ウィンドウ管理とアプリケーション起動

### パッケージ管理

- **Brewfile** - Homebrewパッケージ定義

## セットアップ

```bash
git clone https://github.com/mizunomi32/dotconfig.git
cd dotconfig
./scripts/setup.sh
```

このスクリプトは以下を実行します：

1. `~/.config` を本リポジトリの `.config/` へのシンボリックリンクとして作成
2. `~/.hammerspoon` を本リポジトリの `.hammerspoon/` へのシンボリックリンクとして作成
3. `~/.zshrc` に `.config/zsh/.zshrc` を読み込む行を追記
4. Brewfileからパッケージをインストール（Homebrewがインストールされている場合）

既存のディレクトリがある場合は、タイムスタンプ付きでバックアップされます。

## ドキュメント

- [Hammerspoonキーバインド](docs/hammerspoon.md)

## 主要な機能

### Zsh

- Zinitによるプラグイン管理
- Powerlevel10kテーマ
- fzfによる履歴検索
- 補完機能の強化

初回ターミナル起動時にZinitが自動でプラグインをインストールします。

### Hammerspoon

ウィンドウ管理とアプリケーション起動のキーバインドを提供します。
詳細は [Hammerspoonキーバインド](docs/hammerspoon.md) を参照してください。

主なキーバインド：
- `⌘ + ⌥ + 矢印キー`: ウィンドウを画面の半分に配置
- `⌘ + ⌥ + ⌃ + 矢印キー`: ウィンドウを画面の4分の1に配置
- `⌃` を2回タップ: WezTermを表示/非表示切り替え

## 更新

設定を更新する場合：

```bash
cd ~/src/github.com/mizunomi32/dotconfig
git pull
./scripts/update.sh  # 必要に応じてパッケージを更新
```

## 注意事項

- `.gitignore`で除外されている設定ファイル（gcloud, firebase, 1password等）は機密情報を含むため管理対象外
- htoprcはhtop終了時に自動書き換えされるため、手動編集は推奨しない
- zsh設定を使用するには事前に `brew install fzf` が必要（Brewfileに含まれています）
- Powerlevel10kの設定は `p10k configure` で対話的に再生成可能
