# dotconfig

個人用の設定ファイル管理リポジトリ

## 含まれる設定

- git
- htop
- mise
- wezterm

## セットアップ

```bash
git clone https://github.com/mizunomi32/dotconfig.git
cd dotconfig
./scripts/setup.sh
```

このスクリプトは `~/.config` を本リポジトリの `.config` へのシンボリックリンクとして作成します。

既存の `~/.config` がある場合は `~/.config.backup.{timestamp}` にバックアップされます。
