# WezTerm ユーティリティ関数

# タブタイトルを変更する関数
tab_title() {
  if [[ -z "$1" ]]; then
    echo "Usage: tab_title <title>"
    return 1
  fi
  printf '\033]2;%s\033\\' "$1"
}

# 現在のディレクトリ名をタブタイトルに設定
tab_title_pwd() {
  printf '\033]2;%s\033\\' "${PWD##*/}"
}

# タブタイトルをリセット（デフォルトに戻す）
tab_title_reset() {
  printf '\033]2;\033\\'
}
