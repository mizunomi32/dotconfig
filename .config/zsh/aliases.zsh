# エイリアス設定
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias ..='cd ..'
alias ...='cd ../..'
alias la='ls -A'
alias ll='ls -alF'
alias l='ls -CF'
alias g='git'
alias ga='git add'
alias gc='git commit -v'
alias gp='git push'
alias gst='git status'
alias gl='git log --oneline --graph --decorate'
alias gco='git checkout'
alias gcb='git checkout -b'
alias df='df -h'
alias mkdir='mkdir -p'
alias vim='nvim'

alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up'
alias dcd='docker compose down'

# dotconfig
alias setup='"$(dirname "$(readlink ~/.config)")"/scripts/setup.sh'
alias update='"$(dirname "$(readlink ~/.config)")"/scripts/update.sh'

