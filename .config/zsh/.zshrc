# Zinit初期化
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Powerlevel10k
zinit ice depth=1
zinit light romkatv/powerlevel10k

# プラグイン
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

# fzf連携（履歴検索: Ctrl+R、ファイル検索: Ctrl+T、ディレクトリ移動: Alt+C）
zinit light junegunn/fzf
zinit light Aloxaf/fzf-tab

# 補完システム初期化
autoload -Uz compinit && compinit

# p10k設定読み込み
[[ -f ~/.config/zsh/.p10k.zsh ]] && source ~/.config/zsh/.p10k.zsh

# エイリアス読み込み
[[ -f ~/.config/zsh/aliases.zsh ]] && source ~/.config/zsh/aliases.zsh

# WezTerm ユーティリティ
[[ -f ~/.config/zsh/wezterm-utils.zsh ]] && source ~/.config/zsh/wezterm-utils.zsh

# dotconfig更新チェック
[[ -f ~/.config/zsh/dotconfig-update-check.zsh ]] && source ~/.config/zsh/dotconfig-update-check.zsh

# ghq連携
[[ -f ~/.config/zsh/ghq-utils.zsh ]] && source ~/.config/zsh/ghq-utils.zsh
