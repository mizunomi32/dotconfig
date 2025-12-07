# ghq + fzf 連携

cdrepo() {
    local repodir=$(ghq list | fzf -1 +m) && cd $(ghq root)/$repodir
}

# ghq get のエイリアス
alias gg='ghq get'
